<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Plan extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'price',
        'billing_period',
        'badge',
        'ai_daily_limit',
        'vocab_limit',
        'features',
        'feature_permissions',
        'is_featured',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'features' => 'array',
        'feature_permissions' => 'array',
        'is_featured' => 'boolean',
        'is_active' => 'boolean',
        'ai_daily_limit' => 'integer',
        'vocab_limit' => 'integer',
        'sort_order' => 'integer',
    ];

    public static function availableFeatureKeys(): array
    {
        return [
            'import_pdf' => [
                'label' => 'Import PDF & Documents',
                'description' => 'Allow importing local PDF, EPUB and text files',
                'icon' => 'fa-file-arrow-up',
            ],
            'paste_read' => [
                'label' => 'Paste & Read',
                'description' => 'Allow pasting long articles and essays to read',
                'icon' => 'fa-paste',
            ],
            'save_from_web' => [
                'label' => 'Save from Web URL',
                'description' => 'Extract articles from any web link into reader mode',
                'icon' => 'fa-globe',
            ],
            'cloud_sync' => [
                'label' => 'Cloud Sync & Multi-Device Backup',
                'description' => 'Keep vocabulary, progress and notes synced',
                'icon' => 'fa-cloud-arrow-up',
            ],
            'unlimited_ai' => [
                'label' => 'Unlimited AI Assistant',
                'description' => 'Full access to AI tutor without daily query limits',
                'icon' => 'fa-wand-magic-sparkles',
            ],
            'custom_shelves' => [
                'label' => 'Custom Collections & Shelves',
                'description' => 'Create personalized reading folders',
                'icon' => 'fa-folder-plus',
            ],
        ];
    }
}
