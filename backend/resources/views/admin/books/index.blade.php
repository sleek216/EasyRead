@extends('admin.layout')

@section('title', 'Curated Library & Books - Easy Read Studio')
@section('page_title', 'Curated Library & Books')

@section('content')
<div class="space-y-6">

    <!-- Top KPI Strip (4 Cards) -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Total Library</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($totalBooksCount) }}</h3>
                <p class="text-xs text-[#4B6B4A] font-semibold">Total catalog items</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#F3EFE6] text-[#4B6B4A] flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-book-bookmark"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Published</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-emerald-700">{{ number_format($publishedBooksCount) }}</h3>
                <p class="text-xs text-emerald-600 font-semibold">Live in mobile app</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 border border-emerald-200 flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-circle-check"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Unpublished</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#C28B38]">{{ number_format($unpublishedBooksCount) }}</h3>
                <p class="text-xs text-[#C28B38] font-semibold">Hidden / Drafts</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/30 flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-eye-slash"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Categories</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($totalCategoriesCount) }}</h3>
                <p class="text-xs text-[#7A7569] font-medium">Curated genres</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#F3EFE6] text-[#7A7569] flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-layer-group"></i>
            </div>
        </div>
    </div>

    <!-- Filter & Search Toolbar Header -->
    <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] space-y-4 shadow-xs">
        <!-- Action & Status Tabs Bar -->
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-[#E5DFD3] pb-4">
            <div class="flex flex-wrap items-center gap-1.5 sm:gap-2">
                <a href="{{ route('admin.books.index') }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition {{ ($statusFilter === 'all' && $categoryFilter === 'all') ? 'bg-[#16241D] text-white shadow-xs' : 'text-[#7A7569] hover:bg-[#F3EFE6] hover:text-[#16241D]' }}">
                    All Books ({{ $totalBooksCount }})
                </a>

                <a href="{{ route('admin.books.index', ['status' => 'published']) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition {{ $statusFilter === 'published' ? 'bg-emerald-700 text-white shadow-xs' : 'text-[#7A7569] hover:bg-emerald-50 hover:text-emerald-700' }}">
                    <i class="fa-solid fa-circle-check mr-1 text-[11px]"></i> Published ({{ $publishedBooksCount }})
                </a>

                <a href="{{ route('admin.books.index', ['status' => 'unpublished']) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition {{ $statusFilter === 'unpublished' ? 'bg-[#C28B38] text-white shadow-xs' : 'text-[#7A7569] hover:bg-[#FFF8EE] hover:text-[#C28B38]' }}">
                    <i class="fa-solid fa-eye-slash mr-1 text-[11px]"></i> Unpublished Drafts ({{ $unpublishedBooksCount }})
                </a>
            </div>

            <!-- Create Book Action -->
            <a href="{{ route('admin.books.create') }}" class="px-4 py-2 bg-[#4B6B4A] hover:bg-[#3A5439] active:scale-[0.99] text-white font-bold text-xs sm:text-sm rounded-xl shadow-xs flex items-center space-x-1.5 transition">
                <i class="fa-solid fa-plus text-xs"></i>
                <span>Add New Book</span>
            </a>
        </div>

        <!-- Search & Filter Controls -->
        <form method="GET" action="{{ route('admin.books.index') }}" class="flex flex-wrap items-center gap-3">
            @if($statusFilter !== 'all') <input type="hidden" name="status" value="{{ $statusFilter }}"> @endif

            <!-- Search Field -->
            <div class="relative flex-1 min-w-[240px]">
                <i class="fa-solid fa-magnifying-glass absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-xs"></i>
                <input type="text" name="search" value="{{ $search }}" placeholder="Search by book title or author..."
                       class="w-full pl-10 pr-4 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs sm:text-sm text-[#16241D] placeholder-[#7A7569] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] transition">
                @if($search || $categoryFilter !== 'all' || $statusFilter !== 'all')
                    <a href="{{ route('admin.books.index') }}" 
                       class="absolute right-3 top-1/2 -translate-y-1/2 text-[11px] text-[#7A7569] hover:text-[#16241D] font-bold">Clear</a>
                @endif
            </div>

            <!-- Category Filter Dropdown -->
            <div class="shrink-0">
                <select name="category" onchange="this.form.submit()" class="px-3.5 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs sm:text-sm text-[#16241D] font-medium focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] transition">
                    <option value="all">All Categories</option>
                    @foreach($categoriesList as $cat)
                        <option value="{{ $cat }}" {{ $categoryFilter === $cat ? 'selected' : '' }}>{{ $cat }}</option>
                    @endforeach
                </select>
            </div>

            <!-- Sort Dropdown -->
            <div class="shrink-0">
                <select name="sort" onchange="this.form.submit()" class="px-3.5 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs sm:text-sm text-[#16241D] font-medium focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] transition">
                    <option value="latest" {{ $sort === 'latest' ? 'selected' : '' }}>Sort: Newest First</option>
                    <option value="oldest" {{ $sort === 'oldest' ? 'selected' : '' }}>Sort: Oldest First</option>
                    <option value="title_asc" {{ $sort === 'title_asc' ? 'selected' : '' }}>Sort: Title (A-Z)</option>
                    <option value="most_paragraphs" {{ $sort === 'most_paragraphs' ? 'selected' : '' }}>Sort: Most Paragraphs</option>
                </select>
            </div>
        </form>
    </div>

    <!-- Books Listing Table Card -->
    <div class="bg-white rounded-3xl border border-[#E5DFD3] overflow-hidden shadow-xs">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="border-b border-[#E5DFD3] bg-[#FDFBF7] text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">
                        <th class="px-5 py-3.5">Book Title</th>
                        <th class="px-4 py-3.5">Author</th>
                        <th class="px-4 py-3.5">Category</th>
                        <th class="px-4 py-3.5">Read Time</th>
                        <th class="px-4 py-3.5">Paragraphs</th>
                        <th class="px-4 py-3.5">Status</th>
                        <th class="px-5 py-3.5 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E5DFD3]/60">
                    @forelse($books as $book)
                    <tr class="hover:bg-[#FAF7F0] transition group">
                        <!-- Book Title Column -->
                        <td class="px-5 py-3.5">
                            <div class="flex items-center space-x-3 max-w-sm sm:max-w-md">
                                <a href="{{ route('admin.books.show', $book->id) }}" class="w-9 h-11 rounded-lg flex items-center justify-center font-bold text-xs shrink-0 shadow-2xs border border-black/10 text-white hover:scale-105 transition" 
                                     style="background-color: {{ $book->cover_color ?? '#4B6B4A' }};" title="Click to Read Book">
                                    <i class="fa-solid fa-book-open text-xs"></i>
                                </a>
                                <div class="min-w-0">
                                    <h4 class="font-bold text-[#16241D] text-xs sm:text-sm line-clamp-1 leading-snug hover:text-[#4B6B4A] transition" title="{{ $book->title }}">
                                        <a href="{{ route('admin.books.show', $book->id) }}">{{ $book->title }}</a>
                                    </h4>
                                    @if($book->collection)
                                        <p class="text-[11px] text-[#7A7569] font-medium flex items-center gap-1 mt-0.5">
                                            <i class="fa-solid fa-folder text-[10px] text-[#4B6B4A]"></i>
                                            <span>{{ $book->collection->name }}</span>
                                        </p>
                                    @endif
                                </div>
                            </div>
                        </td>

                        <!-- Author Column -->
                        <td class="px-4 py-3.5 whitespace-nowrap text-xs sm:text-sm font-semibold text-[#16241D]">
                            {{ $book->author }}
                        </td>

                        <!-- Category Column -->
                        <td class="px-4 py-3.5 whitespace-nowrap">
                            <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-[#F3EFE6] text-[#5C5649] border border-[#E5DFD3] inline-block">
                                {{ $book->category }}
                            </span>
                        </td>

                        <!-- Read Time Column -->
                        <td class="px-4 py-3.5 whitespace-nowrap text-xs text-[#7A7569] font-medium">
                            <i class="fa-regular fa-clock mr-1 text-[11px] text-[#7A7569]"></i>
                            <span>{{ $book->read_time }}</span>
                        </td>

                        <!-- Paragraphs Column -->
                        <td class="px-4 py-3.5 whitespace-nowrap text-xs">
                            <span class="font-bold text-[#16241D]">{{ number_format($book->paragraphs->count()) }}</span>
                            <span class="text-[#7A7569]">paras</span>
                        </td>

                        <!-- Interactive Status Column (1-Click Toggle Publish / Unpublish) -->
                        <td class="px-4 py-3.5 whitespace-nowrap">
                            <form action="{{ route('admin.books.toggle-publish', $book->id) }}" method="POST" class="inline">
                                @csrf
                                @if($book->is_public)
                                    <button type="submit" title="Click to Unpublish (Hide from App)" class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 hover:bg-rose-50 hover:text-rose-700 hover:border-rose-200 border border-emerald-200 inline-flex items-center gap-1 transition group/btn">
                                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 group-hover/btn:bg-rose-500"></span>
                                        <span>Published</span>
                                    </button>
                                @else
                                    <button type="submit" title="Click to Publish to App" class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#FFF8EE] text-[#C28B38] hover:bg-emerald-50 hover:text-emerald-700 hover:border-emerald-200 border border-[#C28B38]/30 inline-flex items-center gap-1 transition group/btn">
                                        <span class="w-1.5 h-1.5 rounded-full bg-[#C28B38] group-hover/btn:bg-emerald-500"></span>
                                        <span>Unpublished</span>
                                    </button>
                                @endif
                            </form>
                        </td>

                        <!-- Actions Column -->
                        <td class="px-5 py-3.5 text-right space-x-1 whitespace-nowrap">
                            <!-- View & Read Book -->
                            <a href="{{ route('admin.books.show', $book->id) }}" title="View & Read Book" class="p-1.5 text-[#4B6B4A] hover:bg-[#F3EFE6] rounded-lg transition inline-flex items-center">
                                <i class="fa-solid fa-book-open text-sm"></i>
                            </a>

                            <!-- Edit Book -->
                            <a href="{{ route('admin.books.edit', $book->id) }}" title="Edit Book" class="p-1.5 text-[#5C5649] hover:text-[#16241D] hover:bg-[#F3EFE6] rounded-lg transition inline-flex items-center">
                                <i class="fa-solid fa-pen text-sm"></i>
                            </a>

                            <!-- Delete Book -->
                            <form action="{{ route('admin.books.destroy', $book->id) }}" method="POST" class="inline" data-confirm="Are you sure you want to delete book '{{ addslashes($book->title) }}' and all its paragraphs?">
                                @csrf
                                @method('DELETE')
                                <button type="submit" title="Delete Book" class="p-1.5 text-[#A13B3B] hover:bg-[#FDF2F2] rounded-lg transition inline-flex items-center">
                                    <i class="fa-solid fa-trash text-sm"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="text-center py-12 text-[#7A7569]">
                            <i class="fa-solid fa-book-open text-3xl mb-2 block text-[#D9D2C5]"></i>
                            <p class="font-bold text-sm text-[#16241D]">No books found matching your filters</p>
                            <p class="text-xs text-[#7A7569] mt-1">Try clearing your search keyword or switching category filters</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($books->hasPages())
        <div class="px-6 py-4 border-t border-[#E5DFD3] bg-[#FBF9F4]">
            {{ $books->links() }}
        </div>
        @endif
    </div>
</div>
@endsection
