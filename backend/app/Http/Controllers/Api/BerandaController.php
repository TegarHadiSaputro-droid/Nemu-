<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActiveOrder;
use App\Models\Banner;
use App\Models\Commodity;
use App\Models\MarketStore;
use App\Models\Product;
use App\Services\MarketPriceFetcherService;
use Illuminate\Http\JsonResponse;

class BerandaController extends Controller
{
    /**
     * Mengembalikan data lengkap untuk Halaman Beranda (HomeScreen).
     */
    public function index(): JsonResponse
    {
        $activeOrder = ActiveOrder::where('is_active', true)->latest()->first();

        $banners = Banner::all()->map(function ($b) {
            return [
                'tag' => $b->tag,
                'title' => $b->title,
                'sub' => $b->sub,
                'bg_color' => $b->bg_color,
                'tag_color' => $b->tag_color,
                'icon' => $b->icon,
            ];
        });

        $commodities = Commodity::with('histories')->get()->map(function ($c) {
            $historyPrices = $c->histories->pluck('price')->toArray();
            $days = $c->histories->pluck('day_label')->toArray();

            return [
                'id' => $c->id,
                'name' => $c->name,
                'icon' => $c->icon,
                'unit' => $c->unit,
                'current_price' => (float) $c->current_price,
                'predicted_price' => (float) $c->predicted_price,
                'change_percent' => (float) $c->change_percent,
                'is_up' => (bool) $c->is_up,
                'prediction_note' => $c->prediction_note,
                'history_prices' => $historyPrices,
                'days' => $days,
            ];
        });

        $quickProducts = Product::all()->map(function ($p) {
            return [
                'id' => $p->id,
                'name' => $p->name,
                'store' => $p->store_name,
                'price' => (float) $p->price,
                'unit' => $p->unit,
                'icon' => $p->icon,
                'image_url' => $p->image_url,
                'restock' => $p->restock_time,
            ];
        });

        $stores = MarketStore::all()->map(function ($s) {
            return [
                'id' => $s->id,
                'name' => $s->name,
                'category' => $s->category,
                'rating' => (float) $s->rating,
                'distance' => $s->distance,
                'is_open' => (bool) $s->is_open,
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => [
                'active_order' => $activeOrder ? [
                    'is_active' => (bool) $activeOrder->is_active,
                    'courier_name' => $activeOrder->courier_name,
                    'est_minutes' => $activeOrder->est_minutes,
                    'store_name' => $activeOrder->store_name,
                    'items_summary' => $activeOrder->items_summary,
                ] : null,
                'banners' => $banners,
                'commodities' => $commodities,
                'quick_products' => $quickProducts,
                'stores' => $stores,
            ],
        ]);
    }

    /**
     * Trigger manual perbarui data harga pasar dari portal online.
     */
    public function syncPrices(MarketPriceFetcherService $fetcher): JsonResponse
    {
        $result = $fetcher->fetchAndSyncPrices();

        return response()->json([
            'status' => 'success',
            'message' => 'Data harga pasar berhasil diperbarui secara real-time!',
            'details' => $result,
        ]);
    }
}
