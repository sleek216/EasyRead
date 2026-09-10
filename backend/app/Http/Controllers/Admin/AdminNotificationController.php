<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AppNotification;
use App\Models\User;
use App\Models\Plan;
use App\Services\NotificationService;

class AdminNotificationController extends Controller
{
    /**
     * Display announcement console and notification history.
     */
    public function index(Request $request)
    {
        $search = $request->query('search');
        $typeFilter = $request->query('type', 'all');

        $query = AppNotification::with('user')->latest();

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('message', 'like', "%{$search}%");
            });
        }

        if ($typeFilter !== 'all') {
            $query->where('type', $typeFilter);
        }

        $notifications = $query->paginate(15)->appends($request->query());

        // Summary Metrics
        $totalSent = AppNotification::count();
        $broadcastCount = AppNotification::where('is_broadcast', true)->count();
        $announcementsCount = AppNotification::where('type', 'announcement')->count();
        $newBooksCount = AppNotification::where('type', 'new_book')->count();
        $subscriptionNotifsCount = AppNotification::where('type', 'subscription')->count();

        $plans = Plan::where('is_active', true)->get();
        $totalUsersCount = User::count();

        return view('admin.notifications.index', compact(
            'notifications',
            'search',
            'typeFilter',
            'totalSent',
            'broadcastCount',
            'announcementsCount',
            'newBooksCount',
            'subscriptionNotifsCount',
            'plans',
            'totalUsersCount'
        ));
    }

    /**
     * Broadcast an announcement or direct notification from the Admin Panel.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title'   => 'required|string|max:255',
            'message' => 'required|string|max:2000',
            'type'    => 'required|string|in:announcement,general,new_book,subscription',
            'target'  => 'required|string', // 'all' or 'user_ID' or 'plan_ID'
        ]);

        $title   = trim($validated['title']);
        $message = trim($validated['message']);
        $type    = $validated['type'];
        $target  = $validated['target'];

        if ($target === 'all') {
            NotificationService::broadcastAll($type, $title, $message);
            $targetDesc = "all users";
        } elseif (str_starts_with($target, 'plan_')) {
            $planId = substr($target, 5);
            $plan = Plan::find($planId);
            $userIds = User::where('plan_id', $planId)->pluck('id');
            foreach ($userIds as $uid) {
                NotificationService::sendToUser($uid, $type, $title, $message, ['plan_name' => $plan?->name]);
            }
            $targetDesc = count($userIds) . " users on " . ($plan?->name ?? 'selected plan');
        } elseif (str_starts_with($target, 'user_')) {
            $userId = (int) substr($target, 5);
            $user = User::findOrFail($userId);
            NotificationService::sendToUser($user->id, $type, $title, $message);
            $targetDesc = $user->name;
        } else {
            NotificationService::broadcastAll($type, $title, $message);
            $targetDesc = "all users";
        }

        return redirect()->route('admin.notifications.index')->with('success', "Announcement \"{$title}\" dispatched successfully to {$targetDesc}!");
    }

    /**
     * Delete a notification / announcement from the database.
     */
    public function destroy($id)
    {
        $notif = AppNotification::findOrFail($id);
        $title = $notif->title;
        $notif->delete();

        return redirect()->route('admin.notifications.index')->with('success', "Notification \"{$title}\" deleted.");
    }
}
