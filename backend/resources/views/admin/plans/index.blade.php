@extends('admin.layout')

@section('title', 'Plans & Pricing - Easy Read Studio')
@section('page_title', 'Plans & Pricing')

@section('content')
<div class="space-y-6">

    <!-- Top Action Bar & Stats -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div class="flex items-center space-x-3">
            <span class="px-3.5 py-1.5 rounded-2xl bg-white border border-[#E5DFD3] text-xs font-bold text-[#16241D] shadow-2xs">
                Total Plans: <span class="text-[#3E5C45]">{{ $totalCount }}</span>
            </span>
            <span class="px-3.5 py-1.5 rounded-2xl bg-[#3E5C45]/10 border border-[#3E5C45]/20 text-xs font-bold text-[#3E5C45]">
                Active on Mobile: <span>{{ $activeCount }}</span>
            </span>
        </div>

        <div class="flex items-center space-x-3">
            <!-- Add Plan Button -->
            <button type="button" onclick="openCreatePlanModal()"
                    class="px-5 py-2.5 rounded-2xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold shadow-xs hover:shadow-sm transition flex items-center space-x-2 shrink-0">
                <i class="fa-solid fa-plus text-xs"></i>
                <span>Create New Plan</span>
            </button>
        </div>
    </div>

    <!-- Plans Cards Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        @forelse($plans as $plan)
            <div class="bg-white rounded-3xl border {{ $plan->is_featured ? 'border-[#C28B38] ring-2 ring-[#C28B38]/20 shadow-md' : 'border-[#E5DFD3] shadow-xs' }} hover:shadow-md transition flex flex-col justify-between overflow-hidden relative group">
                
                <!-- Card Header -->
                <div class="p-6 space-y-4">
                    <div class="flex items-start justify-between">
                        <div>
                            <div class="flex items-center space-x-2">
                                <h3 class="font-serif font-bold text-[#16241D] text-lg">{{ $plan->name }}</h3>
                                @if($plan->badge)
                                    <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#C28B38]/15 text-[#8B5A2B] border border-[#C28B38]/30">
                                        {{ $plan->badge }}
                                    </span>
                                @endif
                            </div>
                            <span class="text-xs font-mono text-[#7A7569]">#{{ $plan->slug }}</span>
                        </div>

                        <!-- Active / Inactive Status Indicator -->
                        <form action="{{ route('admin.plans.toggle-active', $plan->id) }}" method="POST">
                            @csrf
                            <button type="submit" 
                                    class="px-2.5 py-1 rounded-full text-[10px] font-bold transition flex items-center space-x-1 {{ $plan->is_active ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100' : 'bg-stone-100 text-stone-500 border border-stone-200 hover:bg-stone-200' }}"
                                    title="Click to toggle mobile visibility">
                                <span class="w-1.5 h-1.5 rounded-full {{ $plan->is_active ? 'bg-emerald-600 animate-pulse' : 'bg-stone-400' }}"></span>
                                <span>{{ $plan->is_active ? 'Active' : 'Disabled' }}</span>
                            </button>
                        </form>
                    </div>

                    <!-- Pricing & Billing Period -->
                    <div class="pt-2 border-t border-[#E5DFD3]/60">
                        <div class="flex items-baseline space-x-1.5">
                            <span class="font-serif font-extrabold text-2xl text-[#16241D]">{{ $plan->price }}</span>
                        </div>
                        @if($plan->billing_period)
                            <span class="text-xs font-medium text-[#7A7569] block mt-0.5">{{ $plan->billing_period }}</span>
                        @endif
                    </div>

                    <!-- Limits Badges -->
                    <div class="flex flex-wrap gap-1.5 pt-1">
                        <span class="px-2.5 py-1 rounded-xl text-[11px] font-bold bg-[#F3EFE6] text-[#3E5C45] flex items-center space-x-1">
                            <i class="fa-solid fa-wand-magic-sparkles text-[10px]"></i>
                            <span>{{ is_null($plan->ai_daily_limit) ? 'Unlimited AI' : $plan->ai_daily_limit . ' AI/day' }}</span>
                        </span>
                        <span class="px-2.5 py-1 rounded-xl text-[11px] font-bold bg-[#F3EFE6] text-[#3E5C45] flex items-center space-x-1">
                            <i class="fa-solid fa-book-bookmark text-[10px]"></i>
                            <span>{{ is_null($plan->vocab_limit) ? 'Unlimited Vocab' : $plan->vocab_limit . ' words' }}</span>
                        </span>
                    </div>

                    <!-- App Entitlements Matrix (Core Gating Feature) -->
                    @if(false)
                    <div class="space-y-2 pt-3 border-t border-[#E5DFD3]/60">
                        <span class="text-[11px] font-bold uppercase tracking-wider text-[#7A7569] block">App Features Access</span>
                        <div class="grid grid-cols-2 gap-1.5 text-[11px]">
                            @php
                                $perms = $plan->feature_permissions ?? [];
                            @endphp
                            @foreach($availableFeatures as $fKey => $fMeta)
                                @php $isAllowed = !empty($perms[$fKey]); @endphp
                                <div class="flex items-center space-x-1.5 py-0.5 {{ $isAllowed ? 'text-[#16241D]' : 'text-gray-400 line-through' }}">
                                    <i class="fa-solid {{ $isAllowed ? 'fa-check text-[#3E5C45]' : 'fa-xmark text-gray-300' }} text-[10px]"></i>
                                    <span class="truncate">{{ $fMeta['label'] }}</span>
                                </div>
                            @endforeach
                        </div>
                    </div>
                    @endif

                    <!-- Marketing Features List -->
                    @if(!empty($plan->features) && is_array($plan->features))
                    <div class="space-y-1.5 pt-3 border-t border-[#E5DFD3]/60">
                        <span class="text-[11px] font-bold uppercase tracking-wider text-[#7A7569] block">Display Highlights</span>
                        <ul class="space-y-1 text-xs text-[#16241D]">
                            @foreach($plan->features as $feature)
                                <li class="flex items-start space-x-1.5">
                                    <i class="fa-solid fa-circle-check text-[#C28B38] text-[10px] mt-1 shrink-0"></i>
                                    <span class="leading-tight text-[11px]">{{ $feature }}</span>
                                </li>
                            @endforeach
                        </ul>
                    </div>
                    @endif
                </div>

                <!-- Card Footer / Actions -->
                <div class="p-4 bg-[#FDFBF7] border-t border-[#E5DFD3] flex items-center justify-between">
                    <span class="text-[11px] text-[#7A7569] font-medium">Order: #{{ $plan->sort_order }}</span>

                    <div class="flex items-center space-x-1">
                        <!-- Edit Button -->
                        <button type="button" 
                                onclick="openEditPlanModal({{ json_encode($plan) }})"
                                class="px-3 py-1.5 rounded-xl border border-[#E5DFD3] bg-white text-xs font-bold text-[#16241D] hover:bg-[#F3EFE6] hover:text-[#3E5C45] transition flex items-center space-x-1 shadow-2xs">
                            <i class="fa-solid fa-pen-to-square text-xs"></i>
                            <span>Edit</span>
                        </button>

                        <!-- Delete Button -->
                        <form action="{{ route('admin.plans.destroy', $plan->id) }}" method="POST" class="inline"
                              data-confirm="Are you sure you want to delete subscription plan '{{ addslashes($plan->name) }}'?">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="p-1.5 rounded-xl text-[#7A7569] hover:text-rose-600 hover:bg-rose-50 transition" title="Delete Plan">
                                <i class="fa-solid fa-trash-can"></i>
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        @empty
            <div class="col-span-full py-16 text-center bg-white rounded-3xl border border-[#E5DFD3]">
                <div class="w-12 h-12 rounded-2xl bg-[#F3EFE6] text-[#7A7569] flex items-center justify-center mx-auto text-lg mb-3">
                    <i class="fa-solid fa-gem"></i>
                </div>
                <h3 class="font-serif font-bold text-lg text-[#16241D]">No subscription plans created</h3>
                <p class="text-xs text-[#7A7569] max-w-sm mx-auto mt-1 mb-5">Create your first mobile subscription package with pricing and feature toggles.</p>
                <button onclick="openCreatePlanModal()" class="px-5 py-2.5 rounded-2xl bg-[#3E5C45] text-white text-xs font-bold shadow-xs">
                    Create New Plan
                </button>
            </div>
        @endforelse
    </div>
