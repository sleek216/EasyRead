<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AccountDeletion extends Model
{
    use HasFactory;

    protected $table = 'account_deletions';

    protected $fillable = [
        'user_id',
        'name',
        'email',
        'ip_address',
        'device_name',
        'reason',
        'deleted_at',
    ];

    protected function casts(): array
    {
        return [
            'deleted_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class)->withTrashed();
    }
}
