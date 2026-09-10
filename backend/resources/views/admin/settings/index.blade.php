@extends('admin.layout')

@section('title', 'App Settings - Easy Read Studio')
@section('page_title', 'App Settings')

@section('content')
<div class="w-full space-y-6">

    <!-- Top Horizontal Navigation Tabs (Responsive Scrollable Container) -->
    <div class="overflow-x-auto pb-1.5 max-w-full custom-scrollbar">
        <div class="flex items-center gap-2 bg-[#F3EFE6]/70 p-1.5 rounded-2xl border border-[#E5DFD3] w-max shadow-2xs">
        <button type="button" onclick="switchSettingTab('ai')" id="tab-btn-ai"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 bg-[#3E5C45] text-white shadow-xs">
            <i class="fa-solid fa-wand-magic-sparkles text-xs"></i>
            <span>AI Configuration</span>
        </button>

        <button type="button" onclick="switchSettingTab('app')" id="tab-btn-app"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 text-[#7A7569] hover:text-[#16241D] hover:bg-[#E5DFD3]/40">
            <i class="fa-solid fa-sliders text-xs"></i>
            <span>App, Branding & Limits</span>
        </button>

        <button type="button" onclick="switchSettingTab('purchases')" id="tab-btn-purchases"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 text-[#7A7569] hover:text-[#16241D] hover:bg-[#E5DFD3]/40">
            <i class="fa-solid fa-credit-card text-xs"></i>
            <span>In-App Purchases (RevenueCat)</span>
        </button>

        <button type="button" onclick="switchSettingTab('privacy')" id="tab-btn-privacy"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 text-[#7A7569] hover:text-[#16241D] hover:bg-[#E5DFD3]/40">
            <i class="fa-solid fa-shield-halved text-xs"></i>
            <span>Privacy Policy</span>
        </button>

        <button type="button" onclick="switchSettingTab('social')" id="tab-btn-social"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 text-[#7A7569] hover:text-[#16241D] hover:bg-[#E5DFD3]/40">
            <i class="fa-brands fa-google text-xs"></i>
            <span>Social Auth (Google & Apple)</span>
        </button>

        <button type="button" onclick="switchSettingTab('smtp')" id="tab-btn-smtp"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 text-[#7A7569] hover:text-[#16241D] hover:bg-[#E5DFD3]/40">
            <i class="fa-solid fa-envelope text-xs"></i>
            <span>Email (SMTP)</span>
        </button>

        <button type="button" onclick="switchSettingTab('notifications')" id="tab-btn-notifications"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 text-[#7A7569] hover:text-[#16241D] hover:bg-[#E5DFD3]/40">
            <i class="fa-solid fa-bell text-xs"></i>
            <span>Push & Notifications</span>
        </button>

        <button type="button" onclick="switchSettingTab('dropbox')" id="tab-btn-dropbox"
                class="setting-tab-btn px-5 py-2.5 rounded-xl text-xs font-bold transition flex items-center space-x-2 text-[#7A7569] hover:text-[#16241D] hover:bg-[#E5DFD3]/40">
            <i class="fa-brands fa-dropbox text-xs text-[#0061FF]"></i>
            <span>Cloud Storage (Dropbox)</span>
        </button>
        </div>
    </div>

    <form action="{{ route('admin.settings.update') }}" method="POST" enctype="multipart/form-data" class="space-y-6">
        @csrf
        <input type="hidden" name="active_tab" id="activeSettingTabInput" value="{{ request('tab', session('active_tab', 'ai')) }}">

        <!-- TAB 1: AI Configuration -->
        <div id="tab-content-ai" class="setting-tab-content space-y-6">
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
                
                <!-- Card Header -->
                <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
                    <div>
                        <h3 class="font-serif font-bold text-[#16241D] text-lg">AI Assistant Engine & Credentials</h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">Select your preferred AI provider, enter its API key, and test the connection</p>
                    </div>
                    <span id="aiActiveBadge" class="px-3 py-1 rounded-full text-xs font-bold bg-[#3E5C45]/10 text-[#3E5C45] uppercase tracking-wider">
                        Active: {{ str_replace('_', ' ', strtoupper($settings['ai_provider'] ?? 'google_ai_studio')) }}
                    </span>
                </div>

                <!-- 1. LLM Dropdown Selector -->
                <div class="space-y-2">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                        Select AI Provider (LLM) <span class="text-rose-500">*</span>
                    </label>
                    <select name="ai_provider" id="aiProviderSelect" onchange="onAiProviderChange()"
                            class="w-full px-4 py-3.5 rounded-2xl border-2 border-[#3E5C45]/40 bg-[#FDFBF7] text-sm text-[#16241D] font-bold focus:bg-white focus:border-[#3E5C45] outline-hidden transition shadow-2xs cursor-pointer">
                        <option value="google_ai_studio" {{ ($settings['ai_provider'] ?? 'google_ai_studio') === 'google_ai_studio' ? 'selected' : '' }}>
                            Google AI Studio (Gemini 1.5 Flash & Pro) — Recommended
                        </option>
                        <option value="openrouter" {{ ($settings['ai_provider'] ?? '') === 'openrouter' ? 'selected' : '' }}>
                            OpenRouter AI (Universal: Gemini, Claude, Llama, GPT)
                        </option>
                        <option value="openai" {{ ($settings['ai_provider'] ?? '') === 'openai' ? 'selected' : '' }}>
                            OpenAI (ChatGPT Direct / GPT-4o-mini & GPT-4o)
                        </option>
                    </select>
                </div>

                <!-- 2. Dynamic Provider Fields Container -->

                <!-- DYNAMIC BLOCK 1: Google AI Studio -->
                <div id="provider-fields-google_ai_studio" class="provider-fields-block space-y-5 p-5 rounded-2xl bg-[#F8F5EE] border border-[#E5DFD3] {{ ($settings['ai_provider'] ?? 'google_ai_studio') === 'google_ai_studio' ? '' : 'hidden' }}">
                    <div class="flex items-center space-x-2 text-xs font-bold text-[#3E5C45]">
                        <i class="fa-solid fa-flask"></i>
                        <span>Google AI Studio Credentials</span>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Google AI Studio API Key <span class="text-rose-500">*</span>
                        </label>
                        <div class="relative">
                            <input type="password" id="googleAiStudioKey" name="google_ai_studio_key" 
                                   value="{{ old('google_ai_studio_key', $settings['google_ai_studio_key'] ?? '') }}" 
                                   placeholder="AIzaSy..."
                                   class="w-full pl-4 pr-12 py-3 rounded-xl border border-[#E5DFD3] bg-white font-mono text-sm text-[#16241D] focus:border-[#3E5C45] focus:ring-1 focus:ring-[#3E5C45] outline-hidden transition">
                            <button type="button" onclick="toggleKeyVisibility('googleAiStudioKey', 'toggleAiStudioIcon')" 
                                    class="absolute right-3 top-1/2 -translate-y-1/2 p-2 text-[#7A7569] hover:text-[#16241D] transition">
                                <i class="fa-solid fa-eye" id="toggleAiStudioIcon"></i>
                            </button>
                        </div>
                        <p class="text-xs text-[#7A7569]">
                            Obtain from Google AI Studio. Starts with <code class="font-mono bg-[#EFE9DC] px-1.5 py-0.5 rounded text-[#3E5C45]">AIzaSy...</code>
                        </p>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Gemini Model
                        </label>
                        <select name="google_ai_studio_model" id="googleAiStudioModel" 
                                class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white text-sm text-[#16241D] font-medium focus:border-[#3E5C45] outline-hidden transition">
                            <option value="gemini-3.5-flash" {{ ($settings['google_ai_studio_model'] ?? '') === 'gemini-3.5-flash' || empty($settings['google_ai_studio_model']) ? 'selected' : '' }}>
                                gemini-3.5-flash — Fast & Smart (Recommended)
                            </option>
                            <option value="gemini-3.7-flash" {{ ($settings['google_ai_studio_model'] ?? '') === 'gemini-3.7-flash' ? 'selected' : '' }}>
                                gemini-3.7-flash — Next Gen Flash
                            </option>
                            <option value="gemini-3.6-flash" {{ ($settings['google_ai_studio_model'] ?? '') === 'gemini-3.6-flash' ? 'selected' : '' }}>
                                gemini-3.6-flash — Balanced Flash
                            </option>
                            <option value="gemini-3.1-flash-lite" {{ ($settings['google_ai_studio_model'] ?? '') === 'gemini-3.1-flash-lite' ? 'selected' : '' }}>
                                gemini-3.1-flash-lite — Lightweight & Fast
                            </option>
                        </select>
                    </div>

                    <div class="pt-2 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <button type="button" onclick="testGoogleAiStudioConnection()" id="testAiStudioBtn"
                                class="px-5 py-2.5 rounded-xl border border-[#3E5C45] text-[#3E5C45] hover:bg-[#3E5C45] hover:text-white text-xs font-bold transition flex items-center space-x-2 bg-white">
                            <i class="fa-solid fa-bolt text-xs"></i>
                            <span>Test Google AI Studio Connection</span>
                        </button>
                        <div id="testAiStudioResult" class="text-xs font-medium hidden"></div>
                    </div>
                </div>

                <!-- DYNAMIC BLOCK 2: OpenRouter AI -->
                <div id="provider-fields-openrouter" class="provider-fields-block space-y-5 p-5 rounded-2xl bg-[#F4EFFB] border border-[#E1D4F4] {{ ($settings['ai_provider'] ?? '') === 'openrouter' ? '' : 'hidden' }}">
                    <div class="flex items-center space-x-2 text-xs font-bold text-[#6D28D9]">
                        <i class="fa-solid fa-network-wired"></i>
                        <span>OpenRouter AI Credentials</span>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            OpenRouter API Key <span class="text-rose-500">*</span>
                        </label>
                        <div class="relative">
                            <input type="password" id="openRouterApiKey" name="openrouter_api_key" 
                                   value="{{ old('openrouter_api_key', $settings['openrouter_api_key'] ?? '') }}" 
                                   placeholder="sk-or-v1-..."
                                   class="w-full pl-4 pr-12 py-3 rounded-xl border border-[#E1D4F4] bg-white font-mono text-sm text-[#16241D] focus:border-[#6D28D9] focus:ring-1 focus:ring-[#6D28D9] outline-hidden transition">
                            <button type="button" onclick="toggleKeyVisibility('openRouterApiKey', 'toggleOpenRouterIcon')" 
                                    class="absolute right-3 top-1/2 -translate-y-1/2 p-2 text-[#7A7569] hover:text-[#16241D] transition">
                                <i class="fa-solid fa-eye" id="toggleOpenRouterIcon"></i>
                            </button>
                        </div>
                        <p class="text-xs text-[#7A7569]">
                            Obtain from <a href="https://openrouter.ai/keys" target="_blank" class="text-[#6D28D9] underline font-semibold">openrouter.ai/keys</a>. Starts with <code class="font-mono bg-[#EFE9DC] px-1.5 py-0.5 rounded text-[#6D28D9]">sk-or-v1-...</code>
                        </p>
                    </div>

                    <div class="space-y-2">
                        <div class="flex items-center justify-between">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                OpenRouter Model ID <span class="text-rose-500">*</span>
                            </label>
                            <span class="text-[11px] text-[#7A7569]">Verified: <code class="font-mono text-[#6D28D9]">google/gemini-flash-1.5</code></span>
                        </div>
                        <input type="text" id="openRouterModel" name="openrouter_model" 
                               value="{{ old('openrouter_model', $settings['openrouter_model'] ?? 'google/gemini-flash-1.5') }}" 
                               placeholder="google/gemini-flash-1.5"
                               class="w-full px-4 py-3 rounded-xl border border-[#E1D4F4] bg-white font-mono text-sm text-[#16241D] font-bold focus:border-[#6D28D9] focus:ring-1 focus:ring-[#6D28D9] outline-hidden transition">
                        
                        <!-- Quick Select Presets -->
                        <div class="flex flex-wrap items-center gap-1.5 pt-1">
                            <span class="text-[11px] font-bold text-[#7A7569] mr-1">Quick Select:</span>
                            <button type="button" onclick="setOpenRouterModel('google/gemini-flash-1.5')" 
                                    class="px-2.5 py-1 rounded-lg text-xs font-mono font-semibold bg-[#6D28D9]/10 text-[#6D28D9] hover:bg-[#6D28D9] hover:text-white transition border border-[#6D28D9]/20">
                                google/gemini-flash-1.5 ⭐
                            </button>
                            <button type="button" onclick="setOpenRouterModel('google/gemini-2.0-flash-001')" 
                                    class="px-2.5 py-1 rounded-lg text-xs font-mono font-semibold bg-purple-50 text-purple-700 hover:bg-[#6D28D9] hover:text-white transition border border-purple-200">
                                google/gemini-2.0-flash-001
                            </button>
                            <button type="button" onclick="setOpenRouterModel('openai/gpt-4o-mini')" 
                                    class="px-2.5 py-1 rounded-lg text-xs font-mono font-semibold bg-blue-50 text-blue-700 hover:bg-[#2E4C6D] hover:text-white transition border border-blue-200">
                                openai/gpt-4o-mini
                            </button>
                            <button type="button" onclick="setOpenRouterModel('meta-llama/llama-3.3-70b-instruct')" 
                                    class="px-2.5 py-1 rounded-lg text-xs font-mono font-semibold bg-amber-50 text-amber-700 hover:bg-amber-600 hover:text-white transition border border-amber-200">
                                meta-llama/llama-3.3-70b-instruct
                            </button>
                            <button type="button" onclick="setOpenRouterModel('deepseek/deepseek-chat')" 
                                    class="px-2.5 py-1 rounded-lg text-xs font-mono font-semibold bg-emerald-50 text-emerald-700 hover:bg-emerald-600 hover:text-white transition border border-emerald-200">
                                deepseek/deepseek-chat
                            </button>
                        </div>
                    </div>

                    <div class="pt-2 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <button type="button" onclick="testOpenRouterConnection()" id="testOpenRouterBtn"
                                class="px-5 py-2.5 rounded-xl border border-[#6D28D9] text-[#6D28D9] hover:bg-[#6D28D9] hover:text-white text-xs font-bold transition flex items-center space-x-2 bg-white">
                            <i class="fa-solid fa-bolt text-xs"></i>
                            <span>Test OpenRouter Connection</span>
                        </button>
                        <div id="testOpenRouterResult" class="text-xs font-medium hidden"></div>
                    </div>
                </div>

                <!-- DYNAMIC BLOCK 3: OpenAI (ChatGPT Direct) -->
                <div id="provider-fields-openai" class="provider-fields-block space-y-5 p-5 rounded-2xl bg-[#EEF2F6] border border-[#D5DEE7] {{ ($settings['ai_provider'] ?? '') === 'openai' ? '' : 'hidden' }}">
                    <div class="flex items-center space-x-2 text-xs font-bold text-[#2E4C6D]">
                        <i class="fa-solid fa-robot"></i>
                        <span>OpenAI (ChatGPT Direct) Credentials</span>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            OpenAI API Key <span class="text-rose-500">*</span>
                        </label>
                        <div class="relative">
                            <input type="password" id="openAiApiKey" name="openai_api_key" 
                                   value="{{ old('openai_api_key', $settings['openai_api_key'] ?? '') }}" 
                                   placeholder="sk-..."
                                   class="w-full pl-4 pr-12 py-3 rounded-xl border border-[#D5DEE7] bg-white font-mono text-sm text-[#16241D] focus:border-[#2E4C6D] focus:ring-1 focus:ring-[#2E4C6D] outline-hidden transition">
                            <button type="button" onclick="toggleKeyVisibility('openAiApiKey', 'toggleOpenAiIcon')" 
                                    class="absolute right-3 top-1/2 -translate-y-1/2 p-2 text-[#7A7569] hover:text-[#16241D] transition">
                                <i class="fa-solid fa-eye" id="toggleOpenAiIcon"></i>
                            </button>
                        </div>
                        <p class="text-xs text-[#7A7569]">
                            Obtain from OpenAI Platform Dashboard. Starts with <code class="font-mono bg-[#E0E7EE] px-1.5 py-0.5 rounded text-[#2E4C6D]">sk-...</code>
                        </p>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            OpenAI GPT Model
                        </label>
                        <select name="openai_model" id="openAiModel" 
                                class="w-full px-4 py-3 rounded-xl border border-[#D5DEE7] bg-white text-sm text-[#16241D] font-medium focus:border-[#2E4C6D] outline-hidden transition">
                            <option value="gpt-4o-mini" {{ ($settings['openai_model'] ?? '') === 'gpt-4o-mini' ? 'selected' : '' }}>
                                gpt-4o-mini (Fast & Low Cost - Recommended)
                            </option>
                            <option value="gpt-4o" {{ ($settings['openai_model'] ?? '') === 'gpt-4o' ? 'selected' : '' }}>
                                gpt-4o (Flagship Model)
                            </option>
                            <option value="gpt-3.5-turbo" {{ ($settings['openai_model'] ?? '') === 'gpt-3.5-turbo' ? 'selected' : '' }}>
                                gpt-3.5-turbo (Legacy Fast)
                            </option>
                        </select>
                    </div>

                    <div class="pt-2 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <button type="button" onclick="testOpenAiConnection()" id="testOpenAiBtn"
                                class="px-5 py-2.5 rounded-xl border border-[#2E4C6D] text-[#2E4C6D] hover:bg-[#2E4C6D] hover:text-white text-xs font-bold transition flex items-center space-x-2 bg-white">
                            <i class="fa-solid fa-bolt text-xs"></i>
                            <span>Test OpenAI Connection</span>
                        </button>
                        <div id="testOpenAiResult" class="text-xs font-medium hidden"></div>
                    </div>
                </div>

                <!-- 3. AI Temperature / Creativity -->
                <div class="space-y-2 pt-2 border-t border-[#E5DFD3]">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                        AI Temperature / Creativity
                    </label>
                    <select name="ai_temperature" 
                            class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <option value="0.7" {{ ($settings['ai_temperature'] ?? '0.7') === '0.7' ? 'selected' : '' }}>
                            0.7 - Balanced & Natural (Recommended for General Reading)
                        </option>
                        <option value="0.2" {{ ($settings['ai_temperature'] ?? '0.7') === '0.2' ? 'selected' : '' }}>
                            0.2 - Precise & Concise (Dictionary Style & Translations)
                        </option>
                        <option value="1.0" {{ ($settings['ai_temperature'] ?? '0.7') === '1.0' ? 'selected' : '' }}>
                            1.0 - Highly Creative & Detailed
                        </option>
                    </select>
                    <p class="text-xs text-[#7A7569]">Controls style and randomness for all AI reading actions.</p>
                </div>

                <!-- Supported Translation Languages Section -->
                <div class="space-y-3 pt-4 border-t border-[#E5DFD3]">
                    <div class="flex items-center justify-between">
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Supported Translation Languages <span class="text-rose-500">*</span>
                            </label>
                            <p class="text-xs text-[#7A7569] mt-0.5">
                                Readers will choose from these languages when tapping "Translate" under passages. Enter languages separated by commas.
                            </p>
                        </div>
                        <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-[#3E5C45]/10 text-[#3E5C45] flex items-center space-x-1">
                            <i class="fa-solid fa-language text-xs"></i>
                            <span>App Synced</span>
                        </span>
                    </div>

                    <textarea name="translation_languages" id="translationLanguagesInput" rows="3"
                              placeholder="Urdu, Spanish, French, German, Arabic, Hindi, Chinese, Turkish, Italian, Portuguese, Japanese, Russian"
                              class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:bg-white focus:border-[#3E5C45] outline-hidden transition">{{ old('translation_languages', $settings['translation_languages'] ?? 'Urdu, Spanish, French, German, Arabic, Hindi, Chinese, Turkish, Italian, Portuguese, Japanese, Russian') }}</textarea>

                    <div class="space-y-2 pt-1">
                        <div class="flex items-center justify-between text-[11px] font-bold">
                            <span class="text-[#7A7569] flex items-center space-x-1.5">
                                <i class="fa-solid fa-tags text-[10px] text-[#3E5C45]"></i>
                                <span>Click tags to toggle on/off:</span>
                            </span>
                            <span id="selectedLanguagesCount" class="px-2.5 py-0.5 rounded-full bg-[#3E5C45]/10 text-[#3E5C45]">
                                0 selected
                            </span>
                        </div>
                        <div class="flex flex-wrap items-center gap-2" id="languageTagsContainer">
                            @foreach(['Urdu', 'Spanish', 'French', 'German', 'Arabic', 'Hindi', 'Chinese', 'Turkish', 'Italian', 'Portuguese', 'Japanese', 'Russian', 'Persian', 'Indonesian', 'Korean'] as $lang)
                                <button type="button" 
                                        data-lang="{{ $lang }}"
                                        onclick="toggleLanguageTag('{{ $lang }}')"
                                        class="lang-tag-btn px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center cursor-pointer border shadow-2xs">
                                    <i class="lang-icon fa-solid fa-plus text-[10px] mr-1.5 text-[#A19A8D]"></i>
                                    <span>{{ $lang }}</span>
                                </button>
                            @endforeach
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- TAB 2: App, Branding & Limits -->
        <div id="tab-content-app" class="setting-tab-content space-y-6 hidden">
            
            <!-- Branding & Logo Section -->
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
                <div class="border-b border-[#E5DFD3] pb-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                    <div>
                        <h3 class="font-serif font-bold text-[#16241D] text-lg">Web Logo & Brand Identity</h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">Upload your website logo. This single file is automatically applied across the website header, navigation, and browser tab favicon.</p>
                    </div>
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-[11px] font-bold bg-[#3E5C45]/10 text-[#3E5C45] self-start sm:self-auto border border-[#3E5C45]/20">
                        <i class="fa-solid fa-wand-magic-sparkles mr-1.5 text-xs"></i> 1 Logo = Web & Favicon
                    </span>
                </div>

                <!-- Single Unified Field: Web Logo -->
                <div class="p-6 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] space-y-5">
                    <div class="flex items-center justify-between">
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Web Logo
                            </label>
                            <p class="text-xs text-[#7A7569] mt-0.5">Single unified logo for web header, sidebar & browser tab</p>
                        </div>
                        <span class="text-[11px] font-semibold text-[#3E5C45] bg-white px-2.5 py-1 rounded-lg border border-[#E5DFD3] shadow-2xs">
                            Unified Field
                        </span>
                    </div>

                    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
                        <!-- Dual Preview: Web Logo + Browser Tab Mockup -->
                        <div class="lg:col-span-5 flex flex-wrap sm:flex-nowrap items-center gap-4">
                            <!-- Web Logo Box -->
                            <div class="flex flex-col items-center">
                                <div class="w-20 h-20 rounded-2xl bg-white border border-[#E5DFD3] shadow-2xs flex items-center justify-center overflow-hidden p-2 transition-all" id="logoPreviewContainer">
                                    @php
                                        $currentLogo = !empty($settings['app_logo']) ? $settings['app_logo'] : (!empty($settings['app_favicon']) ? $settings['app_favicon'] : '');
                                    @endphp
                                    @if(!empty($currentLogo))
                                        <img src="{{ asset($currentLogo) }}" id="logoPreview" class="w-full h-full object-contain" alt="Logo">
                                    @else
                                        <div id="logoPreview" class="w-full h-full flex items-center justify-center bg-[#3E5C45] text-white rounded-xl">
                                            <i class="fa-solid fa-book-open text-2xl"></i>
                                        </div>
                                    @endif
                                </div>
                                <span class="text-[10px] font-bold text-[#7A7569] uppercase tracking-wider mt-1.5">Web Logo</span>
                            </div>

                            <!-- Sync Arrow -->
                            <div class="hidden sm:flex text-[#A19A8D] flex-col items-center px-1">
                                <i class="fa-solid fa-arrow-right text-xs"></i>
                                <span class="text-[9px] font-bold uppercase tracking-tighter text-[#3E5C45] mt-0.5">Syncs</span>
                            </div>

                            <!-- Browser Tab Mini Mockup -->
                            <div class="flex flex-col items-center">
                                <div class="h-20 w-44 rounded-2xl bg-[#E8E2D5]/50 border border-[#E5DFD3] p-2 flex flex-col justify-between shadow-2xs">
                                    <div class="bg-white rounded-lg px-2 py-1.5 border border-[#E5DFD3] flex items-center space-x-2 shadow-xs">
                                        <div class="w-4 h-4 rounded-xs flex items-center justify-center overflow-hidden shrink-0" id="faviconMiniPreviewContainer">
                                            @if(!empty($currentLogo))
                                                <img src="{{ asset($currentLogo) }}" class="w-full h-full object-contain" alt="Favicon">
                                            @else
                                                <div class="w-full h-full bg-[#3E5C45] rounded-xs flex items-center justify-center text-white text-[8px]">
                                                    <i class="fa-solid fa-book text-[7px]"></i>
                                                </div>
                                            @endif
                                        </div>
                                        <span class="text-[10px] font-semibold text-[#16241D] truncate flex-1">{{ $settings['app_name'] ?? 'EasyRead' }}</span>
                                        <i class="fa-solid fa-xmark text-[9px] text-[#A19A8D]"></i>
                                    </div>
                                    <div class="flex items-center space-x-1 px-1">
                                        <div class="w-1.5 h-1.5 rounded-full bg-[#A19A8D]/60"></div>
                                        <div class="w-1.5 h-1.5 rounded-full bg-[#A19A8D]/40"></div>
                                        <span class="text-[9px] text-[#7A7569] font-medium ml-1">Browser Tab</span>
                                    </div>
                                </div>
                                <span class="text-[10px] font-bold text-[#7A7569] uppercase tracking-wider mt-1.5">Tab Favicon</span>
                            </div>
                        </div>

                        <!-- File Input & Controls -->
                        <div class="lg:col-span-7 space-y-2.5">
                            <input type="file" name="app_logo" id="appLogoInput" accept="image/png,image/jpeg,image/svg+xml,image/webp,image/x-icon" onchange="previewWebLogo(this)"
                                   class="block w-full text-xs text-[#7A7569] file:mr-3 file:py-2.5 file:px-5 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-[#3E5C45] file:text-white hover:file:bg-[#2F4936] file:cursor-pointer transition shadow-xs">
                            <input type="hidden" name="remove_logo" id="removeLogoInput" value="0">
                            <div class="flex items-center justify-between flex-wrap gap-2 pt-1">
                                <p class="text-[11px] text-[#7A7569]">
                                    PNG, SVG, JPG, WebP, or ICO (Max 4MB).
                                </p>
                                @if(!empty($currentLogo))
                                    <button type="button" onclick="resetWebLogoToDefault()" class="text-[11px] font-semibold text-rose-600 hover:text-rose-700 hover:underline flex items-center cursor-pointer">
                                        <i class="fa-solid fa-trash-can mr-1"></i> Reset to Default
                                    </button>
                                @endif
                            </div>
                            <p class="text-[11px] text-[#3E5C45] font-medium flex items-center">
                                <i class="fa-solid fa-circle-check mr-1.5 text-xs"></i> Setting this logo updates both website logo and browser favicon automatically.
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Limits & General App Config -->
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
                <div class="border-b border-[#E5DFD3] pb-4">
                    <h3 class="font-serif font-bold text-[#16241D] text-lg">Usage Limits & Contact Info</h3>
                    <p class="text-xs text-[#7A7569] mt-0.5">Configure system usage limits, vocabulary capacity, and reader application settings</p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Reading Speed (WPM — Words Per Minute)
                        </label>
                        <input type="number" name="reading_speed_wpm" value="{{ old('reading_speed_wpm', $settings['reading_speed_wpm'] ?? 200) }}" min="30" max="500"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-xs text-[#7A7569]">Average reading speed used to calculate read time for books (e.g. 200 WPM = Fast, 100 WPM = Slow/Learning). Updating auto-recalculates all books!</p>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Application Name
                        </label>
                        <input type="text" name="app_name" value="{{ old('app_name', $settings['app_name']) }}"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-xs text-[#7A7569]">Display name across the admin studio and reader interfaces.</p>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Support & Help Email
                        </label>
                        <input type="email" name="support_email" value="{{ old('support_email', $settings['support_email'] ?? 'support@easyread.com') }}"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-xs text-[#7A7569]">Contact email shown in reader support flows.</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- TAB 3: In-App Purchases (RevenueCat) -->
        <div id="tab-content-purchases" class="setting-tab-content space-y-6 hidden">
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
                <div class="border-b border-[#E5DFD3] pb-4 flex items-center justify-between">
                    <div>
                        <h3 class="font-serif font-bold text-[#16241D] text-lg">RevenueCat In-App Purchases (iOS & Android)</h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">Configure Apple StoreKit & Google Play Billing credentials powered by RevenueCat</p>
                    </div>
                    <span class="px-3 py-1 rounded-full text-xs font-bold bg-[#3E5C45]/10 text-[#3E5C45]">
                        Mobile Billing SDK
                    </span>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Google Play Public API Key (Android)
                        </label>
                        <input type="text" name="revenuecat_google_key" value="{{ old('revenuecat_google_key', $settings['revenuecat_google_key']) }}" placeholder="goog_..."
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] font-mono text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-xs text-[#7A7569]">Obtain from RevenueCat Project Settings > API Keys > Android (starts with <code class="font-mono text-[#3E5C45]">goog_</code>).</p>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Apple App Store Public API Key (iOS)
                        </label>
                        <input type="text" name="revenuecat_apple_key" value="{{ old('revenuecat_apple_key', $settings['revenuecat_apple_key']) }}" placeholder="appl_..."
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] font-mono text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-xs text-[#7A7569]">Obtain from RevenueCat Project Settings > API Keys > iOS (starts with <code class="font-mono text-[#3E5C45]">appl_</code>).</p>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Entitlement Identifier
                        </label>
                        <input type="text" name="revenuecat_entitlement_id" value="{{ old('revenuecat_entitlement_id', $settings['revenuecat_entitlement_id'] ?? 'plus') }}" placeholder="plus"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] font-mono text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-xs text-[#7A7569]">The entitlement unlocking premium features in RevenueCat (Default: <code class="font-mono text-[#3E5C45]">plus</code>).</p>
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Webhook Authorization Secret (Optional)
                        </label>
                        <input type="text" name="revenuecat_webhook_secret" value="{{ old('revenuecat_webhook_secret', $settings['revenuecat_webhook_secret']) }}" placeholder="Optional secret token"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] font-mono text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-xs text-[#7A7569]">Custom Authorization header sent from RevenueCat dashboard.</p>
                    </div>
                </div>

                <!-- Webhook Endpoint Box -->
                <div class="p-5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] space-y-2">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-bold uppercase tracking-wider text-[#16241D]">RevenueCat Webhook URL Endpoint</span>
                        <span class="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md border border-emerald-200">Live Webhook</span>
                    </div>
                    <div class="flex items-center space-x-2">
                        <input type="text" readonly value="{{ url('/api/revenuecat/webhook') }}" id="webhookUrlInput"
                               class="w-full px-4 py-2.5 rounded-xl border border-[#E5DFD3] bg-white font-mono text-xs text-[#16241D] outline-hidden">
                        <button type="button" onclick="navigator.clipboard.writeText(document.getElementById('webhookUrlInput').value); showAdminToast('RevenueCat Webhook URL Copied to Clipboard!', 'success');"
                                class="px-4 py-2.5 rounded-xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold transition shrink-0">
                            <i class="fa-solid fa-copy mr-1"></i> Copy
                        </button>
                    </div>
                    <p class="text-[11px] text-[#7A7569]">Paste this webhook URL into your RevenueCat Dashboard > Project > Integrations > Webhooks to sync real-time purchases into database.</p>
                </div>
            </div>
        </div>

        <!-- TAB 4: Privacy Policy -->
        <div id="tab-content-privacy" class="setting-tab-content space-y-6 hidden">
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
                <div class="border-b border-[#E5DFD3] pb-4">
                    <div class="flex items-center justify-between">
                        <div>
                            <h3 class="font-serif font-bold text-[#16241D] text-lg">Privacy Policy & Reader Data Terms</h3>
                            <p class="text-xs text-[#7A7569] mt-0.5">This policy syncs live with the mobile app's Privacy & Data section</p>
                        </div>
                        <span class="px-3 py-1 rounded-full text-xs font-bold bg-[#3E5C45]/10 text-[#3E5C45] flex items-center space-x-1.5">
                            <i class="fa-solid fa-mobile-screen-button text-xs"></i>
                            <span>Mobile Synced</span>
                        </span>
                    </div>
                </div>

                <div class="space-y-2">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                        Mobile Privacy Policy Content
                    </label>
                    <textarea name="privacy_policy" rows="10"
                              class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-sans leading-relaxed focus:bg-white focus:border-[#3E5C45] outline-hidden transition">{{ old('privacy_policy', $settings['privacy_policy']) }}</textarea>
                    <p class="text-xs text-[#7A7569]">Readers will see this exact policy when they tap "Privacy & data" in the mobile app's Profile tab.</p>
                </div>
            </div>
        </div>

        <!-- TAB 5: Social Auth (Google & Apple) -->
        <div id="tab-content-social" class="setting-tab-content space-y-6 hidden">
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
                
                <!-- Section Header -->
                <div class="border-b border-[#E5DFD3] pb-4 flex items-center justify-between">
                    <div>
                        <h3 class="font-serif font-bold text-[#16241D] text-lg">Social Authentication & OAuth Settings</h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">Configure 1-tap Google and Apple login options for readers on Android and iOS</p>
                    </div>
                    <span class="px-3 py-1 rounded-full text-xs font-bold bg-[#3E5C45]/10 text-[#3E5C45] flex items-center space-x-1.5">
                        <i class="fa-brands fa-google text-xs"></i>
                        <i class="fa-brands fa-apple text-xs ml-0.5"></i>
                        <span class="ml-1">OAuth Live</span>
                    </span>
                </div>

                <!-- 1. Google Sign-In Configuration -->
                <div class="p-5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] space-y-4">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center space-x-3">
                            <div class="w-10 h-10 rounded-xl bg-white border border-[#E5DFD3] flex items-center justify-center text-rose-500 shadow-2xs">
                                <i class="fa-brands fa-google text-lg"></i>
                            </div>
                            <div>
                                <h4 class="font-bold text-[#16241D] text-sm">Google Sign-In</h4>
                                <p class="text-xs text-[#7A7569]">Allow readers to log in and sign up with their Google accounts</p>
                            </div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="google_auth_enabled" value="1" class="sr-only peer"
                                   {{ ($settings['google_auth_enabled'] ?? '1') == '1' ? 'checked' : '' }}>
                            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E5C45]"></div>
                        </label>
                    </div>

                    <div class="space-y-1.5 pt-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Google Web Client ID (OAuth 2.0)
                        </label>
                        <input type="text" name="google_web_client_id" value="{{ old('google_web_client_id', $settings['google_web_client_id'] ?? '') }}"
                               placeholder="e.g. 1234567890-abcdefg123456.apps.googleusercontent.com"
                               class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                        <p class="text-[11px] text-[#7A7569]">Found in Firebase Console > Authentication > Sign-in method > Google (Web SDK configuration) or Google Cloud Console Credentials.</p>
                    </div>
                </div>

                <!-- 2. Apple Sign-In Configuration -->
                <div class="p-5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] space-y-4">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center space-x-3">
                            <div class="w-10 h-10 rounded-xl bg-white border border-[#E5DFD3] flex items-center justify-center text-black shadow-2xs">
                                <i class="fa-brands fa-apple text-xl"></i>
                            </div>
                            <div>
                                <h4 class="font-bold text-[#16241D] text-sm">Apple Sign-In</h4>
                                <p class="text-xs text-[#7A7569]">Required by Apple App Store guidelines when social login is provided</p>
                            </div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="apple_auth_enabled" value="1" class="sr-only peer"
                                   {{ ($settings['apple_auth_enabled'] ?? '1') == '1' ? 'checked' : '' }}>
                            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E5C45]"></div>
                        </label>
                    </div>
                </div>

                <!-- 3. Firebase Project References -->
                <div class="p-5 rounded-2xl border border-[#E5DFD3] bg-white space-y-4">
                    <div class="flex items-center space-x-2 border-b border-[#E5DFD3] pb-3">
                        <i class="fa-solid fa-fire text-amber-500 text-sm"></i>
                        <h4 class="font-bold text-[#16241D] text-sm">Firebase Reference Credentials (Optional)</h4>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Firebase Project ID
                            </label>
                            <input type="text" name="firebase_project_id" value="{{ old('firebase_project_id', $settings['firebase_project_id'] ?? '') }}"
                                   placeholder="e.g. easyread-reader-1234"
                                   class="w-full px-4 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden">
                        </div>

                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Firebase Web API Key
                            </label>
                            <input type="text" name="firebase_api_key" value="{{ old('firebase_api_key', $settings['firebase_api_key'] ?? '') }}"
                                   placeholder="e.g. AIzaSyD..."
                                   class="w-full px-4 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden">
                        </div>
                    </div>
                </div>

                <!-- Instructions Card -->
                <div class="p-4 rounded-2xl bg-amber-50/70 border border-amber-200/60 flex items-start space-x-3">
                    <i class="fa-solid fa-circle-info text-amber-600 mt-0.5 text-sm"></i>
                    <div class="text-xs text-[#16241D] space-y-1">
                        <p class="font-bold">Setup Tip for Development & Client Handover:</p>
                        <p class="text-[#7A7569] leading-relaxed">
                            When the client takes over the app, they simply paste their own Google Web Client ID here. No app code or rebuild is needed to update server-side verification. Ensure the Android app's SHA-1 fingerprint is added in the corresponding Firebase Console project.
                        </p>
                    </div>
                </div>

            </div>
        </div>

        <!-- TAB 6: SMTP Email Settings -->
        <div id="tab-content-smtp" class="setting-tab-content space-y-6 hidden">
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">

                <!-- Section Header -->
                <div class="border-b border-[#E5DFD3] pb-4 flex items-center justify-between">
                    <div>
                        <h3 class="font-serif font-bold text-[#16241D] text-lg">SMTP Email Settings</h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">Configure outgoing email server for sending OTP password reset codes to users</p>
                    </div>
                    <span class="px-3 py-1 rounded-full text-xs font-bold bg-[#3E5C45]/10 text-[#3E5C45] flex items-center space-x-1.5">
                        <i class="fa-solid fa-envelope text-xs"></i>
                        <span class="ml-1">Forgot Password</span>
                    </span>
                </div>

                <!-- SMTP Configuration Grid -->
                <div class="p-5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] space-y-5">
                    <div class="flex items-center space-x-2 border-b border-[#E5DFD3] pb-3">
                        <i class="fa-solid fa-server text-[#3E5C45] text-sm"></i>
                        <h4 class="font-bold text-[#16241D] text-sm">Server Configuration</h4>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <!-- SMTP Host -->
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                SMTP Host <span class="text-rose-500">*</span>
                            </label>
                            <input type="text" name="smtp_host" id="smtpHost"
                                   value="{{ old('smtp_host', $settings['smtp_host'] ?? '') }}"
                                   placeholder="e.g. smtp.gmail.com"
                                   class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                            <p class="text-[11px] text-[#7A7569]">Gmail: smtp.gmail.com &nbsp;·&nbsp; Outlook: smtp.office365.com</p>
                        </div>

                        <!-- SMTP Port -->
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Port
                            </label>
                            <input type="number" name="smtp_port" id="smtpPort"
                                   value="{{ old('smtp_port', $settings['smtp_port'] ?? '587') }}"
                                   placeholder="587"
                                   class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                            <p class="text-[11px] text-[#7A7569]">587 (TLS recommended) &nbsp;·&nbsp; 465 (SSL) &nbsp;·&nbsp; 25 (plain)</p>
                        </div>

                        <!-- SMTP Username -->
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Username / Email <span class="text-rose-500">*</span>
                            </label>
                            <input type="text" name="smtp_username" id="smtpUsername"
                                   value="{{ old('smtp_username', $settings['smtp_username'] ?? '') }}"
                                   placeholder="e.g. yourapp@gmail.com"
                                   class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                        </div>

                        <!-- SMTP Password -->
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Password / App Password <span class="text-rose-500">*</span>
                            </label>
                            <div class="relative">
                                <input type="password" name="smtp_password" id="smtpPassword"
                                       value="{{ old('smtp_password', $settings['smtp_password'] ?? '') }}"
                                       placeholder="••••••••••••••••"
                                       class="w-full px-4 py-3 pr-10 rounded-xl border border-[#E5DFD3] bg-white font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                                <button type="button" onclick="toggleSmtpPassword()"
                                        class="absolute right-3 top-1/2 -translate-y-1/2 text-[#A19A8D] hover:text-[#16241D] transition">
                                    <i id="smtpPasswordEye" class="fa-solid fa-eye text-xs"></i>
                                </button>
                            </div>
                            <p class="text-[11px] text-[#7A7569]">For Gmail: use an App Password (requires 2-Step Verification ON)</p>
                        </div>
                    </div>

                    <!-- Encryption + From Address -->
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Encryption</label>
                            <select name="smtp_encryption" id="smtpEncryption"
                                    class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                                <option value="tls" {{ ($settings['smtp_encryption'] ?? 'tls') === 'tls' ? 'selected' : '' }}>TLS (Recommended)</option>
                                <option value="ssl" {{ ($settings['smtp_encryption'] ?? '') === 'ssl' ? 'selected' : '' }}>SSL</option>
                                <option value="" {{ ($settings['smtp_encryption'] ?? '') === '' ? 'selected' : '' }}>None</option>
                            </select>
                        </div>

                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">From Address</label>
                            <input type="email" name="smtp_from_address" id="smtpFromAddress"
                                   value="{{ old('smtp_from_address', $settings['smtp_from_address'] ?? '') }}"
                                   placeholder="noreply@yourapp.com"
                                   class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white font-mono text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                        </div>

                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">From Name</label>
                            <input type="text" name="smtp_from_name"
                                   value="{{ old('smtp_from_name', $settings['smtp_from_name'] ?? '') }}"
                                   placeholder="EasyRead"
                                   class="w-full px-4 py-3 rounded-xl border border-[#E5DFD3] bg-white text-xs text-[#16241D] focus:border-[#3E5C45] outline-hidden transition">
                        </div>
                    </div>
                </div>

                <!-- Test Email -->
                <div class="p-5 rounded-2xl border border-[#E5DFD3] bg-white space-y-4">
                    <div class="flex items-center space-x-2 border-b border-[#E5DFD3] pb-3">
                        <i class="fa-solid fa-paper-plane text-[#3E5C45] text-sm"></i>
                        <h4 class="font-bold text-[#16241D] text-sm">Test Email Connection</h4>
                    </div>
                    <p class="text-xs text-[#7A7569]">Send a test email using the settings above (save settings first, then test).</p>
                    <div class="flex items-center gap-3 flex-wrap">
                        <input type="text" id="smtpTestEmail" placeholder="Enter test recipient email"
                               class="flex-1 min-w-[200px] px-4 py-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs text-[#16241D] font-mono focus:border-[#3E5C45] outline-hidden">
                        <button type="button" id="testSmtpBtn" onclick="testSmtpConnection()"
                                class="px-5 py-2.5 rounded-xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold transition flex items-center space-x-2">
                            <i class="fa-solid fa-paper-plane text-xs"></i>
                            <span>Send Test Email</span>
                        </button>
                    </div>
                    <div id="testSmtpResult" class="hidden text-xs font-medium flex items-center space-x-1.5"></div>
                </div>

                <!-- Gmail Setup Guide -->
                <div class="p-4 rounded-2xl bg-blue-50/60 border border-blue-200/60 flex items-start space-x-3">
                    <i class="fa-brands fa-google text-blue-500 mt-0.5 text-sm"></i>
                    <div class="text-xs text-[#16241D] space-y-1.5">
                        <p class="font-bold">Gmail Setup Guide (Easiest):</p>
                        <ol class="text-[#7A7569] leading-relaxed list-decimal pl-4 space-y-1">
                            <li>Go to your Google Account → <strong>Security</strong> → Enable <strong>2-Step Verification</strong></li>
                            <li>Go to <strong>App Passwords</strong> (search in Google Account)</li>
                            <li>Select App: <em>Mail</em>, Device: <em>Other</em>, type "EasyRead", click <strong>Generate</strong></li>
                            <li>Copy the 16-character App Password and paste it in the <strong>Password</strong> field above</li>
                            <li>Host: <code class="bg-blue-100 px-1 rounded">smtp.gmail.com</code>, Port: <code class="bg-blue-100 px-1 rounded">587</code>, Encryption: <code class="bg-blue-100 px-1 rounded">TLS</code></li>
                        </ol>
                    </div>
                </div>

            </div>
        </div>

        <!-- TAB 7: Push & Notifications (In-App & FCM) -->
        <div id="tab-content-notifications" class="setting-tab-content space-y-6 hidden">
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">

                <!-- Card Header -->
                <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
                    <div>
                        <h3 class="font-serif font-bold text-[#16241D] text-lg">Push & In-App Notification Preferences</h3>
                        <p class="text-xs text-[#7A7569] mt-0.5">Control automatic announcements, email triggers, and Firebase Cloud Messaging (FCM) keys</p>
                    </div>
                    <span class="px-3 py-1 rounded-full text-xs font-bold bg-[#3E5C45]/10 text-[#3E5C45] uppercase tracking-wider flex items-center space-x-1.5">
                        <i class="fa-solid fa-bell text-[11px]"></i>
                        <span>Active</span>
                    </span>
                </div>

                <!-- Section 1: Automated Event Triggers -->
                <div class="space-y-4">
                    <h4 class="text-xs font-bold uppercase tracking-wider text-[#16241D] flex items-center space-x-2">
                        <i class="fa-solid fa-bolt text-amber-500"></i>
                        <span>Automated Event Notification Triggers</span>
                    </h4>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        
                        <!-- Toggle 1: In-App Notification Center -->
                        <div class="p-4 rounded-2xl bg-[#F8F5EE] border border-[#E5DFD3] flex items-center justify-between">
                            <div class="space-y-0.5 pr-3">
                                <label for="enableInAppNotifs" class="text-xs font-bold text-[#16241D] cursor-pointer">
                                    In-App Notification Center 🔔
                                </label>
                                <p class="text-[11px] text-[#7A7569]">Enable top-bar Bell icon and announcements inbox in mobile app</p>
                            </div>
                            <label class="relative inline-flex items-center cursor-pointer shrink-0">
                                <input type="checkbox" id="enableInAppNotifs" name="enable_in_app_notifications" value="1" 
                                       {{ ($settings['enable_in_app_notifications'] ?? '1') === '1' ? 'checked' : '' }}
                                       class="sr-only peer">
                                <div class="w-11 h-6 bg-[#E5DFD3] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-[#E5DFD3] after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E5C45]"></div>
                            </label>
                        </div>

                        <!-- Toggle 2: New Book Published Alert -->
                        <div class="p-4 rounded-2xl bg-[#F8F5EE] border border-[#E5DFD3] flex items-center justify-between">
                            <div class="space-y-0.5 pr-3">
                                <label for="enableNewBookNotifs" class="text-xs font-bold text-[#16241D] cursor-pointer">
                                    New Book Broadcast Alerts 📖
                                </label>
                                <p class="text-[11px] text-[#7A7569]">Auto-broadcast in-app notice to readers when you publish a new book</p>
                            </div>
                            <label class="relative inline-flex items-center cursor-pointer shrink-0">
                                <input type="checkbox" id="enableNewBookNotifs" name="enable_new_book_notifications" value="1" 
                                       {{ ($settings['enable_new_book_notifications'] ?? '1') === '1' ? 'checked' : '' }}
                                       class="sr-only peer">
                                <div class="w-11 h-6 bg-[#E5DFD3] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-[#E5DFD3] after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E5C45]"></div>
                            </label>
                        </div>

                        <!-- Toggle 3: Subscription Receipt Emails -->
                        <div class="p-4 rounded-2xl bg-[#F8F5EE] border border-[#E5DFD3] flex items-center justify-between">
                            <div class="space-y-0.5 pr-3">
                                <label for="enableSubEmails" class="text-xs font-bold text-[#16241D] cursor-pointer">
                                    Subscription Invoice Emails 💳
                                </label>
                                <p class="text-[11px] text-[#7A7569]">Send branded confirmation & invoice receipt email on purchase</p>
                            </div>
                            <label class="relative inline-flex items-center cursor-pointer shrink-0">
                                <input type="checkbox" id="enableSubEmails" name="enable_subscription_receipt_emails" value="1" 
                                       {{ ($settings['enable_subscription_receipt_emails'] ?? '1') === '1' ? 'checked' : '' }}
                                       class="sr-only peer">
                                <div class="w-11 h-6 bg-[#E5DFD3] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-[#E5DFD3] after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E5C45]"></div>
                            </label>
                        </div>

                        <!-- Toggle 4: Account Suspension Notices -->
                        <div class="p-4 rounded-2xl bg-[#F8F5EE] border border-[#E5DFD3] flex items-center justify-between">
                            <div class="space-y-0.5 pr-3">
                                <label for="enableSuspensionEmails" class="text-xs font-bold text-[#16241D] cursor-pointer">
                                    Account Suspension Email ⚠️
                                </label>
                                <p class="text-[11px] text-[#7A7569]">Send official notice email when an admin suspends a user account</p>
                            </div>
                            <label class="relative inline-flex items-center cursor-pointer shrink-0">
                                <input type="checkbox" id="enableSuspensionEmails" name="enable_suspension_emails" value="1" 
                                       {{ ($settings['enable_suspension_emails'] ?? '1') === '1' ? 'checked' : '' }}
                                       class="sr-only peer">
                                <div class="w-11 h-6 bg-[#E5DFD3] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-[#E5DFD3] after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E5C45]"></div>
                            </label>
                        </div>

                    </div>
                </div>

                <!-- Section 2: Firebase Cloud Messaging (FCM) Push Settings -->
                <div class="space-y-4 pt-3 border-t border-[#E5DFD3]">
                    <div class="flex items-center justify-between">
                        <h4 class="text-xs font-bold uppercase tracking-wider text-[#16241D] flex items-center space-x-2">
                            <i class="fa-solid fa-cloud text-indigo-500"></i>
                            <span>Firebase Cloud Messaging (FCM) Device Push</span>
                        </h4>
                        
                        <label class="relative inline-flex items-center cursor-pointer shrink-0">
                            <input type="checkbox" name="fcm_enabled" value="1" 
                                   {{ ($settings['fcm_enabled'] ?? '0') === '1' ? 'checked' : '' }}
                                   class="sr-only peer">
                            <div class="w-11 h-6 bg-[#E5DFD3] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-[#E5DFD3] after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#3E5C45]"></div>
                        </label>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        
                        <!-- FCM Project ID -->
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                Firebase Project ID
                            </label>
                            <input type="text" name="fcm_project_id" value="{{ $settings['fcm_project_id'] ?? '' }}" 
                                   placeholder="e.g. easyread-prod-123" 
                                   class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-mono focus:bg-white focus:border-[#3E5C45] outline-hidden transition shadow-2xs">
                        </div>

                        <!-- FCM Sender ID -->
                        <div class="space-y-1.5">
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                FCM Sender ID / Project Number
                            </label>
                            <input type="text" name="fcm_sender_id" value="{{ $settings['fcm_sender_id'] ?? '' }}" 
                                   placeholder="e.g. 109283746501" 
                                   class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-mono focus:bg-white focus:border-[#3E5C45] outline-hidden transition shadow-2xs">
                        </div>

                        <!-- FCM Server / Service Key -->
                        <div class="space-y-1.5 md:col-span-2">
                            <div class="flex items-center justify-between">
                                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                                    FCM Service Account JSON / Server Key
                                </label>
                                @php
                                    $hasServiceAccount = file_exists(storage_path('app/firebase/service-account.json')) || (!empty($settings['fcm_server_key']) && str_starts_with(trim($settings['fcm_server_key']), '{'));
                                @endphp
                                @if($hasServiceAccount)
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800">
                                        <i class="fa-solid fa-circle-check mr-1 text-[9px]"></i> HTTP v1 Active & Connected
                                    </span>
                                @endif
                            </div>
                            <div class="relative">
                                <textarea id="fcmServerKey" name="fcm_server_key" rows="4"
                                          placeholder="Paste your Firebase Service Account JSON (Google Cloud) or Legacy Server Key" 
                                          class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs text-[#16241D] font-mono focus:bg-white focus:border-[#3E5C45] outline-hidden transition shadow-2xs leading-relaxed">{{ $settings['fcm_server_key'] ?? '' }}</textarea>
                            </div>
                            <p class="text-[11px] text-[#7A7569]">
                                Firebase Console → Project Settings → Service Accounts → "Generate new private key" (recommended) or Cloud Messaging Legacy Key.
                            </p>
                        </div>

                    </div>
                </div>

                <!-- Live Test Push Notification (Sound & Popup Verification) -->
                <div class="p-5 rounded-2xl bg-[#F8F5EE] border border-[#E5DFD3] space-y-4">
                    <div class="flex items-center justify-between">
                        <div class="space-y-0.5">
                            <h4 class="text-xs font-bold uppercase tracking-wider text-[#16241D] flex items-center space-x-2">
                                <i class="fa-solid fa-paper-plane text-[#3E5C45]"></i>
                                <span>Test Live Push Notification & Sound</span>
                            </h4>
                            <p class="text-[11px] text-[#7A7569]">Send an instant broadcast test push to verify sound and heads-up banner on mobile devices.</p>
                        </div>
                        <button type="button" id="testPushBtn" onclick="testPushConnection()"
                                class="px-5 py-2.5 rounded-xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold transition flex items-center space-x-2 shadow-2xs cursor-pointer">
                            <i class="fa-solid fa-bell text-xs"></i>
                            <span>Send Test Push Notification</span>
                        </button>
                    </div>
                    <div id="testPushResult" class="hidden"></div>
                </div>

                <!-- Info Guide -->
                <div class="p-4 rounded-2xl bg-amber-50/60 border border-amber-200/60 flex items-start space-x-3">
                    <i class="fa-solid fa-lightbulb text-amber-600 mt-0.5 text-sm"></i>
                    <div class="text-xs text-[#16241D] space-y-1">
                        <p class="font-bold">How Push Notifications Work (Like WhatsApp):</p>
                        <p class="text-[#7A7569] leading-relaxed">
                            When an announcement or book alert is dispatched, the system uses <strong>high-priority FCM channels</strong> with max sound and vibration. This wakes up the device, displays a floating heads-up banner at the top of the screen, and plays the device notification ringtone even if the app is completely closed or killed.
                        </p>
                    </div>
                </div>

            </div>
        </div>

        <!-- TAB 8: Dropbox Cloud Storage -->
        <div id="tab-content-dropbox" class="setting-tab-content space-y-6 hidden">
            <div class="bg-white p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-6">
                
                <!-- Card Header -->
                <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
                    <div class="flex items-center space-x-3">
                        <div class="w-10 h-10 rounded-2xl bg-[#0061FF]/10 flex items-center justify-center text-[#0061FF]">
                            <i class="fa-brands fa-dropbox text-xl"></i>
                        </div>
                        <div>
                            <h3 class="font-serif font-bold text-[#16241D] text-lg">Dropbox Cloud Storage Integration</h3>
                            <p class="text-xs text-[#7A7569] mt-0.5">Configure your Dropbox Developer App Key and Secret for in-app reading & file downloads</p>
                        </div>
                    </div>
                    <span class="px-3 py-1 rounded-full text-xs font-bold {{ !empty($settings['dropbox_app_key']) ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800' }}">
                        {{ !empty($settings['dropbox_app_key']) ? 'Credentials Active' : 'Setup Required' }}
                    </span>
                </div>

                <!-- Enable/Disable Toggle -->
                <div class="p-5 rounded-2xl bg-[#F8F5EE] border border-[#E5DFD3] flex items-center justify-between">
                    <div class="space-y-0.5">
                        <span class="text-xs font-bold uppercase tracking-wider text-[#16241D]">Enable Dropbox Integration</span>
                        <p class="text-xs text-[#7A7569]">Allows app users to browse and import their books (PDF, EPUB, DOCX, TXT) directly from Dropbox.</p>
                    </div>
                    <label class="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" name="dropbox_enabled" value="1" class="sr-only peer" {{ ($settings['dropbox_enabled'] ?? '1') == '1' ? 'checked' : '' }}>
                        <div class="w-11 h-6 bg-[#E5DFD3] peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-[#D5CFBF] after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#0061FF]"></div>
                    </label>
                </div>

                <!-- Credentials Grid -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                    <!-- App Key -->
                    <div class="space-y-1.5">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Dropbox App Key <span class="text-rose-500">*</span>
                        </label>
                        <input type="text" name="dropbox_app_key" id="dropboxAppKey"
                               value="{{ $settings['dropbox_app_key'] ?? '1j22ldywe7y316j' }}" 
                               placeholder="e.g. 1j22ldywe7y316j"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-mono focus:bg-white focus:border-[#0061FF] outline-hidden transition shadow-2xs">
                        <p class="text-[11px] text-[#7A7569]">Your public OAuth 2.0 App Key from the Dropbox App Console.</p>
                    </div>

                    <!-- App Secret -->
                    <div class="space-y-1.5">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Dropbox App Secret <span class="text-rose-500">*</span>
                        </label>
                        <div class="relative">
                            <input type="password" name="dropbox_app_secret" id="dropboxAppSecret"
                                   value="{{ $settings['dropbox_app_secret'] ?? '5vl09ge69dbawph' }}" 
                                   placeholder="e.g. 5vl09ge69dbawph"
                                   class="w-full px-4 py-3 pr-12 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-mono focus:bg-white focus:border-[#0061FF] outline-hidden transition shadow-2xs">
                            <button type="button" onclick="toggleKeyVisibility('dropboxAppSecret', 'dropboxSecretEye')" 
                                    class="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#7A7569] hover:text-[#16241D] transition p-1">
                                <i id="dropboxSecretEye" class="fa-solid fa-eye text-sm"></i>
                            </button>
                        </div>
                        <p class="text-[11px] text-[#7A7569]">Your secret token for authenticating OAuth code exchanges.</p>
                    </div>
                </div>

                <!-- Info Guide & Scopes Requirement -->
                <div class="p-5 rounded-2xl bg-[#0061FF]/5 border border-[#0061FF]/20 space-y-3">
                    <div class="flex items-center space-x-2 text-xs font-bold text-[#0061FF]">
                        <i class="fa-solid fa-circle-info"></i>
                        <span>Dropbox Console Setup Guide</span>
                    </div>
                    <div class="text-xs text-[#16241D] space-y-2">
                        <p class="text-[#7A7569] leading-relaxed">
                            To ensure books can be browsed and opened smoothly, ensure the following permissions are enabled in your 
                            <a href="https://www.dropbox.com/developers/apps" target="_blank" class="text-[#0061FF] underline font-bold">Dropbox Developer Console</a>:
                        </p>
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-3 pt-1">
                            <div class="bg-white p-3 rounded-xl border border-[#E5DFD3]">
                                <span class="font-mono text-xs font-bold text-[#0061FF]">files.metadata.read</span>
                                <p class="text-[10px] text-[#7A7569] mt-0.5">Allows listing folders & files</p>
                            </div>
                            <div class="bg-white p-3 rounded-xl border border-[#E5DFD3]">
                                <span class="font-mono text-xs font-bold text-[#0061FF]">files.content.read</span>
                                <p class="text-[10px] text-[#7A7569] mt-0.5">Allows downloading book files</p>
                            </div>
                            <div class="bg-white p-3 rounded-xl border border-[#E5DFD3]">
                                <span class="font-mono text-xs font-bold text-[#0061FF]">account_info.read</span>
                                <p class="text-[10px] text-[#7A7569] mt-0.5">Shows user display name/email</p>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>

        <!-- Submit Action Bar -->

        <div class="flex items-center justify-end space-x-4 pt-2">
            <button type="submit" 
                    class="px-8 py-3.5 rounded-2xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-sm font-bold shadow-xs hover:shadow-sm transition flex items-center space-x-2">
                <i class="fa-solid fa-check text-xs"></i>
                <span>Save All App Settings</span>
            </button>
        </div>
    </form>
</div>

<script>
function toggleSmtpPassword() {
    const input = document.getElementById('smtpPassword');
    const eye   = document.getElementById('smtpPasswordEye');
    if (input.type === 'password') {
        input.type = 'text';
        eye.className = 'fa-solid fa-eye-slash text-xs';
    } else {
        input.type = 'password';
        eye.className = 'fa-solid fa-eye text-xs';
    }
}

async function testSmtpConnection() {
    const email     = document.getElementById('smtpTestEmail').value.trim();
    const btn       = document.getElementById('testSmtpBtn');
    const resultDiv = document.getElementById('testSmtpResult');

    if (!email) {
        resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200 flex items-center space-x-1.5';
        resultDiv.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-rose-600"></i><span>Please enter a recipient email address.</span>';
        resultDiv.classList.remove('hidden');
        return;
    }

    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin text-xs"></i><span>Sending...</span>';
    resultDiv.className = 'text-xs font-medium text-[#7A7569] flex items-center space-x-1.5';
    resultDiv.innerHTML = '<span>Connecting to SMTP server...</span>';
    resultDiv.classList.remove('hidden');

    try {
        const response = await fetch("{{ route('admin.settings.test-smtp') }}", {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': document.querySelector('meta[name=csrf-token]')?.content || '{{ csrf_token() }}' },
            body: JSON.stringify({ email: email })
        });
        const data = await response.json();
        if (data.success) {
            resultDiv.className = 'text-xs font-bold text-emerald-700 bg-emerald-50 px-3.5 py-2 rounded-xl border border-emerald-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-circle-check text-emerald-600"></i><span>${data.message}</span>`;
        } else {
            resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-triangle-exclamation text-rose-600"></i><span>${data.message}</span>`;
        }
    } catch (e) {
        resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200';
        resultDiv.innerHTML = `Connection error: ${e.message}`;
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-paper-plane text-xs"></i><span>Send Test Email</span>';
    }
}

async function testPushConnection() {
    const serverKey = document.getElementById('fcmServerKey')?.value.trim() || '';
    const btn = document.getElementById('testPushBtn');
    const resultDiv = document.getElementById('testPushResult');

    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin text-xs"></i><span>Broadcasting Push...</span>';
    resultDiv.className = 'text-xs font-medium text-[#7A7569] flex items-center space-x-1.5';
    resultDiv.innerHTML = '<span>Sending high-priority test push to all connected devices...</span>';
    resultDiv.classList.remove('hidden');

    try {
        const response = await fetch("{{ route('admin.settings.test-push') }}", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name=csrf-token]')?.content || '{{ csrf_token() }}'
            },
            body: JSON.stringify({ server_key: serverKey })
        });
        const data = await response.json();
        if (data.success) {
            resultDiv.className = 'text-xs font-bold text-emerald-700 bg-emerald-50 px-3.5 py-2.5 rounded-xl border border-emerald-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-circle-check text-emerald-600"></i><span>${data.message}</span>`;
        } else {
            resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2.5 rounded-xl border border-rose-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-triangle-exclamation text-rose-600"></i><span>${data.message}</span>`;
        }
    } catch (e) {
        resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2.5 rounded-xl border border-rose-200';
        resultDiv.innerHTML = `Connection error: ${e.message}`;
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-bell text-xs"></i><span>Send Test Push Notification</span>';
    }
}

function switchSettingTab(tab) {
    // Hide all tab contents
    document.querySelectorAll('.setting-tab-content').forEach(el => el.classList.add('hidden'));
    // Reset all tab buttons
    document.querySelectorAll('.setting-tab-btn').forEach(btn => {
        btn.classList.remove('bg-[#3E5C45]', 'text-white', 'shadow-xs');
        btn.classList.add('text-[#7A7569]', 'hover:text-[#16241D]', 'hover:bg-[#E5DFD3]/40');
    });

    // Activate selected tab content
    const activeContent = document.getElementById('tab-content-' + tab);
    if (activeContent) {
        activeContent.classList.remove('hidden');
    }

    // Highlight selected tab button
    const activeBtn = document.getElementById('tab-btn-' + tab);
    if (activeBtn) {
        activeBtn.classList.remove('text-[#7A7569]', 'hover:text-[#16241D]', 'hover:bg-[#E5DFD3]/40');
        activeBtn.classList.add('bg-[#3E5C45]', 'text-white', 'shadow-xs');
    }

    // Keep hidden input updated for form submission
    const tabInput = document.getElementById('activeSettingTabInput');
    if (tabInput) {
        tabInput.value = tab;
    }

    // Update URL hash without jumping page
    if (history.replaceState) {
        history.replaceState(null, null, '#tab-' + tab);
    }
}

function onAiProviderChange() {
    const selected = document.getElementById('aiProviderSelect').value;
    
    // Hide all provider fields blocks
    document.querySelectorAll('.provider-fields-block').forEach(el => el.classList.add('hidden'));
    
    // Show selected provider fields block
    const activeBlock = document.getElementById('provider-fields-' + selected);
    if (activeBlock) {
        activeBlock.classList.remove('hidden');
    }

    // Update active badge text
    const badge = document.getElementById('aiActiveBadge');
    if (badge) {
        badge.innerText = 'Active: ' + selected.replace(/_/g, ' ').toUpperCase();
    }
}

function setOpenRouterModel(modelId) {
    const input = document.getElementById('openRouterModel');
    if (input) {
        input.value = modelId;
    }
}

function previewImage(input, containerId) {
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const container = document.getElementById(containerId);
            if (container) {
                container.innerHTML = `<img src="${e.target.result}" class="w-full h-full object-contain p-1.5" alt="Preview">`;
            }
        }
        reader.readAsDataURL(input.files[0]);
    }
}

function previewWebLogo(input) {
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const logoContainer = document.getElementById('logoPreviewContainer');
            const faviconContainer = document.getElementById('faviconMiniPreviewContainer');
            if (logoContainer) {
                logoContainer.innerHTML = `<img src="${e.target.result}" id="logoPreview" class="w-full h-full object-contain" alt="Logo Preview">`;
            }
            if (faviconContainer) {
                faviconContainer.innerHTML = `<img src="${e.target.result}" class="w-full h-full object-contain" alt="Favicon Preview">`;
            }
            const removeInput = document.getElementById('removeLogoInput');
            if (removeInput) removeInput.value = '0';
        };
        reader.readAsDataURL(input.files[0]);
    }
}

function resetWebLogoToDefault() {
    const removeInput = document.getElementById('removeLogoInput');
    if (removeInput) removeInput.value = '1';
    
    const fileInput = document.getElementById('appLogoInput');
    if (fileInput) fileInput.value = '';

    const logoContainer = document.getElementById('logoPreviewContainer');
    const faviconContainer = document.getElementById('faviconMiniPreviewContainer');
    if (logoContainer) {
        logoContainer.innerHTML = `
            <div id="logoPreview" class="w-full h-full flex items-center justify-center bg-[#3E5C45] text-white rounded-xl">
                <i class="fa-solid fa-book-open text-2xl"></i>
            </div>
        `;
    }
    if (faviconContainer) {
        faviconContainer.innerHTML = `
            <div class="w-full h-full bg-[#3E5C45] rounded-xs flex items-center justify-center text-white text-[8px]">
                <i class="fa-solid fa-book text-[7px]"></i>
            </div>
        `;
    }

    if (window.showAppToast) {
        window.showAppToast('Logo reset to default. Click "Save All App Settings" to confirm.', 'info');
    }
}

function toggleKeyVisibility(inputId, iconId) {
    const input = document.getElementById(inputId);
    const icon = document.getElementById(iconId);
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
}

async function testGoogleAiStudioConnection() {
    const apiKey = document.getElementById('googleAiStudioKey').value.trim();
    const model = document.getElementById('googleAiStudioModel').value;
    const btn = document.getElementById('testAiStudioBtn');
    const resultDiv = document.getElementById('testAiStudioResult');

    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin text-xs"></i><span>Testing AI Studio...</span>';
    resultDiv.className = 'text-xs font-medium text-[#7A7569] flex items-center space-x-1.5';
    resultDiv.innerHTML = '<span>Connecting to Google AI Studio API...</span>';
    resultDiv.classList.remove('hidden');

    try {
        const response = await fetch("{{ route('admin.settings.test-google-ai-studio') }}", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ api_key: apiKey, model: model })
        });
        const data = await response.json();

        if (data.success) {
            resultDiv.className = 'text-xs font-bold text-emerald-700 bg-emerald-50 px-3.5 py-2 rounded-xl border border-emerald-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-circle-check text-emerald-600"></i><span>${data.message} (${data.reply})</span>`;
        } else {
            resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-triangle-exclamation text-rose-600"></i><span>${data.message}</span>`;
        }
    } catch (e) {
        resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200';
        resultDiv.innerHTML = `Connection failed: ${e.message}`;
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-bolt text-xs"></i><span>Test Google AI Studio Connection</span>';
    }
}

async function testOpenRouterConnection() {
    const apiKey = document.getElementById('openRouterApiKey').value.trim();
    const model = document.getElementById('openRouterModel').value;
    const btn = document.getElementById('testOpenRouterBtn');
    const resultDiv = document.getElementById('testOpenRouterResult');

    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin text-xs"></i><span>Testing OpenRouter...</span>';
    resultDiv.className = 'text-xs font-medium text-[#7A7569] flex items-center space-x-1.5';
    resultDiv.innerHTML = '<span>Connecting to OpenRouter AI...</span>';
    resultDiv.classList.remove('hidden');

    try {
        const response = await fetch("{{ route('admin.settings.test-openrouter') }}", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ api_key: apiKey, model: model })
        });
        const data = await response.json();

        if (data.success) {
            resultDiv.className = 'text-xs font-bold text-emerald-700 bg-emerald-50 px-3.5 py-2 rounded-xl border border-emerald-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-circle-check text-emerald-600"></i><span>${data.message} (${data.reply})</span>`;
        } else {
            resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-triangle-exclamation text-rose-600"></i><span>${data.message}</span>`;
        }
    } catch (e) {
        resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200';
        resultDiv.innerHTML = `Connection failed: ${e.message}`;
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-bolt text-xs"></i><span>Test OpenRouter Connection</span>';
    }
}

async function testOpenAiConnection() {
    const apiKey = document.getElementById('openAiApiKey').value.trim();
    const model = document.getElementById('openAiModel').value;
    const btn = document.getElementById('testOpenAiBtn');
    const resultDiv = document.getElementById('testOpenAiResult');

    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin text-xs"></i><span>Testing OpenAI...</span>';
    resultDiv.className = 'text-xs font-medium text-[#7A7569] flex items-center space-x-1.5';
    resultDiv.innerHTML = '<span>Connecting to OpenAI ChatGPT API...</span>';
    resultDiv.classList.remove('hidden');

    try {
        const response = await fetch("{{ route('admin.settings.test-openai') }}", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ api_key: apiKey, model: model })
        });
        const data = await response.json();

        if (data.success) {
            resultDiv.className = 'text-xs font-bold text-emerald-700 bg-emerald-50 px-3.5 py-2 rounded-xl border border-emerald-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-circle-check text-emerald-600"></i><span>${data.message} (${data.reply})</span>`;
        } else {
            resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200 flex items-center space-x-1.5';
            resultDiv.innerHTML = `<i class="fa-solid fa-triangle-exclamation text-rose-600"></i><span>${data.message}</span>`;
        }
    } catch (e) {
        resultDiv.className = 'text-xs font-bold text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-200';
        resultDiv.innerHTML = `Connection failed: ${e.message}`;
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-bolt text-xs"></i><span>Test OpenAI Connection</span>';
    }
}

// ============================================================
// DYNAMIC LANGUAGE TAGS (TOGGLE & REAL-TIME FILLING)
// ============================================================
function getSelectedLanguages() {
    const input = document.getElementById('translationLanguagesInput');
    if (!input) return [];
    return input.value
        .split(',')
        .map(s => s.trim())
        .filter(Boolean);
}

function syncLanguageTags() {
    const selectedList = getSelectedLanguages();
    const selectedLower = selectedList.map(s => s.toLowerCase());
    const buttons = document.querySelectorAll('.lang-tag-btn');
    const counter = document.getElementById('selectedLanguagesCount');

    buttons.forEach(btn => {
        const lang = btn.getAttribute('data-lang');
        if (!lang) return;
        const isSelected = selectedLower.includes(lang.toLowerCase());
        const icon = btn.querySelector('.lang-icon');

        if (isSelected) {
            // Filled & Highlighted Style
            btn.className = 'lang-tag-btn px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center cursor-pointer border shadow-xs bg-[#3E5C45] text-white border-[#3E5C45] ring-2 ring-[#3E5C45]/25';
            if (icon) {
                icon.className = 'lang-icon fa-solid fa-check text-[10px] mr-1.5 text-emerald-300';
            }
        } else {
            // Outlined & Unselected Style
            btn.className = 'lang-tag-btn px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center cursor-pointer border shadow-2xs bg-white text-[#5C5649] border-[#E5DFD3] hover:border-[#3E5C45] hover:text-[#16241D] hover:bg-[#F3EFE6]';
            if (icon) {
                icon.className = 'lang-icon fa-solid fa-plus text-[10px] mr-1.5 text-[#A19A8D]';
            }
        }
    });

    if (counter) {
        const count = selectedList.length;
        counter.innerText = count === 1 ? '1 language selected' : `${count} languages selected`;
    }
}

function toggleLanguageTag(lang) {
    const input = document.getElementById('translationLanguagesInput');
    if (!input) return;

    let list = getSelectedLanguages();
    const existingIdx = list.findIndex(item => item.toLowerCase() === lang.toLowerCase());

    if (existingIdx !== -1) {
        // Already selected -> Remove it
        list.splice(existingIdx, 1);
    } else {
        // Not selected -> Add it
        list.push(lang);
    }

    input.value = list.join(', ');
    syncLanguageTags();
}

// Attach input listeners for real-time synchronization & Tab Auto-Restore
document.addEventListener('DOMContentLoaded', function() {
    const input = document.getElementById('translationLanguagesInput');
    if (input) {
        input.addEventListener('input', syncLanguageTags);
        input.addEventListener('change', syncLanguageTags);
    }
    syncLanguageTags();

    // Auto-restore tab: Priority: URL hash (#tab-notifications) -> hidden active input -> default
    let initialTab = '';
    const hash = window.location.hash;
    if (hash && hash.startsWith('#tab-')) {
        initialTab = hash.replace('#tab-', '');
    } else {
        const tabInput = document.getElementById('activeSettingTabInput');
        if (tabInput && tabInput.value) {
            initialTab = tabInput.value;
        }
    }

    if (initialTab && document.getElementById('tab-content-' + initialTab)) {
        switchSettingTab(initialTab);
    }
});

// Immediately sync if DOM already ready
syncLanguageTags();
</script>
@endsection
