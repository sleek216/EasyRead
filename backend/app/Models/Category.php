<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'color_hex',
        'sort_order',
    ];

    public function books()
    {
        return $this->hasMany(Book::class, 'category', 'name');
    }
}
