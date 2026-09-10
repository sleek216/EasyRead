@extends('admin.layout')

@section('title', 'Announcements & Notifications')

@section('content')
<div class="space-y-6">

    <!-- Page Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl sm:text-3xl font-bold font-serif text-[#16241D]">Announcements & Notifications</h1>
            <p class="text-sm text-[#736B5E] mt-1">Broadcast announcements, push messages, and monitor automated system notifications.</p>
        </div>
        <div>
            <span class="inline-flex items-center px-4 py-2 rounded-xl text-xs font-semibold bg-[#3E5C45]/10 text-[#3E5C45] border border-[#3E5C45]/20">
                <i class="fa-solid fa-paper-plane mr-2 text-xs"></i>
                <span>{{ number_format($totalSent) }} Total Dispatched</span>
            </span>
        </div>
    </div>

    <!-- Grid: Create Announcement Form + Tips -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Left 2 Cols: Broadcast Form -->
        <div class="lg:col-span-2 bg-white rounded-2xl border border-[#E5DFD3] p-5 sm:p-6 shadow-sm">
            <div class="flex items-center space-x-3 mb-5 pb-4 border-b border-[#F0EBE1]">
                <div class="w-10 h-10 rounded-xl bg-[#3E5C45]/10 text-[#3E5C45] flex items-center justify-center text-lg">
                    <i class="fa-solid fa-bullhorn"></i>
                </div>
                <div>
                    <h2 class="text-lg font-bold text-[#16241D]">Send New Announcement</h2>
                    <p class="text-xs text-[#736B5E]">Publish a message instantly to readers' in-app notification centers.</p>
                </div>
            </div>

            <form action="{{ route('admin.notifications.store') }}" method="POST" class="space-y-4">
                @csrf

                <!-- Title -->
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D] mb-1.5">Announcement Title *</label>
                    <input type="text" name="title" required value="{{ old('title') }}" 
                           placeholder="e.g. New Feature: Offline Reading Mode is Live!" 
                           class="w-full px-4 py-2.5 rounded-xl border border-[#E5DFD3] text-sm text-[#16241D] placeholder-[#A0988A] focus:outline-none focus:ring-2 focus:ring-[#3E5C45]/30 focus:border-[#3E5C45]">
                </div>

                <!-- Message -->
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D] mb-1.5">Notification Message *</label>
                    <textarea name="message" rows="3" required 
                              placeholder="Write a clear, concise announcement for your readers..."
                              class="w-full px-4 py-2.5 rounded-xl border border-[#E5DFD3] text-sm text-[#16241D] placeholder-[#A0988A] focus:outline-none focus:ring-2 focus:ring-[#3E5C45]/30 focus:border-[#3E5C45]">{{ old('message') }}</textarea>
                </div>

                <!-- Type & Target Grid -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D] mb-1.5">Category Type</label>
                        <select name="type" class="w-full px-4 py-2.5 rounded-xl border border-[#E5DFD3] text-sm text-[#16241D] bg-white focus:outline-none focus:ring-2 focus:ring-[#3E5C45]/30 focus:border-[#3E5C45]">
                            <option value="announcement">General Announcement</option>
                            <option value="new_book">New Book Alert</option>
                            <option value="subscription">Subscription & VIP Notice</option>
                            <option value="general">General Notice</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D] mb-1.5">Target Audience</label>
                        <select name="target" class="w-full px-4 py-2.5 rounded-xl border border-[#E5DFD3] text-sm text-[#16241D] bg-white focus:outline-none focus:ring-2 focus:ring-[#3E5C45]/30 focus:border-[#3E5C45]">
                            <option value="all">All Registered Readers (Broadcast)</option>
                            @foreach($plans as $plan)
                                <option value="plan_{{ $plan->id }}">{{ $plan->name }} Users Only</option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <!-- Submit Button -->
                <div class="pt-2 flex justify-end">
                    <button type="submit" 
                            class="px-6 py-2.5 bg-[#3E5C45] text-white font-semibold text-sm rounded-xl hover:bg-[#2F4635] active:scale-[0.98] transition flex items-center space-x-2 shadow-sm cursor-pointer">
                        <i class="fa-solid fa-paper-plane text-xs"></i>
                        <span>Broadcast Announcement</span>
                    </button>
                </div>
            </form>
        </div>

        <!-- Right 1 Col: Info / Instructions -->
        <div class="bg-[#F4EFE6] rounded-2xl border border-[#E5DFD3] p-5 sm:p-6 flex flex-col justify-between">
            <div class="space-y-3">
                <h3 class="text-sm font-bold uppercase tracking-wider text-[#16241D] flex items-center space-x-2">
                    <i class="fa-solid fa-circle-info text-[#3E5C45]"></i>
                    <span>Notification System</span>
                </h3>
                <p class="text-xs text-[#736B5E] leading-relaxed">
                    Announcements published here appear immediately in the Mobile App's <strong>Notification Center</strong>.
                </p>
                <div class="space-y-2 pt-2 text-xs text-[#524B3E]">
                    <div class="flex items-start space-x-2">
                        <i class="fa-solid fa-check text-emerald-600 mt-0.5"></i>
                        <span><strong>Global Broadcasts</strong>: All users receive unread badge count on mobile top bar.</span>
                    </div>
                    <div class="flex items-start space-x-2">
                        <i class="fa-solid fa-check text-emerald-600 mt-0.5"></i>
                        <span><strong>Auto Book Alerts</strong>: Triggered automatically when publishing new books.</span>
                    </div>
                    <div class="flex items-start space-x-2">
                        <i class="fa-solid fa-check text-emerald-600 mt-0.5"></i>
                        <span><strong>Transactional SMTP</strong>: Subscription invoices and suspension notices are sent via background mail.</span>
                    </div>
                </div>
            </div>

            <div class="mt-4 pt-4 border-t border-[#E5DFD3]/60 text-[11px] text-[#8C8375]">
                <i class="fa-solid fa-shield-halved mr-1"></i> Fast, background delivery without app or server lag.
            </div>
        </div>
    </div>

    <!-- Notification History Table -->
    <div class="bg-white rounded-2xl border border-[#E5DFD3] shadow-sm overflow-hidden">
        
        <!-- Header & Filters -->
        <div class="p-4 sm:p-5 border-b border-[#F0EBE1] flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
                <h3 class="text-base font-bold text-[#16241D]">Notification Logs & History</h3>
                <p class="text-xs text-[#736B5E]">Review past announcements and automated system notifications.</p>
            </div>

            <!-- Filter Pills -->
            <div class="flex items-center space-x-2 overflow-x-auto pb-1 sm:pb-0">
                <a href="{{ route('admin.notifications.index', ['type' => 'all']) }}" 
                   class="px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap {{ $typeFilter === 'all' ? 'bg-[#3E5C45] text-white' : 'bg-[#F4EFE6] text-[#736B5E] hover:bg-[#EAE4D7]' }}">
                    All
                </a>
                <a href="{{ route('admin.notifications.index', ['type' => 'announcement']) }}" 
                   class="px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap {{ $typeFilter === 'announcement' ? 'bg-[#3E5C45] text-white' : 'bg-[#F4EFE6] text-[#736B5E] hover:bg-[#EAE4D7]' }}">
                    Announcements
                </a>
                <a href="{{ route('admin.notifications.index', ['type' => 'new_book']) }}" 
                   class="px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap {{ $typeFilter === 'new_book' ? 'bg-[#3E5C45] text-white' : 'bg-[#F4EFE6] text-[#736B5E] hover:bg-[#EAE4D7]' }}">
                    New Books
                </a>
                <a href="{{ route('admin.notifications.index', ['type' => 'subscription']) }}" 
                   class="px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap {{ $typeFilter === 'subscription' ? 'bg-[#3E5C45] text-white' : 'bg-[#F4EFE6] text-[#736B5E] hover:bg-[#EAE4D7]' }}">
                    Subscriptions
                </a>
                <a href="{{ route('admin.notifications.index', ['type' => 'suspension']) }}" 
                   class="px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap {{ $typeFilter === 'suspension' ? 'bg-[#3E5C45] text-white' : 'bg-[#F4EFE6] text-[#736B5E] hover:bg-[#EAE4D7]' }}">
                    Suspensions
                </a>
            </div>
        </div>

        <!-- Table -->
        <div class="overflow-x-auto">
            <table class="w-full text-left text-xs sm:text-sm">
                <thead class="bg-[#FBF9F4] text-[#736B5E] uppercase text-[10px] sm:text-xs font-bold tracking-wider border-b border-[#F0EBE1]">
                    <tr>
                        <th class="py-3.5 px-4 sm:px-6">Type</th>
                        <th class="py-3.5 px-4">Title & Message</th>
                        <th class="py-3.5 px-4">Target Audience</th>
                        <th class="py-3.5 px-4">Sent At</th>
                        <th class="py-3.5 px-4 sm:px-6 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0EBE1]">
                    @forelse($notifications as $notif)
                        <tr class="hover:bg-[#FBF9F4]/60 transition">
                            <!-- Type Badge -->
                            <td class="py-3.5 px-4 sm:px-6">
                                @if($notif->type === 'announcement')
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-200">
                                        <i class="fa-solid fa-bullhorn mr-1.5 text-[10px]"></i> Announcement
                                    </span>
                                @elseif($notif->type === 'new_book')
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-800 border border-emerald-200">
                                        <i class="fa-solid fa-book-open mr-1.5 text-[10px]"></i> New Book
                                    </span>
                                @elseif($notif->type === 'subscription')
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-indigo-50 text-indigo-800 border border-indigo-200">
                                        <i class="fa-solid fa-credit-card mr-1.5 text-[10px]"></i> Subscription
                                    </span>
                                @elseif($notif->type === 'suspension')
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-50 text-rose-800 border border-rose-200">
                                        <i class="fa-solid fa-user-xmark mr-1.5 text-[10px]"></i> Suspension
                                    </span>
                                @else
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-50 text-slate-800 border border-slate-200">
                                        <i class="fa-solid fa-bell mr-1.5 text-[10px]"></i> Notice
                                    </span>
                                @endif
                            </td>

                            <!-- Title & Message -->
                            <td class="py-3.5 px-4 max-w-md">
                                <div class="font-bold text-[#16241D] text-sm">{{ trim(preg_replace('/[\x{1F300}-\x{1F6FF}\x{1F900}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]/u', '', $notif->title)) }}</div>
                                <div class="text-[#736B5E] text-xs mt-0.5 line-clamp-2">{{ trim(preg_replace('/[\x{1F300}-\x{1F6FF}\x{1F900}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]/u', '', $notif->message)) }}</div>
                            </td>

                            <!-- Recipient -->
                            <td class="py-3.5 px-4">
                                @if($notif->is_broadcast)
                                    <span class="font-semibold text-emerald-800 flex items-center">
                                        <i class="fa-solid fa-globe text-xs mr-1.5 text-emerald-600"></i> All Readers (Broadcast)
                                    </span>
                                @elseif($notif->user)
                                    <div>
                                        <div class="font-semibold text-[#16241D]">{{ $notif->user->name }}</div>
                                        <div class="text-xs text-[#736B5E]">{{ $notif->user->email }}</div>
                                    </div>
                                @else
                                    <span class="text-[#A0988A] italic">Direct User</span>
                                @endif
                            </td>

                            <!-- Date -->
                            <td class="py-3.5 px-4 text-[#736B5E] text-xs whitespace-nowrap">
                                <div>{{ $notif->created_at->format('M d, Y') }}</div>
                                <div class="text-[11px] text-[#A0988A]">{{ $notif->created_at->format('h:i A') }} ({{ $notif->created_at->diffForHumans() }})</div>
                            </td>

                            <!-- Actions -->
                            <td class="py-3.5 px-4 sm:px-6 text-right">
                                <form action="{{ route('admin.notifications.destroy', $notif->id) }}" method="POST" 
                                      onsubmit="return confirm('Are you sure you want to delete this notification record?');" class="inline-block">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            class="p-1.5 text-[#A0988A] hover:text-rose-600 hover:bg-rose-50 rounded-lg transition" 
                                            title="Delete Notification">
                                        <i class="fa-solid fa-trash text-xs"></i>
                                    </button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="py-8 text-center text-[#736B5E]">
                                <i class="fa-solid fa-bell-slash text-2xl text-[#C8BFB0] mb-2 block"></i>
                                No notifications found.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        @if($notifications->hasPages())
            <div class="p-4 border-t border-[#F0EBE1]">
                {{ $notifications->links() }}
            </div>
        @endif

    </div>

</div>
@endsection
