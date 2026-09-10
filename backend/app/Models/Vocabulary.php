<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Vocabulary extends Model
{
    protected $fillable = [
        'user_id',
        'word',
        'pos',
        'meaning',
        'example',
        'synonyms',
        'origin',
        'source_title',
        'is_mastered',
        'review_count',
    ];

    protected function casts(): array
    {
        return [
            'synonyms' => 'array',
            'is_mastered' => 'boolean',
            'review_count' => 'integer',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
