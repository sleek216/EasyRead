<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Backup extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'snapshot_data',
        'item_count',
    ];

    protected function casts(): array
    {
        return [
            'snapshot_data' => 'array',
            'item_count' => 'integer',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
