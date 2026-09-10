<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminCategoryController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->query('search');

        $query = Category::withCount('books');

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('slug', 'like', "%{$search}%");
            });
        }

        $categories = $query->orderBy('sort_order')->orderBy('name')->paginate(15);

        return view('admin.categories.index', compact('categories', 'search'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'slug' => 'nullable|string|max:100|unique:categories,slug',
            'color_hex' => 'required|string|max:20',
        ]);

        $slug = !empty($validated['slug']) ? Str::slug($validated['slug']) : Str::slug($validated['name']);

        Category::create([
            'name' => trim($validated['name']),
            'slug' => $slug,
            'color_hex' => $validated['color_hex'],
            'sort_order' => (Category::max('sort_order') + 1),
        ]);

        return redirect()->route('admin.categories.index')->with('success', 'Category "' . $validated['name'] . '" created successfully.');
    }

    public function update(Request $request, $id)
    {
        $category = Category::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'slug' => 'nullable|string|max:100|unique:categories,slug,' . $category->id,
            'color_hex' => 'required|string|max:20',
        ]);

        $slug = !empty($validated['slug']) ? Str::slug($validated['slug']) : Str::slug($validated['name']);

        $category->update([
            'name' => trim($validated['name']),
            'slug' => $slug,
            'color_hex' => $validated['color_hex'],
        ]);

        return redirect()->route('admin.categories.index')->with('success', 'Category "' . $category->name . '" updated successfully.');
    }

    public function destroy($id)
    {
        $category = Category::findOrFail($id);
        $name = $category->name;
        $category->delete();

        return redirect()->route('admin.categories.index')->with('success', 'Category "' . $name . '" deleted successfully.');
    }
}
