// seller_langganan_screen.dart
//
// Halaman "Langganan Nemu+" untuk seller (baik kategori Pasar maupun
// Jasa — lihat daftar_usaha_form_page.dart).
//
// Sebelumnya halaman ini cuma badge "COMING SOON" tanpa data apa pun.
// Sekarang ditampilkan status langganan yang sebenarnya, dibaca dari
// field 'nemuPlusAktifSampai' di dokumen Firestore seller/{uid} — field
// itu diisi pertama kali saat submit di daftar_usaha_form_page.dart
// (trial gratis 30 hari dari tanggal pendaftaran).
//
// Setelah trial habis, langganan Nemu+ ditagih Rp599.000/TAHUN (bukan
// bulanan). Alur pembayaran online belum dibikin — tombol "Perpanjang
// Langganan" saat ini melakukan perpanjangan manual: begitu ditekan &
// dikonfirmasi user, field 'nemuPlusAktifSampai' langsung ditambah 365
// hari dari tanggal sekarang (atau dari tanggal aktif saat ini kalau
// masih aktif, supaya sisa masa aktif tidak hilang). Halaman otomatis
// ikut ke-refresh karena pakai snapshots(), bukan get() sekali doang.
//
// TODO: begitu payment gateway online siap, ganti _perpanjangLangganan()
// supaya update field ini terjadi setelah callback pembayaran sukses,
// bukan langsung saat tombol ditekan.

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const Color _lanGreen   = Color(0xFF007C3F);
const Color _lanYellow  = Color(0xFFD9DF36);
const Color _lanDark    = Color(0xFF0F1B11);
const Color _lanAmber   = Color(0xFFF59E0B);
const Color _lanRed     = Color(0xFFEF4444);

