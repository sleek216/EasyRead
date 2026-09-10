<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // e.g. Monthly, Quarterly, Yearly
            $table->string('slug')->unique(); // e.g. monthly, quarterly, yearly
            $table->string('price'); // e.g. R29, R69, R189, $9.99
            $table->string('billing_period')->nullable(); // e.g. billed monthly, R23/mo
            $table->string('badge')->nullable(); // e.g. Best value, Most Popular
            $table->integer('ai_daily_limit')->nullable(); // null = unlimited
            $table->integer('vocab_limit')->nullable(); // null = unlimited
            $table->json('features')->nullable(); // Array of feature strings
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plans');
    }
};
