<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Book;
use App\Models\BookParagraph;
use App\Models\Collection;
use App\Models\Category;

class AdminBookController extends Controller
{
    public function index(Request $request)
    {
        $search = trim($request->query('search', ''));
        $categoryFilter = $request->query('category', 'all');
        $statusFilter = $request->query('status', 'all');
        $featuredFilter = $request->query('featured', 'all');
        $sort = $request->query('sort', 'latest');

        $query = Book::with(['collection', 'paragraphs'])->whereNull('user_id');

        if ($statusFilter === 'published') {
            $query->where('is_public', true);
        } elseif ($statusFilter === 'unpublished') {
            $query->where('is_public', false);
        }


        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('author', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($categoryFilter !== 'all') {
            $query->where('category', $categoryFilter);
        }

        $hasFeaturedCol = \Illuminate\Support\Facades\Schema::hasColumn('books', 'is_featured');

        if ($hasFeaturedCol) {
            if ($featuredFilter === '1') {
                $query->where('is_featured', true);
            } elseif ($featuredFilter === '0') {
                $query->where('is_featured', false);
            }
        }

        switch ($sort) {
            case 'oldest':
                $query->oldest();
                break;
            case 'title_asc':
                $query->orderBy('title', 'asc');
                break;
            case 'most_paragraphs':
                $query->withCount('paragraphs')->orderBy('paragraphs_count', 'desc');
                break;
            case 'latest':
            default:
                $query->latest();
                break;
        }

        $books = $query->paginate(15)->appends($request->query());

        // KPI Counts (Curated Official Books only)
        $totalBooksCount = Book::whereNull('user_id')->count();
        $publishedBooksCount = Book::whereNull('user_id')->where('is_public', true)->count();
        $unpublishedBooksCount = Book::whereNull('user_id')->where('is_public', false)->count();
        $featuredBooksCount = $hasFeaturedCol
            ? Book::whereNull('user_id')->where('is_featured', true)->count()
            : 0;
        $totalCategoriesCount = Category::count();
        $totalParagraphsCount = BookParagraph::whereHas('book', function($q) {
            $q->whereNull('user_id');
        })->count();

        $categoriesList = Category::orderBy('name')->pluck('name')->toArray();

        return view('admin.books.index', compact(
            'books',
            'search',
            'categoryFilter',
            'statusFilter',
            'featuredFilter',
            'sort',
            'totalBooksCount',
            'publishedBooksCount',
            'unpublishedBooksCount',
            'featuredBooksCount',
            'totalCategoriesCount',
            'totalParagraphsCount',
            'categoriesList'
        ));
    }

    public function togglePublish($id)
    {
        $book = Book::findOrFail($id);
        $book->is_public = !$book->is_public;
        $book->save();

        $statusMessage = $book->is_public
            ? 'Book "' . $book->title . '" published successfully to mobile app library.'
            : 'Book "' . $book->title . '" unpublished (hidden from mobile app, saved as draft).';

        return back()->with('success', $statusMessage);
    }

    public function create()
    {
        $categories = Category::orderBy('sort_order')->orderBy('name')->get();
        $collections = Collection::whereNull('user_id')->orderBy('name')->get();
        return view('admin.books.create', compact('categories', 'collections'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'author' => 'nullable|string|max:255',
            'category' => 'required|string|max:100',
            'cover_color' => 'required|string|max:50',
            'collection_id' => 'nullable|exists:collections,id',
            'input_source' => 'required|string|in:text,pdf,url',
            'content_text' => 'nullable|required_if:input_source,text|string',
            'pdf_file' => 'nullable|required_if:input_source,pdf|file|mimes:pdf|max:25600',
            'source_url' => 'nullable|required_if:input_source,url|url',
        ]);

        $source = $validated['input_source'];
        $extractedData = [];

        if (!empty($validated['content_text']) && mb_strlen(trim($validated['content_text'])) > 30) {
            $extractedData = $this->extractFromText($validated['content_text']);
        } elseif ($source === 'pdf' && $request->hasFile('pdf_file')) {
            $extractedData = $this->extractFromPdf($request->file('pdf_file'));
        } elseif ($source === 'url' && !empty($validated['source_url'])) {
            $extractedData = $this->extractFromUrl($validated['source_url']);
        } else {
            $extractedData = $this->extractFromText($validated['content_text'] ?? '');
        }

        $paragraphs = $extractedData['paragraphs'] ?? [];
        if (empty($paragraphs)) {
            return back()->withInput()->withErrors(['content_text' => 'Could not extract readable text paragraphs from the provided source.']);
        }

        $finalTitle = !empty($validated['title']) ? trim($validated['title']) : ($extractedData['title'] ?? 'Untitled Book');
        $finalAuthor = !empty($validated['author']) ? trim($validated['author']) : ($extractedData['author'] ?? 'Unknown Author');

        $totalWords = 0;
        foreach ($paragraphs as $p) {
            $totalWords += str_word_count(strip_tags($p));
        }
        $wpm = (int) \App\Models\Setting::get('reading_speed_wpm', 200);
        if ($wpm < 30) $wpm = 200;
        $estimatedMinutes = max(1, (int) ceil($totalWords / $wpm));

        $book = Book::create([
            'title' => $this->sanitizeUtf8($finalTitle),
            'author' => $this->sanitizeUtf8($finalAuthor),
            'category' => $validated['category'],
            'cover_color' => $validated['cover_color'],
            'collection_id' => $validated['collection_id'] ?? null,
            'source_url' => $validated['source_url'] ?? null,
            'source_type' => $source,
            'read_time' => $estimatedMinutes . ' min read',
            'is_public' => true,
        ]);

        foreach ($paragraphs as $index => $paragraph) {
            $cleanPara = $this->sanitizeUtf8($paragraph);
            if (!empty($cleanPara)) {
                BookParagraph::create([
                    'book_id' => $book->id,
                    'paragraph_index' => $index,
                    'content' => $cleanPara,
                ]);
            }
        }

        // Broadcast New Book Notification to all mobile users
        \App\Services\NotificationService::broadcastNewBook($book);

        return redirect()->route('admin.books.index')->with('success', 'Book "' . $finalTitle . '" extracted, published, and notified to users successfully with ' . count($paragraphs) . ' paragraphs.');
    }

    public function edit($id)
    {
        $book = Book::with('paragraphs')->findOrFail($id);
        $categories = Category::orderBy('sort_order')->orderBy('name')->get();
        $collections = Collection::whereNull('user_id')->orderBy('name')->get();

        $contentText = $book->paragraphs->pluck('content')->implode("\n\n");

        return view('admin.books.edit', compact('book', 'categories', 'collections', 'contentText'));
    }

    public function update(Request $request, $id)
    {
        $book = Book::findOrFail($id);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'author' => 'required|string|max:255',
            'category' => 'required|string|max:100',
            'cover_color' => 'required|string|max:50',
            'collection_id' => 'nullable|exists:collections,id',
            'content_text' => 'required|string',
        ]);

