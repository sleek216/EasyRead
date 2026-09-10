<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookController;
use App\Http\Controllers\Api\SyncController;
use App\Http\Controllers\Api\BackupController;
use App\Http\Controllers\Api\VocabularyController;
use App\Http\Controllers\Api\AiAssistantController;

// Public Mobile Auth & Catalog APIs
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/social', [AuthController::class, 'socialLogin']);
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp']);
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);
Route::post('/auth/check-status', [AuthController::class, 'checkStatus']);


Route::get('/social-auth-config', function () {
    return response()->json([
        'success' => true,
        'google_enabled' => (bool)\App\Models\Setting::get('google_auth_enabled', '1'),
        'google_web_client_id' => \App\Models\Setting::get('google_web_client_id', ''),
        'apple_enabled' => (bool)\App\Models\Setting::get('apple_auth_enabled', '1'),
        'firebase_project_id' => \App\Models\Setting::get('firebase_project_id', ''),
    ]);
});

Route::get('/dropbox-config', function () {
    return response()->json([
        'success' => true,
        'dropbox_enabled' => (bool)\App\Models\Setting::get('dropbox_enabled', '1'),
        'dropbox_app_key' => \App\Models\Setting::get('dropbox_app_key', '1j22ldywe7y316j'),
        'dropbox_app_secret' => \App\Models\Setting::get('dropbox_app_secret', '5vl09ge69dbawph'),
    ]);
});

Route::get('/translation-languages', function () {
    $raw = \App\Models\Setting::get('translation_languages', 'Urdu, Spanish, French, German, Arabic, Hindi, Chinese, Turkish, Italian, Portuguese, Japanese, Russian');
    $languages = array_values(array_filter(array_map('trim', explode(',', $raw))));
    return response()->json([
        'success' => true,
        'languages' => $languages,
        'default' => $languages[0] ?? 'Urdu',
    ]);
});

Route::get('/books', [BookController::class, 'index']);
Route::get('/books/{id}', [BookController::class, 'show']);
Route::get('/categories', [BookController::class, 'categories']);
Route::get('/collections', [\App\Http\Controllers\Api\CollectionController::class, 'index']);
Route::get('/plans', function () {
    $plans = \App\Models\Plan::where('is_active', true)
        ->orderBy('sort_order')
        ->orderBy('id')
        ->get();
    return response()->json([
        'success' => true,
        'plans' => $plans,
    ]);
});

// RevenueCat Webhook & Config
Route::post('/revenuecat/webhook', [\App\Http\Controllers\Api\RevenueCatWebhookController::class, 'handle']);
Route::get('/revenuecat-config', function () {
    return response()->json([
        'success' => true,
        'google_key' => \App\Models\Setting::get('revenuecat_google_key', ''),
        'apple_key' => \App\Models\Setting::get('revenuecat_apple_key', ''),
        'entitlement_id' => \App\Models\Setting::get('revenuecat_entitlement_id', 'plus'),
    ]);
});

Route::get('/privacy-policy', function () {
    return response()->json([
        'success' => true,
        'privacy_policy' => \App\Models\Setting::get('privacy_policy', "Easy Read values your reading privacy.\n\n• Private AI Processing: Passages sent to AI for simplify, summarize, explain, or translation are processed securely and never retained to train public models.\n\n• Local & Encrypted Sync: Your vocabulary words, highlights, and book progress are stored securely on your device and encrypted during sync.\n\n• No Data Selling: We do not sell your reading habits, vocabulary, or personal data to any third parties."),
    ]);
});

