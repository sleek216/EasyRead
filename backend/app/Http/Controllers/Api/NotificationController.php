<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AppNotification;

class NotificationController extends Controller
{
    /**
     * Get all notifications for the authenticated user (including global broadcasts).
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $userId = $user->id;

        $notifications = AppNotification::forUser($user)
            ->latest()
            ->take(50)
            ->get()
            ->map(function ($notif) use ($userId) {
                return [
                    'id'           => $notif->id,
                    'type'         => $notif->type,
                    'title'        => $notif->title,
                    'message'      => $notif->message,
                    'data'         => $notif->data,
                    'is_broadcast' => (bool)$notif->is_broadcast,
                    'is_read'      => $notif->isReadBy($userId),
                    'created_at'   => $notif->created_at->toISOString(),
                    'time_ago'     => $notif->created_at->diffForHumans(),
                ];
            });

        $unreadCount = $notifications->where('is_read', false)->count();

        return response()->json([
            'success'       => true,
            'notifications' => $notifications,
            'unread_count'  => $unreadCount,
        ]);
    }

    /**
     * Mark a single notification as read.
     */
    public function markRead(Request $request, $id)
    {
        $user = $request->user();
        $notif = AppNotification::forUser($user)->findOrFail($id);

        $notif->markAsReadFor($user->id);

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as read.',
        ]);
    }

    /**
     * Mark all notifications as read for current user.
     */
    public function markAllRead(Request $request)
    {
        $user = $request->user();
        $notifications = AppNotification::forUser($user)->get();

        foreach ($notifications as $notif) {
            $notif->markAsReadFor($user->id);
        }

        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read.',
        ]);
    }

    /**
     * Dismiss / Delete a single notification for the user.
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $notif = AppNotification::forUser($user)->findOrFail($id);

        if (!$notif->is_broadcast && $notif->user_id == $user->id) {
            $notif->delete();
        } else {
            // For broadcast: just mark as read
            $notif->markAsReadFor($user->id);
        }

        return response()->json([
            'success' => true,
            'message' => 'Notification dismissed.',
        ]);
    }
}
