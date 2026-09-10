<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Book;
use App\Models\ReadingProgress;

echo "--- BOOKS FOR USER 40 ---" . PHP_EOL;
foreach (Book::where('user_id', 40)->get() as $b) {
    echo "Book ID: {$b->id} | Title: {$b->title} | Created: {$b->created_at}" . PHP_EOL;
}

echo "--- PROGRESS FOR USER 40 ---" . PHP_EOL;
foreach (ReadingProgress::where('user_id', 40)->get() as $p) {
    echo "Progress ID: {$p->id} | Title: {$p->book_title} | Progress: {$p->progress_percent}% | LastRead: {$p->last_read_at}" . PHP_EOL;
}
