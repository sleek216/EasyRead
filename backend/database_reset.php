<?php

use App\Models\User;
use App\Models\Book;
use App\Models\Category;
use App\Models\BookParagraph;
use App\Models\Collection;
use App\Models\ReadingProgress;
use App\Models\Vocabulary;
use Illuminate\Support\Facades\Schema;

// Disable foreign key checks for truncation
Schema::disableForeignKeyConstraints();

// Truncate specified tables
User::truncate();
Book::truncate();
Category::truncate();
BookParagraph::truncate();
Collection::truncate();
ReadingProgress::truncate();
Vocabulary::truncate();

Schema::enableForeignKeyConstraints();

// Create 5 New Categories
$categories = [
    ['name' => 'Fantasy', 'slug' => 'fantasy', 'color_hex' => '#9B59B6', 'sort_order' => 1],
    ['name' => 'Science Fiction', 'slug' => 'sci-fi', 'color_hex' => '#3498DB', 'sort_order' => 2],
    ['name' => 'Biography', 'slug' => 'biography', 'color_hex' => '#E67E22', 'sort_order' => 3],
    ['name' => 'History', 'slug' => 'history', 'color_hex' => '#F1C40F', 'sort_order' => 4],
    ['name' => 'Technology', 'slug' => 'technology', 'color_hex' => '#2ECC71', 'sort_order' => 5],
];

foreach ($categories as $cat) {
    Category::create($cat);
}

// Create 5 long books (one for each category)
$dummyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

$booksData = [
    ['title' => 'The Lost Kingdom', 'author' => 'A. B. Writer', 'category' => 'Fantasy', 'cover_color' => 'gold'],
    ['title' => 'Galactic Travels', 'author' => 'C. D. Author', 'category' => 'Science Fiction', 'cover_color' => 'forest'],
    ['title' => 'Life of a Genius', 'author' => 'E. F. Scribe', 'category' => 'Biography', 'cover_color' => 'moss'],
    ['title' => 'World War II', 'author' => 'G. H. Historian', 'category' => 'History', 'cover_color' => 'paper'],
    ['title' => 'Future of AI', 'author' => 'I. J. Techie', 'category' => 'Technology', 'cover_color' => 'ink'],
];

foreach ($booksData as $data) {
    $book = Book::create([
        'title' => $data['title'],
        'author' => $data['author'],
        'category' => $data['category'],
        'cover_color' => $data['cover_color'],
        'read_time' => '120 min read',
        'source_type' => 'article',
        'is_public' => true,
    ]);

    // Insert 500 paragraphs to simulate a 100+ page book
    $paragraphs = [];
    for ($i = 0; $i < 500; $i++) {
        $paragraphs[] = [
            'book_id' => $book->id,
            'paragraph_index' => $i,
            'content' => "Page block " . ($i + 1) . ": " . $dummyText,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
    BookParagraph::insert($paragraphs);
}

echo "Database cleaned and seeded with 5 categories and long books!\n";
