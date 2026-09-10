<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Add sync_enabled to users table
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'sync_enabled')) {
                $table->boolean('sync_enabled')->default(true)->after('is_active');
            }
        });

        // 2. Adjust highlights table for custom book titles and nullable book_id
        Schema::table('highlights', function (Blueprint $table) {
            if (!Schema::hasColumn('highlights', 'book_title')) {
                $table->string('book_title')->nullable()->index()->after('book_id');
            }
        });

        // 3. Adjust reading_progress table for custom book titles and nullable book_id
        Schema::table('reading_progress', function (Blueprint $table) {
            if (!Schema::hasColumn('reading_progress', 'book_title')) {
                $table->string('book_title')->nullable()->index()->after('book_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'sync_enabled')) {
                $table->dropColumn('sync_enabled');
            }
        });

        Schema::table('highlights', function (Blueprint $table) {
            if (Schema::hasColumn('highlights', 'book_title')) {
                $table->dropColumn('book_title');
            }
        });

        Schema::table('reading_progress', function (Blueprint $table) {
            if (Schema::hasColumn('reading_progress', 'book_title')) {
                $table->dropColumn('book_title');
            }
        });
    }
};
