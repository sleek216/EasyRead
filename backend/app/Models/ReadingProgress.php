<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReadingProgress extends Model
{
    protected $fillable = [
        'user_id',
        'book_id',
        'book_title',
        'current_paragraph',
        'progress_percent',
        'is_favorite',
        'is_bookmarked',
        'is_removed',
        'last_read_at',
    ];

    protected function casts(): array
    {
        return [
            'progress_percent' => 'float',
            'is_favorite' => 'boolean',
            'is_bookmarked' => 'boolean',
            'is_removed' => 'boolean',
            'last_read_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function book()
    {
        return $this->belongsTo(Book::class);
    }
}
