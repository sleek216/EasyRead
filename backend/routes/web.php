<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\AdminBookController;
use App\Http\Controllers\Admin\AdminUserController;
use App\Http\Controllers\Admin\AdminAiLogController;
use App\Http\Controllers\Admin\AdminCategoryController;

Route::get('/', function () {
    if (Auth::check() && Auth::user()->role === 'admin') {
        return redirect()->route('admin.dashboard');
    }
    return redirect()->route('admin.login');
});

Route::get('/admin', function () {
    if (Auth::check() && Auth::user()->role === 'admin') {
        return redirect()->route('admin.dashboard');
    }
    return redirect()->route('admin.login');
});

// Admin Authentication (Public)
Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('login.submit');
    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');
});

// Protected Admin Panel Routes
Route::prefix('admin')->name('admin.')->middleware(['admin.auth'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // Books Full CRUD, Extraction & Publish Toggle
    Route::post('/books/{id}/toggle-publish', [AdminBookController::class, 'togglePublish'])->name('books.toggle-publish');
    Route::post('/books/extract-preview', [AdminBookController::class, 'extractPreview'])->name('books.extract-preview');
    Route::resource('books', AdminBookController::class);

    // Categories Full CRUD
    Route::resource('categories', AdminCategoryController::class);

    // Plans & Pricing Full CRUD
    Route::resource('plans', \App\Http\Controllers\Admin\AdminPlanController::class);
    Route::post('/plans/{id}/toggle-active', [\App\Http\Controllers\Admin\AdminPlanController::class, 'toggleActive'])->name('plans.toggle-active');

    // Users & Subscription Management
    Route::get('/users', [AdminUserController::class, 'index'])->name('users.index');
    Route::get('/users/deletions', [AdminUserController::class, 'deletions'])->name('users.deletions');
    Route::get('/users/{id}', [AdminUserController::class, 'show'])->name('users.show');
    Route::post('/users', [AdminUserController::class, 'store'])->name('users.store');
    Route::put('/users/{id}', [AdminUserController::class, 'update'])->name('users.update');
    Route::post('/users/{id}/assign-plan', [AdminUserController::class, 'assignPlan'])->name('users.assign-plan');
    Route::post('/users/{id}/toggle-premium', [AdminUserController::class, 'togglePremium'])->name('users.toggle-premium');
    Route::post('/users/{id}/toggle-status', [AdminUserController::class, 'toggleStatus'])->name('users.toggle-status');
    Route::post('/users/{id}/reset-ai', [AdminUserController::class, 'resetAiUses'])->name('users.reset-ai');
    Route::delete('/users/{id}', [AdminUserController::class, 'destroy'])->name('users.destroy');

    // Announcements & Push Notifications
    Route::resource('notifications', \App\Http\Controllers\Admin\AdminNotificationController::class)->only(['index', 'store', 'destroy']);

    // AI Queries & Token Logs
    Route::get('/ai-logs', [AdminAiLogController::class, 'index'])->name('ai-logs.index');
    Route::post('/ai-logs/clear-cache', [AdminAiLogController::class, 'clearCache'])->name('ai-logs.clear-cache');

    // System & AI Provider Settings (Google AI Studio, OpenRouter, OpenAI)
    Route::get('/settings', [\App\Http\Controllers\Admin\AdminSettingController::class, 'index'])->name('settings.index');
    Route::post('/settings', [\App\Http\Controllers\Admin\AdminSettingController::class, 'update'])->name('settings.update');
    Route::post('/settings/test-google-ai-studio', [\App\Http\Controllers\Admin\AdminSettingController::class, 'testGoogleAiStudio'])->name('settings.test-google-ai-studio');
    Route::post('/settings/test-openrouter', [\App\Http\Controllers\Admin\AdminSettingController::class, 'testOpenRouter'])->name('settings.test-openrouter');
    Route::post('/settings/test-openai', [\App\Http\Controllers\Admin\AdminSettingController::class, 'testOpenAi'])->name('settings.test-openai');
    Route::post('/settings/test-smtp', [\App\Http\Controllers\Admin\AdminSettingController::class, 'testSmtp'])->name('settings.test-smtp');
    Route::post('/settings/test-push', [\App\Http\Controllers\Admin\AdminSettingController::class, 'testPush'])->name('settings.test-push');

    // Admin Profile & Password Management
    Route::get('/profile', [\App\Http\Controllers\Admin\AdminProfileController::class, 'index'])->name('profile.index');
    Route::post('/profile', [\App\Http\Controllers\Admin\AdminProfileController::class, 'update'])->name('profile.update');
});

