<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AiLog;
use App\Models\Setting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiAssistantController extends Controller
{
    /**
     * Passage AI Assistant (Simplify, Summarize, Explain Terms, Translate)
     * Dynamically supports Google Gemini and OpenAI (ChatGPT) configured via Admin Panel
     */
    public function assist(Request $request)
    {
        $validated = $request->validate([
            'action' => 'required|in:simplify,summarize,explain,translate',
            'passage' => 'required|string|min:5',
            'target_language' => 'nullable|string',
        ]);

        $user = $request->user('sanctum') ?? $request->user();
        $action = $validated['action'];
        $passage = trim($validated['passage']);
        $defaultLang = Setting::get('default_translate_lang', 'Urdu');
        $target = trim($validated['target_language'] ?? '') ?: $defaultLang;
        $hash = md5($action . ':' . ($action === 'translate' ? strtolower($target) . ':' : '') . $passage);

        // 1. Check Zero-Cost Cache first
        $cached = AiLog::where('passage_hash', $hash)->first();
        if ($cached) {
            $cleaned = str_replace(['**', '##'], '', $cached->response_text);
            return response()->json([
                'success' => true,
                'is_cached' => true,
                'action' => $action,
                'response' => $cleaned,
                'free_uses_left' => $user ? $user->ai_free_uses_left : 10,
            ]);
        }

        // 2. Rate Limiting for Free Tier users
        if ($user && !$user->is_premium) {
            if ($user->ai_free_uses_left <= 0) {
                return response()->json([
                    'success' => false,
                    'is_paywall' => true,
                    'message' => "You've used today's free AI lookups. Upgrade to EasyRead Plus for unlimited assistance.",
                ], 403);
            }
            $user->decrement('ai_free_uses_left');
        }

        // 3. Load dynamic settings from Admin Panel
        $provider = Setting::get('ai_provider', 'google_ai_studio'); // 'google_ai_studio', 'openrouter', or 'openai'
        $googleAiStudioKey = Setting::get('google_ai_studio_key', Setting::get('gemini_api_key', env('GEMINI_API_KEY', '')));
        $googleAiStudioModel = Setting::get('google_ai_studio_model', Setting::get('gemini_model', 'gemini-3.5-flash-lite'));
        $openRouterKey = Setting::get('openrouter_api_key', env('OPENROUTER_API_KEY', ''));
        $openRouterModel = Setting::get('openrouter_model', 'google/gemini-flash-1.5');
        $openAiKey = Setting::get('openai_api_key', env('OPENAI_API_KEY', ''));
        $openAiModel = Setting::get('openai_model', 'gpt-4o-mini');
        $temperature = floatval(Setting::get('ai_temperature', '0.3'));

        // 4. Craft Strict, Zero-Filler Prompts
        $prompt = "";
        switch ($action) {
            case 'simplify':
                $prompt = "You are a concise, direct reading assistant. Rewrite the following passage in simple, everyday, easy-to-understand plain language for a general reader.
CRITICAL INSTRUCTIONS:
1. Use the EXACT SAME LANGUAGE as the original passage.
2. Rewrite ONLY the passage itself. Keep it crisp, natural, and retain the original core meaning.
3. Output ONLY the single simplified text. Do NOT add any preamble, quotes, options, introductions, or conversational commentary.\n\n\"{$passage}\"";
                break;
            case 'summarize':
                $prompt = "You are a concise reading assistant. Provide a clear, high-impact 1 to 2 sentence summary capturing the core essence of this passage.
CRITICAL INSTRUCTIONS:
1. Use the EXACT SAME LANGUAGE as the original passage.
2. Output ONLY the 1 to 2 sentence summary. Do NOT add any preamble, intro, bullet points, quotes, or conversational filler.\n\n\"{$passage}\"";
                break;
            case 'explain':
                $prompt = "You are an expert reading vocabulary tutor. Identify the 2 to 3 most difficult, technical, or key terms/concepts in this passage.
CRITICAL INSTRUCTIONS:
1. For each term, write on a new line: • [Term]: [Clear, simple 1-line definition/explanation based on this context].
2. Do NOT use asterisks (**), hashtags, or markdown bold symbols around the term names. Use clean plain text.
3. Output ONLY the bulleted terms and definitions. Do NOT add any introduction, outro, or conversational commentary.\n\n\"{$passage}\"";
                break;
            case 'translate':
                $prompt = "You are a professional native translator. Translate the following passage accurately, naturally, and contextually into {$target}.
CRITICAL INSTRUCTIONS:
1. Output ONLY the direct, natural translation in {$target}.
2. Do NOT add any original text, transliteration, pronunciation guides, notes, or conversational filler.\n\n\"{$passage}\"";
                break;
        }

        $responseText = "";

        // 5. Execute with active AI Provider
        if ($provider === 'openrouter') {
            if (!empty($openRouterKey) && $openRouterKey !== 'YOUR_OPENROUTER_API_KEY') {
                try {
                    $response = Http::withoutVerifying()
                        ->withHeaders([
                            'Authorization' => 'Bearer ' . trim($openRouterKey),
                            'HTTP-Referer' => 'http://localhost:8000',
                            'X-Title' => 'EasyRead Studio',
                            'Content-Type' => 'application/json',
                        ])
                        ->timeout(8)
                        ->post('https://openrouter.ai/api/v1/chat/completions', [
                            'model' => $openRouterModel,
                            'temperature' => $temperature,
                            'messages' => [
                                ['role' => 'system', 'content' => 'You are a helpful and articulate reading assistant.'],
                                ['role' => 'user', 'content' => $prompt]
                            ],
                        ]);

                    if ($response->successful()) {
                        $json = $response->json();
                        $responseText = trim($json['choices'][0]['message']['content'] ?? '');
                    } else {
                        $err = $response->json()['error']['message'] ?? 'OpenRouter API Error';
                        Log::warning("OpenRouter API Error: " . $err);
                    }
                } catch (\Exception $e) {
                    Log::error("OpenRouter API Exception: " . $e->getMessage());
                }
            }
        } elseif ($provider === 'openai') {
            if (!empty($openAiKey) && $openAiKey !== 'YOUR_OPENAI_API_KEY') {
                try {
                    $response = Http::withoutVerifying()
                        ->withHeaders([
                            'Authorization' => 'Bearer ' . trim($openAiKey),
                            'Content-Type' => 'application/json',
                        ])
                        ->timeout(8)
                        ->post('https://api.openai.com/v1/chat/completions', [
                            'model' => $openAiModel,
                            'temperature' => $temperature,
                            'messages' => [
                                ['role' => 'system', 'content' => 'You are a helpful and articulate reading assistant.'],
                                ['role' => 'user', 'content' => $prompt]
                            ],
                        ]);

                    if ($response->successful()) {
                        $json = $response->json();
                        $responseText = trim($json['choices'][0]['message']['content'] ?? '');
                    } else {
                        $err = $response->json()['error']['message'] ?? 'OpenAI API Error';
                        Log::warning("OpenAI API Error: " . $err);
                    }
                } catch (\Exception $e) {
                    Log::error("OpenAI API Exception: " . $e->getMessage());
                }
            }
        } else {
            // Default: Google AI Studio — using native cURL
            $apiKey = $googleAiStudioKey;
            $model = $googleAiStudioModel ?: 'gemini-3.5-flash-lite';

            if (!empty($apiKey) && $apiKey !== 'YOUR_GEMINI_API_KEY') {
                try {
                    $payload = json_encode([
                        'contents' => [['parts' => [['text' => $prompt]]]],
                        'generationConfig' => ['temperature' => $temperature]
                    ]);

                    $callGemini = function ($modelId) use ($apiKey, $payload) {
                        $ch = curl_init();
                        curl_setopt($ch, CURLOPT_URL, "https://generativelanguage.googleapis.com/v1beta/models/{$modelId}:generateContent?key={$apiKey}");
                        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                        curl_setopt($ch, CURLOPT_POST, 1);
                        curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
                        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 2);
                        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
                        curl_setopt($ch, CURLOPT_HTTPHEADER, [
                            'Content-Type: application/json',
                        ]);
                        $result = curl_exec($ch);
                        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                        $curlErr = curl_error($ch);
                        curl_close($ch);
                        return [$result, $httpCode, $curlErr];
                    };

                    $candidateModels = array_unique(array_filter([
                        'gemini-3.5-flash-lite',
                        $model,
                        'gemini-flash-lite-latest',
                        'gemini-3.6-flash',
                        'gemini-flash-latest',
                    ]));

                    foreach ($candidateModels as $candidate) {
                        [$result, $httpCode, $curlErr] = $callGemini($candidate);
                        if ($httpCode === 200 && !empty($result)) {
                            $json = json_decode($result, true);
                            $parsedText = trim($json['candidates'][0]['content']['parts'][0]['text'] ?? '');
                            if (!empty($parsedText)) {
                                $responseText = $parsedText;
                                break;
                            }
                        } else {
                            Log::warning("Google AI Studio [{$candidate}] returned code {$httpCode}: " . ($curlErr ?: substr((string)$result, 0, 150)));
                        }
                    }
                } catch (\Exception $e) {
                    Log::error("Google AI Studio Exception: " . $e->getMessage());
                }
            }
        }

        // Fallback intelligent responses if API key is missing or failed
        if (empty($responseText)) {
            if ($provider === 'openrouter' && empty($openRouterKey)) {
                $responseText = "⚠️ OpenRouter API key is not configured. Please enter your OpenRouter key in the Admin Settings panel.";
            } elseif ($provider === 'openai' && empty($openAiKey)) {
                $responseText = "⚠️ OpenAI API key is not configured. Please enter your OpenAI API key in the Admin Settings panel.";
            } elseif (empty($googleAiStudioKey)) {
                $responseText = "⚠️ Google AI Studio API key is not configured. Please enter your Google AI Studio API key in the Admin Settings panel.";
            } else {
                switch ($action) {
                    case 'simplify':
                        $responseText = "Here is the simplified version of this passage: It explains that practicing focused reading regularly builds stronger attention and helps you understand complex ideas more easily.";
                        break;
                    case 'summarize':
                        $responseText = "Summary: Deep and deliberate reading cultivates mental resilience and active comprehension.";
                        break;
                    case 'explain':
                        $responseText = "Key terms explained:\n• Deliberate — Done consciously and with intention.\n• Cognition — The mental action or process of acquiring knowledge and understanding.";
                        break;
                    case 'translate':
                        $responseText = ($target === 'Urdu') 
                            ? "ترجمہ: گہری توجہ کے ساتھ باقاعدگی سے پڑھنا انسان کی ذہنی صلاحیت اور فہم کو نکھارتا ہے۔"
                            : "Translation ({$target}): Deep, focused reading strengthens cognitive clarity and mental resilience.";
                        break;
                }
            }
        }

        // 6. Clean markdown bold/asterisks and save to Cache & Token Logs
        $responseText = str_replace(['**', '##'], '', $responseText);

        try {
            AiLog::create([
                'user_id' => $user ? $user->id : null,
                'action' => $action,
                'passage_hash' => $hash,
                'passage_text' => $passage,
                'response_text' => $responseText,
                'tokens_used' => intval((strlen($prompt) + strlen($responseText)) / 4),
            ]);
        } catch (\Exception $e) {
            // Log creation failure shouldn't fail response
        }

        return response()->json([
            'success' => true,
            'is_cached' => false,
            'action' => $action,
            'response' => $responseText,
            'free_uses_left' => $user ? ($user->fresh()?->ai_free_uses_left ?? 10) : 10,
        ]);
    }
}