</div>

<!-- Create Plan Modal -->
<div id="createPlanModal" class="fixed inset-0 bg-black/40 backdrop-blur-xs z-50 hidden flex items-center justify-center p-4">
    <div class="bg-white max-w-xl w-full rounded-3xl p-7 shadow-2xl border border-[#E5DFD3] space-y-5 max-h-[90vh] overflow-y-auto custom-scrollbar">
        <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
            <div>
                <h3 class="font-serif font-bold text-[#16241D] text-lg">Create New Plan</h3>
                <p class="text-xs text-[#7A7569] mt-0.5">Configure package pricing and feature entitlements</p>
            </div>
            <button onclick="closeCreatePlanModal()" class="text-[#7A7569] hover:text-[#16241D] p-1">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>

        <form action="{{ route('admin.plans.store') }}" method="POST" class="space-y-4">
            @csrf
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Plan Name <span class="text-rose-500">*</span></label>
                    <input type="text" name="name" required placeholder="e.g. Monthly VIP, Yearly Pro"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>

                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Code / Slug</label>
                    <input type="text" name="slug" placeholder="e.g. monthly, quarterly, yearly"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Price Tag <span class="text-rose-500">*</span></label>
                    <input type="text" name="price" required placeholder="e.g. R29, R189"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>

                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Billing Period Subtitle</label>
                    <input type="text" name="billing_period" placeholder="e.g. billed monthly, R15.75/mo"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Badge / Ribbon</label>
                    <input type="text" name="badge" placeholder="e.g. Popular, Best value"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>

                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Sort Order</label>
                    <input type="number" name="sort_order" value="{{ $totalCount + 1 }}" min="1" max="99"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>
            </div>

            <!-- Dynamic Feature Entitlements (Switches) -->
            @if(false)
            <div class="space-y-2 pt-2 border-t border-[#E5DFD3]">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                    App Feature Entitlements (Mobile Access)
                </label>
                <p class="text-[11px] text-[#7A7569]">Select which mobile features users on this package are allowed to access:</p>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                    @foreach($availableFeatures as $key => $feat)
                    <label class="flex items-start space-x-2.5 p-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] hover:bg-white cursor-pointer transition">
                        <input type="checkbox" name="permissions[{{ $key }}]" value="1" checked class="mt-0.5 w-4 h-4 rounded text-[#3E5C45] focus:ring-[#3E5C45]">
                        <div class="text-xs">
                            <span class="font-bold text-[#16241D] flex items-center gap-1.5">
                                <i class="fa-solid {{ $feat['icon'] }} text-[#3E5C45] text-[11px]"></i>
                                {{ $feat['label'] }}
                            </span>
                            <span class="text-[10px] text-[#7A7569] block leading-tight">{{ $feat['description'] }}</span>
                        </div>
                    </label>
                    @endforeach
                </div>
            </div>
            @endif

            <!-- Marketing Features Textarea -->
            <div class="space-y-1.5 pt-2 border-t border-[#E5DFD3]">
                <div class="flex items-center justify-between">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Display Bullet Points</label>
                    <span class="text-[11px] text-[#7A7569]">One per line</span>
                </div>
                <textarea name="features" rows="3" placeholder="Unlimited AI reading assistant&#10;Cross-device cloud sync&#10;Full offline downloads"
                          class="w-full px-4 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs text-[#16241D] font-sans focus:bg-white focus:border-[#3E5C45] outline-hidden transition"></textarea>
            </div>

            <!-- Checkboxes -->
            <div class="flex items-center space-x-6 pt-2">
                <label class="flex items-center space-x-2 text-xs font-bold text-[#16241D] cursor-pointer">
                    <input type="checkbox" name="is_active" value="1" checked class="w-4 h-4 rounded text-[#3E5C45] focus:ring-[#3E5C45]">
                    <span>Active on Mobile App</span>
                </label>

                <label class="flex items-center space-x-2 text-xs font-bold text-[#16241D] cursor-pointer">
                    <input type="checkbox" name="is_featured" value="1" class="w-4 h-4 rounded text-[#C28B38] focus:ring-[#C28B38]">
                    <span>Featured (Highlighted)</span>
                </label>
            </div>

            <div class="flex items-center justify-end space-x-3 pt-4 border-t border-[#E5DFD3]">
                <button type="button" onclick="closeCreatePlanModal()" class="px-5 py-2.5 rounded-xl border border-[#E5DFD3] text-xs font-bold text-[#7A7569] hover:bg-[#F3EFE6] transition">
                    Cancel
                </button>
                <button type="submit" class="px-6 py-2.5 rounded-xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold transition shadow-xs">
                    Save Plan
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Edit Plan Modal -->
<div id="editPlanModal" class="fixed inset-0 bg-black/40 backdrop-blur-xs z-50 hidden flex items-center justify-center p-4">
    <div class="bg-white max-w-xl w-full rounded-3xl p-7 shadow-2xl border border-[#E5DFD3] space-y-5 max-h-[90vh] overflow-y-auto custom-scrollbar">
        <div class="flex items-center justify-between border-b border-[#E5DFD3] pb-4">
            <div>
                <h3 class="font-serif font-bold text-[#16241D] text-lg">Edit Plan</h3>
                <p class="text-xs text-[#7A7569] mt-0.5">Update pricing and feature entitlements</p>
            </div>
            <button onclick="closeEditPlanModal()" class="text-[#7A7569] hover:text-[#16241D] p-1">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>

        <form id="editPlanForm" method="POST" class="space-y-4">
            @csrf
            @method('PUT')
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Plan Name <span class="text-rose-500">*</span></label>
                    <input type="text" id="editName" name="name" required
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>

                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Code / Slug</label>
                    <input type="text" id="editSlug" name="slug"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Price Tag <span class="text-rose-500">*</span></label>
                    <input type="text" id="editPrice" name="price" required
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>

                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Billing Period Subtitle</label>
                    <input type="text" id="editBillingPeriod" name="billing_period"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Badge / Ribbon</label>
                    <input type="text" id="editBadge" name="badge"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>

                <div class="space-y-1.5">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Sort Order</label>
                    <input type="number" id="editSortOrder" name="sort_order" min="1" max="99"
                           class="w-full px-4 py-2.5 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                </div>
            </div>

            <!-- Dynamic Feature Entitlements in Edit Modal -->
            @if(false)
            <div class="space-y-2 pt-2 border-t border-[#E5DFD3]">
                <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                    App Feature Entitlements (Mobile Access)
                </label>
                <p class="text-[11px] text-[#7A7569]">Select which mobile features users on this package are allowed to access:</p>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                    @foreach($availableFeatures as $key => $feat)
                    <label class="flex items-start space-x-2.5 p-2.5 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] hover:bg-white cursor-pointer transition">
                        <input type="checkbox" id="edit_perm_{{ $key }}" name="permissions[{{ $key }}]" value="1" class="mt-0.5 w-4 h-4 rounded text-[#3E5C45] focus:ring-[#3E5C45]">
                        <div class="text-xs">
                            <span class="font-bold text-[#16241D] flex items-center gap-1.5">
                                <i class="fa-solid {{ $feat['icon'] }} text-[#3E5C45] text-[11px]"></i>
                                {{ $feat['label'] }}
                            </span>
                            <span class="text-[10px] text-[#7A7569] block leading-tight">{{ $feat['description'] }}</span>
                        </div>
                    </label>
                    @endforeach
                </div>
            </div>
            @endif

            <!-- Features -->
            <div class="space-y-1.5 pt-2 border-t border-[#E5DFD3]">
                <div class="flex items-center justify-between">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">Display Bullet Points</label>
                    <span class="text-[11px] text-[#7A7569]">One per line</span>
                </div>
                <textarea id="editFeatures" name="features" rows="3"
                          class="w-full px-4 py-2 rounded-xl border border-[#E5DFD3] bg-[#FDFBF7] text-xs text-[#16241D] font-sans focus:bg-white focus:border-[#3E5C45] outline-hidden transition"></textarea>
            </div>

            <!-- Checkboxes -->
            <div class="flex items-center space-x-6 pt-2">
                <label class="flex items-center space-x-2 text-xs font-bold text-[#16241D] cursor-pointer">
                    <input type="checkbox" id="editIsActive" name="is_active" value="1" class="w-4 h-4 rounded text-[#3E5C45] focus:ring-[#3E5C45]">
                    <span>Active on Mobile App</span>
                </label>

                <label class="flex items-center space-x-2 text-xs font-bold text-[#16241D] cursor-pointer">
                    <input type="checkbox" id="editIsFeatured" name="is_featured" value="1" class="w-4 h-4 rounded text-[#C28B38] focus:ring-[#C28B38]">
                    <span>Featured (Highlighted)</span>
                </label>
            </div>

            <div class="flex items-center justify-end space-x-3 pt-4 border-t border-[#E5DFD3]">
                <button type="button" onclick="closeEditPlanModal()" class="px-5 py-2.5 rounded-xl border border-[#E5DFD3] text-xs font-bold text-[#7A7569] hover:bg-[#F3EFE6] transition">
                    Cancel
                </button>
                <button type="submit" class="px-6 py-2.5 rounded-xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-xs font-bold transition shadow-xs">
                    Update Plan
                </button>
            </div>
        </form>
    </div>
