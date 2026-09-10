<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

use App\Models\User;
use App\Models\Collection;
use App\Models\Book;
use App\Models\BookParagraph;
use App\Models\ReadingProgress;
use App\Models\Vocabulary;
use Illuminate\Support\Facades\Hash;

class EasyWordDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Super Admin
        $admin = User::firstOrCreate(
            ['email' => 'admin@easyword.com'],
            [
                'name' => 'EasyRead Admin',
                'password' => Hash::make('admin123456'),
                'role' => 'admin',
                'is_premium' => true,
                'ai_free_uses_left' => 9999,
            ]
        );

        // 2. Create Demo User
        $user = User::firstOrCreate(
            ['email' => 'reader@easyword.com'],
            [
                'name' => 'Elena Rostova',
                'password' => Hash::make('reader123456'),
                'role' => 'user',
                'is_premium' => true,
                'ai_free_uses_left' => 50,
            ]
        );

        // 3. Create Default Curated Collections
        $collections = [
            ['name' => 'Deep Work', 'tag' => 'deep-work', 'color_hex' => '#4B6B4A'],
            ['name' => 'Philosophy', 'tag' => 'philosophy', 'color_hex' => '#8B5A2B'],
            ['name' => 'Essays', 'tag' => 'essays', 'color_hex' => '#2E5B70'],
            ['name' => 'Vocabulary', 'tag' => 'vocabulary', 'color_hex' => '#7A3E65'],
        ];

        foreach ($collections as $c) {
            Collection::firstOrCreate(['tag' => $c['tag']], $c);
        }

        $deepWorkCollection = Collection::where('tag', 'deep-work')->first();

        // 4. Seed Default Book: "The Quiet Power of Reading Slowly"
        $book1 = Book::firstOrCreate(
            ['title' => 'The Quiet Power of Reading Slowly'],
            [
                'author' => 'Alex Michaelides',
                'category' => 'Research',
                'cover_color' => 'forest',
                'read_time' => '6 min read',
                'source_url' => 'https://longform.example/reading-slowly',
                'source_type' => 'article',
                'collection_id' => $deepWorkCollection ? $deepWorkCollection->id : null,
                'is_public' => true,
            ]
        );

        $paragraphs1 = [
            "There is something quietly radical about reading a single page slowly, all the way through, without reaching for another tab. It sounds simple, almost too simple to write about. And yet for many of us it has become an ambiguous skill — something we know we can still do, but rarely choose to.",
            "Attention today is fragmented by design. Every app on your phone is engineered by teams whose primary metric is the second-by-second capture of your gaze. When you open a long essay, you are not just reading; you are entering a quiet counter-movement against an entire digital ecosystem built to distract you.",
            "Deep reading isn't about speed. The modern obsession with reading fifty books a year treats literature like a packing list — items to check off, metrics to display. But real comprehension requires lingering on a well-turned sentence, letting the cadence settle in your mind.",
            "When you pause over an unfamiliar word — say, 'serendipity' or 'resilience' — you are doing more than building vocabulary. You are training patience. The mind that can sit quietly with an unresolved thought is the mind best equipped to solve hard problems.",
            "In the end, the books that shape us are rarely the ones we sprinted through. They are the dog-eared paperbacks we lived with for weeks, whose margins hold our own penciled doubts, and whose final sentence felt less like a finish line and more like a quiet farewell.",
        ];

        foreach ($paragraphs1 as $idx => $content) {
            BookParagraph::firstOrCreate(
                ['book_id' => $book1->id, 'paragraph_index' => $idx],
                ['content' => $content]
            );
        }

        // Seed Book 2: "Atomic Habits"
        $book2 = Book::firstOrCreate(
            ['title' => 'Atomic Habits & Small Changes'],
            [
                'author' => 'James Clear',
                'category' => 'Self-dev',
                'cover_color' => 'gold',
                'read_time' => '12 min read',
                'source_type' => 'article',
                'is_public' => true,
            ]
        );

        $paragraphs2 = [
            "Changes that seem small and unimportant at first will compound into remarkable results if you are willing to stick with them for years. We all deal with setbacks, but in the long run, the quality of our lives often depends on the quality of our habits.",
            "With the same habits, you will end up with the same results. But with better habits, anything is possible.",
            "Habits are the compound interest of self-improvement. Getting 1 percent better every day counts for a lot in the long run.",
        ];

        foreach ($paragraphs2 as $idx => $content) {
            BookParagraph::firstOrCreate(
                ['book_id' => $book2->id, 'paragraph_index' => $idx],
                ['content' => $content]
            );
        }

        // Seed Book 3: "The Architecture of Open Source"
        $book3 = Book::firstOrCreate(
            ['title' => 'The Architecture of Modern Systems'],
            [
                'author' => 'Martin Kleppmann',
                'category' => 'Education',
                'cover_color' => 'navy',
                'read_time' => '18 min read',
                'source_type' => 'article',
                'is_public' => true,
            ]
        );

        $paragraphs3 = [
            "Data is at the center of most software applications today. The difficult problems are no longer about computing power, but about the sheer volume of data, the complexity of data structures, and the speed at which it is generated.",
            "A system is reliable if it continues to work correctly, even when things go wrong.",
        ];

        foreach ($paragraphs3 as $idx => $content) {
            BookParagraph::firstOrCreate(
                ['book_id' => $book3->id, 'paragraph_index' => $idx],
                ['content' => $content]
            );
        }

        // 5. Seed Initial Reading Progress for Demo User
        ReadingProgress::firstOrCreate(
            ['user_id' => $user->id, 'book_id' => $book1->id],
            [
                'current_paragraph' => 1,
                'progress_percent' => 35.0,
                'is_favorite' => true,
                'is_bookmarked' => true,
                'last_read_at' => now(),
            ]
        );

        // 6. Seed Sample Vocabulary
        $words = [
            [
                'word' => 'eloquent',
                'pos' => 'adjective',
                'meaning' => 'Fluent or persuasive in speaking or writing.',
                'example' => 'Her argument was as eloquent as it was persuasive.',
                'synonyms' => ['articulate', 'expressive', 'fluent'],
                'origin' => 'From Latin eloqui, "to speak out."',
                'source_title' => $book1->title,
                'is_mastered' => false,
            ],
            [
                'word' => 'resilience',
                'pos' => 'noun',
                'meaning' => 'The capacity to recover quickly from difficulty.',
                'example' => 'Slow reading builds mental resilience.',
                'synonyms' => ['toughness', 'adaptability', 'hardiness'],
                'origin' => 'From Latin resilire, "to rebound."',
                'source_title' => $book1->title,
                'is_mastered' => true,
            ],
            [
                'word' => 'serendipity',
                'pos' => 'noun',
                'meaning' => 'The occurrence of finding something valuable by chance.',
                'example' => 'Browsing a quiet bookstore brings true serendipity.',
                'synonyms' => ['chance', 'fortune', 'luck'],
                'origin' => 'Coined by Horace Walpole in 1754.',
                'source_title' => $book1->title,
                'is_mastered' => false,
            ],
        ];

        foreach ($words as $w) {
            Vocabulary::firstOrCreate(
                ['user_id' => $user->id, 'word' => $w['word']],
                $w
            );
        }
    }
}
