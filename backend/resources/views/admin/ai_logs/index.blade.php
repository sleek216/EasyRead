@extends('admin.layout')

@section('title', 'AI Logs & Cache - Easy Read Studio')
@section('page_title', 'AI Query Intelligence & Response Cache')

@section('content')
<div class="space-y-7">

    <!-- Metrics Header (Sizable & Modern) -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-1">
            <p class="text-xs font-bold text-[#7A7569] uppercase tracking-wider">Total Tokens Processed</p>
            <h3 class="text-3xl font-bold font-serif text-[#16241D]">{{ number_format($totalTokens) }}</h3>
            <p class="text-xs text-[#7A7569]">Google Gemini 1.5 Flash</p>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-1">
            <p class="text-xs font-bold text-[#7A7569] uppercase tracking-wider">Estimated AI Running Cost</p>
            <h3 class="text-3xl font-bold font-serif text-[#4B6B4A]">${{ number_format(($totalTokens / 1000000) * 0.3, 4) }} USD</h3>
            <p class="text-xs text-[#4B6B4A] font-semibold">Cost-optimized cache architecture</p>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-[#E5DFD3] shadow-xs flex items-center justify-between">
            <div class="space-y-1">
                <p class="text-xs font-bold text-[#7A7569] uppercase tracking-wider">Zero-Cost Cache</p>
                <p class="text-sm font-medium text-[#5C5649]">Instant database re-lookup</p>
            </div>
            <form action="{{ route('admin.ai-logs.clear-cache') }}" method="POST" data-confirm="Clear the entire AI response cache? All future AI explanations and summaries will be regenerated on-demand.">
                @csrf
                <button type="submit" class="px-4 py-2.5 rounded-xl bg-[#FDF2F2] text-[#A13B3B] hover:bg-rose-100 border border-[#A13B3B]/20 text-xs font-bold transition flex items-center space-x-1.5 shadow-2xs">
                    <i class="fa-solid fa-broom text-xs"></i>
                    <span>Clear Cache</span>
                </button>
            </form>
        </div>
    </div>

    <!-- Filter Tabs -->
    <div class="flex items-center space-x-2 overflow-x-auto pb-1">
        <a href="{{ route('admin.ai-logs.index') }}" class="px-4 py-2.5 rounded-xl text-sm font-bold transition {{ empty($action) ? 'bg-[#16241D] text-white shadow-xs' : 'bg-white border border-[#E5DFD3] text-[#7A7569] hover:bg-[#F3EFE6]' }}">
            All Actions
        </a>
        <a href="{{ route('admin.ai-logs.index', ['action' => 'simplify']) }}" class="px-4 py-2.5 rounded-xl text-sm font-bold transition {{ $action === 'simplify' ? 'bg-[#16241D] text-white shadow-xs' : 'bg-white border border-[#E5DFD3] text-[#7A7569] hover:bg-[#F3EFE6]' }}">
            Simplify
        </a>
        <a href="{{ route('admin.ai-logs.index', ['action' => 'summarize']) }}" class="px-4 py-2.5 rounded-xl text-sm font-bold transition {{ $action === 'summarize' ? 'bg-[#16241D] text-white shadow-xs' : 'bg-white border border-[#E5DFD3] text-[#7A7569] hover:bg-[#F3EFE6]' }}">
            Summarize
        </a>
        <a href="{{ route('admin.ai-logs.index', ['action' => 'explain']) }}" class="px-4 py-2.5 rounded-xl text-sm font-bold transition {{ $action === 'explain' ? 'bg-[#16241D] text-white shadow-xs' : 'bg-white border border-[#E5DFD3] text-[#7A7569] hover:bg-[#F3EFE6]' }}">
            Explain Terms
        </a>
        <a href="{{ route('admin.ai-logs.index', ['action' => 'translate']) }}" class="px-4 py-2.5 rounded-xl text-sm font-bold transition {{ $action === 'translate' ? 'bg-[#16241D] text-white shadow-xs' : 'bg-white border border-[#E5DFD3] text-[#7A7569] hover:bg-[#F3EFE6]' }}">
            Translate
        </a>
    </div>

    <!-- AI Logs Table -->
    <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm text-[#5C5649]">
                <thead class="bg-[#F3EFE6] text-[#7A7569] uppercase text-xs font-bold border-b border-[#E5DFD3]">
                    <tr>
                        <th class="px-6 py-4">Action</th>
                        <th class="px-6 py-4">Reader</th>
                        <th class="px-6 py-4">Original Passage</th>
                        <th class="px-6 py-4">AI Response</th>
                        <th class="px-6 py-4">Cache Status</th>
                        <th class="px-6 py-4">Time</th>
                        <th class="px-6 py-4 text-right">Details</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E5DFD3]/60">
                    @forelse($logs as $log)
                    <tr class="hover:bg-[#FAF7F0] transition cursor-pointer"
                        onclick="openAiModal({{ json_encode([
                            'action' => strtoupper($log->action),
                            'time' => $log->created_at->format('M d, Y · h:i A') . ' (' . $log->created_at->diffForHumans() . ')',
                            'user' => $log->user ? ($log->user->name . ' (' . $log->user->email . ')') : 'Anonymous Reader',
                            'passage' => $log->passage_text,
                            'response' => $log->response_text,
                        ]) }})">
                        <td class="px-6 py-4">
                            <span class="px-3 py-1 rounded-md text-[10px] font-bold uppercase tracking-wider bg-[#F3EFE6] text-[#4B6B4A] border border-[#E5DFD3]">
                                {{ $log->action }}
                            </span>
                        </td>
                        <td class="px-6 py-4 font-bold text-[#16241D] text-sm">
                            {{ $log->user ? $log->user->name : 'Anonymous Reader' }}
                        </td>
                        <td class="px-6 py-4 max-w-xs">
                            <p dir="auto" class="truncate italic text-xs text-[#7A7569]">"{{ $log->passage_text }}"</p>
                        </td>
                        <td class="px-6 py-4 max-w-sm">
                            <p dir="auto" class="line-clamp-2 text-xs font-medium text-[#16241D] bg-[#FBF9F4] p-2.5 rounded-xl border border-[#E5DFD3] leading-relaxed">{{ $log->response_text }}</p>
                        </td>
                        <td class="px-6 py-4">
                            @if($log->is_cached)
                                <span class="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">CACHED</span>
                            @else
                                <span class="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-[#F3EFE6] text-[#7A7569] border border-[#E5DFD3]">LIVE</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-xs text-[#7A7569] whitespace-nowrap">
                            {{ $log->created_at->diffForHumans() }}
                        </td>
                        <td class="px-6 py-4 text-right">
                            <button type="button" class="px-3 py-1.5 rounded-lg bg-[#F3EFE6] hover:bg-[#4B6B4A] text-[#16241D] hover:text-white text-xs font-bold transition flex items-center space-x-1 border border-[#E5DFD3] ml-auto">
                                <span>View Output</span>
                                <i class="fa-solid fa-expand text-[10px]"></i>
                            </button>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="text-center py-12 text-[#7A7569]">
                            <i class="fa-solid fa-wand-magic-sparkles text-3xl mb-2 block text-[#D9D2C5]"></i>
                            <p class="font-bold text-sm text-[#16241D]">No AI queries logged in this category.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($logs->hasPages())
        <div class="px-6 py-4 border-t border-[#E5DFD3] bg-[#FBF9F4]">
            {{ $logs->links() }}
        </div>
        @endif
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
        document.getElementById('modalUserText').innerText = data.user || 'Anonymous Reader';
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
