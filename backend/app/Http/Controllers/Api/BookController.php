<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Book;
use App\Models\BookParagraph;
use App\Models\ReadingProgress;
use App\Models\Collection;

class BookController extends Controller
{
    // Spec 1 & 7: Library Listing with Category and Collection Filtering
    public function index(Request $request)
    {
        $category = $request->query('category');
        $collectionTag = $request->query('collection');
        $search = $request->query('search');

        // Official Admin Curated Catalog ONLY (is_public == true and user_id IS NULL)
        // User private/imported documents belong exclusively to the user and never appear in public catalog/featured reads
        $query = Book::with(['collection', 'paragraphs'])
            ->where('is_public', true)
            ->whereNull('user_id');

        if ($category && strtolower($category) !== 'all') {
            $query->where('category', $category);
        }

        if ($collectionTag) {
            $collection = Collection::where('tag', $collectionTag)->first();
            if ($collection) {
                $query->where('collection_id', $collection->id);
            }
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('author', 'like', "%{$search}%");
            });
        }

        $books = $query->latest()->get();

        return response()->json([
            'success' => true,
            'books' => $books,
        ]);
    }

    // Public Categories from Database (Admin Created)
    public function categories()
    {
        $categories = \App\Models\Category::withCount('books')->orderBy('sort_order')->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'categories' => $categories,
        ]);
    }

    // Spec 6: "See All" & Continue Reading Shelf (Netflix-style recent grid)
    public function continueReading(Request $request)
    {
        $user = $request->user();

        $progressItems = ReadingProgress::with('book.paragraphs')
            ->where('user_id', $user->id)
            ->orderBy('last_read_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'items' => $progressItems,
        ]);
    }

    // Book Detail / Reader Load
    public function show($id, Request $request)
    {
        $book = Book::with(['paragraphs', 'collection'])->findOrFail($id);

        $progress = null;
        if ($request->user('sanctum')) {
            $progress = ReadingProgress::where('user_id', $request->user('sanctum')->id)
                ->where('book_id', $book->id)
                ->first();
        }

        return response()->json([
            'success' => true,
            'book' => $book,
            'progress' => $progress,
        ]);
    }

    // Spec 2, 3, 5 & 11: Import / "Save from Web" or "From Another App"
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'author' => 'nullable|string|max:255',
            'category' => 'nullable|string',
            'cover_color' => 'nullable|string',
            'source_url' => 'nullable|url',
            'source_type' => 'nullable|string', // web, article, pdf, epub
            'collection_id' => 'nullable|exists:collections,id', // Spec 3: Uncategorized by default (null)
            'paragraphs' => 'required|array|min:1',
            'paragraphs.*' => 'required|string',
        ]);

        $user = $request->user();

        $book = Book::where('user_id', $user->id)
            ->where('title', $validated['title'])
            ->first();

        if (!$book) {
            $book = Book::create([
                'user_id' => $user->id,
                'collection_id' => $validated['collection_id'] ?? null,
                'title' => $validated['title'],
                'author' => $validated['author'] ?? 'Personal Document',
                'category' => $validated['category'] ?? 'General',
                'cover_color' => $validated['cover_color'] ?? 'forest',
                'source_url' => $validated['source_url'] ?? null,
                'source_type' => $validated['source_type'] ?? 'web',
                'read_time' => ceil(count($validated['paragraphs']) * 0.8) . ' min read',
                'is_public' => false,
            ]);

            foreach ($validated['paragraphs'] as $index => $paragraphText) {
                BookParagraph::create([
                    'book_id' => $book->id,
                    'paragraph_index' => $index,
                    'content' => $paragraphText,
                ]);
            }

            // Initialize progress
            ReadingProgress::firstOrCreate(
                ['user_id' => $user->id, 'book_id' => $book->id],
                [
                    'current_paragraph' => 0,
                    'progress_percent' => 0.00,
                    'last_read_at' => now(),
                ]
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Book/Article saved to library successfully',
            'book' => $book->load('paragraphs'),
        ], 201);
    }

    // Delete user's own document from cloud library
    public function destroyUserDocument(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
        ]);

        $user = $request->user();
        $book = Book::where('user_id', $user->id)
            ->where('title', $validated['title'])
            ->first();

        if ($book) {
            $book->paragraphs()->delete();
            $book->delete();
            return response()->json(['success' => true, 'message' => 'Document deleted from cloud library']);
        }

        return response()->json(['success' => true, 'message' => 'Document already removed']);
    }

    // Update Reading Progress
    public function updateProgress(Request $request, $id)
    {
        $validated = $request->validate([
            'current_paragraph' => 'required|integer|min:0',
            'progress_percent' => 'required|numeric|between:0,100',
            'is_favorite' => 'sometimes|boolean',
            'is_bookmarked' => 'sometimes|boolean',
        ]);

        $user = $request->user();

        $progress = ReadingProgress::updateOrCreate(
            ['user_id' => $user->id, 'book_id' => $id],
            array_merge($validated, ['last_read_at' => now()])
        );

        return response()->json([
            'success' => true,
            'progress' => $progress,
        ]);
    }
}
