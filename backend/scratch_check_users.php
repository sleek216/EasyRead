<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;

foreach (User::withTrashed()->get() as $u) {
    echo "ID: {$u->id} | Email: {$u->email} | Active: {$u->is_active} | DeletedAt: " . ($u->deleted_at ? $u->deleted_at->toDateTimeString() : 'null') . " | Books: " . $u->books()->count() . " | Progress: " . $u->readingProgress()->count() . " | Vocab: " . $u->vocabularies()->count() . PHP_EOL;
}
