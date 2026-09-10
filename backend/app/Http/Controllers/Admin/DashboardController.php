<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\User;
use App\Models\Book;
use App\Models\Vocabulary;
use App\Models\AiLog;
use App\Models\ReadingProgress;

class DashboardController extends Controller
{
    public function index()
    {
        $totalUsers = User::count();
        $paidSubscribers = User::where('is_premium', true)->count();
        $totalBooks = Book::where('is_public', true)->count();
        $totalVocabulary = Vocabulary::count();
        $totalAiQueries = AiLog::count();
        $cachedAiQueries = AiLog::distinct('passage_hash')->count();

        $recentUsers = User::latest()->take(5)->get();
        $recentBooks = Book::where('is_public', true)->with('paragraphs')->latest()->take(5)->get();
        $recentAiLogs = AiLog::with('user')->latest()->take(6)->get();

        return view('admin.dashboard', compact(
            'totalUsers',
            'paidSubscribers',
            'totalBooks',
            'totalVocabulary',
            'totalAiQueries',
            'cachedAiQueries',
            'recentUsers',
            'recentBooks',
            'recentAiLogs'
        ));
    }
}
