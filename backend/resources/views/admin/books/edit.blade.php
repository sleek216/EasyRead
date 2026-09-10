@extends('admin.layout')

@section('title', 'Edit Book - Easy Read')
@section('page_title', 'Edit Book / Article')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">

    <div class="bg-white rounded-2xl border border-gray-200 shadow-sm p-6 sm:p-8">
        <form action="{{ route('admin.books.update', $book->id) }}" method="POST" class="space-y-6">
            @csrf
            @method('PUT')

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <!-- Book Title -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Book / Article Title *</label>
                    <input type="text" name="title" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]" value="{{ old('title', $book->title) }}">
                    @error('title') <span class="text-rose-600 text-xs mt-1 block">{{ $message }}</span> @enderror
                </div>

                <!-- Author Name -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Author Name *</label>
                    <input type="text" name="author" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]" value="{{ old('author', $book->author) }}">
                    @error('author') <span class="text-rose-600 text-xs mt-1 block">{{ $message }}</span> @enderror
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <!-- Category (Dynamic from DB) -->
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <label class="block text-xs font-bold text-gray-700 uppercase tracking-wider">Category *</label>
                        <a href="{{ route('admin.categories.index') }}" target="_blank" class="text-[11px] font-semibold text-[#4B6B4A] hover:underline flex items-center gap-1" title="Manage categories in a new tab">
                            <i class="fa-solid fa-plus text-[9px]"></i> New Category
                        </a>
                    </div>
                    <select name="category" required class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                        @forelse($categories as $cat)
                            <option value="{{ $cat->name }}" {{ old('category', $book->category) === $cat->name ? 'selected' : '' }}>
                                {{ $cat->name }}
                            </option>
                        @empty
                            <option value="General">General</option>
                        @endforelse
                    </select>
                </div>

                <!-- Cover Theme / Color -->
                <div>
                    <label class="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Cover Color Style *</label>
                    <select name="cover_color" class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">
                        @foreach(['forest' => 'Forest Moss', 'gold' => 'Vintage Gold', 'navy' => 'Classic Navy', 'paper' => 'Warm Sand', 'rose' => 'Dusky Rose'] as $val => $label)
                        <option value="{{ $val }}" {{ $book->cover_color === $val ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <!-- Full Content Text -->
            <div>
                <div class="flex items-center justify-between mb-2">
                    <label class="block text-xs font-bold text-gray-700 uppercase tracking-wider">Book / Article Text Content *</label>
                    <span class="text-[11px] text-gray-400 font-medium">Paragraphs are automatically separated by empty lines</span>
                </div>
                <textarea name="content_text" rows="12" required class="w-full p-4 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4B6B4A]">{{ old('content_text', $contentText) }}</textarea>
                @error('content_text') <span class="text-rose-600 text-xs mt-1 block">{{ $message }}</span> @enderror
            </div>

            <!-- Submit Buttons -->
            <div class="flex items-center justify-end space-x-3 pt-4 border-t border-gray-100">
                <a href="{{ route('admin.books.index') }}" class="px-5 py-2.5 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50 text-xs font-bold transition">Cancel</a>
                <button type="submit" class="px-6 py-2.5 rounded-xl bg-[#4B6B4A] hover:bg-[#3d573c] text-white text-xs font-bold transition shadow-sm">
                    <i class="fa-solid fa-floppy-disk mr-2"></i> Update Book & Paragraphs
                </button>
            </div>
        </form>
    </div>

</div>
@endsection
