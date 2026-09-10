<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\File;

class AdminSettingController extends Controller
{
    public function index()
    {
        $settings = [
            'ai_provider' => Setting::get('ai_provider', 'google_ai_studio'),
            'google_ai_studio_key' => Setting::get('google_ai_studio_key', Setting::get('gemini_api_key', env('GEMINI_API_KEY', ''))),
            'google_ai_studio_model' => Setting::get('google_ai_studio_model', Setting::get('gemini_model', 'gemini-1.5-flash')),
            'openrouter_api_key' => Setting::get('openrouter_api_key', env('OPENROUTER_API_KEY', '')),
            'openrouter_model' => Setting::get('openrouter_model', 'google/gemini-flash-1.5'),
            'openai_api_key' => Setting::get('openai_api_key', env('OPENAI_API_KEY', '')),
            'openai_model' => Setting::get('openai_model', 'gpt-4o-mini'),
            'ai_temperature' => Setting::get('ai_temperature', '0.7'),
            'free_ai_limit' => Setting::get('free_ai_limit', '10'),
            'free_vocab_limit' => Setting::get('free_vocab_limit', '30'),
            'app_name' => Setting::get('app_name', 'EasyRead'),
            'app_logo' => Setting::get('app_logo', ''),
            'app_favicon' => Setting::get('app_favicon', ''),
            'support_email' => Setting::get('support_email', 'support@easyread.com'),
            'revenuecat_google_key' => Setting::get('revenuecat_google_key', ''),
            'revenuecat_apple_key' => Setting::get('revenuecat_apple_key', ''),
            'revenuecat_entitlement_id' => Setting::get('revenuecat_entitlement_id', 'plus'),
            'revenuecat_webhook_secret' => Setting::get('revenuecat_webhook_secret', ''),
            'google_auth_enabled' => Setting::get('google_auth_enabled', '1'),
            'google_web_client_id' => Setting::get('google_web_client_id', ''),
            'apple_auth_enabled' => Setting::get('apple_auth_enabled', '1'),
            'firebase_project_id' => Setting::get('firebase_project_id', ''),
            'firebase_api_key' => Setting::get('firebase_api_key', ''),
            'translation_languages' => Setting::get('translation_languages', 'Urdu, Spanish, French, German, Arabic, Hindi, Chinese, Turkish, Italian, Portuguese, Japanese, Russian'),
            'reading_speed_wpm' => Setting::get('reading_speed_wpm', '200'),
            'privacy_policy' => Setting::get('privacy_policy', "EasyRead values your reading privacy.\n\n• Private AI Processing: Passages sent to AI for simplify, summarize, explain, or translation are processed securely and never retained to train public models.\n\n• Local & Encrypted Sync: Your vocabulary words, highlights, and book progress are stored securely on your device and encrypted during sync.\n\n• No Data Selling: We do not sell your reading habits, vocabulary, or personal data to any third parties."),
            // SMTP Email Settings
            'smtp_host'         => Setting::get('smtp_host', ''),
            'smtp_port'         => Setting::get('smtp_port', '587'),
            'smtp_username'     => Setting::get('smtp_username', ''),
            'smtp_password'     => Setting::get('smtp_password', ''),
            'smtp_encryption'   => Setting::get('smtp_encryption', 'tls'),
            'smtp_from_address' => Setting::get('smtp_from_address', ''),
            'smtp_from_name'    => Setting::get('smtp_from_name', ''),
            // Push & Notification Settings
            'enable_in_app_notifications'        => Setting::get('enable_in_app_notifications', '1'),
            'enable_new_book_notifications'      => Setting::get('enable_new_book_notifications', '1'),
            'enable_subscription_receipt_emails' => Setting::get('enable_subscription_receipt_emails', '1'),
            'enable_suspension_emails'           => Setting::get('enable_suspension_emails', '1'),
            'fcm_enabled'                        => Setting::get('fcm_enabled', '0'),
            'fcm_server_key'                     => Setting::get('fcm_server_key', ''),
            'fcm_sender_id'                      => Setting::get('fcm_sender_id', ''),
            'fcm_project_id'                     => Setting::get('fcm_project_id', ''),
            // Dropbox Cloud Storage
            'dropbox_enabled'                    => Setting::get('dropbox_enabled', '1'),
            'dropbox_app_key'                    => Setting::get('dropbox_app_key', '1j22ldywe7y316j'),
            'dropbox_app_secret'                 => Setting::get('dropbox_app_secret', '5vl09ge69dbawph'),
        ];

        return view('admin.settings.index', compact('settings'));
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'ai_provider' => 'required|in:google_ai_studio,openrouter,openai,gemini_direct',
            'google_ai_studio_key' => 'nullable|string',
            'google_ai_studio_model' => 'nullable|string',
            'openrouter_api_key' => 'nullable|string',
            'openrouter_model' => 'nullable|string',
            'openai_api_key' => 'nullable|string',
            'openai_model' => 'nullable|string',
            'gemini_direct_key' => 'nullable|string',
            'gemini_direct_model' => 'nullable|string',
            'ai_temperature' => 'nullable|string',
            'free_ai_limit' => 'nullable|integer|min:1|max:1000',
            'free_vocab_limit' => 'nullable|integer|min:1|max:1000',
            'reading_speed_wpm' => 'nullable|integer|min:30|max:500',
            'app_name' => 'nullable|string|max:100',
            'support_email' => 'nullable|email|max:150',
            'privacy_policy' => 'nullable|string',
            'revenuecat_google_key' => 'nullable|string|max:150',
            'revenuecat_apple_key' => 'nullable|string|max:150',
            'revenuecat_entitlement_id' => 'nullable|string|max:100',
            'revenuecat_webhook_secret' => 'nullable|string|max:150',
            'google_auth_enabled' => 'nullable|string',
            'google_web_client_id' => 'nullable|string|max:255',
            'apple_auth_enabled' => 'nullable|string',
            'firebase_project_id' => 'nullable|string|max:100',
            'firebase_api_key' => 'nullable|string|max:255',
            'translation_languages' => 'nullable|string|max:1000',
            'app_logo' => 'nullable|file|mimes:png,jpg,jpeg,svg,webp,ico|max:4096',
            'app_favicon' => 'nullable|file|mimes:png,ico,svg,jpg,jpeg,webp|max:2048',
            // SMTP
            'smtp_host'         => 'nullable|string|max:255',
            'smtp_port'         => 'nullable|integer|min:1|max:65535',
            'smtp_username'     => 'nullable|string|max:255',
            'smtp_password'     => 'nullable|string|max:500',
            'smtp_encryption'   => 'nullable|in:tls,ssl,',
            'smtp_from_address' => 'nullable|email|max:255',
            'smtp_from_name'    => 'nullable|string|max:100',
            // Push & Notifications
            'fcm_server_key'    => 'nullable|string|max:10000',
            'fcm_sender_id'     => 'nullable|string|max:255',
            'fcm_project_id'    => 'nullable|string|max:255',
            // Dropbox
            'dropbox_app_key'    => 'nullable|string|max:255',
            'dropbox_app_secret' => 'nullable|string|max:255',
        ]);

        // Process standard text settings
        $textFields = [
            'ai_provider',
            'google_ai_studio_key',
            'google_ai_studio_model',
            'openrouter_api_key',
            'openrouter_model',
            'openai_api_key',
            'openai_model',
            'gemini_direct_key',
            'gemini_direct_model',
            'ai_temperature',
            'free_ai_limit',
            'free_vocab_limit',
            'reading_speed_wpm',
            'app_name',
            'support_email',
            'privacy_policy',
            'revenuecat_google_key',
            'revenuecat_apple_key',
            'revenuecat_entitlement_id',
            'revenuecat_webhook_secret',
            'google_web_client_id',
            'firebase_project_id',
            'firebase_api_key',
            'translation_languages',
            // SMTP Settings
            'smtp_host',
            'smtp_port',
            'smtp_username',
            'smtp_password',
            'smtp_encryption',
            'smtp_from_address',
            'smtp_from_name',
            // Push & Notifications
            'fcm_server_key',
            'fcm_sender_id',
            'fcm_project_id',
            // Dropbox Settings
            'dropbox_app_key',
            'dropbox_app_secret',
        ];

        foreach ($textFields as $field) {
            if ($request->has($field)) {
                Setting::set($field, $request->input($field) ?? '');
            }
        }

        // Toggles
        Setting::set('enable_in_app_notifications', $request->has('enable_in_app_notifications') ? '1' : '0');
        Setting::set('enable_new_book_notifications', $request->has('enable_new_book_notifications') ? '1' : '0');
        Setting::set('enable_subscription_receipt_emails', $request->has('enable_subscription_receipt_emails') ? '1' : '0');
        Setting::set('enable_suspension_emails', $request->has('enable_suspension_emails') ? '1' : '0');
        Setting::set('fcm_enabled', $request->has('fcm_enabled') ? '1' : '0');
        Setting::set('google_auth_enabled', $request->has('google_auth_enabled') ? '1' : '0');
        Setting::set('apple_auth_enabled', $request->has('apple_auth_enabled') ? '1' : '0');
        Setting::set('dropbox_enabled', $request->has('dropbox_enabled') ? '1' : '0');

        // Auto-recalculate read_time for all books if WPM changed
        $wpm = (int) Setting::get('reading_speed_wpm', '200');
        if ($wpm < 30) $wpm = 200;
        $books = \App\Models\Book::with('paragraphs')->get();
        foreach ($books as $b) {
            $totalWords = 0;
            foreach ($b->paragraphs as $p) {
                $totalWords += str_word_count(strip_tags($p->content));
            }
            $mins = max(1, (int) ceil($totalWords / $wpm));
            $b->update(['read_time' => $mins . ' min read']);
        }

        // Toggles
        Setting::set('google_auth_enabled', $request->has('google_auth_enabled') ? '1' : '0');
        Setting::set('apple_auth_enabled', $request->has('apple_auth_enabled') ? '1' : '0');

        // Backward compatibility sync
        if ($request->has('google_ai_studio_key')) {
            Setting::set('gemini_api_key', $request->input('google_ai_studio_key') ?? '');
        }
        if ($request->has('google_ai_studio_model')) {
            Setting::set('gemini_model', $request->input('google_ai_studio_model') ?? 'gemini-1.5-flash');
        }

        // Handle Unified Web Logo & Favicon Upload (Single field sets both website logo & browser favicon)
        if ($request->hasFile('app_logo')) {
            $file = $request->file('app_logo');
            $filename = 'logo_' . time() . '.' . $file->getClientOriginalExtension();
            $destPath = public_path('uploads/branding');
            if (!file_exists($destPath)) {
                mkdir($destPath, 0755, true);
            }
            $file->move($destPath, $filename);
            $logoPath = 'uploads/branding/' . $filename;
            Setting::set('app_logo', $logoPath);
            Setting::set('app_favicon', $logoPath); // auto-sync as favicon
        } elseif ($request->input('remove_logo') === '1') {
            Setting::set('app_logo', '');
            Setting::set('app_favicon', '');
        } elseif ($request->hasFile('app_favicon')) {
            // Fallback for legacy favicon uploads
            $file = $request->file('app_favicon');
            $filename = 'favicon_' . time() . '.' . $file->getClientOriginalExtension();
            $destPath = public_path('uploads/branding');
            if (!file_exists($destPath)) {
                mkdir($destPath, 0755, true);
            }
            $file->move($destPath, $filename);
            $faviconPath = 'uploads/branding/' . $filename;
            Setting::set('app_favicon', $faviconPath);
            if (empty(Setting::get('app_logo'))) {
                Setting::set('app_logo', $faviconPath);
            }
        }

        $activeTab = $request->input('active_tab', 'ai');

        return redirect()->route('admin.settings.index', ['tab' => $activeTab])
            ->with('active_tab', $activeTab)
            ->with('success', 'App Settings updated successfully.');
    }

    public function testSmtp(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $host       = Setting::get('smtp_host', '');
        $username   = Setting::get('smtp_username', '');
        $password   = Setting::get('smtp_password', '');
        $port       = (int)(Setting::get('smtp_port', 587) ?: 587);
        $encryption = Setting::get('smtp_encryption', 'tls');
        $fromAddr   = Setting::get('smtp_from_address', Setting::get('support_email', 'noreply@easyread.com'));
        $fromName   = Setting::get('smtp_from_name', Setting::get('app_name', 'EasyRead'));

        if (empty($host) || empty($username)) {
            return response()->json([
                'success' => false,
                'message' => 'SMTP Host and Username are required. Please fill in your SMTP settings and save first.',
            ]);
        }

        // Apply SMTP settings at runtime
        config([
            'mail.default'                 => 'smtp',
            'mail.mailers.smtp.transport'  => 'smtp',
            'mail.mailers.smtp.host'       => $host,
            'mail.mailers.smtp.port'       => $port,
            'mail.mailers.smtp.username'   => $username,
            'mail.mailers.smtp.password'   => $password,
            'mail.mailers.smtp.encryption' => $encryption,
            'mail.mailers.smtp.scheme'     => null,
            'mail.from.address'            => $fromAddr,
            'mail.from.name'               => $fromName,
        ]);

        $appName = Setting::get('app_name', 'EasyRead');
        try {
            \Mail::to($request->email)->send(new \App\Mail\OtpPasswordResetMail('123456', 'Test User', $appName));
            return response()->json([
                'success' => true,
                'message' => "Test email sent successfully to {$request->email}! Check your inbox.",
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'SMTP Error: ' . $e->getMessage(),
            ]);
        }
    }

    public function testPush(Request $request)
    {
        $serverKey = trim($request->input('server_key') ?: Setting::get('fcm_server_key', ''));
        if (empty($serverKey)) {
            return response()->json([
                'success' => false,
                'message' => 'Please enter or save your Firebase Cloud Messaging (FCM) Server Key first.',
            ]);
        }

        // Temporarily set key in settings for the test if provided
        if ($request->has('server_key')) {
            Setting::set('fcm_server_key', $serverKey);
        }

        $sent = \App\Services\NotificationService::sendFcmPush(
            "🔔 EasyRead Alert",
            "Test notification with loud sound & popup banner received successfully! 🚀",
            '/topics/all_users',
            ['type' => 'test']
        );

        if ($sent) {
            return response()->json([
                'success' => true,
                'message' => 'Test push broadcasted to all connected devices! Check your phone screen.',
            ]);
        } else {
            return response()->json([
                'success' => false,
                'message' => 'Failed to dispatch test push. Please verify that your FCM Server Key is valid.',
            ]);
        }
    }

    public function testGoogleAiStudio(Request $request)
    {
        $apiKey = trim($request->input('api_key') ?: Setting::get('google_ai_studio_key', Setting::get('gemini_api_key', env('GEMINI_API_KEY'))));
        $model = trim($request->input('model') ?: Setting::get('google_ai_studio_model', 'gemini-3.5-flash'));

        if (empty($apiKey) || $apiKey === 'YOUR_GEMINI_API_KEY') {
            return response()->json([
                'success' => false,
                'message' => 'Please provide a valid Google AI Studio API Key.',
            ]);
        }

        try {
            // Force IPv4 resolution to prevent ISP DNS timeouts
            $response = Http::withoutVerifying()
                ->withOptions([
                    'force_ip_resolve' => 'v4',
                    'connect_timeout' => 10,
                ])
                ->withHeaders([
                    'Content-Type' => 'application/json',
                    'X-goog-api-key' => $apiKey,
                ])
                ->timeout(25)
                ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}", [
                    'contents' => [
                        ['parts' => [['text' => 'Hello! Reply with exactly: "Google AI Studio Gemini is active and ready."']]]
                    ]
                ]);

            // If 400 or 404, try alternative model
            if (!$response->successful() && in_array($response->status(), [400, 404])) {
                $altModel = ($model === 'gemini-3.5-flash') ? 'gemini-3.7-flash' : 'gemini-3.5-flash';
                $response = Http::withoutVerifying()
                    ->withOptions([
                        'force_ip_resolve' => 'v4',
                        'connect_timeout' => 10,
                    ])
                    ->withHeaders([
                        'Content-Type' => 'application/json',
                        'X-goog-api-key' => $apiKey,
                    ])
                    ->timeout(25)
                    ->post("https://generativelanguage.googleapis.com/v1beta/models/{$altModel}:generateContent?key={$apiKey}", [
                        'contents' => [
                            ['parts' => [['text' => 'Hello! Reply with exactly: "Google AI Studio Gemini is active and ready."']]]
                        ]
                    ]);
            }

            if ($response->successful()) {
                $json = $response->json();
                $reply = $json['candidates'][0]['content']['parts'][0]['text'] ?? 'Connection successful.';
                return response()->json([
                    'success' => true,
                    'message' => 'Google AI Studio connection verified successfully!',
                    'reply' => trim($reply),
                ]);
            } else {
                $errorJson = $response->json();
                $errorMsg = $errorJson['error']['message'] ?? ('HTTP ' . $response->status());
                return response()->json([
                    'success' => false,
                    'message' => $errorMsg,
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Connection failed: ' . $e->getMessage(),
            ]);
        }
    }

    public function testOpenRouter(Request $request)
    {
        $apiKey = trim($request->input('api_key') ?: Setting::get('openrouter_api_key', env('OPENROUTER_API_KEY')));
        $model = trim($request->input('model') ?: Setting::get('openrouter_model', 'google/gemini-flash-1.5'));

        if (empty($apiKey) || $apiKey === 'YOUR_OPENROUTER_API_KEY') {
            return response()->json([
                'success' => false,
                'message' => 'Please provide a valid OpenRouter API Key (starts with sk-or-...).',
            ]);
        }

        try {
            $response = Http::withoutVerifying()
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                    'HTTP-Referer' => 'http://localhost:8000',
                    'X-Title' => 'EasyRead Studio',
                    'Content-Type' => 'application/json',
                ])
                ->timeout(15)
                ->post('https://openrouter.ai/api/v1/chat/completions', [
                    'model' => $model,
                    'messages' => [
                        ['role' => 'user', 'content' => 'Hello! Reply with exactly: "OpenRouter AI is active and ready."']
                    ],
                ]);

            if ($response->successful()) {
                $json = $response->json();
                $reply = $json['choices'][0]['message']['content'] ?? 'Connection successful.';
                return response()->json([
                    'success' => true,
                    'message' => 'OpenRouter verified successfully!',
                    'reply' => trim($reply),
                ]);
            } else {
                $errJson = $response->json();
                $errorMsg = $errJson['error']['message'] ?? ('HTTP ' . $response->status());
                return response()->json([
                    'success' => false,
                    'message' => 'OpenRouter Error: ' . $errorMsg,
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Connection failed: ' . $e->getMessage(),
            ]);
        }
    }

    public function testOpenAi(Request $request)
    {
        $apiKey = trim($request->input('api_key') ?: Setting::get('openai_api_key', env('OPENAI_API_KEY')));
        $model = trim($request->input('model') ?: Setting::get('openai_model', 'gpt-4o-mini'));

        if (empty($apiKey) || $apiKey === 'YOUR_OPENAI_API_KEY') {
            return response()->json([
                'success' => false,
                'message' => 'Please provide a valid OpenAI API Key.',
            ]);
        }

        try {
            $response = Http::withoutVerifying()
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                    'Content-Type' => 'application/json',
                ])
                ->timeout(15)
                ->post('https://api.openai.com/v1/chat/completions', [
                    'model' => $model,
                    'messages' => [
                        ['role' => 'user', 'content' => 'Hello! Reply with exactly: "OpenAI ChatGPT is active and ready."']
                    ],
                ]);

            if ($response->successful()) {
                $json = $response->json();
                $reply = $json['choices'][0]['message']['content'] ?? 'Connection successful.';
                return response()->json([
                    'success' => true,
                    'message' => 'OpenAI ChatGPT connection verified successfully!',
                    'reply' => trim($reply),
                ]);
            } else {
                $errorJson = $response->json();
                $errorMsg = $errorJson['error']['message'] ?? ('HTTP ' . $response->status());
                return response()->json([
                    'success' => false,
                    'message' => 'OpenAI Error: ' . $errorMsg,
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Connection failed: ' . $e->getMessage(),
            ]);
        }
    }
}
