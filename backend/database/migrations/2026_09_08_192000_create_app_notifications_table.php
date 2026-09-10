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
        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('cascade');
            $table->string('type')->default('general'); // subscription, announcement, new_book, suspension, general
            $table->string('title');
            $table->text('message');
            $table->json('data')->nullable(); // metadata e.g. ['book_id' => 12, 'plan' => 'Pro']
            $table->boolean('is_broadcast')->default(false);
            $table->json('read_by_users')->nullable(); // for broadcasts: list of user IDs who read it
            $table->timestamp('read_at')->nullable(); // for single user notifications
            $table->timestamps();

            $table->index(['user_id', 'is_broadcast']);
            $table->index('type');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('app_notifications');
    }
};
