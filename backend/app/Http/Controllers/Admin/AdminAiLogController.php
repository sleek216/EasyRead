<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\AiLog;

class AdminAiLogController extends Controller
{
    public function index(Request $request)
    {
        $action = $request->query('action');
        $query = AiLog::with('user');

        if ($action) {
            $query->where('action', $action);
        }

        $logs = $query->latest()->paginate(20);
        $totalTokens = AiLog::sum('tokens_used');

        return view('admin.ai_logs.index', compact('logs', 'action', 'totalTokens'));
    }

    public function clearCache()
    {
        AiLog::truncate();
        return back()->with('success', 'AI response cache cleared successfully.');
    }
}
