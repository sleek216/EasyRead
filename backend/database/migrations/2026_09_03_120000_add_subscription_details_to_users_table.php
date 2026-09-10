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
            $table->foreignId('plan_id')->nullable()->after('is_premium')->constrained('plans')->nullOnDelete();
            $table->string('subscription_plan')->nullable()->after('plan_id');
            $table->string('subscription_price')->nullable()->after('subscription_plan');
            $table->timestamp('subscription_starts_at')->nullable()->after('subscription_price');
            $table->timestamp('subscription_expires_at')->nullable()->after('subscription_starts_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['plan_id']);
            $table->dropColumn([
                'plan_id',
                'subscription_plan',
                'subscription_price',
                'subscription_starts_at',
                'subscription_expires_at',
            ]);
        });
    }
};