        $book->update([
            'title' => $validated['title'],
            'author' => $validated['author'],
            'category' => $validated['category'],
            'cover_color' => $validated['cover_color'],
            'collection_id' => $validated['collection_id'] ?? null,
        ]);

        // Refresh paragraphs
        $paragraphs = array_filter(
            array_map('trim', preg_split('/\R{2,}/', $validated['content_text']))
        );

        $book->paragraphs()->delete();
        foreach ($paragraphs as $index => $paragraph) {
            BookParagraph::create([
                'book_id' => $book->id,
                'paragraph_index' => $index,
                'content' => $paragraph,
            ]);
        }

        $totalWords = 0;
        foreach ($paragraphs as $p) {
            $totalWords += str_word_count(strip_tags($p));
        }
        $wpm = (int) \App\Models\Setting::get('reading_speed_wpm', 200);
        if ($wpm < 30) $wpm = 200;
        $estimatedMinutes = max(1, (int) ceil($totalWords / $wpm));

        $book->update(['read_time' => $estimatedMinutes . ' min read']);

        return redirect()->route('admin.books.index')->with('success', 'Book updated successfully.');
    }

    public function show($id)
    {
        $book = Book::with(['collection', 'paragraphs'])->findOrFail($id);
        $paragraphsArray = $book->paragraphs->pluck('content')->toArray();
        $totalWordsCount = array_sum(array_map('str_word_count', $paragraphsArray));

        return view('admin.books.show', compact('book', 'totalWordsCount'));
    }

    public function destroy($id)
    {
        $book = Book::findOrFail($id);
        $book->delete();

        return redirect()->route('admin.books.index')->with('success', 'Book removed successfully.');
    }

    public function extractPreview(Request $request)
    {
        $source = $request->input('input_source', 'text');
        $extracted = [];

        if ($source === 'pdf' && $request->hasFile('pdf_file')) {
            $extracted = $this->extractFromPdf($request->file('pdf_file'));
        } elseif ($source === 'url' && $request->filled('source_url')) {
            $extracted = $this->extractFromUrl($request->input('source_url'));
        } else {
            $extracted = $this->extractFromText($request->input('content_text', ''));
        }

        $paras = $extracted['paragraphs'] ?? [];
        $totalWords = array_sum(array_map('str_word_count', $paras));

        return response()->json([
            'success' => !empty($paras),
            'title' => $extracted['title'] ?? '',
            'paragraphs' => $paras,
            'paragraph_count' => count($paras),
            'word_count' => $totalWords,
            'read_time' => ceil(count($paras) * 1.2) . ' min read',
        ]);
    }

    // ─── PURE TEXT EXTRACTION HELPERS (No images, No SVGs, No HTML links) ─────

    private function extractFromUrl(string $url): array
    {
        try {
            $response = \Illuminate\Support\Facades\Http::withoutVerifying()
                ->timeout(15)
                ->withHeaders([
                    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                ])
                ->get($url);

            if (!$response->successful()) {
                throw new \Exception("HTTP status " . $response->status());
            }

            $html = $response->body();
            if (empty($html)) {
                throw new \Exception("Empty response body.");
            }

            $dom = new \DOMDocument();
            @$dom->loadHTML(mb_convert_encoding($html, 'HTML-ENTITIES', 'UTF-8'), LIBXML_NOERROR | LIBXML_NOWARNING);
            $xpath = new \DOMXPath($dom);

            // Extract page title
            $titleNodes = $xpath->query('//title');
            $title = $titleNodes->length > 0 ? trim($titleNodes->item(0)->textContent) : 'Web Article';
            $title = preg_replace('/\s*[\|-].*$/', '', $title);

            // Strip ALL images, SVG, script, style, nav, headers, footers, forms
            $unwantedNodes = $xpath->query('//script | //style | //img | //svg | //iframe | //nav | //header | //footer | //form | //noscript | //aside | //button');
            foreach ($unwantedNodes as $node) {
                $node->parentNode?->removeChild($node);
            }

            $contentNodes = $xpath->query('//article//p | //main//p | //div[contains(@class, "content") or contains(@class, "post") or contains(@class, "article")]//p | //p');
            $paragraphs = [];

            foreach ($contentNodes as $p) {
                $text = trim(preg_replace('/\s+/', ' ', $p->textContent));
                // Remove any inline URLs/links
                $text = preg_replace('/\bhttps?:\/\/\S+/i', '', $text);
                if (mb_strlen($text) > 30) {
                    $paragraphs[] = $text;
                }
            }

            if (empty($paragraphs)) {
                $bodyText = strip_tags($dom->saveHTML());
                $lines = array_filter(array_map('trim', explode("\n", $bodyText)));
                foreach ($lines as $line) {
                    $line = preg_replace('/\bhttps?:\/\/\S+/i', '', $line);
                    if (mb_strlen($line) > 40) {
                        $paragraphs[] = $line;
                    }
                }
            }

            $host = parse_url($url, PHP_URL_HOST) ?? 'Web';

            return [
                'title' => $title,
                'author' => 'Web Article (' . str_replace('www.', '', $host) . ')',
                'paragraphs' => array_values(array_unique($paragraphs)),
            ];
        } catch (\Exception $e) {
            return [
                'title' => 'Web Article',
                'author' => 'Web Source',
                'paragraphs' => ["Failed to extract text from URL: " . $e->getMessage()],
            ];
        }
    }

    private function extractFromPdf($file): array
    {
        try {
            $content = file_get_contents($file->getRealPath());
            if (empty($content)) {
                throw new \Exception("PDF file is empty.");
            }

            $extractedText = $this->parsePdfRawText($content);

            // Clean up text
            $cleanText = preg_replace('/\bhttps?:\/\/\S+/i', '', $extractedText);
            $cleanText = preg_replace('/[^\x20-\x7E\x0A\x0D\xA0-\xFF]/', ' ', $cleanText);

            // Split into paragraphs by double newlines or line endings
            $lines = preg_split('/\R{2,}/', $cleanText);
            $paragraphs = [];

            foreach ($lines as $line) {
                $line = trim(preg_replace('/\s+/', ' ', $line));
                // Ignore PDF metadata remnants, fonts, or short codes
                if (mb_strlen($line) > 20 && !preg_match('/^(Font|Type|MediaBox|Resources|ProcSet|Encoding|ObjStm|Pages|Catalog)\b/i', $line)) {
                    $paragraphs[] = $line;
                }
            }

            if (empty($paragraphs) && !empty(trim($cleanText))) {
                $fallback = trim(preg_replace('/\s+/', ' ', $cleanText));
                if (mb_strlen($fallback) > 15) {
                    $paragraphs = [$fallback];
                }
            }

            if (empty($paragraphs)) {
                throw new \Exception("Could not extract text from PDF. The PDF may be a scanned image or password protected.");
            }

            $title = pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME);
            $title = ucwords(str_replace(['_', '-'], ' ', $title));

            return [
                'title' => $title,
                'author' => 'PDF Document',
                'paragraphs' => array_values(array_unique($paragraphs)),
            ];
        } catch (\Exception $e) {
            return [
                'title' => pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME),
                'author' => 'PDF Source',
                'paragraphs' => ["Error reading PDF: " . $e->getMessage()],
            ];
        }
    }

    private function parsePdfRawText(string $data): string
    {
        $text = '';

        // Extract all streams in PDF
        preg_match_all('/stream[\r\n]+(.*?)[\r\n]+endstream/s', $data, $matches);
        
        foreach ($matches[1] as $stream) {
            // Attempt decompression with multiple zlib formats
            $decompressed = @gzuncompress($stream);
            if ($decompressed === false) {
                $decompressed = @gzinflate(substr($stream, 2));
            }
            if ($decompressed === false) {
                $decompressed = @zlib_decode($stream);
            }
            
            $curr = ($decompressed !== false) ? $decompressed : $stream;

            // 1. Match BT ... ET text blocks
            preg_match_all('/BT[\r\n\s]+(.*?)[\r\n\s]+ET/s', $curr, $btMatches);
            foreach ($btMatches[1] as $bt) {
                // (Literal String) Tj or ' or "
                preg_match_all('/\((.*?)\)\s*(?:T[jJ]|\'|")/s', $bt, $strMatches);
                foreach ($strMatches[1] as $s) {
                    $text .= $this->unescapePdfString($s) . " ";
                }

                // Array TJ: [ (String) -10 (Another) ] TJ
                preg_match_all('/\[(.*?)\]\s*TJ/s', $bt, $tjMatches);
                foreach ($tjMatches[1] as $tj) {
                    preg_match_all('/\((.*?)\)/s', $tj, $subStr);
                    foreach ($subStr[1] as $sub) {
                        $text .= $this->unescapePdfString($sub);
                    }
                    $text .= " ";

                    // Hex strings in TJ arrays: [<48656c6c6f>] TJ
                    preg_match_all('/<([0-9a-fA-F\s]+)>/s', $tj, $hexSub);
                    foreach ($hexSub[1] as $h) {
                        $text .= $this->decodePdfHex($h) . " ";
                    }
                }

                // Hex strings: <48656c6c6f> Tj
                preg_match_all('/<([0-9a-fA-F\s]+)>\s*T[jJ]/s', $bt, $hexMatches);
                foreach ($hexMatches[1] as $h) {
                    $text .= $this->decodePdfHex($h) . " ";
                }
            }
        }

        // 2. Fallback: If BT...ET produced very little text, scan sanitized data for parenthesized strings
        if (mb_strlen(trim($text)) < 50) {
            $cleanData = $this->sanitizeUtf8($data);
            preg_match_all('/\((.*?)\)/s', $cleanData, $rawMatches);
            foreach ($rawMatches[1] as $m) {
                $clean = $this->unescapePdfString($m);
                if (strlen($clean) > 8 && !preg_match('/^\/|^Font|^Type|^[0-9\s]+$/i', $clean)) {
                    $text .= $clean . "\n";
                }
            }
        }

        // 3. Last Fallback: Continuous printable ASCII sequences
        if (mb_strlen(trim($text)) < 30) {
            $cleanData = $this->sanitizeUtf8($data);
            preg_match_all('/[a-zA-Z0-9\s.,!?\'"()-]{25,}/', $cleanData, $asciiMatches);
            foreach ($asciiMatches[0] as $match) {
                if (!preg_match('/(MediaBox|FontDescriptor|ProcSet|Encoding|FlateDecode)/i', $match)) {
                    $text .= trim($match) . "\n";
                }
            }
        }

        return $this->sanitizeUtf8($text);
    }

    private function sanitizeUtf8(string $text): string
    {
        // 1. Convert to valid UTF-8
        $clean = @mb_convert_encoding($text, 'UTF-8', 'UTF-8');
        // 2. Strip non-printable control characters
        $clean = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/u', '', $clean);
        // 3. Remove non-UTF8 high bytes
        $clean = preg_replace('/[^\x20-\x7E\x0A\x0D\xA0-\xFF]/u', ' ', $clean);
        return trim(preg_replace('/\s+/', ' ', $clean));
    }

    private function unescapePdfString(string $s): string
    {
        return str_replace(
            ['\\\\', '\\(', '\\)', '\\n', '\\r', '\\t'],
            ['\\', '(', ')', "\n", "\r", "\t"],
            $s
        );
    }

    private function decodePdfHex(string $hex): string
    {
        $cleanHex = preg_replace('/\s+/', '', $hex);
        if (strlen($cleanHex) % 2 !== 0) {
            $cleanHex .= '0';
        }
        $bin = @hex2bin($cleanHex);
        if ($bin === false) return '';
        // If UTF-16 BE (common in PDF ToUnicode)
        if (str_starts_with($bin, "\xFE\xFF")) {
            return @mb_convert_encoding(substr($bin, 2), 'UTF-8', 'UTF-16BE') ?: '';
        }
        return preg_replace('/[^\x20-\x7E\x0A\x0D]/', '', $bin);
    }

    private function extractFromText(string $rawText): array
    {
        $cleanText = strip_tags($rawText);
        $cleanText = preg_replace('/\bhttps?:\/\/\S+/i', '', $cleanText);

        $paragraphs = array_values(array_filter(
            array_map(function($p) {
                return $this->sanitizeUtf8($p);
            }, preg_split('/\R{2,}/', $cleanText)),
            function($p) {
                return mb_strlen($p) > 2;
            }
        ));

        return [
            'paragraphs' => $paragraphs,
        ];
    }
}
