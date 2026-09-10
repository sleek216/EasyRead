<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Plan;
use App\Models\Collection;
use App\Models\Book;
use App\Models\AccountDeletion;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AdminUserController extends Controller
{
    /**
     * Display all readers and users with full filtering, searching, and metrics.
     */
    public function index(Request $request)
    {
        $search = $request->query('search');
        $planFilter = $request->query('plan', 'all');
        $statusFilter = $request->query('status', 'all');
        $roleFilter = $request->query('role', 'all');
        $sort = $request->query('sort', 'latest');

        // Base Query with relationship counts and plan model eager-loaded
        $query = User::with(['plan'])->withCount(['vocabularies', 'backups', 'readingProgress', 'aiLogs', 'collections']);

        // Search Filter
        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('subscription_plan', 'like', "%{$search}%")
                  ->orWhere('device_name', 'like', "%{$search}%");
            });
        }

        // Plan Filter
        if ($planFilter === 'premium') {
            $query->where('is_premium', true);
        } elseif ($planFilter === 'free') {
            $query->where('is_premium', false);
        } elseif (is_numeric($planFilter)) {
            $query->where('plan_id', $planFilter);
        }

        // Status Filter
        if ($statusFilter === 'active') {
            $query->where('is_active', true);
        } elseif ($statusFilter === 'inactive') {
            $query->where('is_active', false);
        }

        // Ensure this section shows all mobile app readers (role 'reader' or 'user', excluding backend admins)
        $query->where('role', '!=', 'admin');

        // Sorting
        switch ($sort) {
            case 'name_asc':
                $query->orderBy('name', 'asc');
                break;
            case 'most_words':
                $query->orderBy('vocabularies_count', 'desc');
                break;
            case 'most_collections':
                $query->orderBy('collections_count', 'desc');
                break;
            case 'most_backups':
                $query->orderBy('backups_count', 'desc');
                break;
            case 'oldest':
                $query->oldest();
                break;
            case 'latest':
            default:
                $query->latest();
                break;
        }

        $users = $query->paginate(15)->withQueryString();

        // Available subscription plans for dropdowns and filters
        $plans = Plan::where('is_active', true)->orderBy('sort_order')->get();

        // KPI Summary Statistics (Scope to All App Readers, exclude admins)
        $totalUsersCount = User::where('role', '!=', 'admin')->count();
        $premiumUsersCount = User::where('role', '!=', 'admin')->where('is_premium', true)->count();
        $freeUsersCount = User::where('role', '!=', 'admin')->where('is_premium', false)->count();
        $activeTodayCount = User::where('role', '!=', 'admin')->whereDate('last_active_at', today())->count();
        $inactiveUsersCount = User::where('role', '!=', 'admin')->where('is_active', false)->count();

        return view('admin.users.index', compact(
            'users',
            'plans',
            'search',
            'planFilter',
            'statusFilter',
            'roleFilter',
            'sort',
            'totalUsersCount',
            'premiumUsersCount',
            'freeUsersCount',
            'activeTodayCount',
            'inactiveUsersCount'
        ));
    }

    /**
     * Display comprehensive details for a specific user:
     * - Profile & active sessions
     * - Complete subscription package info (plan, price, expiry, status)
     * - All collections created by this user and all books inside each collection
     * - Reading activity shelf & progress percent
     * - Saved vocabulary library
     * - Cloud backups
     */
    public function show($id)
    {
        $user = User::with([
            'plan',
            'collections' => function ($q) {
                $q->withCount('books')->with(['books' => function ($b) {
                    $b->withCount('paragraphs');
                }])->orderBy('name');
            },
            'readingProgress' => function ($q) {
                $q->with(['book' => function ($b) {
                    $b->withCount('paragraphs');
                }])->latest('updated_at');
            },
            'vocabularies' => function ($q) {
                $q->latest()->take(60);
            },
            'backups' => function ($q) {
                $q->latest()->take(10);
            },
            'aiLogs' => function ($q) {
                $q->latest()->take(25);
            },
            'tokens',
        ])->findOrFail($id);

        $plans = Plan::where('is_active', true)->orderBy('sort_order')->get();

        // Additional stats
        $stats = [
            'collections_count' => $user->collections->count(),
            'books_in_collections' => $user->collections->sum('books_count'),
            'reading_count' => $user->readingProgress->count(),
            'favorites_count' => $user->readingProgress->where('is_favorite', true)->count(),
            'bookmarks_count' => $user->readingProgress->where('is_bookmarked', true)->count(),
            'vocab_count' => $user->vocabularies()->count(),
            'mastered_vocab_count' => $user->vocabularies()->where('is_mastered', true)->count(),
            'backups_count' => $user->backups()->count(),
            'ai_logs_count' => $user->aiLogs()->count(),
        ];

        // Past Deletion History for this email
        $pastDeletions = AccountDeletion::where('email', $user->email)
            ->orderBy('deleted_at', 'desc')
            ->get();

        return view('admin.users.show', compact('user', 'plans', 'stats', 'pastDeletions'));
    }

    /**
     * Display audit trail of all deleted accounts.
     * Shows when each user deleted their account, how many times, and current status.
     */
    public function deletions(Request $request)
    {
        $search = $request->query('search');

        $query = AccountDeletion::query();

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('device_name', 'like', "%{$search}%")
                  ->orWhere('ip_address', 'like', "%{$search}%");
            });
        }

        $deletions = $query->orderBy('deleted_at', 'desc')->paginate(20)->withQueryString();

        // Check if any deleted emails have re-registered active accounts
        $emails = $deletions->pluck('email')->unique();
        $activeUsers = User::whereIn('email', $emails)->get()->keyBy('email');

        // Total deletion counts per email
        $deletionCounts = AccountDeletion::whereIn('email', $emails)
            ->select('email', DB::raw('count(*) as total'))
            ->groupBy('email')
            ->pluck('total', 'email');

        $metrics = [
            'total_deletions' => AccountDeletion::count(),
            'unique_emails_deleted' => AccountDeletion::distinct('email')->count('email'),
            're_registered_count' => User::whereIn('email', AccountDeletion::select('email'))->count(),
            'deletions_this_month' => AccountDeletion::whereMonth('deleted_at', now()->month)->whereYear('deleted_at', now()->year)->count(),
        ];

        return view('admin.users.deletions', compact('deletions', 'activeUsers', 'deletionCounts', 'metrics', 'search'));
    }

    /**
     * Create a new reader / admin account manually from dashboard.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email:rfc|max:255|unique:users,email',
            'password' => ['required', 'string', Password::min(6)],
            'role' => 'required|in:admin,user',
            'plan_id' => 'nullable|string',
            'is_active' => 'required|boolean',
            'ai_free_uses_left' => 'nullable|integer|min:0',
        ]);

        $planId = null;
        $planName = null;
        $planPrice = null;
        $startsAt = null;
        $expiresAt = null;
        $isPremium = false;

        if (!empty($validated['plan_id'])) {
            $plan = Plan::find($validated['plan_id']);
            if ($plan && (strtolower($plan->slug ?? '') === 'free' || strtolower($plan->price) === 'free' || str_contains(strtolower($plan->name), 'free'))) {
                $isPremium = false;
                $planId = $plan->id;
                $planName = $plan->name;
                $planPrice = 'Free';
                $startsAt = null;
                $expiresAt = null;
            } elseif ($plan) {
                $isPremium = true;
                $planId = $plan->id;
                $planName = $plan->name;
                $planPrice = $plan->price;
                $startsAt = now();
                $expiresAt = $this->calculateExpirationDate($plan);
            }
        }

        $aiQuota = $validated['ai_free_uses_left'] ?? ($isPremium ? 999 : 10);

        $user = User::create([
            'name' => trim($validated['name']),
            'email' => strtolower(trim($validated['email'])),
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
            'is_premium' => $isPremium,
            'is_active' => $validated['is_active'],
            'plan_id' => $planId,
            'subscription_plan' => $planName,
            'subscription_price' => $planPrice,
            'subscription_starts_at' => $startsAt,
            'subscription_expires_at' => $expiresAt,
            'ai_free_uses_left' => $aiQuota,
            'last_active_at' => now(),
        ]);

        return back()->with('success', "New user '{$user->name}' created successfully.");
    }

    /**
     * Update user details, role, subscription package, status, or password.
     */
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email:rfc|max:255|unique:users,email,' . $user->id,
            'role' => 'required|in:admin,user',
            'plan_id' => 'nullable|string',
            'is_active' => 'required|boolean',
            'ai_free_uses_left' => 'nullable|integer|min:0',
            'password' => 'nullable|string|min:6',
        ]);

        $user->name = trim($validated['name']);
        $user->email = strtolower(trim($validated['email']));
        $user->role = $validated['role'];
        $user->is_active = $validated['is_active'];

        // Handle Subscription Plan
        if (isset($validated['plan_id'])) {
            $plan = Plan::find($validated['plan_id']);
            $oldPlanId = $user->getOriginal('plan_id');

            if ($plan && (strtolower($plan->slug ?? '') === 'free' || strtolower($plan->price) === 'free' || str_contains(strtolower($plan->name), 'free'))) {
                $user->is_premium = false;
                $user->plan_id = $plan->id;
                $user->subscription_plan = $plan->name;
                $user->subscription_price = 'Free';
                $user->subscription_expires_at = null;
                $user->ai_free_uses_left = min((int)$user->ai_free_uses_left, 10);
            } elseif ($plan) {
                $user->is_premium = true;
                $user->plan_id = $plan->id;
                $user->subscription_plan = $plan->name;
                $user->subscription_price = $plan->price;
                $user->subscription_starts_at = now();
                $user->subscription_expires_at = $this->calculateExpirationDate($plan);
                $user->ai_free_uses_left = 999;

                // If plan changed to a new active package, trigger receipt and in-app notice
                if ($oldPlanId != $plan->id) {
                    \App\Services\NotificationService::sendSubscriptionReceipt(
                        $user,
                        $plan->name,
                        $plan->price,
                        $user->subscription_expires_at->format('M d, Y')
                    );
                }
            } else {
                $user->is_premium = false;
                $user->plan_id = null;
                $user->subscription_plan = 'Free Tier';
                $user->subscription_price = 'Free';
                $user->subscription_expires_at = null;
            }
        }


        if (isset($validated['ai_free_uses_left'])) {
            $user->ai_free_uses_left = $validated['ai_free_uses_left'];
        }

        if (!empty($validated['password'])) {
            $user->password = Hash::make($validated['password']);
        }

        // Check if status changed
        $wasActive = (bool)$user->getOriginal('is_active');
        $nowActive = (bool)$user->is_active;

        // If deactivated, revoke all active mobile sessions and notify
        if ($wasActive && !$nowActive) {
            $user->tokens()->delete();
            \App\Services\NotificationService::sendSuspensionNotice($user, 'Administrative account update');
        } elseif (!$wasActive && $nowActive) {
            \App\Services\NotificationService::sendActivationNotice($user);
        }

        $user->save();

        return back()->with('success', "User details for {$user->name} updated successfully.");
    }

    /**
     * Direct action to assign or change a user's subscription package.
     */
    public function assignPlan(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validated = $request->validate([
            'plan_id' => 'required|string',
            'custom_duration_days' => 'nullable|integer|min:1|max:3650',
        ]);

        $plan = Plan::find($validated['plan_id']);

        if ($validated['plan_id'] === 'free' || ($plan && (strtolower($plan->slug ?? '') === 'free' || strtolower($plan->price) === 'free' || str_contains(strtolower($plan->name), 'free')))) {
            $user->update([
                'is_premium' => false,
                'plan_id' => $plan?->id,
                'subscription_plan' => $plan?->name ?? 'Free Tier',
                'subscription_price' => 'Free',
                'subscription_expires_at' => null,
                'ai_free_uses_left' => min($user->ai_free_uses_left, 10),
            ]);

            return back()->with('success', "Subscription for {$user->name} set to " . ($plan?->name ?? 'Free Tier') . ".");
        }

        if (!$plan) {
            return back()->with('error', 'Selected subscription plan not found.');
        }

        $days = !empty($validated['custom_duration_days'])
            ? (int)$validated['custom_duration_days']
            : match($plan->slug) {
                'quarterly' => 90,
                'biannual' => 180,
                'yearly' => 365,
                default => 30,
            };

        $user->update([
            'is_premium' => true,
            'plan_id' => $plan->id,
            'subscription_plan' => $plan->name,
            'subscription_price' => $plan->price,
            'subscription_starts_at' => now(),
            'subscription_expires_at' => now()->addDays($days),
            'ai_free_uses_left' => 999,
        ]);

        // Send subscription invoice receipt via email and in-app notification
        \App\Services\NotificationService::sendSubscriptionReceipt($user, $plan->name, $plan->price, now()->addDays($days)->format('M d, Y'));

        return back()->with('success', "Successfully assigned '{$plan->name}' package ({$plan->price}) to {$user->name}. Valid until " . now()->addDays($days)->format('M d, Y') . ".");
    }

    /**
     * Quick toggle subscription status (Free <-> Plus VIP)
     */
    public function togglePremium($id)
    {
        $user = User::findOrFail($id);
        $user->is_premium = !$user->is_premium;

        if ($user->is_premium) {
            $user->ai_free_uses_left = 999;
            // If no plan assigned, default to first available plan
            if (!$user->plan_id) {
                $defaultPlan = Plan::where('slug', 'monthly')->first() ?? Plan::first();
                if ($defaultPlan) {
                    $user->plan_id = $defaultPlan->id;
                    $user->subscription_plan = $defaultPlan->name;
                    $user->subscription_price = $defaultPlan->price;
                    $user->subscription_starts_at = now();
                    $user->subscription_expires_at = $this->calculateExpirationDate($defaultPlan);
                }
            }
            if ($user->subscription_plan) {
                \App\Services\NotificationService::sendSubscriptionReceipt($user, $user->subscription_plan, $user->subscription_price ?? 'Active', $user->subscription_expires_at?->format('M d, Y') ?? 'Auto-renewing');
            }
        } else {
            $user->ai_free_uses_left = 10;
            $user->plan_id = null;
            $user->subscription_plan = null;
            $user->subscription_price = null;
            $user->subscription_expires_at = null;
        }

        $user->save();

        $statusText = $user->is_premium ? "upgraded to VIP ({$user->subscription_plan})" : 'downgraded to Free tier';
        return back()->with('success', "{$user->name} has been {$statusText}.");
    }

    /**
     * Quick toggle account status (Active <-> Suspended)
     */
    public function toggleStatus($id)
    {
        $user = User::findOrFail($id);
        $user->is_active = !$user->is_active;

        if ($user->is_active) {
            // Send activation notice email & push notification
            \App\Services\NotificationService::sendActivationNotice($user);
        } else {
            $user->tokens()->delete(); // Revoke all mobile tokens
            // Send suspension notice email, push notification & in-app security record
            \App\Services\NotificationService::sendSuspensionNotice($user, 'Administrative account suspension');
        }

        $user->save();

        $statusText = $user->is_active ? 'activated' : 'suspended';
        return back()->with('success', "User {$user->name} account is now {$statusText}.");
    }

    /**
     * Reset user daily AI query limit.
     */
    public function resetAiUses($id)
    {
        $user = User::findOrFail($id);
        $defaultUses = $user->is_premium ? 999 : 10;
        $user->update(['ai_free_uses_left' => $defaultUses]);

        return back()->with('success', "Daily AI allowance reset to {$defaultUses} for {$user->name}.");
    }

    /**
     * Remove reader account and associated personal cloud data.
     */
    public function destroy($id)
    {
        $user = User::findOrFail($id);
        $userName = $user->name;
        $userEmail = $user->email;
        $fcmToken = $user->fcm_token;

        // 1. Record deletion audit log
        try {
            \App\Models\AccountDeletion::create([
                'user_id' => $user->id,
                'name' => $userName,
                'email' => $userEmail,
                'ip_address' => request()->ip(),
                'device_name' => $user->device_name ?: 'Mobile App',
                'reason' => 'Account deleted by administrator',
                'deleted_at' => now(),
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Failed to record account deletion audit: " . $e->getMessage());
        }

        // 2. Send instant push notification to user's device
        if (!empty($fcmToken)) {
            \App\Services\NotificationService::sendFcmPush(
                'Account Deleted',
                'Your account has been deleted by EasyRead administrator.',
                $fcmToken,
                [
                    'type' => 'account_deleted',
                    'action' => 'account_deleted',
                ]
            );
        }

        // 3. Permanently wipe all personal user cloud data (reading progress, books, vocab, highlights)
        $user->tokens()->delete();
        $user->highlights()->delete();
        $user->readingProgress()->delete();
        $user->vocabularies()->delete();
        $user->backups()->delete();
        $user->collections()->delete();
        $user->collectionBooks()->delete();
        $user->books()->delete();
        $user->aiLogs()->delete();
        \App\Models\AppNotification::where('user_id', $user->id)->delete();

        // 4. Archive email so if user re-signs up via Google or Email, a 100% brand new account is created
        $user->email = strtolower(trim($userEmail)) . '_deleted_' . time() . '_' . $user->id;
        $user->sync_enabled = false;
        $user->is_active = false;
        $user->save();

        // 5. Soft-delete user
        $user->delete();

        return redirect()->route('admin.users.index')->with('success', "Reader account '{$userName}' has been deleted and all data erased.");
    }

    /**
     * Helper to determine expiration date based on plan slug
     */
    protected function calculateExpirationDate(Plan $plan)
    {
        return match ($plan->slug) {
            'quarterly' => now()->addMonths(3),
            'biannual' => now()->addMonths(6),
            'yearly' => now()->addYear(),
            default => now()->addMonth(),
        };
    }
}
