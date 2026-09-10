<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Backup;
use App\Models\Book;
use App\Models\Highlight;
use App\Models\ReadingProgress;
use App\Models\Vocabulary;
use Illuminate\Support\Facades\DB;

class BackupController extends Controller
{
    // List user backups
    public function index(Request $request)
    {
        $backups = Backup::where('user_id', $request->user()->id)
            ->latest()
            ->select(['id', 'title', 'item_count', 'created_at'])
            ->get();

        return response()->json([
            'success' => true,
            'backups' => $backups,
        ]);
    }

    // Spec 15 & 16: "Back up now" (Create cloud snapshot restore point)
    public function store(Request $request)
    {
        $user = $request->user();

        // 1. Gather all server DB records
        $books = Book::with('paragraphs')->where('user_id', $user->id)->get();
        $highlights = Highlight::where('user_id', $user->id)->get();
        $progress = ReadingProgress::where('user_id', $user->id)->get();
        $vocab = Vocabulary::where('user_id', $user->id)->get();
        $collections = \App\Models\Collection::where('user_id', $user->id)->get();

        // 2. Accept client-side local documents, custom shelves, reading progress, and downloaded books
        $clientLocalBooks = $request->input('local_books', []);
        $clientContinueShelf = $request->input('continue_shelf', []);
        $clientCollections = $request->input('collections', []);
        $clientVocabWords = $request->input('vocab_words', []);
        $clientHighlights = $request->input('highlights', []);
        $clientBookCollections = $request->input('book_collections', []);
        $clientDownloadedBooks = $request->input('downloaded_books', []);

        $snapshot = [
            'books' => $books,
            'highlights' => !empty($clientHighlights) ? $clientHighlights : $highlights,
            'progress' => $progress,
            'vocabulary' => $vocab,
            'collections' => !empty($clientCollections) ? $clientCollections : $collections,
            'local_books' => $clientLocalBooks,
            'continue_shelf' => $clientContinueShelf,
            'vocab_words' => $clientVocabWords,
            'book_collections' => $clientBookCollections,
            'downloaded_books' => $clientDownloadedBooks,
            'created_at' => now()->toIso8601String(),
        ];

        $itemCount = count($clientLocalBooks) + count($clientContinueShelf) + count($clientVocabWords) + count($clientHighlights) + count($clientDownloadedBooks) + $books->count() + $vocab->count();
        if ($itemCount === 0) {
            $itemCount = max(1, count($clientLocalBooks) + $books->count() + $vocab->count());
        }

        // Auto-prune: Keep maximum 10 latest snapshots per user to prevent bloat
        $oldBackupIds = Backup::where('user_id', $user->id)
            ->latest()
            ->skip(9)
            ->take(50)
            ->pluck('id');
        if ($oldBackupIds->isNotEmpty()) {
            Backup::whereIn('id', $oldBackupIds)->delete();
        }

        $clientTitle = $request->input('title');
        $title = !empty($clientTitle) ? $clientTitle : 'Cloud Backup (' . now()->format('d M Y, h:i A') . ')';

        $backup = Backup::create([
            'user_id' => $user->id,
            'title' => $title,
            'snapshot_data' => $snapshot,
            'item_count' => $itemCount,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Cloud backup created successfully',
            'backup' => [
                'id' => $backup->id,
                'title' => $backup->title,
                'item_count' => $backup->item_count,
                'created_at' => $backup->created_at->toIso8601String(),
            ],
        ], 201);
    }

    // Spec 17: "Restore from backup" (Rollback state to snapshot point)
    public function restore($id, Request $request)
    {
        $user = $request->user();
        $backup = Backup::where('user_id', $user->id)->findOrFail($id);

        $data = $backup->snapshot_data;

        DB::transaction(function () use ($user, $data) {
            // Rollback Highlights in DB
            if (isset($data['highlights']) && is_array($data['highlights'])) {
                Highlight::where('user_id', $user->id)->delete();
                foreach ($data['highlights'] as $h) {
                    if (isset($h['paragraph_index'], $h['color'])) {
                        Highlight::create([
                            'user_id' => $user->id,
                            'book_id' => $h['book_id'] ?? null,
                            'book_title' => $h['book_title'] ?? null,
                            'paragraph_index' => $h['paragraph_index'],
                            'color' => $h['color'],
                            'note' => $h['note'] ?? null,
                        ]);
                    }
                }
            }

            // Rollback Vocabulary in DB
            if (isset($data['vocabulary']) && is_array($data['vocabulary'])) {
                Vocabulary::where('user_id', $user->id)->delete();
                foreach ($data['vocabulary'] as $v) {
                    if (isset($v['word'], $v['meaning'])) {
                        Vocabulary::create([
                            'user_id' => $user->id,
                            'word' => $v['word'],
                            'pos' => $v['pos'] ?? 'noun',
                            'meaning' => $v['meaning'],
                            'example' => $v['example'] ?? null,
                            'synonyms' => $v['synonyms'] ?? [],
                            'origin' => $v['origin'] ?? null,
                            'source_title' => $v['source_title'] ?? null,
                            'is_mastered' => $v['is_mastered'] ?? false,
                        ]);
                    }
                }
            }

            // Rollback Reading Progress in DB
            if (isset($data['progress']) && is_array($data['progress'])) {
                ReadingProgress::where('user_id', $user->id)->delete();
                foreach ($data['progress'] as $p) {
                    ReadingProgress::create([
                        'user_id' => $user->id,
                        'book_id' => $p['book_id'] ?? null,
                        'book_title' => $p['book_title'] ?? null,
                        'current_paragraph' => $p['current_paragraph'] ?? 0,
                        'progress_percent' => $p['progress_percent'] ?? 0,
                        'is_removed' => $p['is_removed'] ?? false,
                        'last_read_at' => $p['last_read_at'] ?? now(),
                    ]);
                }
            }

            // Rollback Collection Books in DB
            if (isset($data['book_collections']) && is_array($data['book_collections'])) {
                \App\Models\CollectionBook::where('user_id', $user->id)->delete();
                foreach ($data['book_collections'] as $title => $tag) {
                    if (!empty($title) && !empty($tag)) {
                        \App\Models\CollectionBook::create([
                            'user_id' => $user->id,
                            'book_title' => $title,
                            'collection_tag' => $tag,
                        ]);
                    }
                }
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Library, documents, highlights, and vocabulary restored successfully.',
            'snapshot' => $data,
        ]);
    }
}
