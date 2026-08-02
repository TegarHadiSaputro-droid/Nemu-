<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'market_store_id',
        'store_name',
        'name',
        'price',
        'unit',
        'icon',
        'image_url',
        'restock_time',
    ];

    protected $casts = [
        'price' => 'float',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(MarketStore::class, 'market_store_id');
    }
}
