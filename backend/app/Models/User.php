<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, HasApiTokens, SoftDeletes;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_premium',
        'is_active',
        'plan_id',
        'subscription_plan',
        'subscription_price',
        'subscription_starts_at',
        'subscription_expires_at',
        'ai_free_uses_left',
        'last_active_at',
        'device_name',
        'avatar_url',
        'sync_enabled',
        'day_streak',
        'total_words_read',
        'fcm_token',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_active_at' => 'datetime',
            'subscription_starts_at' => 'datetime',
            'subscription_expires_at' => 'datetime',
            'is_premium' => 'boolean',
            'is_active' => 'boolean',
            'sync_enabled' => 'boolean',
            'day_streak' => 'integer',
            'total_words_read' => 'integer',
            'ai_free_uses_left' => 'integer',
            'password' => 'hashed',
        ];
    }

    public function plan()
    {
        return $this->belongsTo(Plan::class);
    }

    public function collections()
    {
        return $this->hasMany(Collection::class);
    }

    public function vocabularies()
    {
        return $this->hasMany(Vocabulary::class);
    }

    public function backups()
    {
        return $this->hasMany(Backup::class);
    }

    public function books()
    {
        return $this->hasMany(Book::class);
    }

    public function aiLogs()
    {
        return $this->hasMany(AiLog::class);
    }

    public function highlights()
    {
        return $this->hasMany(Highlight::class);
    }

    public function readingProgress()
    {
        return $this->hasMany(ReadingProgress::class);
    }

    public function deletions()
    {
        return $this->hasMany(AccountDeletion::class);
    }

    public function collectionBooks()
    {
        return $this->hasMany(CollectionBook::class);
    }

    public function downloadedBooks()
    {
        return $this->hasMany(DownloadedBook::class);
    }

    public function hasFeature(string $featureKey): bool
    {
        if ($this->role === 'admin') {
            return true;
        }

        $plan = $this->plan;
        if (!$plan) {
            $plan = Plan::where('slug', 'free')->orWhere('id', 'free')->first();
        }

        if (!$plan) {
            return false;
        }

        $permissions = $plan->feature_permissions ?? $plan->features ?? [];
        if (is_array($permissions) && isset($permissions[$featureKey])) {
            return (bool) $permissions[$featureKey];
        }

        return false;
    }
}
