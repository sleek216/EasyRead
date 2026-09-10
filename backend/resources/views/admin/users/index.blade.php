@extends('admin.layout')

@section('title', 'Users & Readers - Easy Read Studio')
@section('page_title', 'Users & Reader Management')

@section('content')
<div class="space-y-6">

    <!-- Top KPI Strip -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Total Readers</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($totalUsersCount) }}</h3>
                <p class="text-xs text-[#4B6B4A] font-semibold">Registered accounts</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#F3EFE6] text-[#4B6B4A] flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-users"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">VIP Members</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#C28B38]">{{ number_format($premiumUsersCount) }}</h3>
                <p class="text-xs text-[#C28B38] font-semibold">Active subscriptions</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/20 flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-crown"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Free Accounts</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($freeUsersCount) }}</h3>
                <p class="text-xs text-[#7A7569] font-medium">Standard readers</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#F3EFE6] text-[#7A7569] flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-book-open"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Suspended</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#A13B3B]">{{ number_format($inactiveUsersCount) }}</h3>
                <p class="text-xs text-[#A13B3B] font-medium">Deactivated readers</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#FDF2F2] text-[#A13B3B] border border-rose-200 flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-ban"></i>
            </div>
        </div>
    </div>

    <!-- Segmented Tab Filter & Search Header -->
    <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] space-y-4 shadow-xs">
        <!-- Sub-Tabs Navigation -->
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-[#E5DFD3] pb-4">
            <div class="flex flex-wrap items-center gap-1.5 sm:gap-2">
                <a href="{{ route('admin.users.index') }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition {{ ($planFilter === 'all' && $roleFilter === 'all' && $statusFilter === 'all') ? 'bg-[#16241D] text-white shadow-xs' : 'text-[#7A7569] hover:bg-[#F3EFE6] hover:text-[#16241D]' }}">
                    All Users ({{ $totalUsersCount }})
                </a>

                <a href="{{ route('admin.users.index', ['plan' => 'premium']) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition {{ $planFilter === 'premium' ? 'bg-[#C28B38] text-white shadow-xs' : 'text-[#7A7569] hover:bg-[#FFF8EE] hover:text-[#C28B38]' }}">
                    <i class="fa-solid fa-crown mr-1 text-[11px]"></i> VIP ({{ $premiumUsersCount }})
                </a>

                <a href="{{ route('admin.users.index', ['plan' => 'free']) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition {{ $planFilter === 'free' ? 'bg-[#16241D] text-white shadow-xs' : 'text-[#7A7569] hover:bg-[#F3EFE6] hover:text-[#16241D]' }}">
                    Free Tier ({{ $freeUsersCount }})
                </a>

                @if($inactiveUsersCount > 0)
                <a href="{{ route('admin.users.index', ['status' => 'inactive']) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition {{ $statusFilter === 'inactive' ? 'bg-[#A13B3B] text-white shadow-xs' : 'text-[#7A7569] hover:bg-[#FDF2F2] hover:text-[#A13B3B]' }}">
                    Suspended ({{ $inactiveUsersCount }})
                </a>
                @endif

                <a href="{{ route('admin.users.deletions') }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition text-[#A13B3B] hover:bg-[#FDF2F2] hover:text-[#A13B3B]">
                    <i class="fa-solid fa-user-xmark mr-1 text-[11px]"></i> Deleted Accounts ({{ \App\Models\AccountDeletion::count() }})
                </a>
            </div>

            <!-- Create User Action -->
            <button onclick="openAddUserModal()" class="px-4 py-2 bg-[#4B6B4A] hover:bg-[#3A5439] active:scale-[0.99] text-white font-bold text-xs sm:text-sm rounded-xl shadow-xs flex items-center space-x-1.5 transition">
                <i class="fa-solid fa-plus text-xs"></i>
                <span>Add New Reader</span>
            </button>
        </div>

        <!-- Search and Sort Toolbar -->
        <form method="GET" action="{{ route('admin.users.index') }}" class="flex flex-wrap items-center gap-3">
            @if($planFilter !== 'all') <input type="hidden" name="plan" value="{{ $planFilter }}"> @endif
            @if($roleFilter !== 'all') <input type="hidden" name="role" value="{{ $roleFilter }}"> @endif
            @if($statusFilter !== 'all') <input type="hidden" name="status" value="{{ $statusFilter }}"> @endif

            <!-- Search Field -->
            <div class="relative flex-1 min-w-[240px]">
                <i class="fa-solid fa-magnifying-glass absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-xs"></i>
                <input type="text" name="search" value="{{ $search }}" placeholder="Search by reader name, email, or package..."
                       class="w-full pl-10 pr-4 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs sm:text-sm text-[#16241D] placeholder-[#7A7569] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] transition">
                @if($search)
                    <a href="{{ route('admin.users.index', array_filter(['plan' => $planFilter !== 'all' ? $planFilter : null, 'role' => $roleFilter !== 'all' ? $roleFilter : null, 'status' => $statusFilter !== 'all' ? $statusFilter : null])) }}" 
                       class="absolute right-3 top-1/2 -translate-y-1/2 text-[11px] text-[#7A7569] hover:text-[#16241D] font-bold">Clear</a>
                @endif
            </div>

            <!-- Sort Dropdown -->
            <div class="shrink-0">
                <select name="sort" onchange="this.form.submit()" class="px-3.5 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs sm:text-sm text-[#16241D] font-medium focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] transition">
                    <option value="latest" {{ $sort === 'latest' ? 'selected' : '' }}>Sort: Newest First</option>
                    <option value="oldest" {{ $sort === 'oldest' ? 'selected' : '' }}>Sort: Oldest First</option>
                    <option value="name_asc" {{ $sort === 'name_asc' ? 'selected' : '' }}>Sort: Name (A-Z)</option>
                    <option value="most_words" {{ $sort === 'most_words' ? 'selected' : '' }}>Sort: Most Words</option>
                    <option value="most_collections" {{ $sort === 'most_collections' ? 'selected' : '' }}>Sort: Most Collections</option>
                </select>
            </div>
        </form>
    </div>

    <!-- Users Table Card -->
    <div class="bg-white rounded-3xl border border-[#E5DFD3] overflow-hidden shadow-xs">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse min-w-[740px]">
                <thead>
                    <tr class="border-b border-[#E5DFD3] bg-[#FDFBF7] text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">
                        <th class="px-5 py-3.5">Reader</th>
                        <th class="px-4 py-3.5">Email Address</th>
                        <th class="px-4 py-3.5">Subscription Package</th>
                        <th class="px-4 py-3.5">Status</th>
                        <th class="px-4 py-3.5">Joined</th>
                        <th class="px-5 py-3.5 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E5DFD3]/60">
                    @forelse($users as $u)
                    <tr class="hover:bg-[#FAF7F0] transition group">
                        <!-- Reader Name Column (Clickable) -->
                        <td class="px-5 py-3.5 whitespace-nowrap">
                            <a href="{{ route('admin.users.show', $u->id) }}" class="flex items-center space-x-3 group/link">
                                <div class="w-8.5 h-8.5 rounded-full {{ $u->is_premium ? 'bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/30' : 'bg-[#F3EFE6] text-[#4B6B4A]' }} flex items-center justify-center font-bold text-xs shrink-0 group-hover/link:scale-105 transition">
                                    {{ strtoupper(substr($u->name, 0, 2)) }}
                                </div>
                                <div class="font-bold text-[#16241D] text-sm flex items-center space-x-1.5 group-hover/link:text-[#4B6B4A] transition">
                                    <span>{{ $u->name }}</span>
                                    @if($u->role === 'admin')
                                        <span class="px-1.5 py-0.5 rounded text-[9px] font-bold bg-[#E5DFD3] text-[#16241D]">ADMIN</span>
                                    @endif
                                </div>
                            </a>
                        </td>

                        <!-- Email Address Column -->
                        <td class="px-4 py-3.5 whitespace-nowrap text-xs text-[#7A7569] font-medium">
                            {{ $u->email }}
                        </td>

                        <!-- Subscription Package Column (Purchased Package Details) -->
                        <td class="px-4 py-3.5 whitespace-nowrap">
                            @if($u->is_premium)
                                <div class="space-y-0.5">
                                    <span class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/30 inline-flex items-center gap-1">
                                        <i class="fa-solid fa-crown text-[9px]"></i>
                                        <span>{{ $u->subscription_plan ?? ($u->plan->name ?? 'Plus Member') }}</span>
                                    </span>
                                    <span class="block text-[10px] text-[#7A7569] font-medium pl-1">
                                        {{ $u->subscription_price ?? ($u->plan->price ?? '') }}
                                        @if($u->subscription_expires_at)
                                            &bull; exp {{ $u->subscription_expires_at->format('M d, Y') }}
                                        @endif
                                    </span>
                                </div>
                            @else
                                <span class="px-2.5 py-0.5 rounded-full text-xs font-medium bg-[#F3EFE6] text-[#7A7569] inline-flex items-center gap-1">
                                    Free Tier
                                </span>
                            @endif
                        </td>

                        <!-- Status Column -->
                        <td class="px-4 py-3.5 whitespace-nowrap">
                            @if($u->is_active)
                                <span class="px-2 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 inline-flex items-center gap-1">
                                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                    <span>Active</span>
                                </span>
                            @else
                                <span class="px-2 py-0.5 rounded-full text-xs font-bold bg-rose-50 text-rose-700 border border-rose-200 inline-flex items-center gap-1">
                                    <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
                                    <span>Suspended</span>
                                </span>
                            @endif
                        </td>

                        <!-- Joined Date Column -->
                        <td class="px-4 py-3.5 whitespace-nowrap text-xs text-[#7A7569]">
                            {{ $u->created_at->format('M d, Y') }}
                        </td>

                        <!-- Actions Column -->
                        <td class="px-5 py-3.5 text-right space-x-1 whitespace-nowrap">
                            <!-- View / Profile Button -->
                            <a href="{{ route('admin.users.show', $u->id) }}" title="View Reader Profile" class="p-1.5 text-[#5C5649] hover:text-[#16241D] hover:bg-[#F3EFE6] rounded-lg transition inline-flex items-center">
                                <i class="fa-solid fa-eye text-sm"></i>
                            </a>

                            <!-- Edit Button -->
                            <button onclick='openEditUserModal(@json($u))' title="Edit User" class="p-1.5 text-[#5C5649] hover:text-[#16241D] hover:bg-[#F3EFE6] rounded-lg transition inline-flex items-center">
                                <i class="fa-solid fa-pen text-sm"></i>
                            </button>

                            <!-- Status Toggle Button -->
                            <form action="{{ route('admin.users.toggle-status', $u->id) }}" method="POST" class="inline" data-confirm="Are you sure you want to {{ $u->is_active ? 'suspend' : 'activate' }} account for {{ addslashes($u->name) }}?">
                                @csrf
                                <button type="submit" title="{{ $u->is_active ? 'Suspend Reader Account' : 'Activate Reader Account' }}" class="p-1.5 {{ $u->is_active ? 'text-[#7A7569] hover:text-[#A13B3B]' : 'text-emerald-600' }} hover:bg-[#F3EFE6] rounded-lg transition inline-flex items-center">
                                    <i class="fa-solid {{ $u->is_active ? 'fa-ban' : 'fa-check' }} text-sm"></i>
                                </button>
                            </form>

                            <!-- Delete Button -->
                            <form action="{{ route('admin.users.destroy', $u->id) }}" method="POST" class="inline" data-confirm="Permanently delete reader account for '{{ addslashes($u->name) }}'? All personal reading history and dictionary data will be removed.">
                                @csrf
                                @method('DELETE')
                                <button type="submit" title="Delete User" class="p-1.5 text-[#A13B3B] hover:bg-[#FDF2F2] rounded-lg transition inline-flex items-center">
                                    <i class="fa-solid fa-trash text-sm"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="text-center py-12 text-[#7A7569]">
                            <i class="fa-solid fa-user-slash text-3xl mb-2 block text-[#D9D2C5]"></i>
                            <p class="font-bold text-sm text-[#16241D]">No readers found matching your filters</p>
                            <p class="text-xs text-[#7A7569] mt-1">Try clearing your search keyword or switching filter tabs</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($users->hasPages())
        <div class="px-6 py-4 border-t border-[#E5DFD3] bg-[#FBF9F4]">
            {{ $users->links() }}
        </div>
        @endif
    </div>
</div>

<!-- ADD USER MODAL (Clean, Spacious, No AI Quota) -->
<div id="addUserModal" class="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs hidden items-center justify-center p-4 sm:p-6">
    <div class="bg-white rounded-3xl shadow-2xl max-w-lg w-full overflow-hidden border border-[#E5DFD3] animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-[#E5DFD3] bg-[#FDFBF7] flex items-center justify-between">
            <div class="flex items-center space-x-2.5">
                <div class="w-8 h-8 rounded-xl bg-[#4B6B4A] text-white flex items-center justify-center text-xs font-bold shadow-2xs">
                    <i class="fa-solid fa-user-plus"></i>
                </div>
                <h3 class="font-serif font-bold text-base text-[#16241D]">Add New Reader</h3>
            </div>
            <button onclick="closeAddUserModal()" class="text-gray-400 hover:text-gray-600 p-1"><i class="fa-solid fa-xmark text-lg"></i></button>
        </div>

        <form action="{{ route('admin.users.store') }}" method="POST" class="p-6 space-y-4">
            @csrf
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Full Name *</label>
                    <input type="text" name="name" required placeholder="e.g. Elena Rostova" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                </div>

                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Email Address *</label>
                    <input type="email" name="email" required placeholder="user@gmail.com" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                </div>
            </div>

            <div class="space-y-1">
                <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Password *</label>
                <input type="password" name="password" required minlength="6" placeholder="Min 6 characters" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
            </div>

            <input type="hidden" name="role" value="user">

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Account Role</label>
                    <div class="w-full px-3.5 py-2.5 bg-[#F3EFE6]/60 border border-[#E5DFD3] rounded-xl text-sm font-semibold text-[#16241D] flex items-center justify-between">
                        <span>Reader (App User)</span>
                        <span class="text-[10px] font-bold uppercase tracking-wider text-[#4B6B4A] bg-[#4B6B4A]/10 px-2 py-0.5 rounded-md">Mobile Reader</span>
                    </div>
                </div>
                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Status</label>
                    <select name="is_active" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                        <option value="1">Active Account</option>
                        <option value="0">Suspended</option>
                    </select>
                </div>
            </div>

            <div class="space-y-1">
                <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Subscription Package</label>
                <select name="plan_id" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                    @foreach($plans as $plan)
                        <option value="{{ $plan->id }}">{{ $plan->name }} - {{ $plan->price }} ({{ $plan->billing_period }})</option>
                    @endforeach
                </select>
            </div>

            <div class="pt-3 border-t border-[#E5DFD3] flex items-center justify-end space-x-2.5">
                <button type="button" onclick="closeAddUserModal()" class="px-4 py-2 rounded-xl border border-[#E5DFD3] text-xs font-semibold text-[#5C5649] hover:bg-[#F3EFE6]">Cancel</button>
                <button type="submit" class="px-5 py-2 rounded-xl bg-[#4B6B4A] hover:bg-[#3A5439] text-white font-bold text-xs shadow-xs">Create Account</button>
            </div>
        </form>
    </div>
</div>

<!-- EDIT USER MODAL (Clean, Spacious, No AI Quota) -->
<div id="editUserModal" class="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs hidden items-center justify-center p-4 sm:p-6">
    <div class="bg-white rounded-3xl shadow-2xl max-w-lg w-full overflow-hidden border border-[#E5DFD3] animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-[#E5DFD3] bg-[#FDFBF7] flex items-center justify-between">
            <div class="flex items-center space-x-2.5">
                <div class="w-8 h-8 rounded-xl bg-[#C28B38] text-white flex items-center justify-center text-xs font-bold shadow-2xs">
                    <i class="fa-solid fa-user-pen"></i>
                </div>
                <h3 class="font-serif font-bold text-base text-[#16241D]">Edit Reader Details</h3>
            </div>
            <button onclick="closeEditUserModal()" class="text-gray-400 hover:text-gray-600 p-1"><i class="fa-solid fa-xmark text-lg"></i></button>
        </div>

        <form id="editUserForm" method="POST" class="p-6 space-y-4">
            @csrf
            @method('PUT')
            
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Full Name *</label>
                    <input type="text" id="edit_name" name="name" required class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                </div>

                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Email Address *</label>
                    <input type="email" id="edit_email" name="email" required class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                </div>
            </div>

            <input type="hidden" id="edit_role" name="role" value="user">

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Account Role</label>
                    <div class="w-full px-3.5 py-2.5 bg-[#F3EFE6]/60 border border-[#E5DFD3] rounded-xl text-sm font-semibold text-[#16241D] flex items-center justify-between">
                        <span>Reader (App User)</span>
                        <span class="text-[10px] font-bold uppercase tracking-wider text-[#4B6B4A] bg-[#4B6B4A]/10 px-2 py-0.5 rounded-md">Mobile Reader</span>
                    </div>
                </div>

                <div class="space-y-1">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Status</label>
                    <select id="edit_is_active" name="is_active" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                        <option value="1">Active Account</option>
                        <option value="0">Suspended</option>
                    </select>
                </div>
            </div>

            <div class="space-y-1.5">
                <div class="flex items-center justify-between">
                    <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Subscription Package</label>
                    <span id="edit_current_plan_badge" class="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/30"></span>
                </div>
                <select id="edit_plan_id" name="plan_id" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                    @foreach($plans as $plan)
                        <option value="{{ $plan->id }}">{{ $plan->name }} - {{ $plan->price }} ({{ $plan->billing_period }})</option>
                    @endforeach
                </select>
            </div>

            <div class="space-y-1">
                <label class="block text-[11px] font-bold text-[#16241D] uppercase tracking-wider">Reset Password <span class="font-normal text-[#7A7569] lowercase">(optional)</span></label>
                <input type="password" name="password" minlength="6" placeholder="Leave blank to keep unchanged" class="w-full px-3.5 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
            </div>

            <div class="pt-3 border-t border-[#E5DFD3] flex items-center justify-end space-x-2.5">
                <button type="button" onclick="closeEditUserModal()" class="px-4 py-2 rounded-xl border border-[#E5DFD3] text-xs font-semibold text-[#5C5649] hover:bg-[#F3EFE6]">Cancel</button>
                <button type="submit" class="px-5 py-2 rounded-xl bg-[#4B6B4A] hover:bg-[#3A5439] text-white font-bold text-xs shadow-xs">Save Changes</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openAddUserModal() {
        const modal = document.getElementById('addUserModal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
    function closeAddUserModal() {
        const modal = document.getElementById('addUserModal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }

    function openEditUserModal(user) {
        const form = document.getElementById('editUserForm');
        form.action = `/admin/users/${user.id}`;
        document.getElementById('edit_name').value = user.name;
        document.getElementById('edit_email').value = user.email;
        document.getElementById('edit_role').value = user.role;
        document.getElementById('edit_is_active').value = user.is_active ? '1' : '0';
        
        // Subscription package selection & current plan badge
        const planSelect = document.getElementById('edit_plan_id');
        const badge = document.getElementById('edit_current_plan_badge');
        let currentPlanName = user.subscription_plan || (user.plan ? user.plan.name : (user.is_premium ? 'VIP Plan' : 'Free Tier'));
        badge.innerText = `Current: ${currentPlanName}`;

        let selectedIndex = 0;
        let matched = false;
        
        if (user.plan_id) {
            for (let i = 0; i < planSelect.options.length; i++) {
                if (String(planSelect.options[i].value) === String(user.plan_id)) {
                    selectedIndex = i;
                    matched = true;
                    break;
                }
            }
        }
        
        if (!matched && user.subscription_plan) {
            const cleanSubPlan = user.subscription_plan.trim().toLowerCase();
            for (let i = 0; i < planSelect.options.length; i++) {
                const optText = planSelect.options[i].text.trim().toLowerCase();
                if (optText.startsWith(cleanSubPlan) || optText.includes(cleanSubPlan)) {
                    selectedIndex = i;
                    matched = true;
                    break;
                }
            }
        }
        
        if (!matched && !user.is_premium) {
            // Find Free Tier option
            for (let i = 0; i < planSelect.options.length; i++) {
                if (planSelect.options[i].text.toLowerCase().includes('free')) {
                    selectedIndex = i;
                    break;
                }
            }
        }
        planSelect.selectedIndex = selectedIndex;
        
        const modal = document.getElementById('editUserModal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
    function closeEditUserModal() {
        const modal = document.getElementById('editUserModal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
</script>
@endsection
