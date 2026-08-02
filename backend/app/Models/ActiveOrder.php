<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ActiveOrder extends Model
{
    use HasFactory;

    protected $fillable = [
        'courier_name',
        'est_minutes',
        'store_name',
        'items_summary',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'est_minutes' => 'integer',
    ];
}
