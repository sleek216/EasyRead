<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Highlight;
use App\Models\ReadingProgress;
use App\Models\Vocabulary;
use App\Models\CollectionBook;
use App\Models\DownloadedBook;
use App\Models\Book;
use Carbon\Carbon;

class SyncController extends Controller
{
    // Pull changes from cloud since last timestamp
    public function pull(Request $request)
    {
        $user = $request->user();
        $since = $request->query('since'); // ISO string or timestamp

        $highlightsQuery = Highlight::where('user_id', $user->id);
        $progressQuery = ReadingProgress::with('book')->where('user_id', $user->id);
        $vocabQuery = Vocabulary::where('user_id', $user->id);
        $downloadsQuery = DownloadedBook::where('user_id', $user->id);
        $userBooksQuery = Book::with('paragraphs')->where('user_id', $user->id);

        if ($since) {
            $highlightsQuery->where('updated_at', '>', $since);
            $progressQuery->where('updated_at', '>', $since);
            $vocabQuery->where('updated_at', '>', $since);
            $downloadsQuery->where('updated_at', '>', $since);
            $userBooksQuery->where('updated_at', '>', $since);
        }

        return response()->json([
            'success' => true,
            'timestamp' => now()->toIso8601String(),
            'highlights' => $highlightsQuery->get(),
            'progress' => $progressQuery->get()->map(function ($p) {
                $item = $p->toArray();
                $item['is_reset'] = ((float)$p->progress_percent == 0 && (int)$p->current_paragraph == 0);
                $item['is_removed'] = (bool)($p->is_removed ?? false);
                return $item;
            }),
            'vocabulary' => $vocabQuery->get(),
            'collection_books' => CollectionBook::where('user_id', $user->id)->get(),
            'downloaded_books' => $downloadsQuery->get(),
            'user_books' => $userBooksQuery->get(),
        ]);
    }

