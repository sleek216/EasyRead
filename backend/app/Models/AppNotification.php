<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class AppNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'message',
        'data',
        'is_broadcast',
        'read_by_users',
        'read_at',
    ];

    protected $casts = [
        'data' => 'array',
        'read_by_users' => 'array',
        'is_broadcast' => 'boolean',
        'read_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope for a specific user (including broadcasts relevant to user registration date)
     */
    public function scopeForUser($query, $user, $userCreatedAt = null)
    {
        $userId = $user instanceof User ? $user->id : (is_numeric($user) ? (int)$user : null);
        if ($user instanceof User) {
            $userCreatedAt = $userCreatedAt ?? $user->created_at;
        } elseif ($userCreatedAt === null && $userId) {
            $u = User::find($userId, ['id', 'created_at']);
            $userCreatedAt = $u ? $u->created_at : null;
        }

        return $query->where(function ($q) use ($userId, $userCreatedAt) {
            $q->where('user_id', $userId)
              ->orWhere(function ($b) use ($userCreatedAt) {
                  $b->where('is_broadcast', true);
                  if ($userCreatedAt) {
                      $b->where('created_at', '>=', Carbon::parse($userCreatedAt)->subMinutes(5));
                  }
              });
        });
    }

    /**
     * Determine if this notification has been read by the given user
     */
    public function isReadBy($userId): bool
    {
        if ($this->is_broadcast) {
            $readList = $this->read_by_users ?? [];
            return in_array((int)$userId, array_map('intval', $readList));
        }

        return $this->read_at !== null;
    }

    /**
     * Mark as read for the given user
     */
    public function markAsReadFor($userId): void
    {
        if ($this->is_broadcast) {
            $readList = $this->read_by_users ?? [];
            if (!in_array((int)$userId, array_map('intval', $readList))) {
                $readList[] = (int)$userId;
                $this->read_by_users = array_values(array_unique($readList));
                $this->save();
            }
        } else {
            if (!$this->read_at) {
                $this->read_at = now();
                $this->save();
            }
        }
    }
}
