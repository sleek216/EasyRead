@extends('admin.layout')

@section('title', $user->name . ' - Reader Profile - Easy Read Studio')
@section('page_title', 'Reader Profile: ' . $user->name)

@section('content')
<div class="space-y-7">

    <!-- Top Breadcrumb & Action Bar -->
    <div class="flex flex-wrap items-center justify-between gap-4">
        <div class="flex items-center space-x-2 text-xs font-semibold text-[#7A7569]">
            <a href="{{ route('admin.users.index') }}" class="hover:text-[#16241D] flex items-center gap-1.5 transition">
                <i class="fa-solid fa-arrow-left text-[11px]"></i>
                <span>Users & Readers</span>
            </a>
            <span>/</span>
            <span class="text-[#16241D]">{{ $user->name }}</span>
            @if($user->role === 'admin')
                <span class="ml-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-[#E5DFD3] text-[#16241D]">ADMIN</span>
            @endif
        </div>

        <div class="flex flex-wrap items-center gap-2.5">
            <!-- Edit Profile Trigger -->
            <button onclick="openEditModal()" class="px-3.5 py-2 rounded-xl text-xs font-bold border border-[#E5DFD3] bg-white text-[#16241D] hover:bg-[#F3EFE6] transition flex items-center gap-1.5 shadow-2xs">
                <i class="fa-solid fa-pen text-[11px]"></i>
                <span>Edit Account</span>
            </button>


            <!-- Toggle Status (Activate / Suspend) -->
            <form action="{{ route('admin.users.toggle-status', $user->id) }}" method="POST" class="inline" data-confirm="Are you sure you want to {{ $user->is_active ? 'suspend' : 'activate' }} reader '{{ addslashes($user->name) }}'?">
                @csrf
                <button type="submit" class="px-3.5 py-2 rounded-xl text-xs font-bold {{ $user->is_active ? 'border-rose-200 bg-[#FDF2F2] text-[#A13B3B] hover:bg-rose-100' : 'border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100' }} transition flex items-center gap-1.5 shadow-2xs">
                    <i class="fa-solid {{ $user->is_active ? 'fa-ban' : 'fa-check' }} text-[11px]"></i>
                    <span>{{ $user->is_active ? 'Suspend Reader' : 'Activate Reader' }}</span>
                </button>
            </form>

            <!-- Delete User -->
            <form action="{{ route('admin.users.destroy', $user->id) }}" method="POST" class="inline" data-confirm="Are you sure you want to delete reader '{{ addslashes($user->name) }}'? All personal reading data will be removed permanently.">
                @csrf
                @method('DELETE')
                <button type="submit" class="p-2 rounded-xl text-xs font-bold text-gray-400 hover:text-rose-600 hover:bg-rose-50 transition" title="Delete User">
                    <i class="fa-solid fa-trash-can text-sm"></i>
                </button>
            </form>
        </div>
    </div>

    @if(isset($pastDeletions) && $pastDeletions->isNotEmpty())
    <div class="flex justify-end mb-4">
        <a href="{{ route('admin.users.deletions', ['search' => $user->email]) }}" class="text-xs font-semibold text-[#7A7569] hover:text-[#16241D] transition flex items-center gap-1.5 bg-white border border-[#E5DFD3] px-3 py-1.5 rounded-lg shadow-sm">
            <i class="fa-solid fa-clock-rotate-left"></i>
            <span>View User Logs ({{ $pastDeletions->count() }} past {{ Str::plural('deletion', $pastDeletions->count()) }})</span>
        </a>
    </div>
    @endif

    <!-- Top KPI Grid: Subscription, Collections, Reading, & Words -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <!-- 1. Subscription Package -->
        <div class="bg-white p-5 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-2">
            <div class="flex items-center justify-between">
                <span class="text-[11px] font-bold uppercase tracking-wider text-[#7A7569]">Subscription Package</span>
                <span class="w-8 h-8 rounded-xl {{ $user->is_premium ? 'bg-[#FFF8EE] text-[#C28B38]' : 'bg-[#F3EFE6] text-[#7A7569]' }} flex items-center justify-center text-sm">
                    <i class="fa-solid fa-crown"></i>
                </span>
            </div>
            <div>
                <h4 class="text-xl font-bold font-serif {{ $user->is_premium ? 'text-[#C28B38]' : 'text-[#16241D]' }}">
                    {{ $user->subscription_plan ?? ($user->is_premium ? 'Plus VIP' : 'Free Tier') }}
                </h4>
                <p class="text-xs text-[#7A7569] font-medium mt-0.5">
                    @if($user->is_premium)
                        {{ $user->subscription_price ?? 'Paid' }} &bull;
                        @if($user->subscription_expires_at)
                            Expires {{ $user->subscription_expires_at->format('M d, Y') }}
                        @else
                            Active Lifetime
                        @endif
                    @else
                        Standard Free Account
                    @endif
                </p>
            </div>
        </div>

        <!-- 2. Custom Collections -->
        <div class="bg-white p-5 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-2">
            <div class="flex items-center justify-between">
                <span class="text-[11px] font-bold uppercase tracking-wider text-[#7A7569]">User Collections</span>
                <span class="w-8 h-8 rounded-xl bg-[#F3EFE6] text-[#4B6B4A] flex items-center justify-center text-sm">
                    <i class="fa-solid fa-folder-open"></i>
                </span>
            </div>
            <div>
                <h4 class="text-xl font-bold font-serif text-[#16241D]">
                    {{ $stats['collections_count'] }} <span class="text-sm font-normal text-[#7A7569]">Shelves</span>
                </h4>
                <p class="text-xs text-[#4B6B4A] font-semibold mt-0.5">
                    {{ $stats['books_in_collections'] }} total books organized
                </p>
            </div>
        </div>

        <!-- 3. Reading Activity -->
        <div class="bg-white p-5 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-2">
            <div class="flex items-center justify-between">
                <span class="text-[11px] font-bold uppercase tracking-wider text-[#7A7569]">Reading Books</span>
                <span class="w-8 h-8 rounded-xl bg-[#F0F5FA] text-[#2E4C6D] flex items-center justify-center text-sm">
                    <i class="fa-solid fa-book-reader"></i>
                </span>
            </div>
            <div>
                <h4 class="text-xl font-bold font-serif text-[#16241D]">
                    {{ $stats['reading_count'] }} <span class="text-sm font-normal text-[#7A7569]">In Progress</span>
                </h4>
                <p class="text-xs text-[#2E4C6D] font-semibold mt-0.5">
                    {{ $stats['favorites_count'] }} favorites &bull; {{ $stats['bookmarks_count'] }} bookmarked
                </p>
            </div>
        </div>

        <!-- 4. Saved Vocabulary & AI Quota -->
        <div class="bg-white p-5 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-2">
            <div class="flex items-center justify-between">
                <span class="text-[11px] font-bold uppercase tracking-wider text-[#7A7569]">Saved Vocabulary</span>
                <span class="w-8 h-8 rounded-xl bg-[#FAF0F5] text-[#7A3E65] flex items-center justify-center text-sm">
                    <i class="fa-solid fa-spell-check"></i>
                </span>
            </div>
            <div>
                <h4 class="text-xl font-bold font-serif text-[#16241D]">
                    {{ $stats['vocab_count'] }} <span class="text-sm font-normal text-[#7A7569]">Words</span>
                </h4>
                <p class="text-xs text-[#7A3E65] font-semibold mt-0.5">
                    {{ $stats['mastered_vocab_count'] }} mastered words
                </p>
            </div>
        </div>
    </div>

    <!-- Main Content Layout (2 Columns) -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-7 items-start">

        <!-- LEFT COLUMN (2 Cols): User Collections with Books & Reading Activity -->
        <div class="lg:col-span-2 space-y-7">

            <!-- SECTION A: USER CUSTOM COLLECTIONS & BOOKS IN EACH (Core User Requirement) -->
            <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-6 sm:p-7 space-y-5">
                <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
                    <div>
                        <h3 class="font-serif font-bold text-lg text-[#16241D] flex items-center gap-2">
                            <i class="fa-solid fa-folder-open text-[#4B6B4A]"></i>
                            <span>User Custom Collections & Books</span>
                        </h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">
                            Custom folders created by this reader and books organized inside each shelf
                        </p>
                    </div>
                    <span class="px-3 py-1 bg-[#F3EFE6] text-[#4B6B4A] rounded-full text-xs font-bold">
                        {{ $user->collections->count() }} Collections
                    </span>
                </div>

                @if($user->collections->isEmpty())
                    <div class="py-10 text-center space-y-3">
                        <div class="w-14 h-14 rounded-2xl bg-[#F3EFE6] text-[#7A7569] flex items-center justify-center mx-auto text-xl">
                            <i class="fa-solid fa-folder-plus"></i>
                        </div>
                        <div>
                            <h4 class="font-bold text-sm text-[#16241D]">No Custom Collections Yet</h4>
                            <p class="text-xs text-[#7A7569] mt-1 max-w-sm mx-auto">
                                When {{ $user->name }} creates custom shelves in the mobile app (e.g. "Favorites", "Night Reads", "Research"), they will appear here with all categorized books.
                            </p>
                        </div>
                    </div>
                @else
                    <div class="space-y-4">
                        @foreach($user->collections as $col)
                        <div class="rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] p-5 space-y-3.5 transition hover:border-[#4B6B4A]/50">
                            <!-- Collection Header Card -->
                            <div class="flex flex-wrap items-center justify-between gap-2 border-b border-[#E5DFD3]/70 pb-3">
                                <div class="flex items-center space-x-3">
                                    <div class="w-8 h-8 rounded-xl flex items-center justify-center text-white text-xs font-bold shadow-2xs"
                                         style="background-color: {{ $col->color_hex ?? '#4B6B4A' }}">
                                        <i class="fa-solid fa-folder"></i>
                                    </div>
                                    <div>
                                        <h4 class="font-bold text-sm text-[#16241D] flex items-center gap-2">
                                            <span>{{ $col->name }}</span>
                                            <span class="text-[11px] font-mono text-[#7A7569] font-normal">#{{ $col->tag }}</span>
                                        </h4>
                                        <p class="text-[11px] text-[#7A7569]">
                                            Created {{ $col->created_at->format('M d, Y') }}
                                        </p>
                                    </div>
                                </div>

                                <div class="flex items-center gap-2">
                                    <span class="px-2.5 py-1 rounded-lg text-xs font-bold bg-white border border-[#E5DFD3] text-[#16241D]">
                                        {{ $col->books->count() }} {{ Str::plural('book', $col->books->count()) }}
                                    </span>
                                </div>
                            </div>

                            <!-- Books Inside this Collection -->
                            @if($col->books->isEmpty())
                                <div class="py-4 text-center text-xs text-[#7A7569] italic">
                                    No books currently linked to this collection shelf.
                                </div>
                            @else
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                                    @foreach($col->books as $bk)
                                    <div class="bg-white p-3.5 rounded-xl border border-[#E5DFD3] flex items-start justify-between gap-3 shadow-2xs">
                                        <div class="space-y-1 min-w-0">
                                            <div class="flex items-center gap-1.5">
                                                <span class="w-2 h-2 rounded-full bg-[#4B6B4A]"></span>
                                                <h5 class="font-bold text-xs text-[#16241D] truncate" title="{{ $bk->title }}">
                                                    {{ $bk->title }}
                                                </h5>
                                            </div>
                                            <p class="text-[11px] text-[#7A7569] truncate">
                                                by {{ $bk->author ?? 'Unknown' }}
                                            </p>
                                            <div class="flex items-center gap-2 pt-1 text-[10px] text-[#7A7569]">
                                                <span class="px-1.5 py-0.5 rounded bg-[#F3EFE6] text-[#16241D] font-medium">
                                                    {{ $bk->category ?? 'General' }}
                                                </span>
                                                <span>&bull;</span>
                                                <span>{{ $bk->paragraphs_count ?? $bk->paragraphs()->count() }} paras</span>
                                                <span>&bull;</span>
                                                <span>{{ $bk->read_time ?? '5 min' }}</span>
                                            </div>
                                        </div>

                                        <a href="{{ route('admin.books.edit', $bk->id) }}" target="_blank" class="p-1.5 text-gray-400 hover:text-[#4B6B4A] rounded-lg transition shrink-0" title="Edit book">
                                            <i class="fa-solid fa-arrow-up-right-from-square text-xs"></i>
                                        </a>
                                    </div>
                                    @endforeach
                                </div>
                            @endif
                        </div>
                        @endforeach
                    </div>
                @endif
            </div>

            <!-- SECTION B: ACTIVE READING ACTIVITY & PROGRESS SHELF -->
            <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-6 sm:p-7 space-y-5">
                <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
                    <div>
                        <h3 class="font-serif font-bold text-lg text-[#16241D] flex items-center gap-2">
                            <i class="fa-solid fa-book-open-reader text-[#2E4C6D]"></i>
                            <span>Reading Progress & Activity Shelf</span>
                        </h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">
                            Real-time sync of books this user is reading in the mobile app
                        </p>
                    </div>
                    <span class="px-3 py-1 bg-[#F0F5FA] text-[#2E4C6D] rounded-full text-xs font-bold">
                        {{ $user->readingProgress->count() }} Books
                    </span>
                </div>

                @if($user->readingProgress->isEmpty())
                    <div class="py-8 text-center text-xs text-[#7A7569] space-y-2">
                        <i class="fa-solid fa-book text-gray-300 text-2xl block"></i>
                        <p>No active reading progress synced yet.</p>
                    </div>
                @else
                    <div class="space-y-3">
                        @foreach($user->readingProgress as $prog)
                        <div class="p-4 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] flex flex-wrap items-center justify-between gap-4">
                            <div class="space-y-1 min-w-[200px]">
                                <div class="flex items-center space-x-2">
                                    <h4 class="font-bold text-sm text-[#16241D]">
                                        {{ $prog->book->title ?? 'Untitled Book #' . $prog->book_id }}
                                    </h4>
                                    @if($prog->is_favorite)
                                        <span class="text-amber-500 text-xs" title="Favorite"><i class="fa-solid fa-star"></i></span>
                                    @endif
                                    @if($prog->is_bookmarked)
                                        <span class="text-rose-500 text-xs" title="Bookmarked"><i class="fa-solid fa-bookmark"></i></span>
                                    @endif
                                </div>
                                <p class="text-xs text-[#7A7569]">
                                    Author: {{ $prog->book->author ?? 'Unknown' }} &bull; Last read {{ $prog->updated_at->diffForHumans() }}
                                </p>
                            </div>

                            <div class="flex items-center space-x-4">
                                <div class="w-32 space-y-1">
                                    <div class="flex justify-between text-[11px] font-bold text-[#16241D]">
                                        <span>Progress</span>
                                        <span>{{ $prog->progress_percent }}%</span>
                                    </div>
                                    <div class="w-full h-2 rounded-full bg-[#E5DFD3] overflow-hidden">
                                        <div class="h-full rounded-full bg-[#4B6B4A]" style="width: {{ $prog->progress_percent }}%"></div>
                                    </div>
                                </div>

                                <span class="px-2.5 py-1 rounded-lg text-xs font-semibold bg-white border border-[#E5DFD3] text-[#7A7569]">
                                    Para {{ $prog->current_paragraph }}
                                </span>
                            </div>
                        </div>
                        @endforeach
                    </div>
                @endif
            </div>

            <!-- SECTION C: SAVED VOCABULARY WORDS -->
            <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-6 sm:p-7 space-y-4">
                <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
                    <div>
                        <h3 class="font-serif font-bold text-lg text-[#16241D] flex items-center gap-2">
                            <i class="fa-solid fa-spell-check text-[#7A3E65]"></i>
                            <span>Saved Vocabulary ({{ $user->vocabularies->count() }})</span>
                        </h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">Words looked up and saved into reader's personal vocabulary bank</p>
                    </div>
                </div>

                @if($user->vocabularies->isEmpty())
                    <div class="py-6 text-center text-xs text-[#7A7569]">
                        No vocabulary words saved yet by this reader.
                    </div>
                @else
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        @foreach($user->vocabularies as $vocab)
                        <div class="p-3.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] space-y-1">
                            <div class="flex items-center justify-between">
                                <h5 class="font-bold text-sm text-[#16241D]">{{ $vocab->word }}</h5>
                                <span class="text-[10px] font-mono px-1.5 py-0.5 rounded {{ $vocab->is_mastered ? 'bg-emerald-100 text-emerald-800' : 'bg-[#E5DFD3] text-[#7A7569]' }}">
                                    {{ $vocab->is_mastered ? 'Mastered' : 'Learning' }}
                                </span>
                            </div>
                            @if($vocab->pos)
                                <span class="text-[11px] italic text-[#7A7569]">{{ $vocab->pos }}</span>
                            @endif
                            <p class="text-xs text-[#16241D] line-clamp-2">{{ $vocab->meaning }}</p>
                        </div>
                        @endforeach
                    </div>
                @endif
            </div>

        </div>

        <!-- RIGHT COLUMN (1 Col): Subscription Manager & Account Info -->
        <div class="space-y-6">

            <!-- 1. MANAGE SUBSCRIPTION PACKAGE (Direct Admin Control) -->
            <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-6 space-y-5">
                <div class="border-b border-[#E5DFD3] pb-3">
                    <h3 class="font-serif font-bold text-base text-[#16241D] flex items-center gap-2">
                        <i class="fa-solid fa-crown text-[#C28B38]"></i>
                        <span>Manage Subscription</span>
                    </h3>
                    <p class="text-xs text-[#7A7569] mt-0.5">Assign or change package for this user</p>
                </div>

                <form action="{{ route('admin.users.assign-plan', $user->id) }}" method="POST" class="space-y-4">
                    @csrf
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D] mb-1.5">
                            Subscription Package
                        </label>
                        <select name="plan_id" class="w-full px-3.5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                            @foreach($plans as $plan)
                                @php
                                    $isSelected = false;
                                    if ($user->plan_id) {
                                        $isSelected = ($user->plan_id == $plan->id);
                                    } elseif ($user->is_premium) {
                                        $isSelected = ($user->subscription_plan == $plan->name);
                                    } else {
                                        $isSelected = str_contains(strtolower($plan->name), 'free') || strtolower($plan->price) === 'free';
                                    }
                                @endphp
                                <option value="{{ $plan->id }}" {{ $isSelected ? 'selected' : '' }}>
                                    {{ $plan->name }} - {{ $plan->price }} ({{ $plan->billing_period }})
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D] mb-1.5">
                            Custom Duration (Days) <span class="text-gray-400 font-normal">(Optional)</span>
                        </label>
                        <input type="number" name="custom_duration_days" placeholder="Leave empty for plan default" class="w-full px-3.5 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                    </div>

                    <button type="submit" class="w-full py-2.5 rounded-xl bg-[#4B6B4A] hover:bg-[#3A5439] text-white text-xs font-bold tracking-wider uppercase transition shadow-xs">
                        Update Package
                    </button>
                </form>

                <!-- Current Plan Expiry Details -->
                @if($user->is_premium && $user->subscription_expires_at)
                <div class="p-3.5 rounded-xl bg-[#FFF8EE] border border-[#C28B38]/30 text-xs space-y-1">
                    <span class="font-bold text-[#C28B38] block">Subscription Schedule</span>
                    <p class="text-[#16241D]">
                        Started: {{ $user->subscription_starts_at?->format('M d, Y') ?? 'N/A' }}
                    </p>
                    <p class="text-[#16241D]">
                        Expires: {{ $user->subscription_expires_at->format('M d, Y') }} 
                        <span class="font-bold text-[#C28B38]">({{ $user->subscription_expires_at->diffForHumans() }})</span>
                    </p>
                </div>
                @endif
            </div>

            <!-- 2. ACCOUNT & DEVICE INFORMATION -->
            <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-6 space-y-4">
                <div class="border-b border-[#E5DFD3] pb-3">
                    <h3 class="font-serif font-bold text-base text-[#16241D]">Account & Security</h3>
                    <p class="text-xs text-[#7A7569] mt-0.5">Mobile device metadata & authentication</p>
                </div>

                <div class="space-y-3 text-xs">
                    <div class="flex items-center justify-between py-1 border-b border-[#E5DFD3]/50">
                        <span class="text-[#7A7569] shrink-0">Reader ID</span>
                        <span class="font-mono font-bold text-[#16241D]">#{{ $user->id }}</span>
                    </div>
                    <div class="flex items-center justify-between py-1 border-b border-[#E5DFD3]/50 gap-2">
                        <span class="text-[#7A7569] shrink-0">Email Address</span>
                        <span class="font-medium text-[#16241D] truncate text-right text-[11.5px]" title="{{ $user->email }}">{{ $user->email }}</span>
                    </div>
                    <div class="flex items-center justify-between py-1 border-b border-[#E5DFD3]/50">
                        <span class="text-[#7A7569] shrink-0">Account Status</span>
                        @if($user->is_active)
                            <span class="font-bold text-emerald-700 flex items-center gap-1">
                                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span> Active
                            </span>
                        @else
                            <span class="font-bold text-[#A13B3B] flex items-center gap-1">
                                <span class="w-1.5 h-1.5 rounded-full bg-[#A13B3B]"></span> Suspended
                            </span>
                        @endif
                    </div>
                    <div class="flex items-center justify-between py-1 border-b border-[#E5DFD3]/50">
                        <span class="text-[#7A7569] shrink-0">Joined Platform</span>
                        <span class="text-[#16241D]">{{ $user->created_at->format('M d, Y (h:i A)') }}</span>
                    </div>
                    <div class="flex items-center justify-between py-1 border-b border-[#E5DFD3]/50">
                        <span class="text-[#7A7569] shrink-0">Last Active</span>
                        <span class="text-[#16241D]">{{ $user->last_active_at ? $user->last_active_at->diffForHumans() : 'Never' }}</span>
                    </div>
                    <div class="flex items-center justify-between py-1 border-b border-[#E5DFD3]/50">
                        <span class="text-[#7A7569] shrink-0">Device</span>
                        <span class="text-[#16241D]">{{ $user->device_name ?? 'Android / iOS App' }}</span>
                    </div>
                    <div class="flex items-center justify-between py-1">
                        <span class="text-[#7A7569] shrink-0">Active Sessions</span>
                        <span class="font-bold text-[#16241D]">{{ $user->tokens->count() }} tokens</span>
                    </div>
                </div>
            </div>

            <!-- 3. CLOUD BACKUPS -->
            <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-6 space-y-3">
                <h3 class="font-serif font-bold text-base text-[#16241D] flex items-center justify-between">
                    <span>Cloud Backups</span>
                    <span class="text-xs font-mono font-bold text-[#7A7569]">{{ $user->backups->count() }} snapshots</span>
                </h3>
                @if($user->backups->isEmpty())
                    <p class="text-xs text-[#7A7569]">No cloud backups stored.</p>
                @else
                    <div class="space-y-2 text-xs">
                        @foreach($user->backups as $bk)
                        <div class="p-2.5 rounded-xl bg-[#FDFBF7] border border-[#E5DFD3] flex items-center justify-between">
                            <span class="text-[#16241D] font-medium">{{ $bk->created_at->format('M d, Y') }}</span>
                            <span class="text-[#7A7569]">{{ $bk->created_at->format('h:i A') }}</span>
                        </div>
                        @endforeach
                    </div>
                @endif
            </div>

        </div>

    </div>

