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
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'day_streak')) {
                $table->integer('day_streak')->default(1)->after('sync_enabled');
            }
            if (!Schema::hasColumn('users', 'total_words_read')) {
                $table->integer('total_words_read')->default(0)->after('day_streak');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'day_streak')) {
                $table->dropColumn('day_streak');
            }
            if (Schema::hasColumn('users', 'total_words_read')) {
                $table->dropColumn('total_words_read');
            }
        });
    }
};
