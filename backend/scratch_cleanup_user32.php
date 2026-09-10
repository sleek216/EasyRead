<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;

$user = User::withTrashed()->find(32);
if ($user) {
    echo "Wiping user 32..." . PHP_EOL;
    $user->tokens()->delete();
    $user->highlights()->delete();
    $user->readingProgress()->delete();
    $user->vocabularies()->delete();
    $user->backups()->delete();
    $user->collections()->delete();
    $user->collectionBooks()->delete();
    $user->books()->delete();
    $user->aiLogs()->delete();
    $user->forceDelete();
    echo "User 32 wiped and force deleted!" . PHP_EOL;
}
