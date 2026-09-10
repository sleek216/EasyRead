<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DownloadedBook extends Model
{
    use HasFactory;

    protected $table = 'downloaded_books';

    protected $fillable = [
        'user_id',
        'book_id',
        'book_title',
        'book_json',
        'is_removed',
        'downloaded_at',
    ];

    protected $casts = [
        'book_json' => 'array',
        'is_removed' => 'boolean',
        'downloaded_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function book()
    {
        return $this->belongsTo(Book::class);
    }
}
