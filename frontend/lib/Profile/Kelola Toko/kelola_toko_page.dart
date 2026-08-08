// kelola_toko_page.dart
//
// Halaman Kelola Toko / Bengkel — Flutter
// Gaya mengikuti account.dart & settings_page.dart:
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11
//
// GUARD ROLE SELLER:
// Halaman ini cuma boleh diakses user yang sudah berlabel "Penjual"
// (roles.seller == true, lihat AuthService.isSeller()). Kalau masih
// berstatus pembeli biasa (belum daftar Nemu+), begitu halaman ini
// dibuka akan langsung muncul pop-up peringatan lalu otomatis kembali
// ke halaman sebelumnya.
//
// Status buka/tutup toko (toggle cepat) tersambung ke Firestore lewat
// AuthService.storeOpenStatusStream() & AuthService.updateStoreOpenStatus().
// Lihat auth_service_tambahan.dart untuk method yang perlu ditambahkan
// ke dalam services/auth_service.dart.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';
import '/services/auth_service.dart';
import 'produk_layanan_page.dart';
import 'pesanan_masuk_page.dart';
import 'informasi_toko_page.dart';
import 'jam_operasional_page.dart';
import 'promosikan_toko_page.dart';
import '../Nemu+/nemu_plus_page.dart';

class KelolaTokoPage extends StatefulWidget {
  const KelolaTokoPage({super.key});

  @override
  State<KelolaTokoPage> createState() => _KelolaTokoPageState();
}

class _KelolaTokoPageState extends State<KelolaTokoPage> {
  bool _isUpdatingStatus = false;

  // null = masih dicek, true/false = hasil pengecekan role
  bool? _isSeller;

  @override
  void initState() {
    super.initState();
    _checkSellerAccess();
  }

  Future<void> _checkSellerAccess() async {
    final isSeller = await AuthService.isSeller();
    if (!mounted) return;

    setState(() => _isSeller = isSeller);

    if (!isSeller) {
      // Tunggu frame pertama selesai supaya context sudah siap dipakai
      // untuk showDialog (halaman ini belum selesai di-build kalau
      // dipanggil langsung dari initState).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNotSellerDialog();
      });
    }
  }

  Future<void> _showNotSellerDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kamu Belum Terdaftar Sebagai Mitra',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Untuk mengelola toko/bengkel, kamu perlu mendaftar sebagai mitra lewat Nemu+ terlebih dahulu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: kInk.withOpacity(0.7),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kInk,
                      foregroundColor: kCream,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext); // tutup dialog
                      Navigator.pop(context); // keluar dari halaman ini
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NemuPlusPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Daftar Sekarang',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // tutup dialog
                      Navigator.pop(context); // kembali ke halaman sebelumnya
                    },
                    child: Text(
                      'Nanti Saja',
                      style: GoogleFonts.manrope(
                        color: kInk.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleStoreStatus(bool currentValue) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);

    final newValue = !currentValue;

    try {
      await AuthService.updateStoreOpenStatus(newValue);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? 'Toko dibuka kembali' : 'Toko ditutup sementara',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kInk,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status toko: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selagi status role masih dicek, atau user ternyata bukan seller
    // (dialog sedang/sudah tampil menuju pop kembali), tampilkan halaman
    // kosong dengan loading indicator saja — jangan render konten Kelola
    // Toko sama sekali.
    if (_isSeller != true) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kGradientTop, kGradientBottom],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kGradientTop, kGradientBottom],
          ),
        ),
        child: Stack(
          children: [
            ...decorCircles(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _TopBar(),
                  const SizedBox(height: 20),
                  // StreamBuilder mendengarkan field `isOpen` di dokumen
                  // seller/{uid} secara real-time. Kalau ada perubahan dari
                  // device lain (atau dari halaman lain), status di sini
                  // otomatis ikut update.
                  StreamBuilder<bool>(
                    stream: AuthService.storeOpenStatusStream(),
                    builder: (context, snapshot) {
                      final isOpen = snapshot.data ?? true;
                      return _StoreHeader(
                        isOpen: isOpen,
                        isLoading: _isUpdatingStatus,
                        onToggle: () => _toggleStoreStatus(isOpen),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _StatsRow(),
                  const SizedBox(height: 24),
                  _SectionLabel(text: 'Kelola'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItemData(
                        icon: Icons.inventory_2_outlined,
                        label: 'Produk / Layanan',
                        trailing: '24',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProdukLayananPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.receipt_long_outlined,
                        label: 'Pesanan masuk',
                        trailing: '3 baru',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PesananMasukPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.storefront_outlined,
                        label: 'Informasi toko',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InformasiTokoPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.schedule_outlined,
                        label: 'Jam operasional',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JamOperasionalPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.campaign_outlined,
                        label: 'Promosikan tokomu',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PromosikanTokoPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.arrow_back, color: kInk),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Kelola Toko',
          style: GoogleFonts.manrope(
            color: kInk,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final bool isOpen;
  final bool isLoading;
  final VoidCallback onToggle;

  const _StoreHeader({
    required this.isOpen,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kGradientTop.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.storefront, color: kInk, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bengkel Rangga Jaya',
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'Buka' : 'Tutup',
                      style: GoogleFonts.manrope(
                        color: kInk.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: isOpen,
                  onChanged: (_) => onToggle(),
                  activeColor: kGradientBottom,
                ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '24', label: 'Produk')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '156', label: 'Terjual')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '4.8', label: 'Rating')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              color: kInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: kInk.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: kInk.withOpacity(0.75),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  _MenuItemData({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return InkWell(
            onTap: item.onTap ?? () {},
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: kInk.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: kInk.withOpacity(0.75)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.trailing != null) ...[
                    Text(
                      item.trailing!,
                      style: GoogleFonts.manrope(
                        color: kInk.withOpacity(0.6),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: kInk.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}