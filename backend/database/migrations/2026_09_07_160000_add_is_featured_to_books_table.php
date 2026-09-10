<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('books') && !Schema::hasColumn('books', 'is_featured')) {
            Schema::table('books', function (Blueprint $table) {
                $table->boolean('is_featured')->default(false)->after('is_public');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('books') && Schema::hasColumn('books', 'is_featured')) {
            Schema::table('books', function (Blueprint $table) {
                $table->dropColumn('is_featured');
            });
        }
    }
};
