<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Commodity extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'icon',
        'unit',
        'current_price',
        'predicted_price',
        'change_percent',
        'is_up',
        'prediction_note',
    ];

    protected $casts = [
        'current_price' => 'float',
        'predicted_price' => 'float',
        'change_percent' => 'float',
        'is_up' => 'boolean',
    ];

    public function histories(): HasMany
    {
        return $this->hasMany(PriceHistory::class)->orderBy('id', 'asc');
    }
}
