// pusat_bantuan_page.dart
//
// Halaman Pusat Bantuan — Flutter
// Gaya mengikuti account.dart & settings_page.dart:
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';

class PusatBantuanPage extends StatelessWidget {
  const PusatBantuanPage({super.key});

  static const List<_FaqData> _faqs = [
    _FaqData(
      question: 'Bagaimana cara memesan jasa di Nemu?',
      answer:
          'Pilih toko atau bengkel yang kamu inginkan, lalu tekan tombol '
          'pesan pada produk atau layanan yang tersedia. Ikuti instruksi '
          'hingga pesanan terkonfirmasi.',
    ),
    _FaqData(
      question: 'Bagaimana cara jadi penjual di Nemu?',
      answer:
          'Buka menu Kelola Toko dari halaman akun, lalu lengkapi data '
          'toko dan produk/layananmu. Setelah diverifikasi, tokomu siap '
          'menerima pesanan.',
    ),
    _FaqData(
      question: 'Metode pembayaran apa saja yang didukung?',
      answer:
          'Nemu mendukung transfer bank, e-wallet, dan pembayaran tunai '
          'langsung di tempat, tergantung pengaturan masing-masing toko.',
    ),
    _FaqData(
      question: 'Bagaimana jika pesanan bermasalah?',
      answer:
          'Hubungi penjual langsung lewat chat, atau ajukan komplain '
          'melalui menu Riwayat Transaksi jika masalah tidak terselesaikan.',
    ),
  ];

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
                  _SectionLabel(text: 'Hubungi kami'),
                  const SizedBox(height: 8),
                  _ContactRow(),
                  const SizedBox(height: 24),
                  _SectionLabel(text: 'Pertanyaan umum'),
                  const SizedBox(height: 8),
                  _FaqCard(items: _faqs),
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
          'Pusat Bantuan',
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
          color: kInk.withOpacity(0.75),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactCard(
            icon: FontAwesomeIcons.whatsapp,
            label: 'WhatsApp',
            brandColor: const Color(0xFF25D366),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactCard(
            icon: FontAwesomeIcons.solidEnvelope,
            label: 'Email',
            brandColor: const Color(0xFFEA4335),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactCard(
            icon: FontAwesomeIcons.instagram,
            label: 'Instagram',
            brandColor: const Color(0xFFC13584),
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final FaIconData icon; // <-- Diubah dari IconData ke FaIconData agar cocok dengan v11.0.0
  final String label;
  final Color brandColor;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 20, color: brandColor), // <-- Menggunakan FaIcon
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: kInk,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqData {
  final String question;
  final String answer;
  const _FaqData({required this.question, required this.answer});
}

class _FaqCard extends StatelessWidget {
  final List<_FaqData> items;
  const _FaqCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: kInk.withOpacity(0.08)),
                ),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding:
                    const EdgeInsets.fromLTRB(12, 0, 12, 14),
                iconColor: kInk,
                collapsedIconColor: kInk.withOpacity(0.5),
                title: Text(
                  item.question,
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.answer,
                      style: GoogleFonts.manrope(
                        color: kInk.withOpacity(0.65),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}