</div>

<script>
function openCreatePlanModal() {
    document.getElementById('createPlanModal').classList.remove('hidden');
}
function closeCreatePlanModal() {
    document.getElementById('createPlanModal').classList.add('hidden');
}

function openEditPlanModal(plan) {
    document.getElementById('editPlanForm').action = `/admin/plans/${plan.id}`;
    document.getElementById('editName').value = plan.name || '';
    document.getElementById('editSlug').value = plan.slug || '';
    document.getElementById('editPrice').value = plan.price || '';
    document.getElementById('editBillingPeriod').value = plan.billing_period || '';
    document.getElementById('editBadge').value = plan.badge || '';
    document.getElementById('editSortOrder').value = plan.sort_order || 1;
    
    // Set feature permissions checkboxes
    const permObj = plan.feature_permissions || {};
    const permKeys = ['import_pdf', 'paste_read', 'save_from_web', 'cloud_sync', 'unlimited_ai', 'custom_shelves'];
    permKeys.forEach(k => {
        const checkbox = document.getElementById(`edit_perm_${k}`);
        if (checkbox) {
            checkbox.checked = Boolean(permObj[k] !== undefined ? permObj[k] : true);
        }
    });

    if (plan.features && Array.isArray(plan.features)) {
        document.getElementById('editFeatures').value = plan.features.join('\n');
    } else {
        document.getElementById('editFeatures').value = '';
    }

    document.getElementById('editIsActive').checked = Boolean(plan.is_active);
    document.getElementById('editIsFeatured').checked = Boolean(plan.is_featured);

    document.getElementById('editPlanModal').classList.remove('hidden');
}
function closeEditPlanModal() {
    document.getElementById('editPlanModal').classList.add('hidden');
}
</script>
@endsection
