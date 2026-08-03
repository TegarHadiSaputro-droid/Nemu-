<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('banners', function (Blueprint $table) {
            $table->id();
            $table->string('tag');
            $table->string('title');
            $table->string('sub');
            $table->string('bg_color')->default('#FFFFFF');
            $table->string('tag_color')->default('#007C3F');
            $table->string('icon')->default('eco_rounded');
            $table->timestamps();
        });

        Schema::create('commodities', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->nullable();
            $table->string('icon');
            $table->string('unit')->default('/kg');
            $table->decimal('current_price', 12, 2)->default(0);
            $table->decimal('predicted_price', 12, 2)->default(0);
            $table->decimal('change_percent', 5, 2)->default(0.0);
            $table->boolean('is_up')->default(true);
            $table->text('prediction_note')->nullable();
            $table->timestamps();
        });

        Schema::create('price_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('commodity_id')->constrained('commodities')->onDelete('cascade');
            $table->string('day_label');
            $table->date('date')->nullable();
            $table->decimal('price', 12, 2);
            $table->timestamps();
        });

        Schema::create('market_stores', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('category');
            $table->decimal('rating', 3, 1)->default(4.5);
            $table->string('distance')->default('1.0 km');
            $table->boolean('is_open')->default(true);
            $table->timestamps();
        });

        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('market_store_id')->nullable()->constrained('market_stores')->onDelete('cascade');
            $table->string('store_name');
            $table->string('name');
            $table->decimal('price', 12, 2);
            $table->string('unit');
            $table->string('icon');
            $table->string('image_url')->nullable();
            $table->string('restock_time')->default('Baru saja');
            $table->timestamps();
        });

        Schema::create('active_orders', function (Blueprint $table) {
            $table->id();
            $table->string('courier_name');
            $table->integer('est_minutes')->default(10);
            $table->string('store_name');
            $table->string('items_summary');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('active_orders');
        Schema::dropIfExists('products');
        Schema::dropIfExists('market_stores');
        Schema::dropIfExists('price_histories');
        Schema::dropIfExists('commodities');
        Schema::dropIfExists('banners');
    }
};
