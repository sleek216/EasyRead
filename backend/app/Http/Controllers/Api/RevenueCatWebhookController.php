<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class RevenueCatWebhookController extends Controller
{
    /**
     * Handle RevenueCat Real-Time Webhook Events
     */
    public function handle(Request $request)
    {
        // Optional Webhook Authorization Check
        $expectedAuth = Setting::get('revenuecat_webhook_secret');
        if (!empty($expectedAuth)) {
            $authHeader = $request->header('Authorization');
            if ($authHeader !== $expectedAuth && $authHeader !== 'Bearer ' . $expectedAuth) {
                return response()->json(['error' => 'Unauthorized webhook token'], 401);
            }
        }

        $payload = $request->all();
        $event = $payload['event'] ?? [];
        $type = $event['type'] ?? '';
        $appUserId = $event['app_user_id'] ?? '';

        Log::info("RevenueCat Webhook [{$type}] received for user [{$appUserId}]");

        if (empty($appUserId)) {
            return response()->json(['status' => 'ignored_no_user_id']);
        }

        // Find user by ID or email
        $user = User::where('id', $appUserId)
                    ->orWhere('email', $appUserId)
                    ->first();

        if (!$user) {
            return response()->json(['status' => 'user_not_found', 'app_user_id' => $appUserId]);
        }

        $productId = $event['product_id'] ?? '';
        $expiresAtMs = $event['expiration_at_ms'] ?? null;

        switch ($type) {
            case 'INITIAL_PURCHASE':
            case 'RENEWAL':
            case 'UNCANCELLATION':
            case 'PRODUCT_CHANGE':
                $user->is_premium = true;

                // Match Plan from product_id
                $plan = null;
                if (!empty($productId)) {
                    $pidLower = strtolower($productId);
                    if (str_contains($pidLower, 'year') || str_contains($pidLower, 'annual')) {
                        $plan = \App\Models\Plan::where('slug', 'yearly')->first();
                    } elseif (str_contains($pidLower, '6month') || str_contains($pidLower, 'biannual')) {
                        $plan = \App\Models\Plan::where('slug', 'biannual')->first();
                    } elseif (str_contains($pidLower, '3month') || str_contains($pidLower, 'quarterly')) {
                        $plan = \App\Models\Plan::where('slug', 'quarterly')->first();
                    } else {
                        $plan = \App\Models\Plan::where('slug', 'monthly')->first();
                    }
                }

                if ($plan) {
                    $user->plan_id = $plan->id;
                    $user->subscription_plan = $plan->name;
                    $user->subscription_price = $plan->price;
                }

                if ($expiresAtMs) {
                    $user->subscription_expires_at = \Carbon\Carbon::createFromTimestampMs($expiresAtMs);
                } elseif ($plan) {
                    $user->subscription_expires_at = match($plan->slug) {
                        'quarterly' => now()->addMonths(3),
                        'biannual' => now()->addMonths(6),
                        'yearly' => now()->addYear(),
                        default => now()->addMonth(),
                    };
                }

                $user->save();
                \App\Services\NotificationService::sendSubscriptionReceipt(
                    $user,
                    $user->subscription_plan ?: 'EasyRead Plus VIP',
                    $user->subscription_price ?: 'Active',
                    $user->subscription_expires_at?->format('M d, Y') ?? 'Auto-renewing'
                );
                Log::info("User ID #{$user->id} upgraded/renewed [{$type}] via RevenueCat. Plan: {$user->subscription_plan}");
                break;

            case 'CANCELLATION':
            case 'EXPIRATION':
                $user->is_premium = false;
                $user->subscription_plan = null;
                $user->subscription_price = null;
                $user->subscription_expires_at = null;
                $user->save();
                Log::info("User ID #{$user->id} Plus Premium expired/cancelled via RevenueCat");
                break;

            default:
                Log::info("RevenueCat Event [{$type}] acknowledged");
                break;
        }

        return response()->json([
            'status' => 'success',
            'user_id' => $user->id,
            'is_premium' => $user->is_premium,
        ]);
    }
}
