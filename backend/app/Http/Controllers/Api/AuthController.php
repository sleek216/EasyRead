<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\AccountDeletion;
use App\Models\Setting;
use App\Mail\OtpPasswordResetMail;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    /**
     * User Registration
     * Creates new user account with secure defaults and returns Sanctum Bearer token.
     */
    public function register(Request $request)
    {
        $inputEmail = strtolower(trim($request->input('email', '')));
        if ($inputEmail !== '') {
            // If account was soft-deleted, force delete it so user can register a fresh account
            User::onlyTrashed()->whereRaw('LOWER(TRIM(email)) = ?', [$inputEmail])->forceDelete();

            // If an active account already exists, inform the user to log in
            $existing = User::whereRaw('LOWER(TRIM(email)) = ?', [$inputEmail])->first();
            if ($existing) {
                return response()->json([
                    'success' => false,
                    'already_registered' => true,
                    'field' => 'email',
                    'message' => 'This email is already registered. Please log in to continue.',
                    'errors' => [
                        'email' => ['This email is already registered. Please log in to continue.'],
                    ],
                ], 422);
            }
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email:rfc|max:255|unique:users,email',
            'password' => ['required', 'string', Password::min(6)],
            'device_name' => 'nullable|string|max:100',
        ], [
            'email.unique' => 'This email is already registered. Please log in to continue.',
        ]);

        $deviceName = $request->input('device_name', 'Mobile Device');
        $freePlan = \App\Models\Plan::where('slug', 'free')->first();

        $user = User::create([
            'name' => trim($validated['name']),
            'email' => strtolower(trim($validated['email'])),
            'password' => Hash::make($validated['password']),
            'role' => 'reader',
            'is_premium' => false,
            'plan_id' => $freePlan?->id,
            'subscription_plan' => $freePlan?->name ?? 'Free Tier',
            'subscription_price' => 'Free',
            'is_active' => true,
            'ai_free_uses_left' => $freePlan?->ai_daily_limit ?? 10,
            'device_name' => $deviceName,
            'last_active_at' => now(),
        ]);

        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'success' => true,
            'is_new_user' => true,
            'message' => 'Account registered successfully',
            'token_type' => 'Bearer',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'is_premium' => $user->is_premium,
                'is_new_user' => true,
                'plan_id' => $user->plan_id,
                'subscription_plan' => $user->subscription_plan,
                'subscription_expires_at' => $user->subscription_expires_at ? $user->subscription_expires_at->toISOString() : null,
                'feature_permissions' => $this->resolvePermissionsForUser($user),
                'ai_free_uses_left' => $user->ai_free_uses_left,
                'device_name' => $user->device_name,
                'day_streak' => (int)($user->day_streak ?? 1),
                'total_words_read' => (int)($user->total_words_read ?? 0),
                'sync_enabled' => (bool)($user->sync_enabled ?? true),
                'preferred_language' => $user->preferred_language ?? 'Urdu',
                'created_at' => $user->created_at->toISOString(),
            ],
        ], 201);
    }

    /**
     * User Login with Rate-Limiting (Brute-force protection)
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'nullable|string|max:100',
        ]);

        $email = strtolower(trim($request->email));
        $throttleKey = 'login_attempts:' . $email . '|' . $request->ip();

        // 1. Rate-Limiting: Max 5 attempts per 60 seconds
        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = RateLimiter::availableIn($throttleKey);
            return response()->json([
                'success' => false,
                'message' => "Too many login attempts. Please try again in {$seconds} seconds.",
                'retry_after' => $seconds,
            ], 429);
        }

        $user = User::where('email', $email)->first();

        // 2. Check if account exists
        if (!$user) {
            RateLimiter::hit($throttleKey, 60);
            return response()->json([
                'success' => false,
                'not_registered' => true,
                'field' => 'email',
                'message' => 'This email is not registered yet. Please register first, then log in.',
                'errors' => [
                    'email' => ['This email is not registered yet. Please register first, then log in.'],
                ],
            ], 404);
        }

        // 3. Password Verification
        if (!Hash::check($request->password, $user->password)) {
            RateLimiter::hit($throttleKey, 60);
            return response()->json([
                'success' => false,
                'field' => 'password',
                'message' => 'Incorrect password entered. Please try again.',
                'errors' => [
                    'password' => ['The password you entered is incorrect. Please check your password.'],
                ],
            ], 401);
        }

        // 3. Check Account Status (Banned/Suspended)
        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been suspended by EasyRead. Please contact support.',
            ], 403);
        }

        // Clear rate limiter on successful authentication
        RateLimiter::clear($throttleKey);

        $deviceName = $request->input('device_name', 'Mobile App');
        $user->update([
            'last_active_at' => now(),
            'device_name' => $deviceName,
        ]);

        // Generate new Bearer token
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'token_type' => 'Bearer',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'is_premium' => $user->is_premium,
                'plan_id' => $user->plan_id,
                'subscription_plan' => $user->subscription_plan,
                'subscription_expires_at' => $user->subscription_expires_at ? $user->subscription_expires_at->toISOString() : null,
                'feature_permissions' => $this->resolvePermissionsForUser($user),
                'ai_free_uses_left' => $user->ai_free_uses_left,
                'device_name' => $user->device_name,
                'day_streak' => (int)($user->day_streak ?? 1),
                'total_words_read' => (int)($user->total_words_read ?? 0),
                'sync_enabled' => (bool)($user->sync_enabled ?? true),
                'preferred_language' => $user->preferred_language ?? 'Urdu',
                'last_active_at' => $user->last_active_at ? $user->last_active_at->toISOString() : null,
                'created_at' => $user->created_at->toISOString(),
            ],
        ]);
    }

    /**
     * Social Authentication (Google & Apple)
     * Verifies or registers a social OAuth user, assigns Free Tier if new,
     * and returns a Sanctum Bearer token.
     */
    public function socialLogin(Request $request)
    {
        $validated = $request->validate([
            'provider' => 'required|in:google,apple',
            'email' => 'required|string|email:rfc|max:255',
            'name' => 'nullable|string|max:255',
            'provider_id' => 'nullable|string|max:255',
            'avatar_url' => 'nullable|string|max:1000',
            'id_token' => 'nullable|string',
            'device_name' => 'nullable|string|max:100',
        ]);

        $email = strtolower(trim($validated['email']));
        $deviceName = $request->input('device_name', 'Mobile App');

        // 1. Fetch only active (non-trashed) user
        $user = User::whereRaw('LOWER(TRIM(email)) = ?', [$email])->first();

        // 2. If user exists and is suspended by admin, block login immediately!
        if ($user && !$user->is_active) {
            return response()->json([
                'success' => false,
                'is_active' => false,
                'message' => 'Your account has been suspended by EasyRead. Please contact support.',
            ], 403);
        }

        // 3. If account was soft-deleted, wipe all old data completely so fresh account has 0 past data
        $trashedUsers = User::onlyTrashed()->whereRaw('LOWER(TRIM(email)) = ?', [$email])->get();
        foreach ($trashedUsers as $tUser) {
            $tUser->tokens()->delete();
            $tUser->highlights()->delete();
            $tUser->readingProgress()->delete();
            $tUser->vocabularies()->delete();
            $tUser->backups()->delete();
            $tUser->collections()->delete();
            $tUser->collectionBooks()->delete();
            $tUser->books()->delete();
            $tUser->aiLogs()->delete();
            $tUser->forceDelete();
        }

        // 4. Create fresh account if user does not exist
        $isNewUser = false;
        if (!$user) {
            $isNewUser = true;
            $freePlan = \App\Models\Plan::where('slug', 'free')->first();
            $displayName = !empty($validated['name']) ? trim($validated['name']) : explode('@', $email)[0];

            try {
                $user = User::create([
                    'name' => $displayName,
                    'email' => $email,
                    'password' => Hash::make(Str::random(32)),
                    'role' => 'reader',
                    'is_premium' => false,
                    'plan_id' => $freePlan?->id,
                    'subscription_plan' => $freePlan?->name ?? 'Free Tier',
                    'subscription_price' => 'Free',
                    'is_active' => true,
                    'ai_free_uses_left' => $freePlan?->ai_daily_limit ?? 10,
                    'device_name' => $deviceName,
                    'avatar_url' => $validated['avatar_url'] ?? null,
                    'last_active_at' => now(),
                ]);
            } catch (\Illuminate\Database\QueryException $e) {
                $user = User::whereRaw('LOWER(TRIM(email)) = ?', [$email])->first();
            }
        }

        if ($user) {
            // Check again in case of race condition
            if (!$user->is_active) {
                return response()->json([
                    'success' => false,
                    'is_active' => false,
                    'message' => 'Your account has been suspended by EasyRead. Please contact support.',
                ], 403);
            }

            // Update avatar or name if provided and not already set
            $updates = [
                'last_active_at' => now(),
                'device_name' => $deviceName,
            ];
            if (empty($user->avatar_url) && !empty($validated['avatar_url'])) {
                $updates['avatar_url'] = $validated['avatar_url'];
            }
            if (empty($user->name) && !empty($validated['name'])) {
                $updates['name'] = trim($validated['name']);
            }
            $user->update($updates);
        }

        // Generate new Sanctum Bearer token
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'success' => true,
            'is_new_user' => $isNewUser,
            'message' => 'Logged in successfully with ' . ucfirst($validated['provider']),
            'token_type' => 'Bearer',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'is_premium' => $user->is_premium,
                'is_new_user' => $isNewUser,
                'plan_id' => $user->plan_id,
                'subscription_plan' => $user->subscription_plan,
                'subscription_expires_at' => $user->subscription_expires_at ? $user->subscription_expires_at->toISOString() : null,
                'feature_permissions' => $this->resolvePermissionsForUser($user),
                'ai_free_uses_left' => $user->ai_free_uses_left,
                'device_name' => $user->device_name,
                'avatar_url' => $user->avatar_url,
                'day_streak' => (int)($user->day_streak ?? 1),
                'total_words_read' => (int)($user->total_words_read ?? 0),
                'sync_enabled' => (bool)($user->sync_enabled ?? true),
                'preferred_language' => $user->preferred_language ?? 'Urdu',
                'last_active_at' => $user->last_active_at ? $user->last_active_at->toISOString() : null,
                'created_at' => $user->created_at->toISOString(),
            ],
        ]);
    }

    /**
     * Get Authenticated User Profile with Realtime Stats
     */
    public function profile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'is_premium' => $user->is_premium,
                'plan_id' => $user->plan_id,
                'subscription_plan' => $user->subscription_plan,
                'subscription_expires_at' => $user->subscription_expires_at ? $user->subscription_expires_at->toISOString() : null,
                'feature_permissions' => $this->resolvePermissionsForUser($user),
                'is_active' => $user->is_active,
                'ai_free_uses_left' => $user->ai_free_uses_left,
                'device_name' => $user->device_name,
                'day_streak' => (int)($user->day_streak ?? 1),
                'total_words_read' => (int)($user->total_words_read ?? 0),
                'sync_enabled' => (bool)($user->sync_enabled ?? true),
                'preferred_language' => $user->preferred_language ?? 'Urdu',
                'vocabulary_count' => $user->vocabularies()->count(),
                'backups_count' => $user->backups()->count(),
                'books_in_progress' => $user->readingProgress()->count(),
                'last_active_at' => $user->last_active_at ? $user->last_active_at->toISOString() : null,
                'created_at' => $user->created_at->toISOString(),
            ],
        ]);
    }

    /**
     * Update User Profile (Name, Email)
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email:rfc|max:255|unique:users,email,' . $user->id,
        ]);

        if (isset($validated['name'])) {
            $user->name = trim($validated['name']);
        }
        if (isset($validated['email'])) {
            $user->email = strtolower(trim($validated['email']));
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user,
        ]);
    }

    /**
     * Change Password securely (verifying old password)
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => ['required', 'string', Password::min(6), 'different:current_password'],
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'The current password provided is incorrect.',
                'errors' => [
                    'current_password' => ['Current password does not match.'],
                ],
            ], 422);
        }

        $user->password = Hash::make($request->new_password);
        $user->save();

        // Optional security: Revoke other tokens except current
        // $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Password updated successfully.',
        ]);
    }

    /**
     * Forgot Password - Send / Generate 6-digit OTP Reset Code
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $email = strtolower(trim($request->email));

        // Check if user previously deleted their account
        $deletion = AccountDeletion::whereRaw('LOWER(TRIM(email)) = ?', [$email])->latest()->first();
        if ($deletion) {
            return response()->json([
                'success' => false,
                'account_deleted' => true,
                'field' => 'email',
                'message' => 'This account was previously deleted. Please sign up to create a new account.',
            ], 403);
        }

        // Check if user exists
        $user = User::whereRaw('LOWER(TRIM(email)) = ?', [$email])->first();
        if (!$user) {
            return response()->json([
                'success' => false,
                'field' => 'email',
                'message' => 'No account found with this email address.',
            ], 404);
        }

        // Check for suspended account
        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'field' => 'email',
                'message' => 'Your account has been deactivated or suspended. Please contact admin support.',
            ], 403);
        }

        // Rate limit: max 3 OTP requests per email per 10 minutes
        $rateLimitKey = 'otp_request:' . $email;
        if (RateLimiter::tooManyAttempts($rateLimitKey, 3)) {
            $seconds = RateLimiter::availableIn($rateLimitKey);
            return response()->json([
                'success' => false,
                'rate_limited' => true,
                'retry_after' => $seconds,
                'message' => "Too many OTP requests. Please wait {$seconds} seconds before requesting a new code.",
            ], 429);
        }
        RateLimiter::hit($rateLimitKey, 600); // 10 min window

        $otp = (string) random_int(100000, 999999);

        // Store OTP in password_reset_tokens (hashed)
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $email],
            [
                'token' => Hash::make($otp),
                'created_at' => now(),
            ]
        );

        // Send email via background process for instant sub-second UI response
        $phpBin = PHP_BINARY;
        $artisan = base_path('artisan');
        $appName = Setting::get('app_name', 'EasyRead');
        $userName = $user->name ?? 'Reader';

        $dispatched = false;
        if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
            $cmd = sprintf(
                'start /B "" %s %s mail:send-otp %s %s %s > NUL 2>&1',
                escapeshellarg($phpBin),
                escapeshellarg($artisan),
                escapeshellarg($email),
                escapeshellarg($otp),
                escapeshellarg($userName)
            );
            $handle = @popen($cmd, 'r');
            if ($handle) {
                @pclose($handle);
                $dispatched = true;
            }
        } else {
            $cmd = sprintf(
                '%s %s mail:send-otp %s %s %s > /dev/null 2>&1 &',
                escapeshellarg($phpBin),
                escapeshellarg($artisan),
                escapeshellarg($email),
                escapeshellarg($otp),
                escapeshellarg($userName)
            );
            @exec($cmd);
            $dispatched = true;
        }

        // Synchronous fallback if background process could not be launched
        if (!$dispatched) {
            $this->configureMailFromSettings();
            try {
                Mail::to($email)->send(new OtpPasswordResetMail($otp, $userName, $appName));
            } catch (\Exception $e) {
                \Log::error('OTP email send failed: ' . $e->getMessage());
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to send email. Please check SMTP settings in Admin Panel or try again.',
                    'smtp_error' => config('app.debug') ? $e->getMessage() : null,
                ], 500);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'A 6-digit verification code has been sent to your email address.',
        ]);
    }

    /**
     * Verify OTP Code Only (Step 2) — Returns a reset_token UUID for use in Step 3
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp'   => 'required|string|size:6',
        ]);

        $email  = strtolower(trim($request->email));
        $record = DB::table('password_reset_tokens')->where('email', $email)->first();

        if (!$record) {
            return response()->json([
                'success' => false,
                'message' => 'No OTP request found for this email. Please request a new code.',
            ], 400);
        }

        // Check expiry (15 minutes)
        if (now()->diffInMinutes($record->created_at) > 15) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            return response()->json([
                'success' => false,
                'expired' => true,
                'message' => 'This OTP has expired. Please request a new verification code.',
            ], 422);
        }

        // Verify OTP
        if (!Hash::check($request->otp, $record->token)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid verification code. Please check and try again.',
            ], 422);
        }

        // OTP verified — issue a short-lived reset_token UUID (15 min)
        $resetToken = Str::uuid()->toString();
        Cache::put('pwd_reset:' . $resetToken, $email, now()->addMinutes(15));

        // Mark OTP as verified (delete from table to prevent reuse)
        DB::table('password_reset_tokens')->where('email', $email)->delete();

        return response()->json([
            'success'     => true,
            'reset_token' => $resetToken,
            'message'     => 'OTP verified. You may now set your new password.',
        ]);
    }

    /**
     * Reset Password using verified reset_token UUID (Step 3)
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'reset_token' => 'required|string',
            'password'    => ['required', 'string', Password::min(6)],
            'device_name' => 'nullable|string|max:100',
        ]);

        $cacheKey = 'pwd_reset:' . $request->reset_token;
        $email    = Cache::get($cacheKey);

        if (!$email) {
            return response()->json([
                'success' => false,
                'expired' => true,
                'message' => 'Your reset session has expired. Please start the process again.',
            ], 422);
        }

        $user = User::where('email', $email)->first();
        if (!$user) {
            Cache::forget($cacheKey);
            return response()->json(['success' => false, 'message' => 'Account not found.'], 404);
        }

        // Update password & revoke all existing sessions
        $user->password = Hash::make($request->password);
        $user->save();
        $user->tokens()->delete();
        Cache::forget($cacheKey);

        // Auto-login: issue fresh token with device name
        $deviceName = $request->input('device_name', 'Mobile App');
        $user->update([
            'last_active_at' => now(),
            'device_name' => $deviceName,
        ]);
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Password reset successful. Welcome back!',
            'token'   => $token,
            'user'    => [
                'id'                   => $user->id,
                'name'                 => $user->name,
                'email'                => $user->email,
                'role'                 => $user->role,
                'is_premium'           => $user->is_premium,
                'plan_id'              => $user->plan_id,
                'subscription_plan'    => $user->subscription_plan,
                'subscription_expires_at' => $user->subscription_expires_at ? $user->subscription_expires_at->toISOString() : null,
                'feature_permissions'  => $this->resolvePermissionsForUser($user),
                'ai_free_uses_left'    => $user->ai_free_uses_left,
                'day_streak'           => (int)($user->day_streak ?? 1),
                'total_words_read'     => (int)($user->total_words_read ?? 0),
                'sync_enabled'         => (bool)($user->sync_enabled ?? true),
                'preferred_language'   => $user->preferred_language ?? 'Urdu',
                'created_at'           => $user->created_at->toISOString(),
            ],
        ]);
    }

    /**
     * Configure Laravel Mail dynamically from Admin Panel DB settings.
     * Falls back to .env if DB settings are not set.
     */
    private function configureMailFromSettings(): void
    {
        $host       = Setting::get('smtp_host', '');
        $port       = Setting::get('smtp_port', '');
        $username   = Setting::get('smtp_username', '');
        $password   = Setting::get('smtp_password', '');
        $encryption = Setting::get('smtp_encryption', 'tls');
        $fromAddr   = Setting::get('smtp_from_address', Setting::get('support_email', env('MAIL_FROM_ADDRESS', 'noreply@easyread.com')));
        $fromName   = Setting::get('smtp_from_name', Setting::get('app_name', env('APP_NAME', 'EasyRead')));

        if (!empty($host) && !empty($username)) {
            // Override runtime config with DB values
            config([
                'mail.default'                        => 'smtp',
                'mail.mailers.smtp.transport'         => 'smtp',
                'mail.mailers.smtp.host'              => $host,
                'mail.mailers.smtp.port'              => (int)($port ?: 587),
                'mail.mailers.smtp.username'          => $username,
                'mail.mailers.smtp.password'          => $password,
                'mail.mailers.smtp.encryption'        => $encryption,
                'mail.mailers.smtp.scheme'            => null,
                'mail.from.address'                   => $fromAddr,
                'mail.from.name'                      => $fromName,
            ]);
        }
    }

    /**
     * Logout from Current Device
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out from current device successfully',
        ]);
    }

    /**
     * Get All Connected Devices / Active Sanctum Sessions
     */
    public function devices(Request $request)
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()?->id;
        
        $devices = $user->tokens()->orderBy('last_used_at', 'desc')->orderBy('created_at', 'desc')->get()->map(function ($token) use ($currentTokenId) {
            $isCurrent = ($currentTokenId !== null && $token->id === $currentTokenId);
            $lastUsed = $token->last_used_at ?? $token->created_at;
            $diffSeconds = $lastUsed ? now()->diffInSeconds($lastUsed) : 999999;
            $isOnline = $isCurrent || ($diffSeconds <= 120); // Active within last 2 minutes

            return [
                'id' => (int)$token->id,
                'name' => $token->name ?: 'Mobile Device',
                'is_current' => $isCurrent,
                'is_online' => $isOnline,
                'created_at' => $token->created_at ? $token->created_at->diffForHumans() : 'Recently',
                'last_active' => $isOnline ? 'Active now' : ($token->last_used_at ? $token->last_used_at->diffForHumans() : 'Inactive'),
                'raw_last_used' => $token->last_used_at ? $token->last_used_at->toISOString() : null,
            ];
        });

        return response()->json([
            'success' => true,
            'devices' => array_values($devices->toArray()),
        ]);
    }

    /**
     * Revoke / Disconnect a Specific Device Session
     */
    public function revokeDevice(Request $request, $id)
    {
        $user = $request->user();
        $tokenId = (int)$id;
        $deleted = $user->tokens()->where('id', $tokenId)->delete();

        return response()->json([
            'success' => true,
            'deleted' => (bool)$deleted,
            'message' => $deleted ? 'Device session disconnected successfully.' : 'Session already revoked.',
        ]);
    }

    /**
     * Logout from ALL other devices except current session (1-step instant batch deletion)
     */
    public function logoutOthers(Request $request)
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()?->id;
        
        $query = $user->tokens();
        if ($currentTokenId) {
            $query->where('id', '!=', $currentTokenId);
        }
        $deleted = $query->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out from all other sessions instantly.',
            'count' => $deleted,
        ]);
    }

    /**
     * Logout from ALL Devices (Revoke all tokens)
     */
    public function logoutAll(Request $request)
    {
        $request->user()->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out from all active sessions and devices.',
        ]);
    }

    /**
     * Compulsory Apple Guideline 5.1.1 (Account Deletion with Server Data Wipe & Audit)
     */
    public function deleteAccount(Request $request)
    {
        $user = $request->user();
        $originalEmail = strtolower(trim($user->email));
        $originalName = $user->name;
        $userId = $user->id;

        // 1. Audit Log in account_deletions table (records when this user deleted account)
        AccountDeletion::create([
            'user_id' => $userId,
            'name' => $originalName,
            'email' => $originalEmail,
            'ip_address' => $request->ip(),
            'device_name' => $user->device_name,
            'reason' => 'Requested permanent account deletion via mobile app (Apple 5.1.1)',
            'deleted_at' => now(),
        ]);

        // 2. Permanently delete/wipe all personal cloud data from the server
        $user->tokens()->delete(); // Revoke all mobile authentication tokens
        $user->highlights()->delete(); // Permanent delete highlights
        $user->readingProgress()->delete(); // Permanent delete reading progress
        $user->vocabularies()->delete(); // Permanent delete saved vocabulary
        $user->backups()->delete(); // Permanent delete cloud backups
        $user->collections()->delete(); // Permanent delete collections
        $user->collectionBooks()->delete(); // Permanent delete book collection assignments
        $user->books()->delete(); // Permanent delete imported books
        $user->aiLogs()->delete(); // Permanent delete AI interaction logs
        \App\Models\AppNotification::where('user_id', $userId)->delete(); // Permanent delete in-app notifications

        // 3. Archive user email to release unique constraint, enabling re-signup with same email
        $user->email = $originalEmail . '_deleted_' . time() . '_' . $userId;
        $user->sync_enabled = false;
        $user->is_active = false;
        $user->save();

        // 4. Soft-delete the user record (deleted_at set to now)
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'Your account has been deleted and all personal data permanently erased from our servers.',
        ]);
    }

    /**
     * Resolve feature permissions / entitlements map for a given user
     */
    public function resolvePermissionsForUser(User $user): array
    {
        // Admin accounts always have full access
        if ($user->role === 'admin') {
            $all = [];
            foreach (array_keys(\App\Models\Plan::availableFeatureKeys()) as $key) {
                $all[$key] = true;
            }
            return $all;
        }

        // Active Subscription check
        if ($user->is_premium) {
            if ($user->plan_id) {
                $plan = \App\Models\Plan::find($user->plan_id);
                if ($plan && is_array($plan->feature_permissions) && !empty($plan->feature_permissions)) {
                    return $plan->feature_permissions;
                }
            }
            // Standard premium default: all features unlocked
            $all = [];
            foreach (array_keys(\App\Models\Plan::availableFeatureKeys()) as $key) {
                $all[$key] = true;
            }
            return $all;
        }

        // Dynamic Free Tier: Read permissions dynamically from the Free Tier plan set by Admin!
        $freePlan = null;
        if ($user->plan_id) {
            $freePlan = \App\Models\Plan::find($user->plan_id);
        }
        if (!$freePlan) {
            $freePlan = \App\Models\Plan::where('slug', 'free')->first();
        }

        if ($freePlan && is_array($freePlan->feature_permissions) && !empty($freePlan->feature_permissions)) {
            return $freePlan->feature_permissions;
        }

        // Fallback default entitlements
        return [
            'import_pdf' => false,
            'paste_read' => false,
            'save_from_web' => false,
            'cloud_sync' => false,
            'unlimited_ai' => false,
            'custom_shelves' => true,
        ];
    }

    /**
     * Update device FCM push notification token
     */
    public function updateFcmToken(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => 'required|string|max:1000',
        ]);

        $user = $request->user();
        if ($user) {
            $user->fcm_token = $validated['fcm_token'];
            $user->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'FCM push token registered successfully',
        ]);
    }

    /**
     * Check if an email has been deleted or suspended (for accurate client-side notices)
     */
    public function checkStatus(Request $request)
    {
        $email = strtolower(trim($request->input('email', '')));
        if (empty($email)) {
            return response()->json([
                'status'  => 'unknown',
                'message' => 'Your session has expired. Please log in again.',
            ]);
        }

        // 1. Check if an active user exists
        $user = User::where('email', $email)->first();
        if ($user) {
            if (!$user->is_active) {
                return response()->json([
                    'status'  => 'suspended',
                    'message' => 'Your account has been suspended by EasyRead.',
                ]);
            }
            return response()->json([
                'status'  => 'active',
                'message' => 'Account is active.',
            ]);
        }

        // 2. Check soft-deleted users
        $trashedUser = User::onlyTrashed()->where('email', $email)->first();
        if ($trashedUser) {
            return response()->json([
                'status'  => 'deleted',
                'message' => 'Your account has been deleted by EasyRead.',
            ]);
        }

        // 3. Check AccountDeletion audit records
        $deletionRecord = \App\Models\AccountDeletion::where('email', $email)->first();
        if ($deletionRecord) {
            return response()->json([
                'status'  => 'deleted',
                'message' => 'Your account has been deleted by EasyRead.',
            ]);
        }

        return response()->json([
            'status'  => 'deleted',
            'message' => 'Your account has been deleted by EasyRead.',
        ]);
    }
}


