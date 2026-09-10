<!DOCTYPE html>
<html lang="en" class="h-full bg-[#FBF9F4]">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Easy Read Studio')</title>
    <!-- Brand Favicon -->
    @php
        $siteLogo = \App\Models\Setting::get('app_logo');
        $siteFavicon = \App\Models\Setting::get('app_favicon') ?: $siteLogo;
        $siteAppName = \App\Models\Setting::get('app_name', 'Easy Read');
    @endphp
    @if(!empty($siteFavicon))
        <link rel="icon" href="{{ asset($siteFavicon) }}">
    @else
        <link rel="icon" type="image/svg+xml" href="{{ asset('favicon.svg') }}">
    @endif
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
                        serif: ['"Fraunces"', 'serif'],
                    },
                    colors: {
                        paper: '#FBF9F4',
                        paperSoft: '#F3EFE6',
                        line: '#E5DFD3',
                        ink: '#16241D',
                        moss: '#4B6B4A',
                        mossDark: '#3A5741',
                        gold: '#C28B38',
                        textMute: '#7A7569',
                    }
                }
            }
        }
    </script>
    <script>
        (function() {
            try {
                if (localStorage.getItem('easyread_admin_sidebar_collapsed') === 'true' && window.innerWidth >= 1024) {
                    document.documentElement.classList.add('sidebar-collapsed');
                }
            } catch(e) {}
        })();
    </script>
    <style>
        body { background-color: #FBF9F4; font-family: 'Plus Jakarta Sans', sans-serif; color: #16241D; }
        .custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(0, 0, 0, 0.1); border-radius: 999px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(0, 0, 0, 0.2); }
        .sidebar-scrollbar { 
            overflow-x: hidden !important; 
            scrollbar-width: none;
            -ms-overflow-style: none;
        }
        .sidebar-scrollbar::-webkit-scrollbar { 
            width: 4px; 
            height: 0px !important;
            display: none;
        }
        .sidebar-scrollbar::-webkit-scrollbar:horizontal { 
            height: 0px !important; 
            display: none !important; 
        }
        .sidebar-scrollbar::-webkit-scrollbar-thumb { 
            background: rgba(255, 255, 255, 0.2); 
            border-radius: 999px; 
        }
        .sidebar-scrollbar:hover::-webkit-scrollbar {
            display: block;
        }

        /* Clean Modern Sidebar Nav Items */
        #sidebar {
            background-color: #3E5C45;
            transition: width 0.25s cubic-bezier(0.4, 0, 0.2, 1), transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            overflow-x: hidden !important;
        }

        .sidebar-link {
            display: flex;
            align-items: center;
            padding: 0.65rem 0.85rem;
            color: rgba(255, 255, 255, 0.82);
            font-size: 0.875rem;
            font-weight: 600;
            border-radius: 1rem;
            transition: all 0.18s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
        }
        .sidebar-link:hover:not(.active) {
            color: #ffffff;
            background-color: rgba(255, 255, 255, 0.12);
        }
        .sidebar-link.active {
            color: #263D2E;
            background-color: #FBF9F4;
            font-weight: 700;
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.12);
        }
        .sidebar-link.active .nav-icon {
            color: #263D2E;
        }

        #sidebarCollapseArrow {
            transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        }

        /* ============================================================ */
        /* DESKTOP COLLAPSED MINI-SIDEBAR (DOCK MODE)                    */
        /* ============================================================ */
        @media (min-width: 1024px) {
            html.sidebar-collapsed #sidebar {
                width: 5rem !important; /* 80px */
            }
            html.sidebar-collapsed #sidebar .sidebar-text {
                display: none !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-header {
                padding: 1.25rem 0.5rem 0.875rem !important;
                flex-direction: column !important;
                justify-content: center !important;
                align-items: center !important;
                gap: 0.625rem !important;
                height: auto !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-brand-box {
                margin: 0 !important;
                justify-content: center !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-arrow-btn {
                margin: 0 !important;
                width: 1.875rem !important; /* 30px */
                height: 1.875rem !important;
                border-radius: 0.625rem !important;
            }
            html.sidebar-collapsed #sidebar #sidebarCollapseArrow {
                transform: rotate(180deg) !important;
            }
            html.sidebar-collapsed #sidebar nav {
                padding: 1rem 0.5rem !important;
                display: flex !important;
                flex-direction: column !important;
                align-items: center !important;
                gap: 0.35rem !important;
                overflow-x: hidden !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-link {
                justify-content: center !important;
                padding: 0 !important;
                width: 2.75rem !important; /* 44px */
                height: 2.75rem !important; /* 44px */
                margin: 0 auto !important;
                border-radius: 0.875rem !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-link .nav-icon {
                margin-right: 0 !important;
                font-size: 1.1rem !important;
                width: auto !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-logout-box {
                padding: 1rem 0.5rem !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-logout-btn {
                justify-content: center !important;
                padding: 0 !important;
                width: 2.75rem !important;
                height: 2.75rem !important;
                margin: 0 auto !important;
                border-radius: 0.875rem !important;
            }
            html.sidebar-collapsed #sidebar .sidebar-logout-btn .nav-icon {
                margin-right: 0 !important;
                font-size: 1.1rem !important;
            }
        }

        @keyframes toastProgress {
            from { width: 100%; }
            to { width: 0%; }
        }
        .toast-progress {
            animation: toastProgress linear forwards;
        }
    </style>
</head>
<body class="h-full flex overflow-hidden">

    <!-- Mobile & Tablet Sidebar Backdrop (Blur + Fade) -->
    <div id="sidebarBackdrop" 
         onclick="toggleSidebar(false)" 
         class="fixed inset-0 bg-black/50 backdrop-blur-xs z-40 hidden lg:hidden transition-opacity duration-300 opacity-0 pointer-events-none">
    </div>

    <!-- Sidebar Navigation (Responsive Drawer on Mobile/Tablet, Collapsible Static on Desktop) -->
    <aside id="sidebar" 
           class="fixed lg:static inset-y-0 left-0 z-50 w-72 max-w-[85vw] lg:w-[264px] bg-[#3E5C45] flex flex-col justify-between transition-all duration-300 ease-in-out -translate-x-full lg:translate-x-0 shrink-0 select-none shadow-2xl lg:shadow-none overflow-hidden border-r border-white/10">
        
        <div class="flex flex-col flex-1 overflow-hidden">
            <!-- Brand Logo Header with Arrow Toggle Button -->
            <div class="sidebar-header h-20 px-5 flex items-center justify-between shrink-0 border-b border-white/10 transition-all duration-300">
                <a href="{{ route('admin.dashboard') }}" 
                   data-tooltip="{{ $siteAppName }} Dashboard"
                   class="sidebar-brand-box flex items-center space-x-3 group min-w-0 relative">
                    @if(!empty($siteLogo))
                        <div class="w-10 h-10 rounded-2xl bg-white flex items-center justify-center overflow-hidden shadow-xs group-hover:scale-105 transition shrink-0 p-1 border border-white/10">
                            <img src="{{ asset($siteLogo) }}" class="w-full h-full object-contain" alt="{{ $siteAppName }}">
                        </div>
                    @else
                        <div class="w-10 h-10 rounded-2xl bg-white/15 backdrop-blur-xs flex items-center justify-center text-white shadow-xs group-hover:scale-105 transition shrink-0 border border-white/10">
                            <i class="fa-solid fa-book-open text-base"></i>
                        </div>
                    @endif
                    <div class="sidebar-text truncate">
                        <span class="font-serif font-bold text-white text-base leading-none block truncate max-w-[130px]">{{ $siteAppName }}</span>
                        <span class="text-[10px] font-semibold text-emerald-200/80 uppercase tracking-wider block mt-1">Admin Studio</span>
                    </div>
                </a>
                
                <!-- Desktop Collapse / Expand Arrow Button -->
                <button type="button"
                        id="sidebarCollapseBtn" 
                        onclick="toggleSidebarCollapse()" 
                        data-tooltip="Toggle Menu (Ctrl+B)"
                        class="sidebar-arrow-btn hidden lg:flex items-center justify-center w-8 h-8 rounded-xl bg-white/10 hover:bg-white/20 text-white/90 hover:text-white transition cursor-pointer shrink-0 border border-white/10 relative group" 
                        aria-label="Toggle sidebar menu">
                    <i id="sidebarCollapseArrow" class="fa-solid fa-chevron-left text-xs"></i>
                </button>

                <!-- Mobile / Tablet Drawer Close Button -->
                <button type="button" onclick="toggleSidebar(false)" class="lg:hidden text-white/80 hover:text-white p-2 rounded-xl hover:bg-white/10 transition cursor-pointer" aria-label="Close Sidebar Menu">
                    <i class="fa-solid fa-xmark text-xl"></i>
                </button>
            </div>

            <!-- Navigation Links (Data-Tooltip Driven, Zero Horizontal Scrollbar) -->
            <nav class="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto overflow-x-hidden sidebar-scrollbar">
                
                <!-- Dashboard -->
                <a href="{{ route('admin.dashboard') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="Dashboard"
                   class="sidebar-link {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-chart-pie w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">Dashboard</span>
                </a>

                <!-- Users & Readers -->
                <a href="{{ route('admin.users.index') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="Users & Readers ({{ \App\Models\User::count() }})"
                   class="sidebar-link {{ request()->routeIs('admin.users.*') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-users w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">Users & Readers</span>
                    <span class="sidebar-text px-2 py-0.5 rounded-full text-xs font-bold {{ request()->routeIs('admin.users.*') ? 'bg-[#3E5C45]/15 text-[#3E5C45]' : 'bg-white/20 text-white' }}">
                        {{ \App\Models\User::count() }}
                    </span>
                </a>

                <!-- Library & Books -->
                <a href="{{ route('admin.books.index') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="Library & Books ({{ \App\Models\Book::where('is_public', true)->count() }})"
                   class="sidebar-link {{ request()->routeIs('admin.books.*') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-book-bookmark w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">Library & Books</span>
                    <span class="sidebar-text px-2 py-0.5 rounded-full text-xs font-bold {{ request()->routeIs('admin.books.*') ? 'bg-[#3E5C45]/15 text-[#3E5C45]' : 'bg-white/20 text-white' }}">
                        {{ \App\Models\Book::where('is_public', true)->count() }}
                    </span>
                </a>

                <!-- Categories -->
                <a href="{{ route('admin.categories.index') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="Categories ({{ \App\Models\Category::count() }})"
                   class="sidebar-link {{ request()->routeIs('admin.categories.*') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-layer-group w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">Categories</span>
                    <span class="sidebar-text px-2 py-0.5 rounded-full text-xs font-bold {{ request()->routeIs('admin.categories.*') ? 'bg-[#3E5C45]/15 text-[#3E5C45]' : 'bg-white/20 text-white' }}">
                        {{ \App\Models\Category::count() }}
                    </span>
                </a>

                <!-- Plans & Pricing -->
                <a href="{{ route('admin.plans.index') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="Plans & Pricing ({{ \App\Models\Plan::where('is_active', true)->count() }})"
                   class="sidebar-link {{ request()->routeIs('admin.plans.*') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-gem w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">Plans & Pricing</span>
                    <span class="sidebar-text px-2 py-0.5 rounded-full text-xs font-bold {{ request()->routeIs('admin.plans.*') ? 'bg-[#3E5C45]/15 text-[#3E5C45]' : 'bg-white/20 text-white' }}">
                        {{ \App\Models\Plan::where('is_active', true)->count() }}
                    </span>
                </a>

                <!-- Announcements & Push Notifications -->
                <a href="{{ route('admin.notifications.index') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="Announcements & Notifications"
                   class="sidebar-link {{ request()->routeIs('admin.notifications.*') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-bullhorn w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">Announcements</span>
                </a>

                <!-- AI Logs & Cache -->
                <a href="{{ route('admin.ai-logs.index') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="AI Logs & Cache"
                   class="sidebar-link {{ request()->routeIs('admin.ai-logs.*') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-wand-magic-sparkles w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">AI Logs & Cache</span>
                </a>

                <!-- App Settings -->
                <a href="{{ route('admin.settings.index') }}" 
                   onclick="handleNavClick()"
                   data-tooltip="App Settings"
                   class="sidebar-link {{ request()->routeIs('admin.settings.*') ? 'active' : '' }}">
                    <i class="nav-icon fa-solid fa-sliders w-6 text-center text-base mr-3 shrink-0"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1">App Settings</span>
                </a>
            </nav>
        </div>

        <!-- Bottom Logout Action -->
        <div class="sidebar-logout-box p-3.5 border-t border-white/10 shrink-0">
            <form action="{{ route('admin.logout') }}" method="POST" data-confirm="Are you sure you want to log out of Easy Read Studio?">
                @csrf
                <button type="submit" 
                        data-tooltip="Log Out"
                        class="sidebar-logout-btn sidebar-link w-full hover:bg-rose-500/20 hover:text-rose-200 transition group cursor-pointer">
                    <i class="nav-icon fa-solid fa-arrow-right-from-bracket w-6 text-center text-base mr-3 shrink-0 text-white/75 group-hover:text-rose-300"></i>
                    <span class="sidebar-text whitespace-nowrap flex-1 text-left">Logout</span>
                </button>
            </form>
        </div>
    </aside>

    <!-- Main Content Layout Area -->
    <div class="flex-1 flex flex-col h-screen overflow-hidden bg-[#FBF9F4]">
        <!-- Top App Bar (Responsive Header) -->
        <header class="h-16 sm:h-20 px-4 sm:px-6 lg:px-8 flex items-center justify-between z-10 shrink-0 bg-[#FBF9F4] border-b border-[#E5DFD3]">
            <!-- Left Page Title with Hamburger Menu Button on Mobile -->
            <div class="flex items-center space-x-3 sm:space-x-4">
                <!-- Hamburger Button (Mobile & Tablet) -->
                <button onclick="toggleSidebar(true)" 
                        class="lg:hidden text-[#16241D] p-2 sm:p-2.5 rounded-xl hover:bg-[#EAE4D7] active:scale-95 transition flex items-center justify-center" 
                        aria-label="Open Sidebar Menu">
                    <i class="fa-solid fa-bars text-lg sm:text-xl"></i>
                </button>

                <div class="truncate">
                    <div class="hidden sm:flex items-center space-x-2 text-[11px] font-bold text-[#7A7569] uppercase tracking-wider">
                        <span>Studio</span>
                        <i class="fa-solid fa-chevron-right text-[8px] text-[#A19A8D]"></i>
                        <span class="text-[#3E5C45] truncate">@yield('page_title', 'Dashboard')</span>
                    </div>
                    <h2 class="text-lg sm:text-xl font-bold text-[#16241D] font-serif tracking-tight truncate">@yield('page_title', 'Dashboard')</h2>
                </div>
            </div>

            <!-- Right Profile Link -->
            <div class="flex items-center space-x-2">
                <a href="{{ route('admin.profile.index') }}" 
                   title="Account Profile & Password Settings"
                   class="flex items-center space-x-2.5 sm:space-x-3 px-2.5 sm:px-3.5 py-2 rounded-2xl border border-transparent hover:border-[#E5DFD3] hover:bg-white transition group {{ request()->routeIs('admin.profile.*') ? 'bg-white border-[#E5DFD3] shadow-2xs' : '' }}">
                    <div class="w-8 h-8 rounded-full bg-[#3E5C45]/10 text-[#3E5C45] flex items-center justify-center text-sm group-hover:bg-[#3E5C45] group-hover:text-white transition shrink-0">
                        <i class="fa-solid fa-user-tie text-xs"></i>
                    </div>
                    <div class="hidden md:block text-left pr-1">
                        <p class="text-xs font-bold text-[#16241D] leading-none group-hover:text-[#3E5C45] transition">{{ auth()->user()->name ?? 'Easy Read Admin' }}</p>
                        <p class="text-[11px] text-[#7A7569] mt-0.5">Super Admin</p>
                    </div>
                    <i class="fa-solid fa-chevron-right text-[9px] text-[#A19A8D] group-hover:text-[#3E5C45] transition hidden md:block"></i>
                </a>
            </div>
        </header>

        <!-- Main Dynamic Content Canvas (Responsive Padding) -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto custom-scrollbar">
            <div class="max-w-7xl mx-auto w-full">
                @yield('content')
            </div>
        </main>
    </div>

    <!-- =============================================================== -->
    <!-- UNIVERSAL IN-APP CONFIRMATION POPUP MODAL                       -->
    <!-- (Replaces browser confirm() with elegant UI modal)              -->
    <!-- =============================================================== -->
    <div id="adminConfirmModal" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs hidden opacity-0 transition-all duration-200">
        <div id="adminConfirmModalCard" class="bg-white rounded-3xl p-6 sm:p-7 max-w-md w-full shadow-2xl border border-[#E5DFD3] transform scale-95 transition-all duration-200 space-y-5">
            <div class="flex items-start space-x-4">
                <div id="adminConfirmIconBox" class="w-12 h-12 rounded-2xl bg-rose-50 text-rose-600 border border-rose-100 flex items-center justify-center text-xl shrink-0">
                    <i id="adminConfirmIcon" class="fa-solid fa-trash-can"></i>
                </div>
                <div class="space-y-1 flex-1">
                    <h3 id="adminConfirmTitle" class="font-serif font-bold text-[#16241D] text-lg leading-tight">Confirm Action</h3>
                    <p id="adminConfirmMessage" class="text-xs sm:text-sm text-[#5C5649] leading-relaxed">Are you sure you want to proceed?</p>
                </div>
            </div>

            <div class="flex items-center justify-end space-x-3 pt-2">
                <button type="button" id="adminConfirmCancelBtn" class="px-5 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FBF9F4] text-[#16241D] font-bold text-xs sm:text-sm hover:bg-[#F3EFE6] transition">
                    Cancel
                </button>
                <button type="button" id="adminConfirmSubmitBtn" class="px-5 py-2.5 rounded-xl bg-[#A13B3B] hover:bg-rose-700 text-white font-bold text-xs sm:text-sm shadow-xs transition flex items-center space-x-2">
                    <span id="adminConfirmBtnText">Confirm</span>
                </button>
            </div>
        </div>
    </div>

    <!-- =============================================================== -->
    <!-- GLOBAL FLOATING TOOLTIP FOR MINI SIDEBAR                        -->
    <!-- (Detached from sidebar DOM to prevent any overflow/scrollbars)  -->
    <!-- =============================================================== -->
    <div id="sidebarFloatingTooltip" 
         class="fixed z-[999] pointer-events-none px-3.5 py-1.5 rounded-xl bg-[#121F17] text-white text-xs font-bold shadow-2xl border border-white/15 opacity-0 transition-all duration-150 transform -translate-y-1/2 scale-95 flex items-center">
        <span id="sidebarFloatingTooltipText"></span>
        <span class="absolute right-full top-1/2 -translate-y-1/2 border-4 border-transparent border-r-[#121F17]"></span>
    </div>

    <!-- =============================================================== -->
    <!-- UNIVERSAL FLOATING TOAST NOTIFICATIONS CONTAINER                -->
    <!-- =============================================================== -->
    <div id="adminToastContainer" class="fixed top-4 right-4 sm:top-6 sm:right-6 z-[110] flex flex-col space-y-3 pointer-events-none max-w-sm w-full px-4 sm:px-0"></div>

    <script>
        // ============================================================
        // 1. RESPONSIVE SIDEBAR DRAWER CONTROLLER
        // ============================================================
        function toggleSidebar(forceState) {
            const sidebar = document.getElementById('sidebar');
            const backdrop = document.getElementById('sidebarBackdrop');
            if (!sidebar || !backdrop) return;

            const isCurrentlyOpen = !sidebar.classList.contains('-translate-x-full');
            const shouldOpen = typeof forceState === 'boolean' ? forceState : !isCurrentlyOpen;

            if (shouldOpen) {
                sidebar.classList.remove('-translate-x-full');
                backdrop.classList.remove('hidden');
                // Trigger fade-in
                requestAnimationFrame(() => {
                    backdrop.classList.remove('opacity-0', 'pointer-events-none');
                    backdrop.classList.add('opacity-100', 'pointer-events-auto');
                });
            } else {
                sidebar.classList.add('-translate-x-full');
                backdrop.classList.remove('opacity-100', 'pointer-events-auto');
                backdrop.classList.add('opacity-0', 'pointer-events-none');
                setTimeout(() => {
                    if (sidebar.classList.contains('-translate-x-full')) {
                        backdrop.classList.add('hidden');
                    }
                }, 300);
            }
        }

        function handleNavClick() {
            if (window.innerWidth < 1024) {
                toggleSidebar(false);
            }
        }

        // ============================================================
        // DESKTOP SIDEBAR COLLAPSE / EXPAND CONTROLLER (Arrow Toggle)
        // ============================================================
        function toggleSidebarCollapse() {
            const isCollapsed = document.documentElement.classList.toggle('sidebar-collapsed');
            localStorage.setItem('easyread_admin_sidebar_collapsed', isCollapsed ? 'true' : 'false');
            
            // Hide any lingering tooltip
            const tooltip = document.getElementById('sidebarFloatingTooltip');
            if (tooltip) {
                tooltip.classList.remove('opacity-100', 'scale-100');
                tooltip.classList.add('opacity-0', 'scale-95');
            }
        }

        // Synchronize state on page load
        document.addEventListener('DOMContentLoaded', function() {
            const savedState = localStorage.getItem('easyread_admin_sidebar_collapsed');
            if (savedState === 'true' && window.innerWidth >= 1024) {
                document.documentElement.classList.add('sidebar-collapsed');
            } else if (savedState === 'false') {
                document.documentElement.classList.remove('sidebar-collapsed');
            }
        });

        // Keyboard Shortcuts: Ctrl+B / Cmd+B to toggle sidebar, Escape to close drawer / modals
        document.addEventListener('keydown', function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'b') {
                e.preventDefault();
                toggleSidebarCollapse();
            }
            if (e.key === 'Escape') {
                toggleSidebar(false);
                closeConfirmDialog();
            }
        });

        // ============================================================
        // GLOBAL FLOATING TOOLTIP FOR COLLAPSED MINI-SIDEBAR
        // ============================================================
        document.addEventListener('mouseover', function(e) {
            if (!document.documentElement.classList.contains('sidebar-collapsed')) return;
            const target = e.target.closest('[data-tooltip]');
            if (!target) return;

            const tooltip = document.getElementById('sidebarFloatingTooltip');
            const text = document.getElementById('sidebarFloatingTooltipText');
            if (!tooltip || !text) return;

            const tooltipLabel = target.getAttribute('data-tooltip');
            if (!tooltipLabel) return;

            text.innerText = tooltipLabel;
            const rect = target.getBoundingClientRect();

            tooltip.style.left = (rect.right + 12) + 'px';
            tooltip.style.top = (rect.top + rect.height / 2) + 'px';
            tooltip.classList.remove('opacity-0', 'scale-95');
            tooltip.classList.add('opacity-100', 'scale-100');
        });

        document.addEventListener('mouseout', function(e) {
            const target = e.target.closest('[data-tooltip]');
            if (!target) return;
            const tooltip = document.getElementById('sidebarFloatingTooltip');
            if (tooltip) {
                tooltip.classList.remove('opacity-100', 'scale-100');
                tooltip.classList.add('opacity-0', 'scale-95');
            }
        });

        // ============================================================
        // 2. IN-APP TOAST NOTIFICATION SYSTEM
        // ============================================================
        window.showAdminToast = function(message, type = 'success', duration = 4000) {
            const container = document.getElementById('adminToastContainer');
            if (!container) return;

            const toastId = 'toast_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5);
            const toast = document.createElement('div');
            toast.id = toastId;
            toast.className = 'pointer-events-auto relative overflow-hidden flex items-start space-x-3 px-4 py-3.5 rounded-2xl shadow-2xl border transition-all duration-300 transform translate-y-2 opacity-0 text-white';

            let iconHtml = '';
            let progressBg = 'bg-white/30';

            if (type === 'success') {
                toast.classList.add('bg-[#16241D]', 'border-emerald-500/30');
                iconHtml = '<div class="w-6 h-6 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5"><i class="fa-solid fa-check"></i></div>';
            } else if (type === 'error' || type === 'danger') {
                toast.classList.add('bg-[#A13B3B]', 'border-white/20');
                iconHtml = '<div class="w-6 h-6 rounded-xl bg-white/20 text-white flex items-center justify-center font-bold text-xs shrink-0 mt-0.5"><i class="fa-solid fa-exclamation"></i></div>';
            } else if (type === 'warning') {
                toast.classList.add('bg-[#8A5C1E]', 'border-amber-400/30');
                iconHtml = '<div class="w-6 h-6 rounded-xl bg-amber-400/20 text-amber-300 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5"><i class="fa-solid fa-triangle-exclamation"></i></div>';
            } else {
                toast.classList.add('bg-[#2C3E33]', 'border-white/20');
                iconHtml = '<div class="w-6 h-6 rounded-xl bg-white/20 text-white flex items-center justify-center font-bold text-xs shrink-0 mt-0.5"><i class="fa-solid fa-info"></i></div>';
            }

            toast.innerHTML = `
                ${iconHtml}
                <div class="flex-1 pr-1">
                    <p class="text-xs sm:text-sm font-semibold leading-snug">${message}</p>
                </div>
                <button onclick="dismissAdminToast('${toastId}')" class="text-white/60 hover:text-white p-1 transition shrink-0">
                    <i class="fa-solid fa-xmark text-xs"></i>
                </button>
                <div class="absolute bottom-0 left-0 right-0 h-1 bg-black/20">
                    <div class="h-full ${progressBg} toast-progress" style="animation-duration: ${duration}ms;"></div>
                </div>
            `;

            container.appendChild(toast);

            // Animate In
            requestAnimationFrame(() => {
                toast.classList.remove('translate-y-2', 'opacity-0');
                toast.classList.add('translate-y-0', 'opacity-100');
            });

            // Auto dismiss
            setTimeout(() => {
                dismissAdminToast(toastId);
            }, duration);
        };

        window.dismissAdminToast = function(toastId) {
            const toast = document.getElementById(toastId);
            if (toast) {
                toast.classList.add('opacity-0', '-translate-y-2');
                setTimeout(() => toast.remove(), 250);
            }
        };

        // OVERRIDE BROWSER ALERT GLOBALLY:
        // Any legacy or inline alert() now displays our sleek in-app toast!
        window.alert = function(msg) {
            window.showAdminToast(msg, 'info');
        };

        // ============================================================
        // 3. IN-APP CONFIRMATION MODAL SYSTEM
        // ============================================================
        let currentConfirmCallback = null;

        window.showConfirmDialog = function(options) {
            const {
                title = 'Are you sure?',
                message = 'Please confirm this action to proceed.',
                confirmText = 'Yes, Proceed',
                cancelText = 'Cancel',
                type = 'danger',
                onConfirm = null
            } = options;

            currentConfirmCallback = onConfirm;

            const modal = document.getElementById('adminConfirmModal');
            const card = document.getElementById('adminConfirmModalCard');
            const titleEl = document.getElementById('adminConfirmTitle');
            const msgEl = document.getElementById('adminConfirmMessage');
            const submitBtn = document.getElementById('adminConfirmSubmitBtn');
            const submitText = document.getElementById('adminConfirmBtnText');
            const cancelBtn = document.getElementById('adminConfirmCancelBtn');
            const iconBox = document.getElementById('adminConfirmIconBox');
            const icon = document.getElementById('adminConfirmIcon');

            titleEl.innerText = title;
            msgEl.innerText = message;
            submitText.innerText = confirmText;
            cancelBtn.innerText = cancelText;

            // Configure Styling based on Type
            submitBtn.className = 'px-5 py-2.5 rounded-xl font-bold text-xs sm:text-sm shadow-xs transition flex items-center space-x-2 text-white';
            iconBox.className = 'w-12 h-12 rounded-2xl flex items-center justify-center text-xl shrink-0 border';

            if (type === 'danger') {
                submitBtn.classList.add('bg-[#A13B3B]', 'hover:bg-rose-700');
                iconBox.classList.add('bg-rose-50', 'text-rose-600', 'border-rose-100');
                icon.className = 'fa-solid fa-trash-can';
            } else if (type === 'warning') {
                submitBtn.classList.add('bg-[#C28B38]', 'hover:bg-amber-600');
                iconBox.classList.add('bg-amber-50', 'text-amber-600', 'border-amber-100');
                icon.className = 'fa-solid fa-triangle-exclamation';
            } else {
                submitBtn.classList.add('bg-[#3E5C45]', 'hover:bg-[#2F4936]');
                iconBox.classList.add('bg-[#F3EFE6]', 'text-[#3E5C45]', 'border-[#E5DFD3]');
                icon.className = 'fa-solid fa-circle-question';
            }

            modal.classList.remove('hidden');
            requestAnimationFrame(() => {
                modal.classList.remove('opacity-0');
                modal.classList.add('opacity-100');
                card.classList.remove('scale-95');
                card.classList.add('scale-100');
            });
        };

        function closeConfirmDialog() {
            const modal = document.getElementById('adminConfirmModal');
            const card = document.getElementById('adminConfirmModalCard');
            if (!modal || modal.classList.contains('hidden')) return;

            modal.classList.remove('opacity-100');
            modal.classList.add('opacity-0');
            card.classList.remove('scale-100');
            card.classList.add('scale-95');

            setTimeout(() => {
                modal.classList.add('hidden');
                currentConfirmCallback = null;
            }, 200);
        }

        document.getElementById('adminConfirmCancelBtn')?.addEventListener('click', closeConfirmDialog);
        document.getElementById('adminConfirmModal')?.addEventListener('click', function(e) {
            if (e.target === this) closeConfirmDialog();
        });

        document.getElementById('adminConfirmSubmitBtn')?.addEventListener('click', function() {
            if (typeof currentConfirmCallback === 'function') {
                const cb = currentConfirmCallback;
                closeConfirmDialog();
                cb();
            } else {
                closeConfirmDialog();
            }
        });

        // ============================================================
        // 4. GLOBAL FORM SUBMISSION INTERCEPTOR
        // (Automatically catches data-confirm and onsubmit confirm calls)
        // ============================================================
        document.addEventListener('submit', function(e) {
            const form = e.target;
            if (!form || form.tagName !== 'FORM') return;

            // If already confirmed by our in-app modal, allow submission
            if (form.dataset.confirmed === 'true') {
                delete form.dataset.confirmed;
                return true;
            }

            let confirmMsg = form.getAttribute('data-confirm') || form.dataset.confirm;

            // If onsubmit has confirm(...), extract and remove it so native dialog never pops
            if (!confirmMsg && form.hasAttribute('onsubmit')) {
                const onsubmitStr = form.getAttribute('onsubmit');
                const match = onsubmitStr.match(/confirm\(['"](.*?)['"]\)/);
                if (match && match[1]) {
                    confirmMsg = match[1];
                    form.removeAttribute('onsubmit');
                    form.setAttribute('data-confirm', confirmMsg);
                }
            }

            if (confirmMsg) {
                e.preventDefault();
                e.stopImmediatePropagation();

                const isDelete = form.action.includes('destroy') || 
                                 form.querySelector('input[name="_method"][value="DELETE"]') ||
                                 confirmMsg.toLowerCase().includes('delete') ||
                                 confirmMsg.toLowerCase().includes('remove');
                
                const isLogout = form.action.includes('logout') || confirmMsg.toLowerCase().includes('log out');

                window.showConfirmDialog({
                    title: isDelete ? 'Confirm Deletion' : (isLogout ? 'Confirm Logout' : 'Please Confirm'),
                    message: confirmMsg,
                    confirmText: isDelete ? 'Yes, Delete' : (isLogout ? 'Yes, Log Out' : 'Yes, Proceed'),
                    cancelText: 'Cancel',
                    type: isDelete ? 'danger' : (isLogout ? 'warning' : 'info'),
                    onConfirm: () => {
                        form.dataset.confirmed = 'true';
                        form.submit();
                    }
                });
                return false;
            }
        }, true); // Capture phase ensures we intercept before inline onsubmit fires

        // ============================================================
        // 5. SESSION FLASH MESSAGES
        // ============================================================
        document.addEventListener('DOMContentLoaded', function() {
            @if(session('success'))
                window.showAdminToast("{{ addslashes(session('success')) }}", 'success', 4500);
            @endif
            @if(session('error'))
                window.showAdminToast("{{ addslashes(session('error')) }}", 'error', 5500);
            @endif
            @if(session('warning'))
                window.showAdminToast("{{ addslashes(session('warning')) }}", 'warning', 5000);
            @endif
            @if(session('info'))
                window.showAdminToast("{{ addslashes(session('info')) }}", 'info', 4500);
            @endif
        });
    </script>
</body>
</html>
