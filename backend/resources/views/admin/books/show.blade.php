@extends('admin.layout')

@section('title', $book->title . ' - Easy Read Studio')
@section('page_title', 'View Book Reader')

@section('content')
<div class="max-w-5xl mx-auto space-y-6">

    <!-- Top Navigation & Action Header -->
    <div class="flex flex-wrap items-center justify-between gap-4">
        <a href="{{ route('admin.books.index') }}" class="px-4 py-2 bg-white hover:bg-[#F3EFE6] text-[#16241D] font-bold text-xs sm:text-sm rounded-xl border border-[#E5DFD3] shadow-xs flex items-center space-x-2 transition">
            <i class="fa-solid fa-arrow-left text-xs"></i>
            <span>Back to All Books</span>
        </a>

        <div class="flex items-center space-x-2">
            <a href="{{ route('admin.books.edit', $book->id) }}" class="px-4 py-2 bg-[#F3EFE6] hover:bg-[#EAE4D7] text-[#16241D] font-bold text-xs sm:text-sm rounded-xl border border-[#E5DFD3] shadow-xs flex items-center space-x-1.5 transition">
                <i class="fa-solid fa-pen text-xs text-[#4B6B4A]"></i>
                <span>Edit Metadata & Text</span>
            </a>
            <form action="{{ route('admin.books.destroy', $book->id) }}" method="POST" class="inline" data-confirm="Are you sure you want to delete this book?">
                @csrf
                @method('DELETE')
                <button type="submit" class="px-4 py-2 bg-[#FDF2F2] hover:bg-rose-100 text-[#A13B3B] font-bold text-xs sm:text-sm rounded-xl border border-rose-200 shadow-xs flex items-center space-x-1.5 transition">
                    <i class="fa-solid fa-trash text-xs"></i>
                    <span>Delete Book</span>
                </button>
            </form>
        </div>
    </div>

    <!-- Book Hero Cover Header Card -->
    <div class="bg-white p-6 sm:p-8 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
        <div class="flex flex-col sm:flex-row items-start sm:items-center space-y-4 sm:space-y-0 sm:space-x-6">
            <!-- Cover Block -->
            <div class="w-20 h-28 sm:w-24 sm:h-32 rounded-2xl flex flex-col items-center justify-center font-bold text-white shadow-md border border-black/10 shrink-0 relative overflow-hidden group"
                 style="background-color: {{ $book->cover_color ?? '#4B6B4A' }};">
                <i class="fa-solid fa-book-open text-2xl mb-1"></i>
                <span class="text-[9px] uppercase tracking-widest font-bold opacity-80">EasyRead</span>
            </div>

            <!-- Title & Details -->
            <div class="space-y-2 flex-1 min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                    <span class="px-3 py-1 rounded-full text-xs font-bold bg-[#F3EFE6] text-[#4B6B4A] border border-[#E5DFD3]">
                        {{ $book->category }}
                    </span>
                    @if($book->source_type)
                        <span class="px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-[#FDFBF7] text-[#7A7569] border border-[#E5DFD3] uppercase tracking-wider">
                            Source: {{ strtoupper($book->source_type) }}
                        </span>
                    @endif
                    @if($book->is_public)
                        <span class="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 inline-flex items-center gap-1">
                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                            <span>Published in App</span>
                        </span>
                    @endif
                </div>

                <h1 class="font-serif font-bold text-2xl sm:text-3xl text-[#16241D] leading-tight">
                    {{ $book->title }}
                </h1>
                <p class="text-sm text-[#7A7569] font-medium flex items-center gap-1">
                    <i class="fa-solid fa-user-pen text-xs text-[#4B6B4A]"></i>
                    <span>By {{ $book->author }}</span>
                </p>

                @if($book->source_url)
                    <p class="text-xs text-[#4B6B4A] font-semibold flex items-center gap-1.5 pt-1">
                        <i class="fa-solid fa-globe text-xs"></i>
                        <a href="{{ $book->source_url }}" target="_blank" class="hover:underline truncate max-w-lg">{{ $book->source_url }}</a>
                    </p>
                @endif
            </div>
        </div>

        <!-- KPI Metrics Grid -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-4 border-t border-[#E5DFD3]">
            <div class="p-3.5 bg-[#FDFBF7] rounded-2xl border border-[#E5DFD3]">
                <p class="text-[10px] font-bold text-[#7A7569] uppercase tracking-wider">Paragraphs</p>
                <p class="text-lg font-bold text-[#16241D] font-serif mt-0.5">{{ number_format($book->paragraphs->count()) }}</p>
            </div>
            <div class="p-3.5 bg-[#FDFBF7] rounded-2xl border border-[#E5DFD3]">
                <p class="text-[10px] font-bold text-[#7A7569] uppercase tracking-wider">Word Count</p>
                <p class="text-lg font-bold text-[#16241D] font-serif mt-0.5">{{ number_format($totalWordsCount) }}</p>
            </div>
            <div class="p-3.5 bg-[#FDFBF7] rounded-2xl border border-[#E5DFD3]">
                <p class="text-[10px] font-bold text-[#7A7569] uppercase tracking-wider">Read Time</p>
                <p class="text-lg font-bold text-[#16241D] font-serif mt-0.5">{{ $book->read_time }}</p>
            </div>
            <div class="p-3.5 bg-[#FDFBF7] rounded-2xl border border-[#E5DFD3]">
                <p class="text-[10px] font-bold text-[#7A7569] uppercase tracking-wider">Book ID</p>
                <p class="text-lg font-bold text-[#4B6B4A] font-serif mt-0.5">#{{ $book->id }}</p>
            </div>
        </div>
    </div>

    <!-- Search & Content Header Bar -->
    <div class="bg-white p-4 sm:p-5 rounded-3xl border border-[#E5DFD3] shadow-xs flex flex-col sm:flex-row items-center justify-between gap-4">
        <div class="flex items-center space-x-2">
            <i class="fa-solid fa-align-left text-[#4B6B4A]"></i>
            <h3 class="font-serif font-bold text-lg text-[#16241D]">Extracted Paragraphs & Text Content</h3>
        </div>

        <!-- In-Page Paragraph Search Filter -->
        <div class="relative w-full sm:w-72">
            <i class="fa-solid fa-magnifying-glass absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-xs"></i>
            <input type="text" id="paraSearchInput" onkeyup="filterParagraphs()" placeholder="Search in book text..."
                   class="w-full pl-9 pr-4 py-2 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-xs text-[#16241D] placeholder-[#7A7569] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
        </div>
    </div>

    <!-- Paragraphs List -->
    <div class="space-y-4" id="paragraphsContainer">
        @forelse($book->paragraphs as $para)
            <div class="para-card bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] shadow-xs hover:border-[#4B6B4A]/40 transition space-y-3">
                <div class="flex items-center justify-between text-xs border-b border-[#F3EFE6] pb-2.5">
                    <span class="font-bold text-[#4B6B4A] bg-[#F3EFE6] px-2.5 py-0.5 rounded-md border border-[#E5DFD3]">
                        Paragraph #{{ $para->paragraph_index + 1 }}
                    </span>
                    <span class="text-[#7A7569] font-medium">
                        {{ str_word_count($para->content) }} words
                    </span>
                </div>
                <p class="para-content font-serif text-sm sm:text-base text-[#16241D] leading-relaxed select-text">
                    {{ $para->content }}
                </p>
            </div>
        @empty
            <div class="bg-white p-12 rounded-3xl border border-[#E5DFD3] text-center text-[#7A7569]">
                <i class="fa-solid fa-file-circle-xmark text-4xl text-gray-300 mb-3 block"></i>
                <p class="font-bold text-base text-[#16241D]">No Paragraphs Found</p>
                <p class="text-xs mt-1">This book has no text paragraphs saved in the database.</p>
            </div>
        @endforelse
    </div>

</div>

<script>
    function filterParagraphs() {
        const query = document.getElementById('paraSearchInput').value.toLowerCase().trim();
        const cards = document.querySelectorAll('.para-card');

        cards.forEach(card => {
            const content = card.querySelector('.para-content').innerText.toLowerCase();
            if (content.includes(query)) {
                card.style.display = 'block';
            } else {
                card.style.display = 'none';
            }
        });
    }
</script>
@endsection
