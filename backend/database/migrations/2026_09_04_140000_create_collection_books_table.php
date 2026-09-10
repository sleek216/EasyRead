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
        Schema::create('collection_books', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('collection_id')->nullable()->constrained()->nullOnDelete();
            $table->string('collection_tag')->index();
            $table->foreignId('book_id')->nullable()->constrained()->nullOnDelete();
            $table->string('book_title')->index();
            $table->timestamps();

            $table->unique(['user_id', 'book_title']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('collection_books');
    }
};
