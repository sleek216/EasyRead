<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\User;
use App\Models\Setting;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Dispatch an in-app notification to a single user & send native push if device token is known
     */
    public static function sendToUser($userId, string $type, string $title, string $message, array $data = []): ?AppNotification
    {
        $notif = null;
        try {
            $notif = AppNotification::create([
                'user_id'      => $userId,
                'type'         => $type,
                'title'        => $title,
                'message'      => $message,
                'data'         => $data,
                'is_broadcast' => false,
                'read_at'      => null,
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to create user notification: " . $e->getMessage());
        }

        // Deliver native OS Push to user's device (WhatsApp-style popup & loud sound)
        try {
            $user = User::find($userId);
            if ($user && !empty($user->fcm_token)) {
                self::sendFcmPush($title, $message, $user->fcm_token, array_merge($data, ['type' => $type]));
            }
        } catch (\Exception $e) {
            Log::error("Failed to deliver push to user {$userId}: " . $e->getMessage());
        }

        return $notif;
    }

    /**
     * Broadcast an in-app notification to all users & dispatch FCM topic push
     */
    public static function broadcastAll(string $type, string $title, string $message, array $data = []): ?AppNotification
    {
        $notif = null;
        try {
            $notif = AppNotification::create([
                'user_id'        => null,
                'type'           => $type,
                'title'          => $title,
                'message'        => $message,
                'data'           => $data,
                'is_broadcast'   => true,
                'read_by_users'  => [],
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to broadcast notification: " . $e->getMessage());
        }

        // Deliver native OS Push to all devices subscribed to 'all_users' (WhatsApp-style popup & loud sound)
        self::sendFcmPush($title, $message, '/topics/all_users', array_merge($data, ['type' => $type]));

        return $notif;
    }

    /**
     * Dispatch High-Priority Google FCM Push Notification
     * Guarantees delivery with loud sound, vibration, and heads-up banner
     * even when the app is completely closed or killed.
     */
    public static function sendFcmPush(string $title, string $message, string $target = '/topics/all_users', array $data = []): bool
    {
        try {
            // Check if Push Notifications are enabled
            if (Setting::get('fcm_enabled', '1') !== '1') {
                return false;
            }

            // Clean title & message
            $cleanTitle   = strip_tags($title);
            $cleanMessage = strip_tags($message);

            // Check if Firebase Service Account JSON is available (HTTP v1 - modern standard)
            $serviceAccountPath = storage_path('app/firebase/service-account.json');
            $serviceAccountJson = null;

            if (file_exists($serviceAccountPath)) {
                $serviceAccountJson = json_decode(file_get_contents($serviceAccountPath), true);
            } else {
                $storedKey = Setting::get('fcm_server_key');
                if ($storedKey && str_starts_with(trim($storedKey), '{')) {
                    $serviceAccountJson = json_decode($storedKey, true);
                }
            }

            if ($serviceAccountJson && !empty($serviceAccountJson['project_id']) && !empty($serviceAccountJson['private_key'])) {
                return self::sendFcmHttpV1($serviceAccountJson, $target, $cleanTitle, $cleanMessage, $data);
            }

            // Fallback: Legacy FCM Endpoint (if user configured legacy AAAA... server key)
            $serverKey = Setting::get('fcm_server_key') ?: env('FCM_SERVER_KEY');
            if (empty($serverKey)) {
                Log::warning("FCM Push skipped: Neither Service Account nor FCM server key found.");
                return false;
            }

            $payload = [
                'to'       => $target,
                'priority' => 'high',
                'notification' => [
                    'title'              => $cleanTitle,
                    'body'               => $cleanMessage,
                    'sound'              => 'default',
                    'android_channel_id' => 'easyread_alerts',
                    'priority'           => 'high',
                    'click_action'       => 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'channel_id'              => 'easyread_alerts',
                        'sound'                   => 'default',
                        'priority'                => 'max',
                        'default_sound'           => true,
                        'default_vibrate_timings' => true,
                        'notification_priority'   => 'PRIORITY_MAX',
                        'visibility'              => 'PUBLIC',
                    ],
                ],
                'data' => array_merge([
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'title'        => $cleanTitle,
                    'message'      => $cleanMessage,
                    'body'         => $cleanMessage,
                    'timestamp'    => now()->toIso8601String(),
                ], $data),
            ];

            $response = \Illuminate\Support\Facades\Http::withoutVerifying()->withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type'  => 'application/json',
            ])->timeout(6)->post('https://fcm.googleapis.com/fcm/send', $payload);

            if ($response->successful()) {
                Log::info("FCM push dispatched to {$target} (Legacy): " . $response->body());
                return true;
            } else {
                Log::warning("FCM push response [{$response->status()}] for {$target} (Legacy): " . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error("FCM push exception: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Dispatch push notification using modern Google Firebase HTTP v1 API
     */
    protected static function sendFcmHttpV1(array $serviceAccount, string $target, string $title, string $body, array $data = []): bool
    {
        try {
            $projectId = $serviceAccount['project_id'];
            $token = self::getGoogleAccessToken($serviceAccount);
            if (!$token) {
                Log::error("Failed to generate Google OAuth access token for FCM v1");
                return false;
            }

            // Construct payload for HTTP v1
            // Target can be either topic (starts with /topics/) or specific device token
            $messageObj = [
                'notification' => [
                    'title' => $title,
                    'body'  => $body,
                ],
                'android' => [
                    'priority'     => 'HIGH',
                    'notification' => [
                        'channel_id'              => 'easyread_alerts',
                        'sound'                   => 'default',
                        'notification_priority'   => 'PRIORITY_MAX',
                        'default_sound'           => true,
                        'default_vibrate_timings' => true,
                        'visibility'              => 'PUBLIC',
                        'click_action'            => 'FLUTTER_NOTIFICATION_CLICK',
                    ],
                ],
                'data' => array_map(function($val) {
                    return is_string($val) ? $val : json_encode($val);
                }, array_merge([
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'title'        => $title,
                    'message'      => $body,
                    'body'         => $body,
                    'timestamp'    => now()->toIso8601String(),
                ], $data)),
            ];

            if (str_starts_with($target, '/topics/')) {
                $messageObj['topic'] = substr($target, strlen('/topics/'));
            } else {
                $messageObj['token'] = $target;
            }

            $endpoint = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

            $response = \Illuminate\Support\Facades\Http::withoutVerifying()->withHeaders([
                'Authorization' => 'Bearer ' . $token,
                'Content-Type'  => 'application/json; UTF-8',
            ])->timeout(8)->post($endpoint, [
                'message' => $messageObj
            ]);

            if ($response->successful()) {
                Log::info("FCM v1 push SUCCESS to {$target}: " . $response->body());
                return true;
            } else {
                Log::warning("FCM v1 push FAILED [{$response->status()}] to {$target}: " . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error("FCM v1 send exception: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Generate RS256 signed OAuth2 Access Token for Google Cloud Service Account
     */
    protected static function getGoogleAccessToken(array $serviceAccount): ?string
    {
        return \Illuminate\Support\Facades\Cache::remember('google_fcm_v1_access_token', 3300, function () use ($serviceAccount) {
            $now = time();
            $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
            $claim = json_encode([
                'iss'   => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud'   => 'https://oauth2.googleapis.com/token',
                'exp'   => $now + 3600,
                'iat'   => $now,
            ]);

            $b64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
            $b64UrlClaim  = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($claim));
            $signatureInput = $b64UrlHeader . '.' . $b64UrlClaim;

            $privateKey = $serviceAccount['private_key'];
            $binarySignature = '';
            $success = openssl_sign($signatureInput, $binarySignature, $privateKey, 'SHA256');

            if (!$success) {
                Log::error("openssl_sign failed for Google Service Account JWT");
                return null;
            }

            $b64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($binarySignature));
            $jwt = $signatureInput . '.' . $b64UrlSignature;

            $tokenResponse = \Illuminate\Support\Facades\Http::withoutVerifying()->asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]);

            if ($tokenResponse->successful()) {
                return $tokenResponse->json('access_token');
            }

            Log::error("Google OAuth token request failed: " . $tokenResponse->body());
            return null;
        });
    }

    /**
     * 1. Trigger when a user buys / upgrades a subscription:
     * - Dispatches background SMTP receipt email
     * - Creates in-app celebratory notification
     */
    public static function sendSubscriptionReceipt(User $user, string $planName, string $price = '', string $expiresAt = ''): void
    {
        // 1. In-App Notification (if enabled)
        if (Setting::get('enable_in_app_notifications', '1') === '1') {
            self::sendToUser(
                $user->id,
                'subscription',
                "Welcome to {$planName}",
                "Your subscription is now active. Enjoy unlimited AI assistance, premium books, and cross-device sync.",
                [
                    'plan_name'  => $planName,
                    'price'      => $price,
                    'expires_at' => $expiresAt,
                ]
            );
        }

        // 2. Background SMTP Email Dispatch (if enabled)
        if (Setting::get('enable_subscription_receipt_emails', '1') === '1') {
            try {
                $emailSafe   = escapeshellarg($user->email);
                $nameSafe    = escapeshellarg($user->name ?: 'Reader');
                $planSafe    = escapeshellarg($planName);
                $priceSafe   = escapeshellarg($price ?: 'Active');
                $expiresSafe = escapeshellarg($expiresAt ?: 'Auto-renewing');

                $artisan = base_path('artisan');
                $php     = PHP_BINARY;

                if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                    pclose(popen("start /B {$php} {$artisan} mail:send-receipt {$emailSafe} {$nameSafe} {$planSafe} {$priceSafe} {$expiresSafe}", 'r'));
                } else {
                    exec("{$php} {$artisan} mail:send-receipt {$emailSafe} {$nameSafe} {$planSafe} {$priceSafe} {$expiresSafe} > /dev/null 2>&1 &");
                }
            } catch (\Exception $e) {
                Log::error("Async receipt dispatch error for {$user->email}: " . $e->getMessage());
            }
        }
    }

    /**
     * 2. Trigger when Admin suspends a user:
     * - Dispatches background SMTP suspension email
     * - Dispatches high-priority push notification & in-app security notice
     */
    public static function sendSuspensionNotice(User $user, string $reason = ''): void
    {
        $reasonText = $reason ?: 'Administrative policy action';
        $title = "Important Notice: Account Suspended";
        $message = "Your EasyRead account has been temporarily suspended. Reason: {$reasonText}. If you believe this is an error, please contact support.";

        // 1. In-App Security Notification & Push Notification (sendToUser already delivers FCM push to user's device)
        if (Setting::get('enable_in_app_notifications', '1') === '1') {
            self::sendToUser(
                $user->id,
                'suspension',
                $title,
                $message,
                ['reason' => $reasonText, 'action' => 'account_suspended']
            );
        } elseif (!empty($user->fcm_token)) {
            // If in-app notifications disabled, still deliver direct push
            self::sendFcmPush($title, $message, $user->fcm_token, [
                'type'   => 'suspension',
                'action' => 'account_suspended',
                'reason' => $reasonText,
            ]);
        }

        // 2. Background SMTP Email Dispatch (if enabled)
        if (Setting::get('enable_suspension_emails', '1') === '1') {
            try {
                $emailSafe  = escapeshellarg($user->email);
                $nameSafe   = escapeshellarg($user->name ?: 'Reader');
                $reasonSafe = escapeshellarg($reasonText);

                $artisan = base_path('artisan');
                $php     = PHP_BINARY;

                if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                    pclose(popen("start /B {$php} {$artisan} mail:send-suspension {$emailSafe} {$nameSafe} {$reasonSafe}", 'r'));
                } else {
                    exec("{$php} {$artisan} mail:send-suspension {$emailSafe} {$nameSafe} {$reasonSafe} > /dev/null 2>&1 &");
                }
            } catch (\Exception $e) {
                Log::error("Async suspension dispatch error for {$user->email}: " . $e->getMessage());
            }
        }
    }

    /**
     * 3. Trigger when Admin restores / activates a user:
     * - Dispatches background SMTP reactivation email
     * - Dispatches high-priority push notification & in-app welcome back notice
     */
    public static function sendActivationNotice(User $user): void
    {
        $title = "Account Reactivated";
        $message = "Your EasyRead account has been restored and is now active. You can now log in and continue reading.";

        // 1. In-App Notification & Push Notification (sendToUser already delivers FCM push)
        if (Setting::get('enable_in_app_notifications', '1') === '1') {
            self::sendToUser(
                $user->id,
                'activation',
                $title,
                $message,
                ['action' => 'account_activated']
            );
        } elseif (!empty($user->fcm_token)) {
            self::sendFcmPush($title, $message, $user->fcm_token, [
                'type'   => 'activation',
                'action' => 'account_activated',
            ]);
        }

        // 3. Background SMTP Email Dispatch (if enabled)
        if (Setting::get('enable_suspension_emails', '1') === '1') {
            try {
                $emailSafe = escapeshellarg($user->email);
                $nameSafe  = escapeshellarg($user->name ?: 'Reader');

                $artisan = base_path('artisan');
                $php     = PHP_BINARY;

                if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                    pclose(popen("start /B {$php} {$artisan} mail:send-activation {$emailSafe} {$nameSafe}", 'r'));
                } else {
                    exec("{$php} {$artisan} mail:send-activation {$emailSafe} {$nameSafe} > /dev/null 2>&1 &");
                }
            } catch (\Exception $e) {
                Log::error("Async activation dispatch error for {$user->email}: " . $e->getMessage());
            }
        }
    }


    /**
     * 3. Trigger when Admin adds a new book:
     * - Broadcasts in-app notification to all users
     */
    public static function broadcastNewBook($book): void
    {
        if (Setting::get('enable_new_book_notifications', '1') !== '1') {
            return;
        }

        $title  = $book->title ?? 'New Book';
        $author = $book->author ? " by {$book->author}" : '';

        self::broadcastAll(
            'new_book',
            "New Book Added: {$title}",
            "\"{$title}\"{$author} is now available in the Library. Tap to start reading!",
            [
                'book_id'    => $book->id ?? null,
                'book_title' => $title,
                'category'   => $book->category->name ?? ($book->category_id ?? ''),
            ]
        );
    }
}