TextStyle _ls({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _lanDark,
  double? height,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

// Status turunan dari selisih antara sekarang dan 'nemuPlusAktifSampai'.
enum _LanggananStatus { trial, aktif, akanHabis, kadaluarsa }

class SellerLanggananScreen extends StatefulWidget {
  const SellerLanggananScreen({super.key});

  @override
  State<SellerLanggananScreen> createState() => _SellerLanggananScreenState();
}

class _SellerLanggananScreenState extends State<SellerLanggananScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  bool _isProcessingPerpanjangan = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Center(
        child: Text(
          'Kamu perlu login sebagai penjual untuk melihat status langganan.',
          textAlign: TextAlign.center,
          style: _ls(size: 13, color: Colors.white70),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('seller')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _lanYellow),
            );
          }

          final data = snapshot.data?.data();
          final aktifSampaiTimestamp =
              data?['nemuPlusAktifSampai'] as Timestamp?;
          final aktifSampai = aktifSampaiTimestamp?.toDate();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconHeader(aktifSampai),
                const SizedBox(height: 24),

                Text(
                  'Langganan Nemu+',
                  style: _ls(size: 24, weight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Optimalkan Penjualan dan Jangkau Lebih Banyak Pembeli!',
                  style: _ls(size: 14, weight: FontWeight.w600, color: _lanYellow),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                _buildStatusCard(aktifSampai),

                const SizedBox(height: 20),

                _buildFeatureCard(),

                const SizedBox(height: 24),

                _buildActionButton(uid, aktifSampai),

                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  _buildDebugResetButton(uid),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── DEBUG ONLY: reset 'nemuPlusAktifSampai' jadi null supaya bisa
  // lihat lagi tampilan status "belum ada langganan" / "kadaluarsa"
  // tanpa perlu nunggu tanggal beneran lewat. Tombol ini hanya muncul
  // di debug build (kDebugMode), tidak akan tampil di release/production.
  Widget _buildDebugResetButton(String uid) {
    return TextButton.icon(
      onPressed: () async {
        final konfirmasi = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: _lanDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              '[DEBUG] Reset Langganan',
              style: _ls(size: 16, weight: FontWeight.bold, color: Colors.white),
            ),
            content: Text(
              'Field nemuPlusAktifSampai akan dihapus supaya status kembali ke "belum ada langganan". Ini cuma untuk testing tampilan.',
              style: _ls(size: 13, color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Batal', style: _ls(size: 13, color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'Reset',
                  style: _ls(size: 13, weight: FontWeight.bold, color: _lanRed),
                ),
              ),
            ],
          ),
        );

        if (konfirmasi != true) return;

        await FirebaseFirestore.instance.collection('seller').doc(uid).update({
          'nemuPlusAktifSampai': FieldValue.delete(),
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '[DEBUG] Langganan direset.',
              style: _ls(size: 12, color: Colors.white),
            ),
            backgroundColor: _lanRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      icon: Icon(Icons.bug_report_outlined, size: 16, color: Colors.white38),
      label: Text(
        '[DEBUG] Reset Status Langganan',
        style: _ls(size: 11, color: Colors.white38, weight: FontWeight.w600),
      ),
    );
  }

  // ── Status langganan dihitung dari sisa hari ──
  _LanggananStatus _resolveStatus(DateTime? aktifSampai) {
    if (aktifSampai == null) return _LanggananStatus.kadaluarsa;
    final sisaHari = aktifSampai.difference(DateTime.now()).inHours / 24;
    if (sisaHari <= 0) return _LanggananStatus.kadaluarsa;
    if (sisaHari <= 7) return _LanggananStatus.akanHabis;
    return _LanggananStatus.aktif;
  }

  Widget _buildIconHeader(DateTime? aktifSampai) {
    final status = _resolveStatus(aktifSampai);
    final isBermasalah = status == _LanggananStatus.kadaluarsa ||
        status == _LanggananStatus.akanHabis;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isBermasalah
              ? [_lanAmber, _lanAmber.withOpacity(0.7)]
              : [_lanGreen, _lanGreen.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBermasalah ? _lanAmber : _lanGreen).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isBermasalah
              ? Icons.warning_amber_rounded
              : Icons.workspace_premium_rounded,
          color: _lanYellow,
          size: 54,
        ),
      ),
    );
  }

  // ── Kartu status: tanggal aktif sampai kapan + sisa hari ──
  Widget _buildStatusCard(DateTime? aktifSampai) {
    final status = _resolveStatus(aktifSampai);
    final formattedDate = aktifSampai != null
        ? DateFormat('d MMMM yyyy', 'id_ID').format(aktifSampai)
        : '-';
    final sisaHari = aktifSampai != null
        ? aktifSampai.difference(DateTime.now()).inDays
        : 0;

    late final String badgeText;
    late final Color badgeColor;
    late final String descText;

    switch (status) {
      case _LanggananStatus.aktif:
        badgeText = 'AKTIF';
        badgeColor = _lanGreen;
        descText = 'Langganan kamu aktif sampai $formattedDate '
            '(±$sisaHari hari lagi).';
        break;
      case _LanggananStatus.akanHabis:
        badgeText = 'SEGERA HABIS';
        badgeColor = _lanAmber;
        descText = 'Langganan kamu akan habis pada $formattedDate '
            '(tinggal $sisaHari hari lagi). Perpanjang supaya akun tetap aktif.';
        break;
      case _LanggananStatus.kadaluarsa:
        badgeText = 'KADALUARSA';
        badgeColor = _lanRed;
        descText = aktifSampai != null
            ? 'Langganan kamu berakhir pada $formattedDate. Perpanjang sekarang supaya akun kamu aktif kembali.'
            : 'Belum ada data langganan aktif untuk akun ini.';
        break;
      case _LanggananStatus.trial:
        badgeText = 'TRIAL GRATIS';
        badgeColor = _lanAmber;
        descText = 'Masa trial gratis kamu berlaku sampai $formattedDate.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                ),
                child: Text(
                  badgeText,
                  style: _ls(size: 11, weight: FontWeight.bold, color: badgeColor),
                ),
              ),
              const Spacer(),
              Text(
                'Rp599.000/tahun',
                style: _ls(size: 12, weight: FontWeight.w600, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.event_available_rounded, color: _lanYellow, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  descText,
                  style: _ls(size: 12.5, color: Colors.white.withOpacity(0.9), height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            'Selama langganan aktif, kamu tetap terdaftar sebagai mitra Nemu+ dengan:',
            style: _ls(size: 13, color: Colors.white.withOpacity(0.9), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.verified_rounded,
            'Badge Mitra Terverifikasi',
            'Profil toko kamu ditandai sebagai mitra resmi Nemu+ yang sudah lolos verifikasi.',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.storefront_rounded,
            'Akses Penuh Kelola Toko',
            'Buka/tutup toko real-time, kelola produk atau jasa, dan atur profil usaha kamu.',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.search_rounded,
            'Tampil di Pencarian Nemu',
            'Toko kamu aktif ditemukan pembeli di halaman pencarian dan kategori usaha.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _lanYellow, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _ls(size: 13, weight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: _ls(size: 11, color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Perpanjangan manual: belum ada payment gateway, jadi begitu user
  // menekan tombol & mengonfirmasi, field 'nemuPlusAktifSampai' di
  // seller/{uid} langsung ditambah 365 hari.
  // Kalau langganan masih aktif, +365 hari dihitung dari tanggal aktif
  // yang sekarang (bukan dari hari ini) supaya sisa masa aktif tidak
  // hilang. Kalau sudah kadaluarsa/kosong, dihitung dari hari ini.
  //
  // TODO: ganti jadi dipanggil setelah callback pembayaran sukses,
  // begitu payment gateway online siap.
  Future<void> _perpanjangLangganan(
    BuildContext context,
    String uid,
    DateTime? aktifSampai,
  ) async {
    final status = _resolveStatus(aktifSampai);
    final sudahAktif = status == _LanggananStatus.aktif;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _lanDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Perpanjang Langganan Nemu+',
          style: _ls(size: 16, weight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          sudahAktif
              ? 'Langganan kamu akan diperpanjang 1 tahun (Rp599.000) dari tanggal aktif sekarang. Lanjutkan?'
              : 'Langganan kamu akan diaktifkan kembali untuk 1 tahun (Rp599.000) mulai hari ini. Lanjutkan?',
          style: _ls(size: 13, color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Batal', style: _ls(size: 13, color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Ya, Perpanjang',
              style: _ls(size: 13, weight: FontWeight.bold, color: _lanYellow),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _isProcessingPerpanjangan = true);

    try {
      final basisTanggal = sudahAktif ? aktifSampai! : DateTime.now();
      final tanggalBaru = basisTanggal.add(const Duration(days: 365));

      await FirebaseFirestore.instance.collection('seller').doc(uid).update({
        'nemuPlusAktifSampai': Timestamp.fromDate(tanggalBaru),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Langganan berhasil diperpanjang sampai '
            '${DateFormat('d MMMM yyyy', 'id_ID').format(tanggalBaru)}.',
            style: _ls(size: 12, color: Colors.white),
          ),
          backgroundColor: _lanGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperpanjang langganan. Coba lagi.',
            style: _ls(size: 12, color: Colors.white),
          ),
          backgroundColor: _lanRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (context.mounted) {
        setState(() => _isProcessingPerpanjangan = false);
      }
    }
  }

  Widget _buildActionButton(String uid, DateTime? aktifSampai) {
    final status = _resolveStatus(aktifSampai);
    final perluPerpanjang = status == _LanggananStatus.akanHabis ||
        status == _LanggananStatus.kadaluarsa;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lanYellow,
        foregroundColor: _lanDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        elevation: 0,
      ),
      onPressed: _isProcessingPerpanjangan
          ? null
          : () => _perpanjangLangganan(context, uid, aktifSampai),
      child: _isProcessingPerpanjangan
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _lanDark,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  perluPerpanjang
                      ? Icons.refresh_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  perluPerpanjang ? 'Perpanjang Langganan' : 'Perpanjang Lebih Awal',
                  style: _ls(size: 13, weight: FontWeight.bold, color: _lanDark),
                ),
              ],
            ),
    );
  }
}