<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminPlanController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->query('search');

        $query = Plan::query();

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('price', 'like', "%{$search}%")
                  ->orWhere('badge', 'like', "%{$search}%");
            });
        }

        $plans = $query->orderBy('sort_order')->orderBy('id')->get();
        $activeCount = Plan::where('is_active', true)->count();
        $totalCount = Plan::count();
        $availableFeatures = Plan::availableFeatureKeys();

        return view('admin.plans.index', compact('plans', 'search', 'activeCount', 'totalCount', 'availableFeatures'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'slug' => 'nullable|string|max:100|unique:plans,slug',
            'price' => 'required|string|max:50',
            'billing_period' => 'nullable|string|max:100',
            'badge' => 'nullable|string|max:50',
            'ai_daily_limit' => 'nullable|integer|min:0',
            'vocab_limit' => 'nullable|integer|min:0',
            'features' => 'nullable|string', // Comma or newline separated
            'is_featured' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $slug = !empty($validated['slug']) ? Str::slug($validated['slug']) : Str::slug($validated['name']);

        // Process features lines
        $featuresList = [];
        if (!empty($validated['features'])) {
            $lines = preg_split('/[\r\n]+/', $validated['features']);
            foreach ($lines as $line) {
                $trimmed = trim($line);
                if (!empty($trimmed)) {
                    $featuresList[] = $trimmed;
                }
            }
        }

        // Process feature permissions
        $permissions = [];
        foreach (array_keys(Plan::availableFeatureKeys()) as $key) {
            $permissions[$key] = $request->boolean("permissions.{$key}");
        }

        Plan::create([
            'name' => trim($validated['name']),
            'slug' => $slug,
            'price' => trim($validated['price']),
            'billing_period' => $validated['billing_period'] ?? null,
            'badge' => $validated['badge'] ?? null,
            'ai_daily_limit' => $request->filled('ai_daily_limit') ? (int)$validated['ai_daily_limit'] : null,
            'vocab_limit' => $request->filled('vocab_limit') ? (int)$validated['vocab_limit'] : null,
            'features' => $featuresList,
            'feature_permissions' => $permissions,
            'is_featured' => $request->has('is_featured'),
            'is_active' => $request->has('is_active'),
            'sort_order' => $validated['sort_order'] ?? (Plan::max('sort_order') + 1),
        ]);

        return redirect()->route('admin.plans.index')->with('success', 'Plan "' . $validated['name'] . '" created successfully.');
    }

    public function update(Request $request, $id)
    {
        $plan = Plan::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'slug' => 'nullable|string|max:100|unique:plans,slug,' . $plan->id,
            'price' => 'required|string|max:50',
            'billing_period' => 'nullable|string|max:100',
            'badge' => 'nullable|string|max:50',
            'ai_daily_limit' => 'nullable|integer|min:0',
            'vocab_limit' => 'nullable|integer|min:0',
            'features' => 'nullable|string',
            'is_featured' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $slug = !empty($validated['slug']) ? Str::slug($validated['slug']) : Str::slug($validated['name']);

        $featuresList = [];
        if (!empty($validated['features'])) {
            $lines = preg_split('/[\r\n]+/', $validated['features']);
            foreach ($lines as $line) {
                $trimmed = trim($line);
                if (!empty($trimmed)) {
                    $featuresList[] = $trimmed;
                }
            }
        }

        // Process feature permissions
        $permissions = [];
        foreach (array_keys(Plan::availableFeatureKeys()) as $key) {
            $permissions[$key] = $request->boolean("permissions.{$key}");
        }

        $plan->update([
            'name' => trim($validated['name']),
            'slug' => $slug,
            'price' => trim($validated['price']),
            'billing_period' => $validated['billing_period'] ?? null,
            'badge' => $validated['badge'] ?? null,
            'ai_daily_limit' => $request->filled('ai_daily_limit') ? (int)$validated['ai_daily_limit'] : null,
            'vocab_limit' => $request->filled('vocab_limit') ? (int)$validated['vocab_limit'] : null,
            'features' => $featuresList,
            'feature_permissions' => $permissions,
            'is_featured' => $request->has('is_featured'),
            'is_active' => $request->has('is_active'),
            'sort_order' => $validated['sort_order'] ?? $plan->sort_order,
        ]);

        return redirect()->route('admin.plans.index')->with('success', 'Plan "' . $plan->name . '" updated successfully.');
    }

    public function toggleActive($id)
    {
        $plan = Plan::findOrFail($id);
        $plan->is_active = !$plan->is_active;
        $plan->save();

        $status = $plan->is_active ? 'activated' : 'deactivated';
        return redirect()->route('admin.plans.index')->with('success', 'Plan "' . $plan->name . '" ' . $status . ' successfully.');
    }

    public function destroy($id)
    {
        $plan = Plan::findOrFail($id);
        $name = $plan->name;
        $plan->delete();

        return redirect()->route('admin.plans.index')->with('success', 'Plan "' . $name . '" deleted successfully.');
    }
}
