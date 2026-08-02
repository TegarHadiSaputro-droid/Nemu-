<?php

use App\Http\Controllers\Api\BerandaController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/beranda', [BerandaController::class, 'index']);
    Route::post('/beranda/sync-prices', [BerandaController::class, 'syncPrices']);
});
