// setting_page.dart
//
// Halaman Pengaturan — Flutter
// Diakses dari account.dart lewat menu "Pengaturan" (import
// '../settings/setting_page.dart'). Taruh file ini di folder
// lib/settings/ supaya path importnya cocok.
//
// Gaya mengikuti account.dart & kelola_toko_page.dart:
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11
//
// NOTE: Halaman ini SENGAJA dikosongkan dulu (belum ada menu apapun).
// Tinggal tambahkan section & menu item di dalam ListView pada method
// build() di bawah kalau sudah ditentukan isinya. Widget bantu
// _SectionLabel, _MenuGroup, _MenuItemData sudah disiapkan supaya
// tinggal dipakai lagi nanti.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Theme/app_theme.dart';
import '../Theme/decor_background.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
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

                  _SectionLabel(text: 'Preferensi'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItemData(
                        icon: Icons.notifications_outlined,
                        label: 'Notifikasi',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const _NotifikasiPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.palette_outlined,
                        label: 'Tampilan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const _TampilanPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.language_outlined,
                        label: 'Bahasa',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const _BahasaPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.accessibility_new_outlined,
                        label: 'Aksesibilitas',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const _AksesibilitasPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _SectionLabel(text: 'Aplikasi'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItemData(
                        icon: Icons.location_on_outlined,
                        label: 'Lokasi & Pengiriman',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const _LokasiPengirimanPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Preferensi Belanja',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const _PreferensiBelanjaPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.signal_cellular_alt_outlined,
                        label: 'Data & Penyimpanan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const _DataPenyimpananPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.link_outlined,
                        label: 'Izin Aplikasi',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const _IzinAplikasiPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _SectionLabel(text: 'Keuangan'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItemData(
                        icon: Icons.payments_outlined,
                        label: 'Pengeluaran Bulanan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const _PengeluaranBulananPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.credit_card_outlined,
                        label: 'Metode Pembayaran',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const _MetodePembayaranPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // TODO: tambahkan section & menu Pengaturan lainnya di sini
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
          'Pengaturan',
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
          color: kInk.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu item biasa (baris dengan chevron, untuk navigasi/aksi)
// ---------------------------------------------------------------------------
class _MenuItemData {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDanger;
  final VoidCallback? onTap;
  _MenuItemData({
    required this.icon,
    required this.label,
    this.trailing,
    this.isDanger = false,
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
                      : BorderSide(color: kInk.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: item.isDanger
                        ? Colors.red.shade700
                        : kInk.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.manrope(
                        color: item.isDanger ? Colors.red.shade700 : kInk,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.trailing != null) ...[
                    Flexible(
                      child: Text(
                        item.trailing!,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: kInk.withValues(alpha: 0.6),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: item.isDanger
                        ? Colors.red.shade700.withValues(alpha: 0.6)
                        : kInk.withValues(alpha: 0.4),
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

// ---------------------------------------------------------------------------
// Halaman "Notifikasi"
//
// Catatan: state switch di sini masih lokal (belum tersambung ke
// Firestore/SharedPreferences/FCM topic subscription). Tinggal sambungkan
// di masing-masing _toggle...() kalau backend-nya sudah siap — sudah
// dikasih komentar TODO di titik yang perlu diisi.
// ---------------------------------------------------------------------------
class _NotifikasiPage extends StatefulWidget {
  const _NotifikasiPage();

  @override
  State<_NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<_NotifikasiPage> {
  bool _notifPesanan = true;
  bool _notifChat = true;
  bool _notifPromo = true;
  bool _notifEmail = false;
  bool _suaraGetar = true;

  void _toggleNotifPesanan(bool v) {
    setState(() => _notifPesanan = v);
    // TODO: simpan preferensi & atur subscribe/unsubscribe topic FCM terkait
    // status pesanan
  }

  void _toggleNotifChat(bool v) {
    setState(() => _notifChat = v);
    // TODO: simpan preferensi & atur subscribe/unsubscribe topic FCM chat
  }

  void _toggleNotifPromo(bool v) {
    setState(() => _notifPromo = v);
    // TODO: simpan preferensi & atur subscribe/unsubscribe topic FCM promo
  }

  void _toggleNotifEmail(bool v) {
    setState(() => _notifEmail = v);
    // TODO: simpan preferensi ringkasan aktivitas via email ke backend
  }

  void _toggleSuaraGetar(bool v) {
    setState(() => _suaraGetar = v);
    // TODO: simpan preferensi suara & getar notifikasi
  }

  @override
  Widget build(BuildContext context) {
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
                  Row(
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
                        'Notifikasi',
                        style: GoogleFonts.manrope(
                          color: kInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel(text: 'Aktivitas'),
                  const SizedBox(height: 8),
                  _SwitchGroup(
                    items: [
                      _SwitchItemData(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Notifikasi pesanan',
                        subtitle: 'Update status pesanan masuk & transaksi',
                        value: _notifPesanan,
                        onChanged: _toggleNotifPesanan,
                      ),
                      _SwitchItemData(
                        icon: Icons.chat_bubble_outline,
                        label: 'Notifikasi chat',
                        subtitle: 'Pesan baru dari pembeli/penjual',
                        value: _notifChat,
                        onChanged: _toggleNotifChat,
                      ),
                      _SwitchItemData(
                        icon: Icons.local_offer_outlined,
                        label: 'Notifikasi promo',
                        subtitle: 'Info diskon dan penawaran khusus',
                        value: _notifPromo,
                        onChanged: _toggleNotifPromo,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _SectionLabel(text: 'Lainnya'),
                  const SizedBox(height: 8),
                  _SwitchGroup(
                    items: [
                      _SwitchItemData(
                        icon: Icons.email_outlined,
                        label: 'Notifikasi via email',
                        subtitle: 'Kirim ringkasan aktivitas ke email',
                        value: _notifEmail,
                        onChanged: _toggleNotifEmail,
                      ),
                      _SwitchItemData(
                        icon: Icons.vibration,
                        label: 'Suara & getar',
                        subtitle: 'Bunyi dan getaran saat notifikasi masuk',
                        value: _suaraGetar,
                        onChanged: _toggleSuaraGetar,
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

// ---------------------------------------------------------------------------
// Baris pengaturan dengan Switch (untuk toggle on/off, punya subtitle
// opsional supaya jelas fungsinya)
// ---------------------------------------------------------------------------
class _SwitchItemData {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  _SwitchItemData({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
}

class _SwitchGroup extends StatelessWidget {
  final List<_SwitchItemData> items;
  const _SwitchGroup({required this.items});

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
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : BorderSide(color: kInk.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: kInk.withValues(alpha: 0.75)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: GoogleFonts.manrope(
                          color: kInk,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          item.subtitle!,
                          style: GoogleFonts.manrope(
                            color: kInk.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: item.value,
                  onChanged: item.onChanged,
                  activeThumbColor: kGradientBottom,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold bersama untuk sub-halaman Pengaturan (top bar + background +
// ListView), supaya tiap halaman baru tidak perlu tulis ulang boilerplate
// yang sama.
// ---------------------------------------------------------------------------
class _SubPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SubPageScaffold({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
                  Row(
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
                        title,
                        style: GoogleFonts.manrope(
                          color: kInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Baris info non-interaktif (tanpa chevron/switch), dipakai untuk halaman
// yang sifatnya menampilkan data (mis. rincian pengeluaran)
// ---------------------------------------------------------------------------
class _InfoItemData {
  final IconData icon;
  final String label;
  final String value;
  _InfoItemData({required this.icon, required this.label, required this.value});
}

class _InfoGroup extends StatelessWidget {
  final List<_InfoItemData> items;
  const _InfoGroup({required this.items});

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
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : BorderSide(color: kInk.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: kInk.withValues(alpha: 0.75)),
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
                Text(
                  item.value,
                  style: GoogleFonts.manrope(
                    color: kGradientBottom,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Tampilan"
// ---------------------------------------------------------------------------
class _TampilanPage extends StatefulWidget {
  const _TampilanPage();

  @override
  State<_TampilanPage> createState() => _TampilanPageState();
}

class _TampilanPageState extends State<_TampilanPage> {
  bool _modeGelap = false;
  bool _kurangiAnimasi = false;
  String _ukuranTeks = 'Sedang';

  void _toggleModeGelap(bool v) {
    setState(() => _modeGelap = v);
    // TODO: hubungkan ke ThemeMode aplikasi kalau dark mode sudah didukung
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          v ? 'Mode gelap akan segera hadir' : 'Mode gelap dimatikan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kInk,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleKurangiAnimasi(bool v) {
    setState(() => _kurangiAnimasi = v);
    // TODO: simpan preferensi & kurangi durasi/efek transisi antar halaman
  }

  Future<void> _pilihUkuranTeks() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final options = ['Kecil', 'Sedang', 'Besar'];
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ukuran Teks',
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final selected = opt == _ukuranTeks;
                return InkWell(
                  onTap: () => Navigator.pop(context, opt),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt,
                            style: GoogleFonts.manrope(
                              color: kInk,
                              fontSize: 13.5,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check, size: 18, color: kGradientBottom),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
    if (result != null && result != _ukuranTeks) {
      setState(() => _ukuranTeks = result);
      // TODO: simpan preferensi & terapkan lewat MediaQuery.textScaler global
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageScaffold(
      title: 'Tampilan',
      children: [
        _SectionLabel(text: 'Tema'),
        const SizedBox(height: 8),
        _SwitchGroup(
          items: [
            _SwitchItemData(
              icon: Icons.dark_mode_outlined,
              label: 'Mode gelap',
              subtitle: 'Segera hadir',
              value: _modeGelap,
              onChanged: _toggleModeGelap,
            ),
            _SwitchItemData(
              icon: Icons.motion_photos_off_outlined,
              label: 'Kurangi animasi',
              subtitle: 'Percepat/hilangkan transisi antar halaman',
              value: _kurangiAnimasi,
              onChanged: _toggleKurangiAnimasi,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel(text: 'Teks'),
        const SizedBox(height: 8),
        _MenuGroup(
          items: [
            _MenuItemData(
              icon: Icons.format_size,
              label: 'Ukuran teks',
              trailing: _ukuranTeks,
              onTap: _pilihUkuranTeks,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Bahasa"
// ---------------------------------------------------------------------------
class _BahasaPage extends StatefulWidget {
  const _BahasaPage();

  @override
  State<_BahasaPage> createState() => _BahasaPageState();
}

class _BahasaPageState extends State<_BahasaPage> {
  String _bahasa = 'Indonesia';

  void _pilihBahasa(String opt) {
    if (opt == _bahasa) return;
    setState(() => _bahasa = opt);
    // TODO: simpan preferensi bahasa & terapkan ke localization aplikasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bahasa diganti ke $opt',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kInk,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const options = ['Indonesia', 'English'];
    return _SubPageScaffold(
      title: 'Bahasa',
      children: [
        Container(
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: List.generate(options.length, (index) {
              final opt = options[index];
              final selected = opt == _bahasa;
              final isLast = index == options.length - 1;
              return InkWell(
                onTap: () => _pilihBahasa(opt),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(14) : Radius.zero,
                  bottom: isLast ? const Radius.circular(14) : Radius.zero,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isLast
                          ? BorderSide.none
                          : BorderSide(color: kInk.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt,
                          style: GoogleFonts.manrope(
                            color: kInk,
                            fontSize: 13.5,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check, size: 18, color: kGradientBottom),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Aksesibilitas"
// ---------------------------------------------------------------------------
class _AksesibilitasPage extends StatefulWidget {
  const _AksesibilitasPage();

  @override
  State<_AksesibilitasPage> createState() => _AksesibilitasPageState();
}

class _AksesibilitasPageState extends State<_AksesibilitasPage> {
  bool _kontrasTinggi = false;
  bool _kuranggiGerakan = false;
  bool _pembacaLayar = false;

  void _toggleKontrasTinggi(bool v) {
    setState(() => _kontrasTinggi = v);
    // TODO: simpan preferensi & terapkan tema kontras tinggi
  }

  void _toggleKurangiGerakan(bool v) {
    setState(() => _kuranggiGerakan = v);
    // TODO: simpan preferensi & kurangi animasi/efek yang bergerak
  }

  void _togglePembacaLayar(bool v) {
    setState(() => _pembacaLayar = v);
    // TODO: pastikan Semantics label sudah lengkap untuk TalkBack/VoiceOver
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageScaffold(
      title: 'Aksesibilitas',
      children: [
        _SwitchGroup(
          items: [
            _SwitchItemData(
              icon: Icons.contrast,
              label: 'Kontras tinggi',
              subtitle: 'Perjelas perbedaan warna teks & latar',
              value: _kontrasTinggi,
              onChanged: _toggleKontrasTinggi,
            ),
            _SwitchItemData(
              icon: Icons.motion_photos_off_outlined,
              label: 'Kurangi gerakan',
              subtitle: 'Minimalkan animasi yang bisa memicu pusing',
              value: _kuranggiGerakan,
              onChanged: _toggleKurangiGerakan,
            ),
            _SwitchItemData(
              icon: Icons.record_voice_over_outlined,
              label: 'Dukungan pembaca layar',
              subtitle: 'Optimalkan label untuk TalkBack/VoiceOver',
              value: _pembacaLayar,
              onChanged: _togglePembacaLayar,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Lokasi & Pengiriman"
// ---------------------------------------------------------------------------
class _LokasiPengirimanPage extends StatefulWidget {
  const _LokasiPengirimanPage();

  @override
  State<_LokasiPengirimanPage> createState() => _LokasiPengirimanPageState();
}

class _LokasiPengirimanPageState extends State<_LokasiPengirimanPage> {
  bool _izinLokasi = true;
  String _alamatSaya = 'Belum diatur';
  double _radiusPencarian = 5;

  void _toggleIzinLokasi(bool v) {
    setState(() => _izinLokasi = v);
    // TODO: kalau v == true, minta permission lokasi lewat
    // package:geolocator / package:permission_handler
  }

  Future<void> _editAlamat() async {
    final controller = TextEditingController(
      text: _alamatSaya == 'Belum diatur' ? '' : _alamatSaya,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Alamat Saya',
          style: GoogleFonts.manrope(color: kInk, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: GoogleFonts.manrope(color: kInk),
          decoration: InputDecoration(
            hintText: 'Tulis alamat lengkap...',
            hintStyle: GoogleFonts.manrope(color: kInk.withValues(alpha: 0.4)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: GoogleFonts.manrope(color: kInk)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(
              'Simpan',
              style: GoogleFonts.manrope(
                color: kGradientBottom,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _alamatSaya = result.isEmpty ? 'Belum diatur' : result);
      // TODO: simpan alamat & (kalau ada) koordinat ke Firestore/backend
    }
  }

  void _ubahRadius(double v) {
    setState(() => _radiusPencarian = v);
    // TODO: simpan preferensi radius pencarian toko/kurir terdekat
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageScaffold(
      title: 'Lokasi & Pengiriman',
      children: [
        _SwitchGroup(
          items: [
            _SwitchItemData(
              icon: Icons.my_location_outlined,
              label: 'Izin akses lokasi',
              subtitle: 'Dipakai untuk menampilkan toko/kurir terdekat',
              value: _izinLokasi,
              onChanged: _toggleIzinLokasi,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MenuGroup(
          items: [
            _MenuItemData(
              icon: Icons.location_on_outlined,
              label: 'Alamat saya',
              trailing: _alamatSaya,
              onTap: _editAlamat,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _RadiusCard(value: _radiusPencarian, onChanged: _ubahRadius),
      ],
    );
  }
}

// Kartu slider untuk atur radius pencarian toko/kurir terdekat
class _RadiusCard extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _RadiusCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.social_distance_outlined,
                  size: 18, color: kInk.withValues(alpha: 0.75)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Radius pencarian',
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${value.round()} km',
                style: GoogleFonts.manrope(
                  color: kGradientBottom,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kGradientBottom,
              inactiveTrackColor: kInk.withValues(alpha: 0.1),
              thumbColor: kGradientBottom,
              overlayColor: kGradientBottom.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Preferensi Belanja"
// ---------------------------------------------------------------------------
class _PreferensiBelanjaPage extends StatefulWidget {
  const _PreferensiBelanjaPage();

  @override
  State<_PreferensiBelanjaPage> createState() =>
      _PreferensiBelanjaPageState();
}

class _PreferensiBelanjaPageState extends State<_PreferensiBelanjaPage> {
  bool _rekomendasiRiwayat = true;
  bool _prioritaskanFavorit = true;
  final List<String> _semuaKategori = const [
    'Sayur & Buah',
    'Daging & Ikan',
    'Bahan Pokok',
    'Bengkel',
    'Jasa Rumah Tangga',
  ];
  final Set<String> _kategoriDipilih = {'Sayur & Buah', 'Bahan Pokok'};

  void _toggleRekomendasiRiwayat(bool v) {
    setState(() => _rekomendasiRiwayat = v);
    // TODO: simpan preferensi ke backend/model rekomendasi
  }

  void _togglePrioritaskanFavorit(bool v) {
    setState(() => _prioritaskanFavorit = v);
    // TODO: simpan preferensi urutan tampilan toko favorit
  }

  Future<void> _pilihKategori() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sementara = Set<String>.from(_kategoriDipilih);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kategori Favorit',
                    style: GoogleFonts.manrope(
                      color: kInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._semuaKategori.map((kategori) {
                    final selected = sementara.contains(kategori);
                    return InkWell(
                      onTap: () => setSheetState(() {
                        if (selected) {
                          sementara.remove(kategori);
                        } else {
                          sementara.add(kategori);
                        }
                      }),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                kategori,
                                style: GoogleFonts.manrope(
                                  color: kInk,
                                  fontSize: 13.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: selected
                                  ? kGradientBottom
                                  : kInk.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, sementara),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kInk,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Simpan',
                        style: GoogleFonts.manrope(
                          color: kCream,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _kategoriDipilih
          ..clear()
          ..addAll(result);
      });
      // TODO: simpan kategori favorit ke backend
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageScaffold(
      title: 'Preferensi Belanja',
      children: [
        _SwitchGroup(
          items: [
            _SwitchItemData(
              icon: Icons.history,
              label: 'Rekomendasi dari riwayat belanja',
              subtitle: 'Tampilkan produk mirip yang pernah dibeli',
              value: _rekomendasiRiwayat,
              onChanged: _toggleRekomendasiRiwayat,
            ),
            _SwitchItemData(
              icon: Icons.storefront_outlined,
              label: 'Prioritaskan toko favorit',
              subtitle: 'Tampilkan toko favorit lebih dulu di beranda',
              value: _prioritaskanFavorit,
              onChanged: _togglePrioritaskanFavorit,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MenuGroup(
          items: [
            _MenuItemData(
              icon: Icons.category_outlined,
              label: 'Kategori favorit',
              trailing: '${_kategoriDipilih.length} dipilih',
              onTap: _pilihKategori,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Data & Penyimpanan"
// ---------------------------------------------------------------------------
class _DataPenyimpananPage extends StatefulWidget {
  const _DataPenyimpananPage();

  @override
  State<_DataPenyimpananPage> createState() => _DataPenyimpananPageState();
}

class _DataPenyimpananPageState extends State<_DataPenyimpananPage> {
  bool _modeHematData = false;
  String _ukuranCache = '18,4 MB';
  bool _isClearingCache = false;

  void _toggleModeHematData(bool v) {
    setState(() => _modeHematData = v);
    // TODO: simpan preferensi & kurangi kualitas gambar saat memuat
  }

  Future<void> _hapusCache() async {
    setState(() => _isClearingCache = true);
    // TODO: panggil pembersihan cache asli (mis. DefaultCacheManager().emptyCache())
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isClearingCache = false;
      _ukuranCache = '0 MB';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cache berhasil dibersihkan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kInk,
      ),
    );
  }

  void _unduhDataSaya() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kami akan mengirim salinan data akunmu ke email terdaftar',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kInk,
      ),
    );
    // TODO: trigger job export data (mis. Cloud Function) lalu kirim ke email
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageScaffold(
      title: 'Data & Penyimpanan',
      children: [
        _SwitchGroup(
          items: [
            _SwitchItemData(
              icon: Icons.data_saver_on_outlined,
              label: 'Mode hemat data',
              subtitle: 'Kurangi kualitas gambar saat memuat',
              value: _modeHematData,
              onChanged: _toggleModeHematData,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MenuGroup(
          items: [
            _MenuItemData(
              icon: Icons.cleaning_services_outlined,
              label:
                  _isClearingCache ? 'Membersihkan cache...' : 'Bersihkan cache',
              trailing: _isClearingCache ? null : _ukuranCache,
              onTap: _isClearingCache ? null : _hapusCache,
            ),
            _MenuItemData(
              icon: Icons.download_outlined,
              label: 'Unduh data saya',
              onTap: _unduhDataSaya,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Izin Aplikasi"
//
// Izin sebenarnya dikontrol di pengaturan sistem HP, jadi switch di sini
// hanya cerminan status & pintasan ke pengaturan sistem. TODO: sambungkan
// ke package permission_handler untuk cek status asli & app_settings
// untuk buka halaman izin sistem.
// ---------------------------------------------------------------------------
class _IzinAplikasiPage extends StatefulWidget {
  const _IzinAplikasiPage();

  @override
  State<_IzinAplikasiPage> createState() => _IzinAplikasiPageState();
}

class _IzinAplikasiPageState extends State<_IzinAplikasiPage> {
  bool _izinKamera = true;
  bool _izinLokasi = true;
  bool _izinNotifikasi = true;
  bool _izinMedia = false;

  void _bukaPengaturanSistem(String namaIzin) {
    // TODO: buka halaman izin aplikasi di pengaturan sistem HP, mis. lewat
    // package app_settings -> AppSettings.openAppSettings()
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ubah izin $namaIzin lewat Pengaturan sistem HP kamu',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kInk,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageScaffold(
      title: 'Izin Aplikasi',
      children: [
        Text(
          'Status izin berikut mengikuti pengaturan sistem HP kamu. Ketuk '
          'salah satu untuk membukanya.',
          style: GoogleFonts.manrope(
            color: kInk.withValues(alpha: 0.75),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _SwitchGroup(
          items: [
            _SwitchItemData(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera',
              subtitle: 'Dipakai untuk unggah foto produk & ulasan',
              value: _izinKamera,
              onChanged: (v) {
                setState(() => _izinKamera = v);
                _bukaPengaturanSistem('Kamera');
              },
            ),
            _SwitchItemData(
              icon: Icons.my_location_outlined,
              label: 'Lokasi',
              subtitle: 'Dipakai untuk menampilkan toko terdekat',
              value: _izinLokasi,
              onChanged: (v) {
                setState(() => _izinLokasi = v);
                _bukaPengaturanSistem('Lokasi');
              },
            ),
            _SwitchItemData(
              icon: Icons.notifications_outlined,
              label: 'Notifikasi',
              subtitle: 'Izin menampilkan notifikasi ke perangkat',
              value: _izinNotifikasi,
              onChanged: (v) {
                setState(() => _izinNotifikasi = v);
                _bukaPengaturanSistem('Notifikasi');
              },
            ),
            _SwitchItemData(
              icon: Icons.photo_library_outlined,
              label: 'Galeri/Media',
              subtitle: 'Dipakai untuk memilih foto dari galeri',
              value: _izinMedia,
              onChanged: (v) {
                setState(() => _izinMedia = v);
                _bukaPengaturanSistem('Galeri/Media');
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Pengeluaran Bulanan"
// ---------------------------------------------------------------------------
class _PengeluaranBulananPage extends StatelessWidget {
  const _PengeluaranBulananPage();

  @override
  Widget build(BuildContext context) {
    // TODO: ganti angka placeholder di bawah dengan data transaksi asli
    // dari backend (mis. agregat koleksi transaksi bulan berjalan)
    return _SubPageScaffold(
      title: 'Pengeluaran Bulanan',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total bulan ini',
                style: GoogleFonts.manrope(
                  color: kInk.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp 0',
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel(text: 'Rincian per kategori'),
        const SizedBox(height: 8),
        _InfoGroup(
          items: [
            _InfoItemData(
              icon: Icons.eco_outlined,
              label: 'Sayur & Buah',
              value: 'Rp 0',
            ),
            _InfoItemData(
              icon: Icons.set_meal_outlined,
              label: 'Daging & Ikan',
              value: 'Rp 0',
            ),
            _InfoItemData(
              icon: Icons.build_outlined,
              label: 'Bengkel',
              value: 'Rp 0',
            ),
            _InfoItemData(
              icon: Icons.category_outlined,
              label: 'Lainnya',
              value: 'Rp 0',
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Metode Pembayaran"
// ---------------------------------------------------------------------------
class _MetodePembayaranPage extends StatefulWidget {
  const _MetodePembayaranPage();

  @override
  State<_MetodePembayaranPage> createState() => _MetodePembayaranPageState();
}

class _MetodePembayaranPageState extends State<_MetodePembayaranPage> {
  // TODO: ganti dengan daftar metode pembayaran asli dari backend
  final List<_MenuItemData> _metode = [];

  void _tambahMetode() {
    // TODO: navigasi ke alur tambah kartu/e-wallet (mis. lewat payment
    // gateway seperti Midtrans/Xendit)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alur tambah metode pembayaran akan segera hadir',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kInk,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageScaffold(
      title: 'Metode Pembayaran',
      children: [
        if (_metode.isNotEmpty) ...[
          _MenuGroup(items: _metode),
          const SizedBox(height: 8),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.credit_card_off_outlined,
                    size: 28, color: kInk.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text(
                  'Belum ada metode pembayaran tersimpan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: kInk.withValues(alpha: 0.6),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        InkWell(
          onTap: _tambahMetode,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 18, color: kGradientBottom),
                const SizedBox(width: 10),
                Text(
                  'Tambah Metode Pembayaran',
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}