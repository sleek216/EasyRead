<!DOCTYPE html>
<html lang="en" class="h-full bg-[#FBF9F4]">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In - {{ \App\Models\Setting::get('app_name', 'Easy Read') }} Studio</title>
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
                        mossDark: '#3A5439',
                        gold: '#C28B38',
                        textMute: '#7A7569',
                    }
                }
            }
        }
    </script>
    <style>
        body { background-color: #FBF9F4; font-family: 'Plus Jakarta Sans', sans-serif; color: #16241D; }

        /* Disable native browser password reveal icon in Edge/IE/Chrome to avoid duplication */
        input::-ms-reveal,
        input::-ms-clear {
            display: none !important;
        }
        input::-webkit-credentials-auto-fill-button {
            visibility: hidden;
            pointer-events: none;
            position: absolute;
            right: 0;
        }

        /* 5-second progress bar countdown animation */
        @keyframes alertCountdown {
            from { width: 100%; }
            to { width: 0%; }
        }
        .alert-progress-bar {
            width: 100%;
            animation: alertCountdown 5s linear forwards;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 antialiased selection:bg-[#4B6B4A] selection:text-white">

    <div class="max-w-md w-full mx-auto space-y-6">

        <!-- Brand Header (Proper Spacing & Clean Typography) -->
        <div class="text-center space-y-3.5">
            @if(!empty($siteLogo))
                <div class="inline-flex items-center justify-center w-16 h-16 rounded-3xl bg-white border border-[#E5DFD3] shadow-md overflow-hidden p-2">
                    <img src="{{ asset($siteLogo) }}" class="w-full h-full object-contain" alt="{{ $siteAppName }}">
                </div>
            @else
                <div class="inline-flex items-center justify-center w-16 h-16 rounded-3xl bg-[#4B6B4A] text-white shadow-lg shadow-[#4B6B4A]/20">
                    <i class="fa-solid fa-book-open text-2xl"></i>
                </div>
            @endif
            <div>
                <h1 class="text-3xl font-bold font-serif text-[#16241D] tracking-tight">{{ $siteAppName }} Studio</h1>
                <p class="text-sm font-medium text-[#7A7569] mt-1">Administrator Management Portal</p>
            </div>
        </div>

        <!-- Login Card -->
        <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-8 sm:p-9 space-y-6">

            <!-- Alert Notifications (Errors, Info & Success) with 5-Second Auto-Dismiss -->
            @php
                $alertType = session('error') ? 'error' : (session('success') ? 'success' : (session('info') ? 'info' : (session('status') ? 'status' : null)));
                $alertMessage = session('error') ?? session('success') ?? session('info') ?? session('status');
            @endphp

            @if($alertMessage)
                <div id="loginAlert" class="relative overflow-hidden p-4 rounded-2xl text-sm font-semibold flex items-center justify-between shadow-xs transition-all duration-500 ease-out {{ $alertType === 'error' ? 'bg-rose-50 border border-rose-200 text-[#A13B3B]' : ($alertType === 'info' ? 'bg-amber-50 border border-amber-200 text-amber-900' : 'bg-emerald-50 border border-emerald-200 text-emerald-900') }}">
                    <div class="flex items-center space-x-3 pr-2">
                        @if($alertType === 'error')
                            <i class="fa-solid fa-circle-exclamation text-base shrink-0 text-rose-600"></i>
                        @elseif($alertType === 'info')
                            <i class="fa-solid fa-circle-info text-base shrink-0 text-amber-600"></i>
                        @else
                            <i class="fa-solid fa-circle-check text-base text-emerald-600 shrink-0"></i>
                        @endif
                        <span class="leading-snug">{{ $alertMessage }}</span>
                    </div>
                    <button type="button" onclick="dismissAlert('loginAlert')" class="text-[#7A7569] hover:text-[#16241D] transition cursor-pointer p-1 rounded-lg hover:bg-black/5 shrink-0" title="Dismiss">
                        <i class="fa-solid fa-xmark text-sm"></i>
                    </button>
                    <!-- 5-Second Progress Countdown Bar -->
                    <div class="absolute bottom-0 left-0 h-[3px] {{ $alertType === 'error' ? 'bg-rose-400/60' : ($alertType === 'info' ? 'bg-amber-400/60' : 'bg-emerald-500/60') }} alert-progress-bar"></div>
                </div>
            @endif

            <form action="{{ route('admin.login.submit') }}" method="POST" class="space-y-5">
                @csrf

                <!-- Email Input -->
                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                        Admin Email
                    </label>
                    <div class="relative flex items-center">
                        <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-[#7A7569]">
                            <i class="fa-solid fa-envelope text-sm"></i>
                        </div>
                        <input type="email" 
                               name="email" 
                               value="{{ old('email') }}" 
                               required 
                               autocomplete="email"
                               placeholder="admin@easyread.com"
                               class="w-full pl-11 pr-4 py-3 bg-[#FBF9F4] border @error('email') border-rose-400 @else border-[#E5DFD3] @enderror rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] focus:bg-white transition text-[#16241D]">
                    </div>
                    @error('email')
                        <p class="text-xs font-semibold text-[#A13B3B] flex items-center mt-1.5">
                            <i class="fa-solid fa-circle-exclamation mr-1.5 text-xs"></i> {{ $message }}
                        </p>
                    @enderror
                </div>

                <!-- Password Input -->
                <div class="space-y-1.5">
                    <div class="flex items-center justify-between">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Password
                        </label>
                    </div>
                    <div class="relative flex items-center">
                        <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-[#7A7569]">
                            <i class="fa-solid fa-lock text-sm"></i>
                        </div>
                        <input type="password" 
                               id="passwordInput"
                               name="password" 
                               required 
                               autocomplete="current-password"
                               placeholder="Enter your password"
                               class="w-full pl-11 pr-12 py-3 bg-[#FBF9F4] border @error('password') border-rose-400 @else border-[#E5DFD3] @enderror rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] focus:bg-white transition text-[#16241D]">
                        <button type="button" 
                                onclick="togglePasswordVisibility()" 
                                id="togglePasswordBtn"
                                aria-label="Toggle password visibility"
                                class="absolute inset-y-0 right-0 pr-4 flex items-center justify-center text-[#7A7569] hover:text-[#16241D] transition cursor-pointer">
                            <i id="eyeIcon" class="fa-solid fa-eye text-base"></i>
                        </button>
                    </div>
                    @error('password')
                        <p class="text-xs font-semibold text-[#A13B3B] flex items-center mt-1.5">
                            <i class="fa-solid fa-circle-exclamation mr-1.5 text-xs"></i> {{ $message }}
                        </p>
                    @enderror
                </div>

                <!-- Remember Me -->
                <div class="flex items-center justify-between pt-1">
                    <label class="flex items-center space-x-2.5 text-sm font-medium text-[#5C5649] cursor-pointer select-none">
                        <input type="checkbox" name="remember" class="w-4 h-4 text-[#4B6B4A] rounded border-[#E5DFD3] focus:ring-[#4B6B4A]">
                        <span>Keep me logged in</span>
                    </label>
                </div>

                <!-- Submit Button -->
                <div class="pt-2">
                    <button type="submit" class="w-full py-3.5 px-5 rounded-xl bg-[#4B6B4A] hover:bg-[#3A5439] active:scale-[0.99] text-white text-sm font-bold shadow-md shadow-[#4B6B4A]/20 flex items-center justify-center space-x-2 transition">
                        <span>Sign In to Studio</span>
                        <i class="fa-solid fa-arrow-right text-xs"></i>
                    </button>
                </div>
            </form>

        </div>

        <!-- Footer Notice -->
        <p class="text-center text-xs text-[#7A7569]">
            Easy Read Book Reading & Vocabulary Studio &copy; {{ date('Y') }}
        </p>

    </div>

    <script>
        function dismissAlert(id) {
            const alert = document.getElementById(id);
            if (!alert) return;
            alert.style.transition = 'all 0.5s cubic-bezier(0.4, 0, 0.2, 1)';
            alert.style.opacity = '0';
            alert.style.transform = 'translateY(-10px)';
            alert.style.maxHeight = alert.scrollHeight + 'px';
            setTimeout(() => {
                alert.style.maxHeight = '0px';
                alert.style.paddingTop = '0px';
                alert.style.paddingBottom = '0px';
                alert.style.marginTop = '0px';
                alert.style.marginBottom = '0px';
                alert.style.borderWidth = '0px';
            }, 50);
            setTimeout(() => {
                alert.remove();
            }, 550);
        }

        // Automatically dismiss alert after 5 seconds
        document.addEventListener('DOMContentLoaded', function() {
            const alert = document.getElementById('loginAlert');
            if (alert) {
                setTimeout(() => {
                    dismissAlert('loginAlert');
                }, 5000);
            }
        });

        function togglePasswordVisibility() {
            const input = document.getElementById('passwordInput');
            const icon = document.getElementById('eyeIcon');
            if (!input || !icon) return;
            if (input.type === 'password') {
                input.type = 'text';
                icon.classList.remove('fa-eye');
                icon.classList.add('fa-eye-slash');
            } else {
                input.type = 'password';
                icon.classList.remove('fa-eye-slash');
                icon.classList.add('fa-eye');
            }
            input.focus();
        }
    </script>
</body>
</html>