    // Push local mobile highlights & notes to cloud
    public function pushHighlights(Request $request)
    {
        $validated = $request->validate([
            'highlights' => 'required|array',
            'highlights.*.book_id' => 'nullable|integer',
            'highlights.*.book_title' => 'nullable|string|max:255',
            'highlights.*.paragraph_index' => 'required|integer',
            'highlights.*.color' => 'required|string',
            'highlights.*.note' => 'nullable|string',
        ]);

        $user = $request->user();

        foreach ($validated['highlights'] as $item) {
            $bookId = $item['book_id'] ?? null;
            $bookTitle = !empty($item['book_title']) ? trim($item['book_title']) : null;
            $pIdx = (int)$item['paragraph_index'];

            $query = Highlight::where('user_id', $user->id)
                ->where('paragraph_index', $pIdx);

            if ($bookId) {
                $query->where('book_id', $bookId);
            } elseif ($bookTitle) {
                $query->where('book_title', $bookTitle);
            }

            $existing = $query->first();

            if ($existing) {
                $existing->update([
                    'color' => $item['color'],
                    'note' => $item['note'] ?? null,
                    'book_title' => $bookTitle ?? $existing->book_title,
                ]);
            } else {
                Highlight::create([
                    'user_id' => $user->id,
                    'book_id' => $bookId,
                    'book_title' => $bookTitle,
                    'paragraph_index' => $pIdx,
                    'color' => $item['color'],
                    'note' => $item['note'] ?? null,
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Highlights synchronized successfully',
        ]);
    }

    // Delete highlight from cloud when cleared by user
    public function deleteHighlight(Request $request)
    {
        $validated = $request->validate([
            'book_title' => 'nullable|string|max:255',
            'book_id' => 'nullable|integer',
            'paragraph_index' => 'required|integer',
        ]);

        $user = $request->user();
        $bookTitle = !empty($validated['book_title']) ? trim($validated['book_title']) : null;
        $bookId = $validated['book_id'] ?? null;
        $pIdx = (int)$validated['paragraph_index'];

        $query = Highlight::where('user_id', $user->id)
            ->where('paragraph_index', $pIdx);

        if ($bookId) {
            $query->where('book_id', $bookId);
        } elseif ($bookTitle) {
            $query->where('book_title', $bookTitle);
        }

        $query->delete();

        return response()->json([
            'success' => true,
            'message' => 'Highlight removed successfully',
        ]);
    }

    // Push local mobile reading progress to cloud
    public function pushProgress(Request $request)
    {
        $validated = $request->validate([
            'book_title' => 'required|string|max:255',
            'book_id' => 'nullable|integer',
            'progress_percent' => 'required|numeric|min:0|max:100',
            'current_paragraph' => 'nullable|integer',
            'is_reset' => 'nullable|boolean',
            'last_read_at' => 'nullable|string',
        ]);

        $user = $request->user();
        $bookTitle = trim($validated['book_title']);
        $bookId = $validated['book_id'] ?? null;
        $progressPercent = (float)$validated['progress_percent'];
        $currentPara = $validated['current_paragraph'] ?? 0;
        $isReset = $request->boolean('is_reset') || $progressPercent == 0;

        // Parse client UTC timestamp or fallback to current UTC time
        $clientTime = !empty($validated['last_read_at'])
            ? \Carbon\Carbon::parse($validated['last_read_at'])->utc()
            : now()->utc();

        $record = ReadingProgress::where('user_id', $user->id)
            ->where(function ($q) use ($bookTitle, $bookId) {
                if ($bookId) {
                    $q->where('book_id', $bookId);
                } else {
                    $q->whereRaw('LOWER(TRIM(book_title)) = ?', [strtolower($bookTitle)]);
                }
            })->first();

        if ($record) {
            $recordTime = $record->last_read_at ? $record->last_read_at->utc() : $record->updated_at->utc();

            // If the book was previously removed on any device:
            // Only un-remove if clientTime is strictly newer than deletion time (user read it again)
            if ($record->is_removed) {
                if (!$isReset && $clientTime->gt($recordTime->addSeconds(1))) {
                    $record->is_removed = false;
                    $record->progress_percent = $progressPercent;
                    $record->current_paragraph = $currentPara;
                    $record->last_read_at = $clientTime;
                    if ($bookTitle && empty($record->book_title)) {
                        $record->book_title = $bookTitle;
                    }
                    $record->save();
                } else {
                    // Stale push from a 2nd device that still had the old book cached before deletion!
                    // Reject stale progress and keep book removed!
                    return response()->json([
                        'success' => true,
                        'is_removed' => true,
                        'message' => 'Book was previously removed from shelf',
                        'progress_percent' => 0,
                        'last_read_at' => $recordTime->toIso8601String(),
                    ]);
                }
            } else {
                // Last-Write-Wins: accept client update if client time >= server time (2s leeway for network latency/drift)
                // Or if explicit isReset was triggered by user
                if ($isReset || $clientTime->gte($recordTime->subSeconds(2))) {
                    $record->progress_percent = $isReset ? 0 : $progressPercent;
                    $record->current_paragraph = $isReset ? 0 : $currentPara;
                    $record->last_read_at = $clientTime;
                    if ($bookTitle && empty($record->book_title)) {
                        $record->book_title = $bookTitle;
                    }
                    $record->save();
                }
            }
        } else {
            $record = ReadingProgress::create([
                'user_id' => $user->id,
                'book_id' => $bookId,
                'book_title' => $bookTitle,
                'current_paragraph' => $isReset ? 0 : $currentPara,
                'progress_percent' => $isReset ? 0 : $progressPercent,
                'is_removed' => false,
                'last_read_at' => $clientTime,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => $isReset ? 'Progress reset to 0%' : 'Reading progress saved',
            'progress_percent' => $record ? $record->progress_percent : ($isReset ? 0 : $progressPercent),
            'last_read_at' => $record && $record->last_read_at ? $record->last_read_at->toIso8601String() : $clientTime->toIso8601String(),
        ]);
    }

    // Remove reading progress from cloud when book is removed from shelf
    public function removeProgress(Request $request)
    {
        $validated = $request->validate([
            'book_title' => 'required|string|max:255',
            'book_id' => 'nullable|integer',
            'removed_at' => 'nullable|string',
        ]);

        $user = $request->user();
        $bookTitle = trim($validated['book_title']);
        $bookId = $validated['book_id'] ?? null;
        $clientTime = !empty($validated['removed_at'])
            ? \Carbon\Carbon::parse($validated['removed_at'])->utc()
            : now()->utc();

        $record = ReadingProgress::where('user_id', $user->id)
            ->where(function ($q) use ($bookTitle, $bookId) {
                if ($bookId) {
                    $q->where('book_id', $bookId);
                } else {
                    $q->whereRaw('LOWER(TRIM(book_title)) = ?', [strtolower($bookTitle)]);
                }
            })->first();

        if ($record) {
            $record->is_removed = true;
            $record->progress_percent = 0;
            $record->current_paragraph = 0;
            $record->last_read_at = $clientTime;
            $record->save();
        } else {
            // Create a tombstone record so stale pushes from other devices are rejected
            ReadingProgress::create([
                'user_id' => $user->id,
                'book_id' => $bookId,
                'book_title' => $bookTitle,
                'current_paragraph' => 0,
                'progress_percent' => 0,
                'is_removed' => true,
                'last_read_at' => $clientTime,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Book removed from shelf successfully',
            'removed_at' => $clientTime->toIso8601String(),
        ]);
    }

    // Push local offline downloads to cloud
    public function pushDownloads(Request $request)
    {
        $validated = $request->validate([
            'downloads' => 'required|array',
            'downloads.*.book_title' => 'required|string|max:255',
            'downloads.*.book_id' => 'nullable|integer',
            'downloads.*.book_json' => 'nullable|array',
            'downloads.*.is_removed' => 'nullable|boolean',
            'downloads.*.downloaded_at' => 'nullable|string',
        ]);

        $user = $request->user();
        $synced = [];

        foreach ($validated['downloads'] as $item) {
            $bookTitle = trim($item['book_title']);
            $isRemoved = (bool)($item['is_removed'] ?? false);
            $bookJson = $item['book_json'] ?? null;
            $bookId = $item['book_id'] ?? null;
            $dAt = !empty($item['downloaded_at']) ? Carbon::parse($item['downloaded_at']) : now();

            $record = DownloadedBook::updateOrCreate(
                ['user_id' => $user->id, 'book_title' => $bookTitle],
                [
                    'book_id' => $bookId,
                    'book_json' => $bookJson,
                    'is_removed' => $isRemoved,
                    'downloaded_at' => $dAt,
                ]
            );
            $synced[] = $record;
        }

        return response()->json([
            'success' => true,
            'synced_count' => count($synced),
            'downloaded_books' => $synced,
        ]);
    }

    // Remove an offline download
    public function removeDownload(Request $request)
    {
        $request->validate(['book_title' => 'required|string']);
        $title = trim($request->book_title);
        $user = $request->user();

        DownloadedBook::updateOrCreate(
            ['user_id' => $user->id, 'book_title' => $title],
            [
                'is_removed' => true,
                'downloaded_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Download marked as removed successfully',
        ]);
    }
}
