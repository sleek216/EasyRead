@extends('admin.layout')

@section('title', 'Categories - Easy Read Studio')
@section('page_title', 'Categories')

@section('content')
<div class="space-y-6">

    <!-- Top Action Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <!-- Search Input -->
        <form method="GET" action="{{ route('admin.categories.index') }}" class="relative max-w-md w-full">
            <i class="fa-solid fa-magnifying-glass absolute left-4 top-1/2 -translate-y-1/2 text-[#7A7569] text-xs"></i>
            <input type="text" name="search" value="{{ $search ?? '' }}" placeholder="Search categories..."
                   class="w-full pl-10 pr-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-white text-xs text-[#16241D] placeholder-[#7A7569] focus:border-[#3E5C45] focus:ring-1 focus:ring-[#3E5C45] outline-hidden shadow-2xs">
        </form>

        <!-- Add Category Button -->
        <button type="button" onclick="openCreateModal()"
                class="px-5 py-2.5 rounded-2xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold shadow-xs hover:shadow-sm transition flex items-center justify-center space-x-2 shrink-0">
            <i class="fa-solid fa-plus text-xs"></i>
            <span>Add Category</span>
        </button>
    </div>

    <!-- Categories Grid / Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        @forelse($categories as $category)
            <div class="bg-white p-5 rounded-3xl border border-[#E5DFD3] shadow-xs hover:shadow-sm transition flex flex-col justify-between space-y-4">
                <div class="flex items-start justify-between">
                    <div class="flex items-center space-x-3">
                        <div class="w-10 h-10 rounded-2xl flex items-center justify-center text-white text-base shadow-xs shrink-0"
                             style="background-color: {{ $category->color_hex ?? '#3E5C45' }};">
                            <i class="fa-solid fa-bookmark"></i>
                        </div>
                        <div>
                            <h3 class="font-serif font-bold text-[#16241D] text-base leading-tight">{{ $category->name }}</h3>
                            <span class="text-[11px] font-mono font-medium text-[#7A7569] block mt-0.5">#{{ $category->slug }}</span>
                        </div>
                    </div>

                    <!-- Books Count Pill -->
                    <span class="px-2.5 py-1 rounded-full bg-[#F3EFE6] text-[#3E5C45] text-xs font-bold shrink-0">
                        {{ $category->books_count }} {{ Str::plural('book', $category->books_count) }}
                    </span>
                </div>

                <div class="flex items-center justify-between pt-2 border-t border-[#E5DFD3]/60 text-xs">
                    <span class="text-[11px] text-[#7A7569] flex items-center space-x-1.5">
                        <span class="w-2.5 h-2.5 rounded-full inline-block" style="background-color: {{ $category->color_hex }};"></span>
                        <span class="font-mono">{{ strtoupper($category->color_hex) }}</span>
                    </span>

                    <div class="flex items-center space-x-1">
                        <!-- Edit Button -->
                        <button type="button" 
                                onclick="openEditModal({{ $category->id }}, '{{ addslashes($category->name) }}', '{{ addslashes($category->slug) }}', '{{ $category->color_hex }}')"
                                class="p-1.5 rounded-xl text-[#7A7569] hover:text-[#3E5C45] hover:bg-[#F3EFE6] transition"
                                title="Edit Category">
                            <i class="fa-solid fa-pen-to-square"></i>
                        </button>

                        <!-- Delete Form -->
                        <form action="{{ route('admin.categories.destroy', $category->id) }}" method="POST" class="inline"
                              data-confirm="Are you sure you want to delete category '{{ addslashes($category->name) }}'? Any associated books will be detached.">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="p-1.5 rounded-xl text-[#7A7569] hover:text-rose-600 hover:bg-rose-50 transition" title="Delete Category">
                                <i class="fa-solid fa-trash-can"></i>
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        @empty
            <div class="col-span-full py-16 text-center bg-white rounded-3xl border border-[#E5DFD3]">
                <div class="w-12 h-12 rounded-2xl bg-[#F3EFE6] text-[#7A7569] flex items-center justify-center mx-auto text-lg mb-3">
                    <i class="fa-solid fa-bookmark"></i>
                </div>
                <h4 class="text-sm font-bold text-[#16241D]">No categories found</h4>
                <p class="text-xs text-[#7A7569] mt-1">Click "Add Category" above to create your first category.</p>
            </div>
        @endforelse
    </div>

    <!-- Pagination -->
    @if($categories->hasPages())
        <div class="pt-2">
            {{ $categories->appends(['search' => $search])->links() }}
        </div>
    @endif
</div>

