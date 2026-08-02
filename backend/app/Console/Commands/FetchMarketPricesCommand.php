<?php

namespace App\Console\Commands;

use App\Services\MarketPriceFetcherService;
use Illuminate\Console\Command;

class FetchMarketPricesCommand extends Command
{
    protected $signature = 'market:fetch-prices';
    protected $description = 'Ambil dan perbarui data harga pangan pasar real-time dari sumber resmi';

    public function handle(MarketPriceFetcherService $fetcher): int
    {
        $this->info('Mengambil data harga komoditas pasar terbaru...');
        $result = $fetcher->fetchAndSyncPrices();
        $this->info("Sukses! Berhasil memperbarui {$result['updated_commodities']} komoditas pada {$result['timestamp']}.");
        return Command::SUCCESS;
    }
}
