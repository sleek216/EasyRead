@extends('admin.layout')

@section('title', 'Add New Book - Easy Read Studio')
@section('page_title', 'Add New Book / Document')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">

    <!-- Header Banner Card -->
    <div class="bg-white p-6 sm:p-7 rounded-3xl border border-[#E5DFD3] shadow-xs space-y-2">
        <div class="flex items-center space-x-3">
            <div class="w-10 h-10 rounded-2xl bg-[#4B6B4A] text-white flex items-center justify-center font-bold text-lg shadow-xs">
                <i class="fa-solid fa-file-arrow-up"></i>
            </div>
            <div>
                <h3 class="font-serif font-bold text-xl text-[#16241D]">Publish Book to Mobile App Library</h3>
                <p class="text-xs text-[#7A7569]">Upload PDF, import Web URL, or paste plain text. Pure clean text is extracted without images or graphics.</p>
            </div>
        </div>
    </div>

    <!-- Main Creation Form Card -->
    <div class="bg-white rounded-3xl border border-[#E5DFD3] shadow-xs p-6 sm:p-8">
        <form action="{{ route('admin.books.store') }}" method="POST" enctype="multipart/form-data" class="space-y-6" id="bookCreateForm">
            @csrf
            <input type="hidden" name="input_source" id="input_source" value="{{ old('input_source', 'text') }}">

            <!-- 1. SOURCE SELECTOR TABS -->
            <div class="space-y-2">
                <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Select Content Source *</label>
                <div class="grid grid-cols-3 gap-3 p-1.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-2xl">
                    <!-- Plain Text Tab -->
                    <button type="button" onclick="switchSourceTab('text')" id="tab_text"
                            class="py-2.5 px-3 rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center space-x-2 transition shadow-xs">
                        <i class="fa-solid fa-align-left text-xs"></i>
                        <span>Paste Plain Text</span>
                    </button>

                    <!-- PDF File Upload Tab -->
                    <button type="button" onclick="switchSourceTab('pdf')" id="tab_pdf"
                            class="py-2.5 px-3 rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center space-x-2 transition">
                        <i class="fa-solid fa-file-pdf text-xs"></i>
                        <span>Upload PDF File</span>
                    </button>

                    <!-- Web URL Link Tab -->
                    <button type="button" onclick="switchSourceTab('url')" id="tab_url"
                            class="py-2.5 px-3 rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center space-x-2 transition">
                        <i class="fa-solid fa-globe text-xs"></i>
                        <span>Import Web URL</span>
                    </button>
                </div>
            </div>

            <!-- 2. DYNAMIC SOURCE INPUT PANELS -->
            
            <!-- PANEL A: PLAIN TEXT -->
            <div id="panel_text" class="space-y-2">
                <div class="flex items-center justify-between">
                    <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Full Text Content *</label>
                    <span class="text-[11px] text-[#7A7569] font-medium">Empty lines automatically form individual reading paragraphs</span>
                </div>
                <textarea name="content_text" id="content_text_input" rows="10" 
                          placeholder="Paste full book chapter or essay text here. Images, HTML links, and graphics are stripped out automatically..."
                          class="w-full p-4 bg-[#FDFBF7] border border-[#E5DFD3] rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A] text-[#16241D] leading-relaxed">{{ old('content_text') }}</textarea>
                @error('content_text') <span class="text-rose-600 text-xs mt-1 block font-semibold">{{ $message }}</span> @enderror
            </div>

            <!-- PANEL B: PDF FILE UPLOAD -->
            <div id="panel_pdf" class="space-y-3 hidden">
                <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Upload PDF Document *</label>
                <div class="border-2 border-dashed border-[#4B6B4A]/40 hover:border-[#4B6B4A] bg-[#FDFBF7] rounded-3xl p-8 text-center transition cursor-pointer relative" id="pdf_drop_zone">
                    <input type="file" name="pdf_file" id="pdf_file_input" accept=".pdf" class="absolute inset-0 w-full h-full opacity-0 cursor-pointer" onchange="handlePdfFileSelected(this)">
                    <div class="space-y-3 pointer-events-none">
                        <div class="w-14 h-14 rounded-2xl bg-[#F3EFE6] text-[#4B6B4A] flex items-center justify-center text-2xl font-bold mx-auto border border-[#E5DFD3]">
                            <i class="fa-solid fa-file-pdf"></i>
                        </div>
                        <div>
                            <p class="font-bold text-sm text-[#16241D]" id="pdf_file_label">Click or Drag & Drop PDF File Here</p>
                            <p class="text-xs text-[#7A7569] mt-1">Extracts clean text paragraphs only • Max size 25 MB</p>
                        </div>
                    </div>
                </div>
                @error('pdf_file') <span class="text-rose-600 text-xs mt-1 block font-semibold">{{ $message }}</span> @enderror
            </div>

            <!-- PANEL C: WEB URL IMPORT -->
            <div id="panel_url" class="space-y-3 hidden">
                <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Web Article Link (URL) *</label>
                <div class="flex items-center space-x-2">
                    <div class="relative flex-1">
                        <i class="fa-solid fa-link absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-xs"></i>
                        <input type="url" name="source_url" id="source_url_input" placeholder="https://example.com/article-slug"
                               value="{{ old('source_url') }}"
                               class="w-full pl-10 pr-4 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-2xl text-xs sm:text-sm text-[#16241D] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                    </div>
                    <button type="button" onclick="triggerExtractPreview()" class="px-5 py-2.5 bg-[#F3EFE6] hover:bg-[#EAE4D7] text-[#16241D] font-bold text-xs sm:text-sm rounded-2xl transition border border-[#E5DFD3] shrink-0">
                        <i class="fa-solid fa-wand-magic-sparkles mr-1.5 text-[#4B6B4A]"></i> Extract Text
                    </button>
                </div>
                <p class="text-xs text-[#7A7569]">Strips all ads, images, navigation menus, and scripts automatically.</p>
                @error('source_url') <span class="text-rose-600 text-xs mt-1 block font-semibold">{{ $message }}</span> @enderror
            </div>

            <!-- EXTRACTION PREVIEW STATUS BAR -->
            <div id="extraction_preview_card" class="hidden p-4 rounded-2xl bg-[#F3EFE6] border border-[#E5DFD3] space-y-2 animate-in fade-in duration-200">
                <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-2 text-xs font-bold text-[#4B6B4A]">
                        <i class="fa-solid fa-circle-check text-sm"></i>
                        <span>Text Extraction Ready</span>
                    </div>
                    <div class="flex items-center space-x-3 text-[11px] font-semibold text-[#7A7569]">
                        <span id="preview_paras_count">0 paras</span>
                        <span>•</span>
                        <span id="preview_words_count">0 words</span>
                        <span>•</span>
                        <span id="preview_read_time">0 min read</span>
                    </div>
                </div>
                <p class="text-xs text-[#16241D] italic line-clamp-2" id="preview_snippet_text">"Clean text preview will show here..."</p>
            </div>

            <!-- 3. BOOK METADATA (TITLE, AUTHOR, CATEGORY, COVER) -->
            <div class="pt-4 border-t border-[#E5DFD3] space-y-5">
                <h4 class="font-serif font-bold text-base text-[#16241D]">Book Metadata & Library Placement</h4>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                    <!-- Book Title -->
                    <div class="space-y-1.5">
                        <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Book / Article Title</label>
                        <input type="text" name="title" id="book_title_input" 
                               placeholder="e.g. Meditations: Inner Peace (optional)" 
                               value="{{ old('title') }}"
                               class="w-full px-4 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-2xl text-xs sm:text-sm text-[#16241D] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                        @error('title') <span class="text-rose-600 text-xs mt-1 block font-semibold">{{ $message }}</span> @enderror
                    </div>

                    <!-- Author Name -->
                    <div class="space-y-1.5">
                        <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Author Name</label>
                        <input type="text" name="author" id="book_author_input" 
                               placeholder="e.g. Marcus Aurelius (optional)" 
                               value="{{ old('author') }}"
                               class="w-full px-4 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-2xl text-xs sm:text-sm text-[#16241D] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                        @error('author') <span class="text-rose-600 text-xs mt-1 block font-semibold">{{ $message }}</span> @enderror
                    </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                    <!-- Category -->
                    <div class="space-y-1.5">
                        <div class="flex items-center justify-between">
                            <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Category *</label>
                            <a href="{{ route('admin.categories.index') }}" target="_blank" class="text-[11px] font-semibold text-[#4B6B4A] hover:underline flex items-center gap-1" title="Manage categories in a new tab">
                                <i class="fa-solid fa-plus text-[9px]"></i> New
                            </a>
                        </div>
                        <select name="category" required class="w-full px-4 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-2xl text-xs sm:text-sm text-[#16241D] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                            @forelse($categories as $cat)
                                <option value="{{ $cat->name }}" {{ old('category') === $cat->name ? 'selected' : '' }}>
                                    {{ $cat->name }}
                                </option>
                            @empty
                                <option value="General">General</option>
                            @endforelse
                        </select>
                    </div>

                    <!-- Cover Color Style -->
                    <div class="space-y-1.5">
                        <label class="block text-xs font-bold text-[#16241D] uppercase tracking-wider">Cover Theme *</label>
                        <select name="cover_color" class="w-full px-4 py-2.5 bg-[#FDFBF7] border border-[#E5DFD3] rounded-2xl text-xs sm:text-sm text-[#16241D] focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                            <option value="#4B6B4A" selected>Forest Moss (Green)</option>
                            <option value="#C28B38">Vintage Gold (Amber)</option>
                            <option value="#2E4C6D">Classic Navy (Blue)</option>
                            <option value="#6E3B4E">Plum (Purple)</option>
                            <option value="#8B5A2B">Warm Ochre (Brown)</option>
                        </select>
                    </div>
                </div>
            </div>

            <!-- Submit Buttons -->
            <div class="flex items-center justify-end space-x-3 pt-4 border-t border-[#E5DFD3]">
                <a href="{{ route('admin.books.index') }}" class="px-5 py-2.5 rounded-2xl border border-[#E5DFD3] text-[#7A7569] hover:bg-[#F3EFE6] text-xs font-bold transition">Cancel</a>
                <button type="submit" class="px-6 py-2.5 rounded-2xl bg-[#4B6B4A] hover:bg-[#3A5439] active:scale-[0.99] text-white text-xs sm:text-sm font-bold transition shadow-xs flex items-center space-x-2">
                    <i class="fa-solid fa-cloud-arrow-up text-xs"></i>
                    <span>Extract & Publish Book</span>
                </button>
            </div>
        </form>
    </div>

</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
<script>
    if (typeof pdfjsLib !== 'undefined') {
        pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
    }

    function switchSourceTab(source) {
        document.getElementById('input_source').value = source;

        const tabs = ['text', 'pdf', 'url'];
        tabs.forEach(t => {
            const btn = document.getElementById('tab_' + t);
            const panel = document.getElementById('panel_' + t);

            if (t === source) {
                btn.className = 'py-2.5 px-3 rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center space-x-2 transition shadow-xs bg-[#16241D] text-white';
                panel.classList.remove('hidden');
            } else {
                btn.className = 'py-2.5 px-3 rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center space-x-2 transition text-[#7A7569] hover:bg-[#F3EFE6] hover:text-[#16241D]';
                panel.classList.add('hidden');
            }
        });
    }

    async function handlePdfFileSelected(input) {
        if (!input.files || !input.files[0]) return;

        const file = input.files[0];
        document.getElementById('pdf_file_label').innerText = 'Selected: ' + file.name + ' (' + (file.size / 1024 / 1024).toFixed(2) + ' MB)';
        
        // Auto fill title if empty
        const titleInput = document.getElementById('book_title_input');
        if (!titleInput.value) {
            let cleanName = file.name.replace(/\.pdf$/i, '').replace(/[-_]/g, ' ');
            titleInput.value = cleanName.charAt(0).toUpperCase() + cleanName.slice(1);
        }

        const previewCard = document.getElementById('extraction_preview_card');
        const snippetText = document.getElementById('preview_snippet_text');
        
        snippetText.innerText = "Parsing PDF pages and extracting clean text...";
        previewCard.classList.remove('hidden');

        // Client-side PDF.js Extraction Engine
        if (typeof pdfjsLib !== 'undefined') {
            try {
                const arrayBuffer = await file.arrayBuffer();
                const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
                let extractedText = '';

                for (let i = 1; i <= pdf.numPages; i++) {
                    const page = await pdf.getPage(i);
                    const textContent = await page.getTextContent();
                    const pageText = textContent.items.map(item => item.str).join(' ');
                    if (pageText.trim().length > 10) {
                        extractedText += pageText.trim() + '\n\n';
                    }
                }

                if (extractedText.trim().length > 30) {
                    document.getElementById('content_text_input').value = extractedText;
                    
                    const paras = extractedText.split(/\n\s*\n/).filter(p => p.trim().length > 15);
                    const words = extractedText.split(/\s+/).filter(Boolean).length;
                    
                    document.getElementById('preview_paras_count').innerText = paras.length + ' paras';
                    document.getElementById('preview_words_count').innerText = words + ' words';
                    document.getElementById('preview_read_time').innerText = Math.ceil(paras.length * 1.2) + ' min read';
                    snippetText.innerText = '"' + paras[0].substring(0, 150) + '..."';
                    return;
                }
            } catch (err) {
                console.log("PDF.js notice: falling back to server-side extraction", err);
            }
        }

        // Fallback to server-side preview endpoint
        triggerExtractPreview();
    }

    function triggerExtractPreview() {
        const source = document.getElementById('input_source').value;
        const formData = new FormData(document.getElementById('bookCreateForm'));

        const previewCard = document.getElementById('extraction_preview_card');
        const snippetText = document.getElementById('preview_snippet_text');
        
        snippetText.innerText = "Extracting clean text paragraphs without images or links...";
        previewCard.classList.remove('hidden');

        fetch("{{ route('admin.books.extract-preview') }}", {
            method: "POST",
            body: formData,
            headers: {
                "X-CSRF-TOKEN": "{{ csrf_token() }}",
                "Accept": "application/json"
            }
        })
        .then(res => res.json())
        .then(data => {
            if (data.success && data.paragraphs.length > 0) {
                document.getElementById('preview_paras_count').innerText = data.paragraph_count + ' paras';
                document.getElementById('preview_words_count').innerText = data.word_count + ' words';
                document.getElementById('preview_read_time').innerText = data.read_time;
                snippetText.innerText = '"' + data.paragraphs[0].substring(0, 140) + '..."';

                const titleInput = document.getElementById('book_title_input');
                if (!titleInput.value && data.title) {
                    titleInput.value = data.title;
                }
            } else {
                snippetText.innerText = "Ready to extract text upon publish.";
            }
        })
        .catch(() => {
            snippetText.innerText = "Ready to extract text upon publish.";
        });
    }

    // Initialize default tab
    switchSourceTab('text');
</script>
@endsection
