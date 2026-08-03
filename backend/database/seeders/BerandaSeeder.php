<?php

namespace Database\Seeders;

use App\Models\ActiveOrder;
use App\Models\Banner;
use App\Models\Commodity;
use App\Models\MarketStore;
use App\Models\PriceHistory;
use App\Models\Product;
use Illuminate\Database\Seeder;

class BerandaSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Active Order
        ActiveOrder::create([
            'courier_name' => 'Pak Budi',
            'est_minutes' => 8,
            'store_name' => 'Lapak Bu Sari',
            'items_summary' => '2 Barang (Kangkung & Tomat)',
            'is_active' => true,
        ]);

        // 2. Banners
        Banner::create([
            'tag' => 'FRESH TODAY',
            'title' => "Belanja Bahan Segar\nTanpa Ke Pasar",
            'sub' => 'Diantar langsung oleh mitra pedagang pasar.',
            'bg_color' => '#FFFFFF',
            'tag_color' => '#007C3F',
            'icon' => 'eco_rounded',
        ]);
        Banner::create([
            'tag' => 'PROMO',
            'title' => "Ongkir Flat Rp2.000\nUntuk Jarak < 3 km",
            'sub' => 'Berlaku setiap hari untuk semua produk pasar.',
            'bg_color' => '#FFFFFF',
            'tag_color' => '#FFA500',
            'icon' => 'local_shipping_rounded',
        ]);
        Banner::create([
            'tag' => 'JASA',
            'title' => "Panggil Tukang\nKapan Saja",
            'sub' => 'Tenaga ahli berpengalaman siap membantu kamu.',
            'bg_color' => '#FFFFFF',
            'tag_color' => '#2196F3',
            'icon' => 'handyman_rounded',
        ]);

        // 3. Commodities & Histories
        $commoditiesData = [
            [
                'name' => 'Cabai Merah',
                'code' => 'CABAI_MERAH',
                'icon' => '🌶️',
                'unit' => '/kg',
                'current_price' => 42000,
                'predicted_price' => 45000,
                'change_percent' => 7.1,
                'is_up' => true,
                'prediction_note' => 'Prediksi Besok: Naik ~Rp3.000 karena pasokan menurun dari daerah penghasil.',
                'history' => [
                    ['day' => '5 hari lalu', 'price' => 35000],
                    ['day' => '4 hari lalu', 'price' => 37000],
                    ['day' => '3 hari lalu', 'price' => 38000],
                    ['day' => 'Lusa', 'price' => 39500],
                    ['day' => 'Kemarin', 'price' => 40000],
                    ['day' => 'Hari Ini', 'price' => 42000],
                    ['day' => 'Prediksi', 'price' => 45000],
                ],
            ],
            [
                'name' => 'Bawang Merah',
                'code' => 'BAWANG_MERAH',
                'icon' => '🧅',
                'unit' => '/kg',
                'current_price' => 28000,
                'predicted_price' => 26500,
                'change_percent' => 5.3,
                'is_up' => false,
                'prediction_note' => 'Prediksi Besok: Turun ~Rp1.500 karena panen lokal dari Brebes masuk.',
                'history' => [
                    ['day' => '5 hari lalu', 'price' => 33000],
                    ['day' => '4 hari lalu', 'price' => 32000],
                    ['day' => '3 hari lalu', 'price' => 31000],
                    ['day' => 'Lusa', 'price' => 30000],
                    ['day' => 'Kemarin', 'price' => 29500],
                    ['day' => 'Hari Ini', 'price' => 28000],
                    ['day' => 'Prediksi', 'price' => 26500],
                ],
            ],
            [
                'name' => 'Tomat Segar',
                'code' => 'TOMAT',
                'icon' => '🍅',
                'unit' => '/kg',
                'current_price' => 12000,
                'predicted_price' => 12000,
                'change_percent' => 0.0,
                'is_up' => false,
                'prediction_note' => 'Prediksi Besok: Stabil di harga Rp12.000 — pasokan cukup.',
                'history' => [
                    ['day' => '5 hari lalu', 'price' => 11000],
                    ['day' => '4 hari lalu', 'price' => 11500],
                    ['day' => '3 hari lalu', 'price' => 12000],
                    ['day' => 'Lusa', 'price' => 11800],
                    ['day' => 'Kemarin', 'price' => 12000],
                    ['day' => 'Hari Ini', 'price' => 12000],
                    ['day' => 'Prediksi', 'price' => 12000],
                ],
            ],
            [
                'name' => 'Daging Ayam',
                'code' => 'DAGING_AYAM',
                'icon' => '🍗',
                'unit' => '/kg',
                'current_price' => 36000,
                'predicted_price' => 38000,
                'change_percent' => 5.5,
                'is_up' => true,
                'prediction_note' => 'Prediksi Besok: Cenderung naik mendekati akhir pekan & permintaan tinggi.',
                'history' => [
                    ['day' => '5 hari lalu', 'price' => 33000],
                    ['day' => '4 hari lalu', 'price' => 33500],
                    ['day' => '3 hari lalu', 'price' => 34000],
                    ['day' => 'Lusa', 'price' => 35000],
                    ['day' => 'Kemarin', 'price' => 35500],
                    ['day' => 'Hari Ini', 'price' => 36000],
                    ['day' => 'Prediksi', 'price' => 38000],
                ],
            ],
            [
                'name' => 'Bawang Putih',
                'code' => 'BAWANG_PUTIH',
                'icon' => '🧄',
                'unit' => '/kg',
                'current_price' => 32000,
                'predicted_price' => 31000,
                'change_percent' => 3.1,
                'is_up' => false,
                'prediction_note' => 'Prediksi Besok: Sedikit turun karena stok impor masuk ke pasar.',
                'history' => [
                    ['day' => '5 hari lalu', 'price' => 34000],
                    ['day' => '4 hari lalu', 'price' => 33500],
                    ['day' => '3 hari lalu', 'price' => 33000],
                    ['day' => 'Lusa', 'price' => 32500],
                    ['day' => 'Kemarin', 'price' => 32500],
                    ['day' => 'Hari Ini', 'price' => 32000],
                    ['day' => 'Prediksi', 'price' => 31000],
                ],
            ],
        ];

        foreach ($commoditiesData as $c) {
            $history = $c['history'];
            unset($c['history']);
            $com = Commodity::create($c);
            foreach ($history as $h) {
                PriceHistory::create([
                    'commodity_id' => $com->id,
                    'day_label' => $h['day'],
                    'price' => $h['price'],
                ]);
            }
        }

        // 4. Stores & Products
        $store1 = MarketStore::create(['name' => 'Pasar Sepinggan', 'category' => 'Sayur, Buah & Daging', 'rating' => 4.8, 'distance' => '1.5 km', 'is_open' => true]);
        $store2 = MarketStore::create(['name' => 'Pasar Buton', 'category' => 'Sembako & Rempah', 'rating' => 4.6, 'distance' => '4.8 km', 'is_open' => true]);
        $store3 = MarketStore::create(['name' => 'Pasar Klandasan', 'category' => 'Ikan & Seafood Segar', 'rating' => 4.9, 'distance' => '9.5 km', 'is_open' => true]);
        MarketStore::create(['name' => 'Pasar Pandansari', 'category' => 'Beras & Palawija', 'rating' => 4.7, 'distance' => '13.0 km', 'is_open' => false]);

        Product::create(['market_store_id' => $store1->id, 'store_name' => 'Lapak Bu Sari', 'name' => 'Kangkung Segar', 'price' => 3000, 'unit' => '/ikat', 'icon' => '🥬', 'image_url' => 'assets/products/kangkung.jpg', 'restock_time' => '1 jam lalu']);
        Product::create(['market_store_id' => $store1->id, 'store_name' => 'Lapak Bu Sari', 'name' => 'Tomat Merah', 'price' => 12000, 'unit' => '/kg', 'icon' => '🍅', 'image_url' => 'assets/products/tomat.jpg', 'restock_time' => '30 mnt lalu']);
        Product::create(['market_store_id' => $store2->id, 'store_name' => 'Kios Pak Budi', 'name' => 'Tempe Papan', 'price' => 4000, 'unit' => '/papan', 'icon' => '🍱', 'image_url' => 'assets/products/tempe.jpg', 'restock_time' => '2 jam lalu']);
        Product::create(['market_store_id' => null, 'store_name' => 'Warung Tani', 'name' => 'Cabai Keriting', 'price' => 42000, 'unit' => '/kg', 'icon' => '🌶️', 'image_url' => 'assets/products/cabai_keriting.jpg', 'restock_time' => '45 mnt lalu']);
        Product::create(['market_store_id' => $store1->id, 'store_name' => 'Lapak Bu Sari', 'name' => 'Bayam Hijau', 'price' => 4000, 'unit' => '/ikat', 'icon' => '🥗', 'image_url' => 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&q=80', 'restock_time' => '20 mnt lalu']);
        Product::create(['market_store_id' => $store3->id, 'store_name' => 'Toko Harapan', 'name' => 'Tahu Putih', 'price' => 8000, 'unit' => '/papan', 'icon' => '🧈', 'image_url' => 'assets/products/tahu.jpg', 'restock_time' => '1 jam lalu']);
    }
}
