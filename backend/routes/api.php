<?php

use App\Http\Controllers\Api\BerandaController;
use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::get('/beranda', [BerandaController::class, 'index']);
    Route::post('/beranda/sync-prices', [BerandaController::class, 'syncPrices']);
});
