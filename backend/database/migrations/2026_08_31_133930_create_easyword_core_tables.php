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
        // 1. Update Users Table with Reading & Subscription fields
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('user')->after('password'); // admin or user
            $table->boolean('is_premium')->default(false)->after('role');
            $table->integer('ai_free_uses_left')->default(10)->after('is_premium');
            $table->timestamp('last_active_at')->nullable()->after('ai_free_uses_left');
            $table->softDeletes()->after('updated_at'); // Apple compliant account deletion
        });

        // 2. Collections (Custom Shelves)
        Schema::create('collections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('tag')->index();
            $table->string('color_hex')->default('#4B6B4A');
            $table->timestamps();
        });

        // 3. Books & Documents
        Schema::create('books', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('cascade'); // null = system/public book
            $table->foreignId('collection_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title');
            $table->string('author')->nullable()->default('Unknown Author');
            $table->string('category')->default('General')->index(); // Fiction, Research, Novel, etc.
            $table->string('cover_color')->default('forest');
            $table->string('read_time')->nullable()->default('5 min read');
            $table->string('source_url')->nullable();
            $table->string('source_type')->default('article'); // article, web, pdf, epub
            $table->boolean('is_public')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        // 4. Book Paragraphs (Clean Reader Text)
        Schema::create('book_paragraphs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('book_id')->constrained()->onDelete('cascade');
            $table->integer('paragraph_index')->index();
            $table->text('content');
            $table->timestamps();
        });

        // 5. User Reading Progress (Netflix-style continue reading)
        Schema::create('reading_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('book_id')->constrained()->onDelete('cascade');
            $table->integer('current_paragraph')->default(0);
            $table->decimal('progress_percent', 5, 2)->default(0.00); // 0.00 to 100.00
            $table->boolean('is_favorite')->default(false);
            $table->boolean('is_bookmarked')->default(false);
            $table->timestamp('last_read_at')->useCurrent();
            $table->timestamps();

            $table->unique(['user_id', 'book_id']);
        });

        // 6. Highlights & Notes (Per paragraph)
        Schema::create('highlights', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('book_id')->constrained()->onDelete('cascade');
            $table->integer('paragraph_index');
            $table->string('color')->default('yellow'); // gold, moss, rose, blue
            $table->text('note')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'book_id', 'paragraph_index']);
        });

        // 7. Personal Vocabulary Bank
        Schema::create('vocabularies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('word')->index();
            $table->string('pos')->nullable()->default('noun');
            $table->text('meaning');
            $table->text('example')->nullable();
            $table->json('synonyms')->nullable();
            $table->string('origin')->nullable();
            $table->string('source_title')->nullable();
            $table->boolean('is_mastered')->default(false);
            $table->integer('review_count')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'word']);
        });

        // 8. Cloud Backup Restore Points
        Schema::create('backups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title')->default('Automatic Cloud Backup');
            $table->json('snapshot_data'); // Books, highlights, vocab JSON snapshot
            $table->integer('item_count')->default(0);
            $table->timestamps();
        });

        // 9. AI Query Logs & Response Cache
        Schema::create('ai_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('action'); // simplify, summarize, explain, translate
            $table->string('passage_hash', 64)->index(); // MD5 hash for instant 0-cost caching
            $table->text('passage_text');
            $table->text('response_text');
            $table->integer('tokens_used')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_logs');
        Schema::dropIfExists('backups');
        Schema::dropIfExists('vocabularies');
        Schema::dropIfExists('highlights');
        Schema::dropIfExists('reading_progress');
        Schema::dropIfExists('book_paragraphs');
        Schema::dropIfExists('books');
        Schema::dropIfExists('collections');
        Schema::table('users', function (Blueprint $table) {
            $table->dropSoftDeletes();
            $table->dropColumn(['role', 'is_premium', 'ai_free_uses_left', 'last_active_at']);
        });
    }
};
