<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Collection;
use App\Models\CollectionBook;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CollectionController extends Controller
{
    // List Collections: Strictly Authenticated User's custom shelves (Isolated per user)
    public function index(Request $request)
    {
        $userId = $request->user('sanctum')?->id;

        if (!$userId) {
            return response()->json([
                'success' => true,
                'collections' => [],
            ]);
        }

        $collections = Collection::withCount('books')
            ->where('user_id', $userId)
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'collections' => $collections,
        ]);
    }

    // Create New Custom Collection for Authenticated User
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'color_hex' => 'nullable|string|max:20',
        ]);

        $user = $request->user('sanctum');
        if ($user && !$user->hasFeature('custom_shelves')) {
            return response()->json([
                'success' => false,
                'message' => 'Custom Collections & Shelves feature is not included in your current plan. Please upgrade to access this feature.',
            ], 403);
        }

        $userId = $user?->id;
        $name = trim($validated['name']);
        $tag = Str::slug($name);

        if (empty($tag)) {
            $tag = 'shelf-' . time();
        }

        // If duplicate tag exists for this user, append a unique suffix
        $existing = Collection::where('user_id', $userId)->where('tag', $tag)->first();
        if ($existing) {
            $tag .= '-' . rand(10, 99);
        }

        $collection = Collection::create([
            'user_id' => $userId,
            'name' => $name,
            'tag' => $tag,
            'color_hex' => $validated['color_hex'] ?? '#4B6B4A',
        ]);

        $collection->loadCount('books');

        return response()->json([
            'success' => true,
            'collection' => $collection,
            'message' => 'Collection created successfully',
        ], 201);
    }

    // Delete Custom Collection
    public function destroy(Request $request, $id)
    {
        $userId = $request->user('sanctum')?->id;
        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        $collection = Collection::where('user_id', $userId)->findOrFail($id);
        $tag = $collection->tag;
        $collection->delete();

        // Also clean up any assigned books for this collection tag for this user
        CollectionBook::where('user_id', $userId)
            ->where('collection_tag', $tag)
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Collection deleted successfully',
        ]);
    }

    // Assign or Remove a Book to/from a User's Collection
    public function assignBook(Request $request)
    {
        $validated = $request->validate([
            'book_title' => 'required|string|max:255',
            'book_id' => 'nullable|integer',
            'collection_tag' => 'nullable|string|max:100',
        ]);

        $user = $request->user();
        if ($user && !$user->hasFeature('custom_shelves')) {
            return response()->json([
                'success' => false,
                'message' => 'Custom Collections & Shelves feature is not included in your current plan. Please upgrade to access this feature.',
            ], 403);
        }

        $bookTitle = trim($validated['book_title']);
        $bookId = $validated['book_id'] ?? null;
        $collectionTag = !empty($validated['collection_tag']) ? trim($validated['collection_tag']) : null;

        if (empty($collectionTag) || strtolower($collectionTag) === 'all' || strtolower($collectionTag) === 'general') {
            // Remove assignment
            CollectionBook::where('user_id', $user->id)
                ->whereRaw('LOWER(TRIM(book_title)) = ?', [strtolower($bookTitle)])
                ->delete();

            return response()->json([
                'success' => true,
                'message' => 'Book removed from custom collection',
            ]);
        }

        // Find collection by tag strictly for this user
        $collection = Collection::where('user_id', $user->id)
            ->where('tag', $collectionTag)
            ->first();

        // Update or create assignment
        $assignment = CollectionBook::updateOrCreate(
            [
                'user_id' => $user->id,
                'book_title' => $bookTitle,
            ],
            [
                'book_id' => $bookId,
                'collection_id' => $collection?->id,
                'collection_tag' => $collectionTag,
            ]
        );

        return response()->json([
            'success' => true,
            'assignment' => $assignment,
            'message' => 'Book assigned to collection successfully',
        ]);
    }
}
