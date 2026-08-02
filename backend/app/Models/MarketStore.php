<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MarketStore extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'category',
        'rating',
        'distance',
        'is_open',
    ];

    protected $casts = [
        'rating' => 'float',
        'is_open' => 'boolean',
    ];

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }
}
