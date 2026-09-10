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
        Schema::table('reading_progress', function (Blueprint $table) {
            if (!Schema::hasColumn('reading_progress', 'is_removed')) {
                $table->boolean('is_removed')->default(false)->after('is_bookmarked');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reading_progress', function (Blueprint $table) {
            if (Schema::hasColumn('reading_progress', 'is_removed')) {
                $table->dropColumn('is_removed');
            }
        });
    }
};
