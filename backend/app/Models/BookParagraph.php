<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BookParagraph extends Model
{
    protected $fillable = [
        'book_id',
        'paragraph_index',
        'content',
    ];

    public function book()
    {
        return $this->belongsTo(Book::class);
    }
}
