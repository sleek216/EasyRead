<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Collection;
use App\Models\Plan;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Admin Global Categories (For Top Filters & Book Categorization)
        $categories = [
            ['name' => 'Fiction', 'slug' => 'fiction', 'color_hex' => '#6E3B4E', 'sort_order' => 1],
            ['name' => 'Research', 'slug' => 'research', 'color_hex' => '#2E4C6D', 'sort_order' => 2],
            ['name' => 'Self-development', 'slug' => 'self-dev', 'color_hex' => '#4B6B4A', 'sort_order' => 3],
            ['name' => 'Education', 'slug' => 'education', 'color_hex' => '#B8873B', 'sort_order' => 4],
            ['name' => 'Business', 'slug' => 'business', 'color_hex' => '#7A3E65', 'sort_order' => 5],
            ['name' => 'Philosophy', 'slug' => 'philosophy', 'color_hex' => '#8B5A2B', 'sort_order' => 6],
        ];

        foreach ($categories as $cat) {
            Category::updateOrCreate(['slug' => $cat['slug']], $cat);
        }

        // 2. Starter Subscription Plans
        $plans = [
            [
                'name' => 'Monthly',
                'slug' => 'monthly',
                'price' => 'R29',
                'billing_period' => 'billed monthly',
                'badge' => null,
                'ai_daily_limit' => null,
                'vocab_limit' => null,
                'features' => [
                    'Unlimited AI reading assistant',
                    'Unlimited vocabulary storage',
                    'Cross-device cloud sync',
                    'Offline full downloads',
                    'Smart article clean mode',
                ],
                'is_featured' => false,
                'is_active' => true,
                'sort_order' => 1,
            ],
            [
                'name' => '3 Months',
                'slug' => 'quarterly',
                'price' => 'R69',
                'billing_period' => 'R23/mo',
                'badge' => 'Popular',
                'ai_daily_limit' => null,
                'vocab_limit' => null,
                'features' => [
                    'Unlimited AI reading assistant',
                    'Unlimited vocabulary storage',
                    'Cross-device cloud sync',
                    'Offline full downloads',
                    'Priority Gemini processing speed',
                ],
                'is_featured' => true,
                'is_active' => true,
                'sort_order' => 2,
            ],
            [
                'name' => '6 Months',
                'slug' => 'biannual',
                'price' => 'R129',
                'billing_period' => 'R21.50/mo',
                'badge' => null,
                'ai_daily_limit' => null,
                'vocab_limit' => null,
                'features' => [
                    'Unlimited AI reading assistant',
                    'Unlimited vocabulary storage',
                    'Cross-device cloud sync',
                    'Offline full downloads',
                    'Priority Gemini processing speed',
                ],
                'is_featured' => false,
                'is_active' => true,
                'sort_order' => 3,
            ],
            [
                'name' => 'Yearly',
                'slug' => 'yearly',
                'price' => 'R189',
                'billing_period' => 'R15.75/mo · billed annually',
                'badge' => 'Best value',
                'ai_daily_limit' => null,
                'vocab_limit' => null,
                'features' => [
                    'Unlimited AI reading assistant',
                    'Unlimited vocabulary storage',
                    'Cross-device cloud sync',
                    'Offline full downloads',
                    'Priority Gemini processing speed',
                    'Early access to next-gen AI models',
                ],
                'is_featured' => false,
                'is_active' => true,
                'sort_order' => 4,
            ],
        ];

        foreach ($plans as $p) {
            Plan::updateOrCreate(['slug' => $p['slug']], $p);
        }
    }
}
