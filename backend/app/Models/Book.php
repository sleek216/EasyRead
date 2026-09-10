<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\SoftDeletes;

class Book extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id',
        'collection_id',
        'title',
        'author',
        'category',
        'cover_color',
        'read_time',
        'source_url',
        'source_type',
        'is_public',
        'is_featured',
    ];

    protected function casts(): array
    {
        return [
            'is_public' => 'boolean',
            'is_featured' => 'boolean',
        ];
    }

    public function paragraphs()
    {
        return $this->hasMany(BookParagraph::class)->orderBy('paragraph_index');
    }

    public function collection()
    {
        return $this->belongsTo(Collection::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function progress()
    {
        return $this->hasMany(ReadingProgress::class);
    }
}