// Clean Web Article Text Extractor (Multi-tier: Direct + Jina Reader Fallback for Cloudflare/Medium)
Route::post('/web/extract', function (\Illuminate\Http\Request $request) {
    $url = trim($request->input('url', ''));
    if (empty($url)) {
        return response()->json(['success' => false, 'message' => 'URL is required'], 422);
    }
    if (!str_starts_with($url, 'http://') && !str_starts_with($url, 'https://')) {
        $url = 'https://' . $url;
    }

    $title = 'Web Article';
    $paragraphs = [];

    // Helper: Strictly filter out form junk, navigation, search boxes, login/logout, and UI noise
    $cleanAndValidateParagraphs = function (array $rawList) {
        $uiBlacklist = [
            'fill out this field',
            'log in',
            'log out',
            'my account',
            'manage your subscription',
            'give a gift subscription',
            'newsletters sweepstakes',
            'subscribe to',
            'sign up',
            'all rights reserved',
            'terms of use',
            'terms of service',
            'privacy policy',
            'cookie policy',
            'cookie preferences',
            'photo credit',
            'get help',
            'sexiest man alive',
            'advertisement',
            'click here',
            'skip to content',
            'open navigation',
            'close navigation',
            'follow us on',
            'puzzler view all',
            'view all',
            'share on facebook',
            'share on twitter',
            'share via email',
        ];

        $results = [];
        foreach ($rawList as $raw) {
            $clean = html_entity_decode(trim(strip_tags($raw)));

            // 1. Strip composite markdown image links: ![alt](url)](url) or [ ![alt](url) ](url)
            $clean = preg_replace('/!?\[\s*!?\[.*?\]\(.*?\)\s*\]\(.*?\)/is', '', $clean);
            $clean = preg_replace('/!\[.*?\]\(.*?\)(\]\(.*?\))?/is', '', $clean);

            // 2. Strip standard markdown links: [text](url) -> keep text only
            $clean = preg_replace('/\[(.*?)\]\(.*?\)/is', '$1', $clean);

            // 3. Strip raw URLs and image CDN processing parameters
            $clean = preg_replace('/https?:\/\/[^\s\)]+/is', '', $clean);
            $clean = preg_replace('/(?:decor:)?maxbytes\([^)]*\)[^\s\)]*/is', '', $clean);
            $clean = preg_replace('/\b(?:stripicc|format\(webp\)|maxbytes)\b[^\s\)]*/is', '', $clean);

            $clean = preg_replace('/\s+/', ' ', $clean);
            $clean = trim($clean);
            $lower = strtolower($clean);

            // 4. Discard lines that are image captions or CDN garbage
            if (preg_match('/^!?\[?Image\s*\d*:/i', $clean) || str_contains($lower, 'stripicc()') || str_contains($lower, 'maxbytes(')) {
                continue;
            }

            // Minimum length: real reading paragraphs have at least 40 characters and 7 words
            if (strlen($clean) < 40 || str_word_count($clean) < 7) {
                continue;
            }

            // Exclude paragraphs containing UI / form / newsletter boilerplate
            $isBlacklisted = false;
            foreach ($uiBlacklist as $word) {
                if (str_contains($lower, $word)) {
                    $isBlacklisted = true;
                    break;
                }
            }
            if ($isBlacklisted) continue;

            // Natural language grammar check: real sentences end with terminal punctuation
            $lastChar = substr(rtrim($clean), -1);
            if (!in_array($lastChar, ['.', '!', '?', '"', "'", '”', '’', ')'])) {
                continue;
            }

            $results[] = $clean;
        }

        return $results;
    };

    // Tier 1: Direct HTTP fetch with modern Chrome browser headers
    try {
        $response = \Illuminate\Support\Facades\Http::withoutVerifying()->timeout(10)->withHeaders([
            'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language' => 'en-US,en;q=0.9',
            'Sec-Ch-Ua' => '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
            'Sec-Ch-Ua-Mobile' => '?0',
            'Sec-Ch-Ua-Platform' => '"Windows"',
            'Upgrade-Insecure-Requests' => '1',
        ])->get($url);

        if ($response->successful()) {
            $html = $response->body();

            // 1. Strip all interactive, form, and navigation tags completely
            $tagsToStrip = ['script', 'style', 'nav', 'header', 'footer', 'aside', 'form', 'button', 'input', 'select', 'textarea', 'dialog', 'menu', 'search', 'iframe', 'svg', 'video', 'audio', 'noscript', 'canvas'];
            foreach ($tagsToStrip as $tag) {
                $html = preg_replace('/<' . $tag . '\b[^>]*>(.*?)<\/' . $tag . '>/is', '', $html);
                $html = preg_replace('/<' . $tag . '\b[^>]*\/?>/is', '', $html);
            }

            // 2. Strip elements with common boilerplate classes (navigation, sidebars, newsletters, banners)
            $boilerPattern = '/<(div|section|aside|ul|ol|p)\b[^>]*(?:id|class)=["\'][^"\']*(?:nav|menu|sidebar|footer|header|newsletter|subscribe|subscription|sign-in|login|auth|modal|popup|ad-|advertisement|banner|breadcrumb|social|share|comment|promo|related)[^"\']*["\'][^>]*>(.*?)<\/\1>/is';
            for ($i = 0; $i < 2; $i++) {
                $html = preg_replace($boilerPattern, '', $html);
            }

            // 3. Locate Article / Main content container
            $articleHtml = null;
            $containerPatterns = [
                '/<article\b[^>]*>(.*?)<\/article>/is',
                '/<main\b[^>]*>(.*?)<\/main>/is',
                '/<div\b[^>]*(?:class|id)=["\'][^"\']*(?:article-body|story-body|entry-content|post-content|article-content|content-body|article__body|article_body)[^"\']*["\'][^>]*>(.*?)<\/div>/is',
                '/<div\b[^>]*itemprop=["\']articleBody["\'][^>]*>(.*?)<\/div>/is',
            ];

            foreach ($containerPatterns as $pattern) {
                if (preg_match($pattern, $html, $matches) && strlen(trim(strip_tags($matches[1]))) > 250) {
                    $articleHtml = $matches[1];
                    break;
                }
            }

            $sourceHtml = $articleHtml ?? $html;

            // Extract title
            if (preg_match('/<title\b[^>]*>(.*?)<\/title>/is', $html, $matches)) {
                $rawTitle = html_entity_decode(trim(strip_tags($matches[1])));
                if (!empty($rawTitle)) {
                    $title = $rawTitle;
                }
            }

            // Extract & clean paragraphs
            preg_match_all('/<p\b[^>]*>(.*?)<\/p>/is', $sourceHtml, $matches);
            if (!empty($matches[1])) {
                $paragraphs = $cleanAndValidateParagraphs($matches[1]);
            }
        }
    } catch (\Exception $e) {
        // Direct fetch failed or timed out, will proceed to Tier 2
    }

    // Tier 2: Cloudflare & Anti-Bot Bypass via Jina Reader (Medium, Substack, Paywalled SPAs)
    if (count($paragraphs) < 2) {
        try {
            $jinaUrl = 'https://r.jina.ai/' . $url;
            $jinaRes = \Illuminate\Support\Facades\Http::withoutVerifying()->timeout(12)->withHeaders([
                'Accept' => 'application/json',
                'User-Agent' => 'EasyRead/1.0',
            ])->get($jinaUrl);

            if ($jinaRes->successful()) {
                $jinaData = $jinaRes->json();
                if (!empty($jinaData['data']['title'])) {
                    $title = $jinaData['data']['title'];
                }
                $content = $jinaData['data']['content'] ?? $jinaRes->body();

                $lines = preg_split('/(\r\n|\n|\r){2,}/', $content);
                $jinaRawParas = [];
                foreach ($lines as $line) {
                    $clean = trim($line);
                    if (str_starts_with($clean, '#') || str_starts_with($clean, '![') || str_starts_with($clean, 'URL Source:') || str_starts_with($clean, 'Title:')) {
                        continue;
                    }
                    $clean = preg_replace('/\[(.*?)\]\(.*?\)/', '$1', $clean);
                    $clean = preg_replace('/[*_`]/', '', $clean);
                    if (strlen($clean) > 25) {
                        $jinaRawParas[] = $clean;
                    }
                }

                $validatedJina = $cleanAndValidateParagraphs($jinaRawParas);
                if (count($validatedJina) >= 2) {
                    $paragraphs = $validatedJina;
                }
            }
        } catch (\Exception $e) {
            // Jina fallback failed
        }
    }

    // Tier 3: If still empty, return informative error
    if (empty($paragraphs)) {
        return response()->json([
            'success' => false,
            'message' => 'Could not extract readable article text from this link. Try another article or blog URL.',
        ], 400);
    }

    return response()->json([
        'success' => true,
        'title' => $title,
        'url' => $url,
        'paragraphs' => array_values($paragraphs),
        'word_count' => count(explode(' ', implode(' ', $paragraphs))),
    ]);
});