<!-- Create Category Modal -->
<div id="createCategoryModal" class="fixed inset-0 bg-black/40 backdrop-blur-xs z-50 hidden flex items-center justify-center p-4">
    <div class="bg-white max-w-md w-full rounded-3xl p-7 shadow-2xl border border-[#E5DFD3] space-y-5 animate-scale-in">
        <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
            <div>
                <h3 class="font-serif font-bold text-[#16241D] text-lg">Add New Category</h3>
                <p class="text-xs text-[#7A7569] mt-0.5">Readers will see this category filter across the app</p>
            </div>
            <button onclick="closeCreateModal()" class="text-[#7A7569] hover:text-[#16241D] p-1">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>

        <form action="{{ route('admin.categories.store') }}" method="POST" class="space-y-4">
            @csrf
            <div class="space-y-1.5">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Category Name <span class="text-rose-500">*</span></label>
                <input type="text" name="name" required placeholder="e.g. Fiction, Psychology, Science"
                       class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
            </div>

            <div class="space-y-1.5">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Slug / URL Key (Optional)</label>
                <input type="text" name="slug" placeholder="e.g. fiction, psychology"
                       class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
            </div>

            <div class="space-y-1.5">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Color Theme</label>
                <div class="flex items-center space-x-3">
                    <input type="color" name="color_hex" value="#3E5C45" 
                           class="w-10 h-10 rounded-xl border border-[#E5DFD3] cursor-pointer p-0.5 bg-white">
                    <span class="text-xs text-[#7A7569]">Select a theme color for category badges</span>
                </div>
            </div>

            <div class="flex items-center justify-end space-x-3 pt-3 border-t border-[#E5DFD3]">
                <button type="button" onclick="closeCreateModal()" class="px-5 py-2.5 rounded-xl border border-[#E5DFD3] text-xs font-bold text-[#7A7569] hover:bg-[#F3EFE6] transition">
                    Cancel
                </button>
                <button type="submit" class="px-6 py-2.5 rounded-xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold transition shadow-xs">
                    Save Category
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Edit Category Modal -->
<div id="editCategoryModal" class="fixed inset-0 bg-black/40 backdrop-blur-xs z-50 hidden flex items-center justify-center p-4">
    <div class="bg-white max-w-md w-full rounded-3xl p-7 shadow-2xl border border-[#E5DFD3] space-y-5">
        <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
            <div>
                <h3 class="font-serif font-bold text-[#16241D] text-lg">Edit Category</h3>
                <p class="text-xs text-[#7A7569] mt-0.5">Update category details and color theme</p>
            </div>
            <button onclick="closeEditModal()" class="text-[#7A7569] hover:text-[#16241D] p-1">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>

        <form id="editCategoryForm" method="POST" class="space-y-4">
            @csrf
            @method('PUT')
            <div class="space-y-1.5">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Category Name <span class="text-rose-500">*</span></label>
                <input type="text" id="editName" name="name" required
                       class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
            </div>

            <div class="space-y-1.5">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Slug / URL Key</label>
                <input type="text" id="editSlug" name="slug"
                       class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
            </div>

            <div class="space-y-1.5">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Color Theme</label>
                <div class="flex items-center space-x-3">
                    <input type="color" id="editColor" name="color_hex"
                           class="w-10 h-10 rounded-xl border border-[#E5DFD3] cursor-pointer p-0.5 bg-white">
                    <span class="text-xs text-[#7A7569]">Select a theme color</span>
                </div>
            </div>

            <div class="flex items-center justify-end space-x-3 pt-3 border-t border-[#E5DFD3]">
                <button type="button" onclick="closeEditModal()" class="px-5 py-2.5 rounded-xl border border-[#E5DFD3] text-xs font-bold text-[#7A7569] hover:bg-[#F3EFE6] transition">
                    Cancel
                </button>
                <button type="submit" class="px-6 py-2.5 rounded-xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold transition shadow-xs">
                    Update Category
                </button>
            </div>
        </form>
    </div>
</div>

<script>
function openCreateModal() {
    document.getElementById('createCategoryModal').classList.remove('hidden');
}
function closeCreateModal() {
    document.getElementById('createCategoryModal').classList.add('hidden');
}

function openEditModal(id, name, slug, color) {
    document.getElementById('editCategoryForm').action = `/admin/categories/${id}`;
    document.getElementById('editName').value = name;
    document.getElementById('editSlug').value = slug;
    document.getElementById('editColor').value = color || '#3E5C45';
    document.getElementById('editCategoryModal').classList.remove('hidden');
}
function closeEditModal() {
    document.getElementById('editCategoryModal').classList.add('hidden');
}
</script>
@endsection
