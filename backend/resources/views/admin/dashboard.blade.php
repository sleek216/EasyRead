@extends('admin.layout')

@section('title', 'Dashboard - Easy Read Studio')
@section('page_title', 'Analytics & Overview')

@section('content')
<div class="space-y-6 sm:space-y-8">

    <!-- KPI Metric Cards Grid (100% Responsive: 1 col on mobile, 3 on tablet/desktop) -->
    <div class="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-3 gap-4 sm:gap-6">
        <!-- Total Users -->
        <div class="bg-white p-5 sm:p-6 rounded-2xl sm:rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs hover:border-[#4B6B4A]/40 transition">
            <div class="space-y-1">
                <p class="text-[11px] sm:text-xs font-bold text-[#7A7569] uppercase tracking-wider">Total Readers</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($totalUsers) }}</h3>
                <p class="text-[11px] sm:text-xs text-[#4B6B4A] font-bold flex items-center pt-0.5">
                    <i class="fa-solid fa-arrow-trend-up mr-1.5 text-xs"></i> Active Community
                </p>
            </div>
            <div class="w-12 h-12 sm:w-14 sm:h-14 rounded-xl sm:rounded-2xl bg-[#F3EFE6] text-[#4B6B4A] flex items-center justify-center text-xl sm:text-2xl shrink-0">
                <i class="fa-solid fa-users"></i>
            </div>
        </div>

        <!-- Published Books / Articles -->
        <div class="bg-white p-5 sm:p-6 rounded-2xl sm:rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs hover:border-[#4B6B4A]/40 transition">
            <div class="space-y-1">
                <p class="text-[11px] sm:text-xs font-bold text-[#7A7569] uppercase tracking-wider">Books & Articles</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($totalBooks) }}</h3>
                <p class="text-[11px] sm:text-xs text-[#7A7569] font-medium pt-0.5">
                    Curated Digital Library
                </p>
            </div>
            <div class="w-12 h-12 sm:w-14 sm:h-14 rounded-xl sm:rounded-2xl bg-[#F3EFE6] text-[#16241D] flex items-center justify-center text-xl sm:text-2xl shrink-0">
                <i class="fa-solid fa-book-bookmark"></i>
            </div>
        </div>

        <!-- AI Lookups Served -->
        <div class="bg-white p-5 sm:p-6 rounded-2xl sm:rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs hover:border-[#4B6B4A]/40 transition">
            <div class="space-y-1">
                <p class="text-[11px] sm:text-xs font-bold text-[#7A7569] uppercase tracking-wider">AI Queries Served</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($totalAiQueries) }}</h3>
                <p class="text-[11px] sm:text-xs text-[#4B6B4A] font-bold flex items-center pt-0.5">
                    <i class="fa-solid fa-bolt mr-1.5 text-xs"></i> {{ number_format($cachedAiQueries) }} Zero-Cost Cached
                </p>
            </div>
            <div class="w-12 h-12 sm:w-14 sm:h-14 rounded-xl sm:rounded-2xl bg-[#F3EFE6] text-[#4B6B4A] flex items-center justify-center text-xl sm:text-2xl shrink-0">
                <i class="fa-solid fa-wand-magic-sparkles"></i>
            </div>
        </div>
    </div>

    <!-- Main Content Split Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-5 sm:gap-7">

        <!-- Books Management Quick Table (2 Cols) -->
        <div class="lg:col-span-2 bg-white rounded-2xl sm:rounded-3xl border border-[#E5DFD3] shadow-xs p-5 sm:p-7 space-y-4 sm:space-y-5">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                    <h3 class="font-serif font-bold text-[#16241D] text-base sm:text-lg">Curated Reading Library</h3>
                    <p class="text-xs text-[#7A7569] mt-0.5">Recently added books, essays, and reading materials</p>
                </div>
                <a href="{{ route('admin.books.create') }}" class="inline-flex items-center px-4 py-2.5 rounded-xl bg-[#4B6B4A] hover:bg-[#3A5439] active:scale-[0.99] text-white text-xs font-bold transition shadow-xs self-start sm:self-auto space-x-1.5">
                    <i class="fa-solid fa-plus text-xs"></i>
                    <span>Add New Book</span>
                </a>
            </div>

            <div class="overflow-x-auto rounded-xl sm:rounded-2xl border border-[#E5DFD3]/80">
                <table class="w-full text-left text-sm text-[#5C5649] min-w-[520px]">
                    <thead class="bg-[#F3EFE6] text-[#7A7569] uppercase text-xs font-bold border-b border-[#E5DFD3]">
                        <tr>
                            <th class="px-5 py-3.5">Title & Author</th>
                            <th class="px-4 py-3.5">Category</th>
                            <th class="px-4 py-3.5">Paragraphs</th>
                            <th class="px-5 py-3.5 text-right">Action</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E5DFD3]/60">
                        @forelse($recentBooks as $book)
                        <tr class="hover:bg-[#FAF7F0] transition">
                            <td class="px-5 py-3.5">
                                <div class="font-bold text-[#16241D] text-sm leading-snug">{{ $book->title }}</div>
                                <div class="text-xs text-[#7A7569] mt-0.5">{{ $book->author }} • {{ $book->read_time }}</div>
                            </td>
                            <td class="px-4 py-3.5 whitespace-nowrap">
                                <span class="px-2.5 py-0.5 rounded-lg text-xs font-semibold bg-[#F3EFE6] text-[#5C5649] border border-[#E5DFD3]">
                                    {{ $book->category }}
                                </span>
                            </td>
                            <td class="px-4 py-3.5 font-semibold text-[#16241D] text-sm whitespace-nowrap">
                                {{ $book->paragraphs->count() }} <span class="text-xs font-normal text-[#7A7569]">paras</span>
                            </td>
                            <td class="px-5 py-3.5 text-right whitespace-nowrap">
                                <a href="{{ route('admin.books.edit', $book->id) }}" class="inline-flex items-center px-3 py-1.5 rounded-lg border border-[#E5DFD3] hover:bg-[#F3EFE6] text-[#4B6B4A] text-xs font-bold transition">
                                    Edit
                                </a>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" class="text-center py-8 text-[#7A7569] text-sm">No books found in library.</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div class="text-right pt-1">
                <a href="{{ route('admin.books.index') }}" class="text-xs sm:text-sm font-bold text-[#4B6B4A] hover:underline inline-flex items-center space-x-1">
                    <span>Manage Full Library</span>
                    <i class="fa-solid fa-arrow-right text-xs"></i>
                </a>
            </div>
        </div>

        <!-- Recent Registered Readers (1 Col) -->
        <div class="bg-white rounded-2xl sm:rounded-3xl border border-[#E5DFD3] shadow-xs p-5 sm:p-7 space-y-4 sm:space-y-5">
            <div class="flex items-center justify-between">
                <div>
                    <h3 class="font-serif font-bold text-[#16241D] text-base sm:text-lg">Recent Readers</h3>
                    <p class="text-xs text-[#7A7569] mt-0.5">Latest mobile registrations</p>
                </div>
                <a href="{{ route('admin.users.index') }}" class="text-xs font-bold text-[#4B6B4A] hover:underline">View All</a>
            </div>

            <div class="space-y-2.5">
                @forelse($recentUsers as $u)
                <div class="flex items-center justify-between p-3 rounded-xl sm:rounded-2xl bg-[#FBF9F4] border border-[#E5DFD3] hover:border-[#4B6B4A]/40 transition">
                    <div class="flex items-center space-x-3 truncate">
                        <div class="w-9 h-9 rounded-xl {{ $u->is_premium ? 'bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/30' : 'bg-[#F3EFE6] text-[#4B6B4A]' }} flex items-center justify-center font-bold text-xs sm:text-sm shrink-0 shadow-2xs">
                            {{ strtoupper(substr($u->name, 0, 1)) }}
                        </div>
                        <div class="truncate">
                            <p class="text-xs sm:text-sm font-bold text-[#16241D] truncate leading-tight">{{ $u->name }}</p>
                            <p class="text-[11px] text-[#7A7569] truncate mt-0.5">{{ $u->email }}</p>
                        </div>
                    </div>
                    @if($u->is_premium)
                        <span class="px-2 py-0.5 rounded-lg text-[10px] font-bold bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/30 shrink-0 ml-2">PLUS</span>
                    @else
                        <span class="px-2 py-0.5 rounded-lg text-[10px] font-medium bg-[#F3EFE6] text-[#7A7569] shrink-0 ml-2">FREE</span>
                    @endif
                </div>
                @empty
                <p class="text-sm text-[#7A7569] text-center py-6">No readers registered yet.</p>
                @endforelse
            </div>
        </div>

    </div>

    <!-- AI Intelligence Live Logs -->
    <div class="bg-white rounded-2xl sm:rounded-3xl border border-[#E5DFD3] shadow-xs p-5 sm:p-7 space-y-4 sm:space-y-5">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-[#F3EFE6] pb-4">
            <div>
                <h3 class="font-serif font-bold text-[#16241D] text-base sm:text-lg flex items-center space-x-2">
                    <i class="fa-solid fa-wand-magic-sparkles text-[#4B6B4A]"></i>
                    <span>Live AI Queries (Gemini 1.5 Flash)</span>
                </h3>
                <p class="text-xs text-[#7A7569] mt-0.5">Live AI requests triggered by readers inside the mobile app</p>
            </div>
            <a href="{{ route('admin.ai-logs.index') }}" class="text-xs font-bold text-[#4B6B4A] hover:underline self-start sm:self-auto flex items-center space-x-1">
                <span>View All AI Logs</span>
                <i class="fa-solid fa-arrow-right text-[10px]"></i>
            </a>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 sm:gap-5">
            @forelse($recentAiLogs as $log)
            <div class="p-5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] hover:border-[#4B6B4A]/50 transition flex flex-col justify-between space-y-4 shadow-2xs group">
                <div class="space-y-3">
                    <div class="flex items-center justify-between">
                        <span class="px-2.5 py-1 rounded-md text-[10px] font-bold uppercase tracking-wider bg-[#F3EFE6] text-[#4B6B4A] border border-[#E5DFD3]">
                            {{ $log->action }}
                        </span>
                        <span class="text-[11px] text-[#7A7569] font-medium flex items-center space-x-1">
                            <i class="fa-regular fa-clock text-[10px]"></i>
                            <span>{{ $log->created_at->diffForHumans() }}</span>
                        </span>
                    </div>

                    <div class="space-y-1">
                        <p class="text-[10px] font-bold uppercase tracking-wider text-[#7A7569]">Original Passage</p>
                        <p class="text-xs text-[#5C5649] line-clamp-2 italic bg-[#F3EFE6]/60 p-2.5 rounded-xl border border-[#E5DFD3]/60">
                            "{{ $log->passage_text }}"
                        </p>
                    </div>

                    <div class="space-y-1">
                        <p class="text-[10px] font-bold uppercase tracking-wider text-[#7A7569]">AI Response Output</p>
                        <div class="relative bg-white p-3 rounded-xl border border-[#E5DFD3] text-xs sm:text-sm text-[#16241D] leading-relaxed max-h-28 overflow-hidden">
                            <p class="line-clamp-3 font-medium">{{ $log->response_text }}</p>
                            <div class="absolute inset-x-0 bottom-0 h-8 bg-gradient-to-t from-white to-transparent pointer-events-none"></div>
                        </div>
                    </div>
                </div>

                <div class="pt-2.5 border-t border-[#E5DFD3]/60 flex items-center justify-between">
                    <span class="text-[11px] text-[#7A7569] font-semibold truncate max-w-[150px] flex items-center">
                        <i class="fa-solid fa-user-pen text-[10px] text-[#4B6B4A] mr-1.5"></i>
                        {{ $log->user ? $log->user->name : 'Guest Reader' }}
                    </span>
                    <button type="button" 
                            onclick="openAiModal({{ json_encode([
                                'action' => strtoupper($log->action),
                                'time' => $log->created_at->format('M d, Y · h:i A') . ' (' . $log->created_at->diffForHumans() . ')',
                                'user' => $log->user ? ($log->user->name . ' (' . $log->user->email . ')') : 'Guest Reader',
                                'passage' => $log->passage_text,
                                'response' => $log->response_text,
                            ]) }})"
                            class="px-3 py-1.5 rounded-xl bg-white hover:bg-[#F3EFE6] text-[#16241D] text-xs font-bold transition flex items-center space-x-1.5 border border-[#E5DFD3] shadow-2xs">
                        <span>See Full Output</span>
                        <i class="fa-solid fa-expand text-[10px] text-[#4B6B4A]"></i>
                    </button>
                </div>
            </div>
            @empty
            <div class="col-span-full text-center py-10 text-[#7A7569] text-sm">
                <i class="fa-solid fa-wand-magic-sparkles text-2xl text-[#C5BEB0] mb-2 block"></i>
                <p class="font-bold text-[#16241D]">No AI actions logged yet.</p>
                <p class="text-xs text-[#7A7569] mt-1">Readers can trigger Simplify, Summarize, Explain, or Translate from mobile app.</p>
            </div>
            @endforelse
        </div>
    </div>

