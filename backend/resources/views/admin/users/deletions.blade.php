@extends('admin.layout')

@section('title', 'Deleted Accounts Audit - Easy Read Studio')
@section('page_title', 'Deleted Accounts & Audit Logs')

@section('content')
<div class="space-y-6">

    <!-- Top KPI Strip -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Total Deletions</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#A13B3B]">{{ number_format($metrics['total_deletions']) }}</h3>
                <p class="text-xs text-[#A13B3B] font-semibold">Account deletion events</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#FDF2F2] text-[#A13B3B] border border-rose-200 flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-user-xmark"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Unique Users Deleted</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">{{ number_format($metrics['unique_emails_deleted']) }}</h3>
                <p class="text-xs text-[#7A7569] font-medium">Distinct email accounts</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#F3EFE6] text-[#7A7569] flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-users-slash"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">Re-Registered</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#4B6B4A]">{{ number_format($metrics['re_registered_count']) }}</h3>
                <p class="text-xs text-[#4B6B4A] font-semibold">Signed up again after deletion</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#EDF5EE] text-[#4B6B4A] border border-emerald-200 flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-user-check"></i>
            </div>
        </div>

        <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] flex items-center justify-between shadow-xs">
            <div class="space-y-1">
                <p class="text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">This Month</p>
                <h3 class="text-2xl sm:text-3xl font-bold font-serif text-[#C28B38]">{{ number_format($metrics['deletions_this_month']) }}</h3>
                <p class="text-xs text-[#C28B38] font-medium">{{ now()->format('F Y') }}</p>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-[#FFF8EE] text-[#C28B38] border border-[#C28B38]/20 flex items-center justify-center text-lg font-bold shrink-0">
                <i class="fa-solid fa-calendar-xmark"></i>
            </div>
        </div>
    </div>

    <!-- Main Table Container -->
    <div class="bg-white p-5 sm:p-6 rounded-3xl border border-[#E5DFD3] space-y-4 shadow-xs">
        
        <!-- Navigation Tabs -->
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-[#E5DFD3] pb-4">
            <div class="flex flex-wrap items-center gap-1.5 sm:gap-2">
                <a href="{{ route('admin.users.index') }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition text-[#7A7569] hover:bg-[#F3EFE6] hover:text-[#16241D]">
                    <i class="fa-solid fa-users mr-1 text-[11px]"></i> All Active Users
                </a>

                <a href="{{ route('admin.users.deletions') }}" 
                   class="px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition bg-[#A13B3B] text-white shadow-xs">
                    <i class="fa-solid fa-user-xmark mr-1 text-[11px]"></i> Deleted Accounts Log ({{ $metrics['total_deletions'] }})
                </a>
            </div>

            <!-- Search Form -->
            <form method="GET" action="{{ route('admin.users.deletions') }}" class="flex items-center gap-2">
                <div class="relative">
                    <input type="text" 
                           name="search" 
                           value="{{ $search }}" 
                           placeholder="Search by name, email, IP..." 
                           class="pl-9 pr-3 py-1.5 bg-[#F9F6F0] border border-[#E5DFD3] rounded-xl text-xs sm:text-sm text-[#16241D] placeholder-[#7A7569] focus:outline-hidden focus:ring-1 focus:ring-[#4B6B4A] focus:border-[#4B6B4A] w-64 sm:w-72">
                    <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-xs text-[#7A7569]"></i>
                </div>
                @if($search)
                    <a href="{{ route('admin.users.deletions') }}" class="p-2 text-xs text-[#7A7569] hover:text-[#16241D] rounded-xl hover:bg-[#F3EFE6]" title="Clear Search">
                        <i class="fa-solid fa-xmark"></i>
                    </a>
                @endif
                <button type="submit" class="px-3 py-1.5 bg-[#16241D] text-white text-xs font-bold rounded-xl hover:bg-[#2C4433] transition">
                    Search
                </button>
            </form>
        </div>

        <!-- Table View -->
        <div class="overflow-x-auto">
            <table class="w-full text-left text-xs sm:text-sm text-[#16241D]">
                <thead class="bg-[#FBF9F4] text-[11px] uppercase tracking-wider text-[#7A7569] border-b border-[#E5DFD3]">
                    <tr>
                        <th class="py-3 px-4 rounded-l-xl font-bold">User Account</th>
                        <th class="py-3 px-4 font-bold">Deleted Date & Time</th>
                        <th class="py-3 px-4 font-bold">Deletion History</th>
                        <th class="py-3 px-4 font-bold">Device & IP</th>
                        <th class="py-3 px-4 font-bold">Server Cloud Data</th>
                        <th class="py-3 px-4 rounded-r-xl font-bold">Current Account Status</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E5DFD3]">
                    @forelse($deletions as $item)
                    @php
                        $timesDeleted = $deletionCounts[$item->email] ?? 1;
                        $activeUser = $activeUsers[$item->email] ?? null;
                    @endphp
                    <tr class="hover:bg-[#FBF9F4]/60 transition">
                        <!-- User Account -->
                        <td class="py-3.5 px-4">
                            <div class="flex items-center space-x-3">
                                <div class="w-9 h-9 rounded-full bg-rose-100 text-rose-800 flex items-center justify-center font-bold text-xs shrink-0">
                                    {{ strtoupper(substr($item->name, 0, 2)) }}
                                </div>
                                <div>
                                    <p class="font-bold text-sm text-[#16241D]">{{ $item->name }}</p>
                                    <p class="text-xs text-[#7A7569]">{{ $item->email }}</p>
                                </div>
                            </div>
                        </td>

                        <!-- Deleted Date & Time -->
                        <td class="py-3.5 px-4">
                            <p class="font-bold text-xs text-[#16241D]">
                                {{ $item->deleted_at->format('M d, Y · h:i A') }}
                            </p>
                            <p class="text-[11px] text-[#7A7569]">
                                {{ $item->deleted_at->diffForHumans() }}
                            </p>
                        </td>

                        <!-- Deletion History -->
                        <td class="py-3.5 px-4">
                            @if($timesDeleted > 1)
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-800 border border-rose-200">
                                    <i class="fa-solid fa-rotate-left mr-1 text-[10px]"></i> Deleted {{ $timesDeleted }} times
                                </span>
                            @else
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                                    First deletion
                                </span>
                            @endif
                        </td>

                        <!-- Device & IP -->
                        <td class="py-3.5 px-4">
                            <div class="space-y-0.5">
                                <p class="text-xs font-semibold text-[#16241D]">
                                    <i class="fa-solid fa-mobile-screen-button mr-1 text-[#7A7569]"></i>
                                    {{ $item->device_name ?: 'Mobile App' }}
                                </p>
                                <p class="text-[11px] text-[#7A7569]">
                                    IP: {{ $item->ip_address ?: 'Unknown' }}
                                </p>
                            </div>
                        </td>

                        <!-- Server Data Status -->
                        <td class="py-3.5 px-4">
                            <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-rose-50 text-rose-700 border border-rose-200/60">
                                <i class="fa-solid fa-trash-can mr-1 text-[10px]"></i> Permanently Purged
                            </span>
                            <p class="text-[10.5px] text-[#7A7569] mt-0.5">Books, highlights & words wiped</p>
                        </td>

                        <!-- Current Account Status -->
                        <td class="py-3.5 px-4">
                            @if($activeUser)
                                <a href="{{ route('admin.users.show', $activeUser->id) }}" 
                                   class="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-emerald-100 hover:bg-emerald-200 text-emerald-800 text-xs font-bold transition group"
                                   title="View active re-registered user profile">
                                    <i class="fa-solid fa-user-check text-emerald-600"></i>
                                    <span>Re-registered (User #{{ $activeUser->id }})</span>
                                    <i class="fa-solid fa-arrow-up-right-from-square text-[10px] group-hover:translate-x-0.5 transition"></i>
                                </a>
                            @else
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-500">
                                    <i class="fa-solid fa-circle-xmark mr-1 text-[10px]"></i> No Active Account
                                </span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-[#7A7569]">
                            <div class="w-16 h-16 rounded-full bg-[#F3EFE6] text-[#7A7569] flex items-center justify-center mx-auto mb-3 text-2xl">
                                <i class="fa-solid fa-shield-halved"></i>
                            </div>
                            <p class="font-bold text-base text-[#16241D]">No account deletions recorded</p>
                            <p class="text-xs text-[#7A7569] mt-1">When readers delete their account from the mobile app, their audit logs will appear here.</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        @if($deletions->hasPages())
        <div class="pt-4 border-t border-[#E5DFD3]">
            {{ $deletions->links() }}
        </div>
        @endif

    </div>

</div>
@endsection
