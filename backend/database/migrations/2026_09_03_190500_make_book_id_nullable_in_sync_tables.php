<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Use raw SQL to allow NULL on book_id while keeping foreign key
        try {
            DB::statement('ALTER TABLE `highlights` MODIFY `book_id` BIGINT UNSIGNED NULL');
        } catch (\Throwable $e) {}

        try {
            DB::statement('ALTER TABLE `reading_progress` MODIFY `book_id` BIGINT UNSIGNED NULL');
        } catch (\Throwable $e) {}
    }

    public function down(): void
    {
    }
};