// Authenticated Mobile APIs (Sanctum Protected)
Route::middleware('auth:sanctum')->group(function () {
    // Custom User Collections / Shelves
    Route::post('/collections', [\App\Http\Controllers\Api\CollectionController::class, 'store']);
    Route::post('/collections/assign-book', [\App\Http\Controllers\Api\CollectionController::class, 'assignBook']);
    Route::delete('/collections/{id}', [\App\Http\Controllers\Api\CollectionController::class, 'destroy']);

    // Auth & Profile Management
    Route::get('/user/profile', [AuthController::class, 'profile']);
    Route::get('/user/sync', function (\Illuminate\Http\Request $request) {
        $user = $request->user();

        // 1. Check account active status (Admin suspension check)
        if (!$user->is_active) {
            $user->currentAccessToken()?->delete();
            return response()->json([
                'success' => false,
                'is_active' => false,
                'message' => 'Your account has been suspended by EasyRead.',
            ], 403);
        }

        // 2. Check subscription expiration (Auto-downgrade expired plans)
        if ($user->is_premium && $user->subscription_expires_at && now()->isAfter($user->subscription_expires_at)) {
            $user->is_premium = false;
            $user->plan_id = null;
            $user->subscription_plan = null;
            $user->subscription_price = null;
            $user->subscription_expires_at = null;
            $user->save();
        }

        $permissions = app(\App\Http\Controllers\Api\AuthController::class)->resolvePermissionsForUser($user);

        $currentTokenId = $user->currentAccessToken()?->id;
        $devices = $user->tokens()->orderBy('last_used_at', 'desc')->orderBy('created_at', 'desc')->get()->map(function ($token) use ($currentTokenId) {
            $isCurrent = ($currentTokenId !== null && $token->id === $currentTokenId);
            $lastUsed = $token->last_used_at ?? $token->created_at;
            $diffSeconds = $lastUsed ? now()->diffInSeconds($lastUsed) : 999999;
            $isOnline = $isCurrent || ($diffSeconds <= 120);

            return [
                'id' => (int)$token->id,
                'name' => $token->name ?: 'Mobile Device',
                'is_current' => $isCurrent,
                'is_online' => $isOnline,
                'created_at' => $token->created_at ? $token->created_at->diffForHumans() : 'Recently',
                'last_active' => $isOnline ? 'Active now' : ($token->last_used_at ? $token->last_used_at->diffForHumans() : 'Inactive'),
                'raw_last_used' => $token->last_used_at ? $token->last_used_at->toISOString() : null,
            ];
        })->values();

        // Calculate unread notifications count for live badge display
        $unreadNotifsCount = \App\Models\AppNotification::forUser($user)
            ->get()
            ->filter(function ($n) use ($user) {
                return !$n->isReadBy($user->id);
            })
            ->count();

        return response()->json([
            'success' => true,
            'is_active' => true,
            'is_premium' => (bool)$user->is_premium,
            'sync_enabled' => (bool)($user->sync_enabled ?? true),
            'day_streak' => (int)($user->day_streak ?? 1),
            'total_words_read' => (int)($user->total_words_read ?? 0),
            'plan_id' => $user->plan_id,
            'subscription_plan' => $user->subscription_plan,
            'subscription_expires_at' => $user->subscription_expires_at ? $user->subscription_expires_at->toISOString() : null,
            'feature_permissions' => $permissions,
            'ai_free_uses_left' => $user->ai_free_uses_left,
            'unread_notifications_count' => $unreadNotifsCount,
            'devices' => $devices,
            'devices_count' => count($devices),
        ]);
    });

    Route::post('/user/settings', function (\Illuminate\Http\Request $request) {
        $user = $request->user();
        if ($request->has('sync_enabled')) {
            $user->sync_enabled = $request->boolean('sync_enabled');
        }
        if ($request->has('day_streak')) {
            $user->day_streak = max(1, $request->integer('day_streak'));
        }
        if ($request->has('total_words_read')) {
            $user->total_words_read = max((int)$user->total_words_read, $request->integer('total_words_read'));
        }
        $user->save();

        return response()->json([
            'success' => true,
            'sync_enabled' => (bool)$user->sync_enabled,
            'day_streak' => (int)$user->day_streak,
            'total_words_read' => (int)$user->total_words_read,
            'message' => 'Settings updated successfully',
        ]);
    });

    // In-App Notification Center APIs
    Route::get('/notifications', [\App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::post('/notifications/mark-all-read', [\App\Http\Controllers\Api\NotificationController::class, 'markAllRead']);
    Route::post('/notifications/{id}/read', [\App\Http\Controllers\Api\NotificationController::class, 'markRead']);
    Route::delete('/notifications/{id}', [\App\Http\Controllers\Api\NotificationController::class, 'destroy']);

    Route::post('/sync/push-progress', [\App\Http\Controllers\Api\SyncController::class, 'pushProgress']);
    Route::post('/sync/remove-progress', [\App\Http\Controllers\Api\SyncController::class, 'removeProgress']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::post('/user/change-password', [AuthController::class, 'changePassword']);
    Route::post('/user/subscription', function (\Illuminate\Http\Request $request) {
        $user = $request->user();
        $planSlug = $request->input('plan_slug', 'monthly');
        $isPremium = $request->boolean('is_premium', true);
        
        $plan = \App\Models\Plan::where('slug', $planSlug)->orWhere('id', $planSlug)->first();
        if ($plan && $isPremium) {
            $user->plan_id = $plan->id;
            $user->subscription_plan = $plan->name;
            $user->subscription_price = $plan->price;
            $user->subscription_starts_at = now();
            $user->subscription_expires_at = match($plan->slug) {
                'quarterly' => now()->addMonths(3),
                'biannual' => now()->addMonths(6),
                'yearly' => now()->addYear(),
                default => now()->addMonth(),
            };
            $user->is_premium = true;
            $user->ai_free_uses_left = 999;
        } else {
            $user->is_premium = $isPremium;
            if (!$isPremium) {
                if ($plan && (strtolower($plan->slug) === 'free' || str_contains(strtolower($plan->name), 'free'))) {
                    $user->plan_id = $plan->id;
                    $user->subscription_plan = $plan->name;
                    $user->subscription_price = 'Free';
                } else {
                    $user->plan_id = null;
                    $user->subscription_plan = null;
                    $user->subscription_price = null;
                }
                $user->subscription_expires_at = null;
            }
        }
        $user->save();

        if ($user->is_premium && $user->subscription_plan) {
            \App\Services\NotificationService::sendSubscriptionReceipt($user, $user->subscription_plan, $user->subscription_price ?? 'Active', $user->subscription_expires_at?->format('M d, Y') ?? 'Auto-renewing');
        }

        $permissions = app(\App\Http\Controllers\Api\AuthController::class)->resolvePermissionsForUser($user);

        return response()->json([
            'success' => true,
            'is_premium' => $user->is_premium,
            'user' => array_merge($user->toArray(), [
                'feature_permissions' => $permissions,
            ]),
            'feature_permissions' => $permissions,
        ]);
    });
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);
    Route::get('/user/devices', [AuthController::class, 'devices']);
    Route::post('/user/devices/logout-others', [AuthController::class, 'logoutOthers']);
    Route::delete('/user/devices/{id}', [AuthController::class, 'revokeDevice']);
    Route::delete('/user/account', [AuthController::class, 'deleteAccount']); // Apple 5.1.1 compliant
    Route::post('/user/fcm-token', [AuthController::class, 'updateFcmToken']);

    // Library & Continue Reading (Spec 6)
    Route::get('/library/continue-reading', [BookController::class, 'continueReading']);
    Route::post('/books/import', [BookController::class, 'store']); // Specs 2, 3, 5: Web save & share intent
    Route::delete('/books/user-doc', [BookController::class, 'destroyUserDocument']);
    Route::post('/books/{id}/progress', [BookController::class, 'updateProgress']);

    // Cross-Device Delta Sync (Spec 13 & 14)
    Route::get('/sync/pull', [SyncController::class, 'pull']);
    Route::post('/sync/push-highlights', [SyncController::class, 'pushHighlights']);
    Route::post('/sync/delete-highlight', [SyncController::class, 'deleteHighlight']);
    Route::post('/sync/downloads', [SyncController::class, 'pushDownloads']);
    Route::post('/sync/downloads/remove', [SyncController::class, 'removeDownload']);

    // Cloud Backup & Point-in-time Restore (Specs 15–17)
    Route::get('/backups', [BackupController::class, 'index']);
    Route::post('/backups', [BackupController::class, 'store']);
    Route::post('/backups/{id}/restore', [BackupController::class, 'restore']);

    // Vocabulary Bank & Flashcard Quizzes (Spec 12)
    Route::get('/vocabulary', [VocabularyController::class, 'index']);
    Route::post('/vocabulary', [VocabularyController::class, 'store']);
    Route::post('/vocabulary/{id}/review', [VocabularyController::class, 'recordReview']);
    Route::delete('/vocabulary/{id}', [VocabularyController::class, 'destroy']);
});

// Passage AI Assistant (Spec 9: Gemini 3.6 Flash / AI Proxy - Supports both authenticated users and guest readers)
Route::post('/ai/assist', [AiAssistantController::class, 'assist']);

