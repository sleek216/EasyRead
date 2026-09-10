<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CollectionBook extends Model
{
    protected $fillable = [
        'user_id',
        'collection_id',
        'collection_tag',
        'book_id',
        'book_title',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function collection()
    {
        return $this->belongsTo(Collection::class);
    }

    public function book()
    {
        return $this->belongsTo(Book::class);
    }
}
