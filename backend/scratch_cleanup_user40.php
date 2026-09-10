<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;

$user = User::find(40);
if ($user) {
    echo "Wiping contaminated books & progress from user 40..." . PHP_EOL;
    $user->tokens()->delete();
    $user->highlights()->delete();
    $user->readingProgress()->delete();
    $user->vocabularies()->delete();
    $user->backups()->delete();
    $user->collections()->delete();
    $user->collectionBooks()->delete();
    $user->books()->delete();
    $user->aiLogs()->delete();
    // Force delete user 40 so user can test a completely fresh signup/Google login!
    $user->forceDelete();
    echo "User 40 completely removed from database!" . PHP_EOL;
} else {
    echo "User 40 not found." . PHP_EOL;
}