</div>

<!-- AI Query Details Interactive Modal -->
<div id="aiDetailModal" class="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 hidden">
    <div class="bg-white w-full max-w-2xl rounded-3xl border border-[#E5DFD3] shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 flex flex-col max-h-[90vh]">
        <!-- Modal Header -->
        <div class="px-6 py-4 bg-[#F8F5EE] border-b border-[#E5DFD3] flex items-center justify-between shrink-0">
            <div class="flex items-center space-x-3">
                <span id="modalActionBadge" class="px-3 py-1 rounded-xl text-xs font-bold uppercase tracking-wider bg-[#3E5C45] text-white">
                    ACTION
                </span>
                <div>
                    <h3 class="font-serif font-bold text-[#16241D] text-base">AI Query Details</h3>
                    <p id="modalTimestamp" class="text-[11px] text-[#7A7569] font-medium"></p>
                </div>
            </div>
            <button onclick="closeAiModal()" class="w-8 h-8 rounded-full bg-white border border-[#E5DFD3] text-[#7A7569] hover:text-[#16241D] hover:bg-[#F3EFE6] flex items-center justify-center transition">
                <i class="fa-solid fa-xmark text-sm"></i>
            </button>
        </div>

        <!-- Modal Body Scrollable -->
        <div class="p-6 overflow-y-auto space-y-5 flex-1">
            <!-- Reader Badge -->
            <div class="flex items-center space-x-2 text-xs text-[#7A7569] bg-[#FDFBF7] p-3 rounded-xl border border-[#E5DFD3]">
                <i class="fa-solid fa-user text-[#4B6B4A]"></i>
                <span class="font-bold text-[#16241D]">Reader Account:</span>
                <span id="modalUserText"></span>
            </div>

            <!-- Original Passage Text -->
            <div class="space-y-2">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#7A7569] flex items-center justify-between">
                    <span>Original Selected Passage</span>
                    <i class="fa-solid fa-[#4B6B4A] fa-quote-left text-xs"></i>
                </label>
                <div class="p-4 rounded-2xl bg-[#F3EFE6]/70 border border-[#E5DFD3] text-xs sm:text-sm text-[#16241D] font-serif italic leading-relaxed whitespace-pre-line" id="modalPassageText">
                </div>
            </div>

            <!-- Full AI Output Text -->
            <div class="space-y-2">
                <div class="flex items-center justify-between">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D] flex items-center space-x-1.5">
                        <i class="fa-solid fa-wand-magic-sparkles text-[#4B6B4A]"></i>
                        <span>Full AI Generated Response</span>
                    </label>
                    <button onclick="copyModalAiResponse()" id="copyAiBtn" class="text-xs font-bold text-[#4B6B4A] hover:underline flex items-center space-x-1 bg-[#F3EFE6] px-2.5 py-1 rounded-lg border border-[#E5DFD3]">
                        <i class="fa-regular fa-copy text-xs"></i>
                        <span id="copyBtnLabel">Copy Response</span>
                    </button>
                </div>
                <div class="p-5 rounded-2xl bg-[#FDFBF7] border border-[#E5DFD3] text-sm text-[#16241D] leading-relaxed whitespace-pre-line font-sans shadow-2xs" id="modalResponseText">
                </div>
            </div>
        </div>

        <!-- Modal Footer -->
        <div class="px-6 py-4 bg-[#F8F5EE] border-t border-[#E5DFD3] flex justify-end shrink-0">
            <button onclick="closeAiModal()" class="px-5 py-2.5 rounded-xl bg-[#16241D] hover:bg-[#3A5741] text-white text-xs font-bold transition shadow-xs">
                Close Window
            </button>
        </div>
    </div>
