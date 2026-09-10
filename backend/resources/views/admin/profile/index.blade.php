@extends('admin.layout')

@section('title', 'Admin Profile - Easy Read Studio')
@section('page_title', 'Admin Profile')

@section('content')
<div class="max-w-3xl space-y-7">

    <!-- Profile Management Form -->
    <form action="{{ route('admin.profile.update') }}" method="POST" class="space-y-6">
        @csrf

        <!-- 1. Account Details Card -->
        <div class="bg-white p-5 sm:p-7 rounded-2xl sm:rounded-3xl border border-[#E5DFD3] shadow-xs space-y-5 sm:space-y-6">
            <div class="border-b border-[#E5DFD3] pb-4">
                <h3 class="font-serif font-bold text-[#16241D] text-base sm:text-lg">Account Information</h3>
                <p class="text-xs text-[#7A7569] mt-0.5">Update your personal administrator details and login email</p>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-5">
                <div class="space-y-2">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                        Admin Name <span class="text-rose-500">*</span>
                    </label>
                    <input type="text" name="name" value="{{ old('name', $user->name) }}" required
                           class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                    @error('name')
                        <p class="text-xs text-rose-600 font-semibold">{{ $message }}</p>
                    @enderror
                </div>

                <div class="space-y-2">
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                        Email Address <span class="text-rose-500">*</span>
                    </label>
                    <input type="email" name="email" value="{{ old('email', $user->email) }}" required
                           class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] font-medium focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                    @error('email')
                        <p class="text-xs text-rose-600 font-semibold">{{ $message }}</p>
                    @enderror
                </div>
            </div>
        </div>

        <!-- 2. Security & Password Change Card -->
        <div class="bg-white p-5 sm:p-7 rounded-2xl sm:rounded-3xl border border-[#E5DFD3] shadow-xs space-y-5 sm:space-y-6">
            <div class="border-b border-[#E5DFD3] pb-4">
                <h3 class="font-serif font-bold text-[#16241D] text-base sm:text-lg">Change Password</h3>
                <p class="text-xs text-[#7A7569] mt-0.5">Leave blank if you do not want to change your current password</p>
            </div>

            <div class="space-y-4">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-5">
                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            New Password
                        </label>
                        <input type="password" name="new_password" placeholder="Minimum 6 characters"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                        @error('new_password')
                            <p class="text-xs text-rose-600 font-semibold">{{ $message }}</p>
                        @enderror
                    </div>

                    <div class="space-y-2">
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#16241D]">
                            Confirm New Password
                        </label>
                        <input type="password" name="new_password_confirmation" placeholder="Confirm new password"
                               class="w-full px-4 py-3 rounded-2xl border border-[#E5DFD3] bg-[#FDFBF7] text-sm text-[#16241D] focus:bg-white focus:border-[#3E5C45] outline-hidden transition">
                    </div>
                </div>
            </div>
        </div>

        <!-- Submit Action -->
        <div class="flex items-center justify-end space-x-4 pt-2">
            <button type="submit" 
                    class="w-full sm:w-auto justify-center px-8 py-3.5 rounded-2xl bg-[#3E5C45] hover:bg-[#2F4936] text-white text-sm font-bold shadow-xs hover:shadow-sm transition flex items-center space-x-2">
                <span>Save Profile Changes</span>
            </button>
        </div>
    </form>
</div>
@endsection