</div>

<!-- EDIT USER MODAL -->
<div id="editUserModal" class="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs hidden items-center justify-center p-4">
    <div class="bg-white rounded-3xl max-w-lg w-full p-6 sm:p-7 space-y-5 shadow-2xl border border-[#E5DFD3]">
        <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-3.5">
            <h3 class="font-serif font-bold text-lg text-[#16241D]">Edit Reader Details</h3>
            <button onclick="closeEditModal()" class="text-gray-400 hover:text-gray-600 p-1">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>

        <form action="{{ route('admin.users.update', $user->id) }}" method="POST" class="space-y-4">
            @csrf
            @method('PUT')

            <div class="space-y-1">
                <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Full Name *</label>
                <input type="text" name="name" value="{{ $user->name }}" required class="w-full px-3.5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D]">
            </div>

            <div class="space-y-1">
                <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Email Address *</label>
                <input type="email" name="email" value="{{ $user->email }}" required class="w-full px-3.5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D]">
            </div>

            <div class="grid grid-cols-2 gap-4">
                <div class="space-y-1">
                    <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Role *</label>
                    <select name="role" class="w-full px-3.5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D]">
                        <option value="user" {{ $user->role === 'user' ? 'selected' : '' }}>Reader</option>
                        <option value="admin" {{ $user->role === 'admin' ? 'selected' : '' }}>Administrator</option>
                    </select>
                </div>

                <div class="space-y-1">
                    <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Status *</label>
                    <select name="is_active" class="w-full px-3.5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D]">
                        <option value="1" {{ $user->is_active ? 'selected' : '' }}>Active</option>
                        <option value="0" {{ !$user->is_active ? 'selected' : '' }}>Suspended</option>
                    </select>
                </div>
            </div>

            <div class="space-y-1">
                <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Subscription Package *</label>
                <select name="plan_id" class="w-full px-3.5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D]">
                    <option value="free" {{ !$user->is_premium ? 'selected' : '' }}>Free Tier</option>
                    @foreach($plans as $plan)
                        <option value="{{ $plan->id }}" {{ ($user->plan_id == $plan->id || $user->subscription_plan == $plan->name) ? 'selected' : '' }}>
                            {{ $plan->name }} ({{ $plan->price }})
                        </option>
                    @endforeach
                </select>
            </div>


            <div class="space-y-1">
                <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Reset Password (Optional)</label>
                <input type="password" name="password" placeholder="Leave blank to keep current password" class="w-full px-3.5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D]">
            </div>

            <div class="flex items-center justify-end space-x-3 pt-3 border-t border-[#E5DFD3]">
                <button type="button" onclick="closeEditModal()" class="px-4 py-2 rounded-xl text-xs font-bold text-[#7A7569] hover:bg-gray-100">Cancel</button>
                <button type="submit" class="px-5 py-2 rounded-xl bg-[#4B6B4A] hover:bg-[#3A5439] text-white text-xs font-bold">Save Changes</button>
            </div>
        </form>
    </div>
</div>

<script>
function openEditModal() {
    document.getElementById('editUserModal').classList.remove('hidden');
    document.getElementById('editUserModal').classList.add('flex');
}
function closeEditModal() {
    document.getElementById('editUserModal').classList.add('hidden');
    document.getElementById('editUserModal').classList.remove('flex');
}
</script>
@endsection