</div>

<script>
    function openAiModal(data) {
        document.getElementById('modalActionBadge').innerText = data.action || 'AI QUERY';
        document.getElementById('modalTimestamp').innerText = data.time || '';
        document.getElementById('modalUserText').innerText = data.user || 'Guest Reader';
        document.getElementById('modalPassageText').innerText = '"' + (data.passage || '') + '"';
        
        const respEl = document.getElementById('modalResponseText');
        respEl.innerText = data.response || '';
        
        // Auto-detect Urdu / Arabic text for RTL alignment
        if (/[\u0600-\u06FF]/.test(data.response || '')) {
            respEl.style.direction = 'rtl';
            respEl.style.textAlign = 'right';
            respEl.style.fontFamily = "'Plus Jakarta Sans', 'Noto Nastaliq Urdu', sans-serif";
        } else {
            respEl.style.direction = 'ltr';
            respEl.style.textAlign = 'left';
            respEl.style.fontFamily = "inherit";
        }
        
        document.getElementById('aiDetailModal').classList.remove('hidden');
    }

    function closeAiModal() {
        document.getElementById('aiDetailModal').classList.add('hidden');
    }

    function copyModalAiResponse() {
        const text = document.getElementById('modalResponseText').innerText;
        navigator.clipboard.writeText(text);
        const label = document.getElementById('copyBtnLabel');
        label.innerText = 'Copied!';
        setTimeout(() => { label.innerText = 'Copy Response'; }, 2000);
    }

    // Close on Escape key press
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeAiModal();
    });
</script>
@endsection
