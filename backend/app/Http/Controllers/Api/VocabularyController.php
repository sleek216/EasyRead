<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Vocabulary;

class VocabularyController extends Controller
{
    // Spec 12: List all personal saved vocabulary
    public function index(Request $request)
    {
        $user = $request->user();

        $words = Vocabulary::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'vocabulary' => $words,
            'total_words' => $words->count(),
            'mastered_count' => $words->where('is_mastered', true)->count(),
        ]);
    }

    // Save word from reader dictionary popup
    public function store(Request $request)
    {
        $validated = $request->validate([
            'word' => 'required|string|max:100',
            'pos' => 'nullable|string|max:50',
            'meaning' => 'required|string',
            'example' => 'nullable|string',
            'synonyms' => 'nullable|array',
            'origin' => 'nullable|string',
            'source_title' => 'nullable|string',
        ]);

        $user = $request->user();

        // Enforce 30 words free tier check if not premium
        if (!$user->is_premium) {
            $existingCount = Vocabulary::where('user_id', $user->id)->count();
            if ($existingCount >= 30) {
                return response()->json([
                    'success' => false,
                    'is_paywall' => true,
                    'message' => 'You have reached the free 30-word limit. Upgrade to EasyRead Plus for unlimited vocabulary.',
                ], 403);
            }
        }

        $vocab = Vocabulary::updateOrCreate(
            ['user_id' => $user->id, 'word' => strtolower(trim($validated['word']))],
            array_merge($validated, ['word' => strtolower(trim($validated['word']))])
        );

        return response()->json([
            'success' => true,
            'message' => 'Word saved to your vocabulary bank',
            'item' => $vocab,
        ], 201);
    }

    // Flashcard Quiz Review Score (Know vs Still Learning)
    public function recordReview(Request $request, $id)
    {
        $validated = $request->validate([
            'is_mastered' => 'required|boolean',
        ]);

        $user = $request->user();
        $word = strtolower(trim(urldecode((string)$id)));
        $query = Vocabulary::where('user_id', $user->id);
        $vocab = is_numeric($id) ? $query->find($id) : $query->where('word', $word)->first();

        if ($vocab) {
            $vocab->increment('review_count');
            $vocab->update(['is_mastered' => $validated['is_mastered']]);
        } else {
            $vocab = Vocabulary::create([
                'user_id' => $user->id,
                'word' => $word,
                'meaning' => $request->input('meaning', 'Word marked as learned'),
                'is_mastered' => $validated['is_mastered'],
                'review_count' => 1,
            ]);
        }

        return response()->json([
            'success' => true,
            'item' => $vocab,
        ]);
    }

    public function destroy($id, Request $request)
    {
        $user = $request->user();
        $query = Vocabulary::where('user_id', $user->id);
        if (is_numeric($id)) {
            $query->where('id', $id)->delete();
        } else {
            $query->where('word', strtolower(trim($id)))->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Word removed from vocabulary bank',
        ]);
    }
}
