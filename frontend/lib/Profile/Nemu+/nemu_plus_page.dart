// nemu_plus_page.dart
//
// Halaman Nemu+ — Penjelasan syarat pendaftaran usaha (Pasar atau Jasa).
// Berisi rincian data yang dibutuhkan, alur verifikasi, lalu tombol untuk
// lanjut ke form pendaftaran (DaftarUsahaFormPage).
//
// Info soal biaya langganan (gratis 1 bulan pertama, lalu Rp599.000/bulan)
// SUDAH tidak ditampilkan di sini — cukup ditampilkan sekali di halaman
// form pendaftaran (daftar_usaha_form_page.dart) supaya tidak diulang.
//
// VERSI DISEDERHANAKAN UNTUK TAHAP DEVELOPMENT — disesuaikan dengan
// daftar_usaha_form_page.dart yang sekarang minta kategori usaha (Pasar
// atau Jasa) plus data dasar: Nama lengkap, data lokasi/jasa sesuai
// kategori, dan Nomor rekening. Bagian dokumen wajib/opsional versi
// lengkap (NIK, foto KTP, SPSTB, dst) dihapus dulu sampai tahap
// verifikasi beneran mulai dikerjakan.
//
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/decor_background.dart';
import 'daftar_usaha_form_page.dart';

class NemuPlusPage extends StatelessWidget {
  const NemuPlusPage({super.key});

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
                  _TopBar(title: 'Nemu+'),
                  const SizedBox(height: 20),
                  _HeroBadge(),
                  const SizedBox(height: 24),

                  _SectionHeading('Data yang dibutuhkan'),
                  const SizedBox(height: 10),
                  _RequirementCard(
                    items: const [
                      'Kategori usaha (Pasar atau Jasa)',
                      'Nama lengkap',
                      'Data lokasi/jasa sesuai kategori yang dipilih',
                      'Nomor rekening',
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SectionHeading('Alur verifikasi'),
                  const SizedBox(height: 10),
                  _VerificationFlowCard(),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DaftarUsahaFormPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kInk,
                        foregroundColor: kCream,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Lanjutkan ke Pendaftaran',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu akan diminta memilih kategori usaha (Pasar atau Jasa) lalu mengisi data sesuai daftar di atas pada langkah berikutnya.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: kInk.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
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
  final String title;
  const _TopBar({required this.title});

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
          title,
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

class _HeroBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, size: 40, color: kGradientBottom),
          const SizedBox(height: 8),
          Text(
            'Nemu+ untuk Pemilik Usaha',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: kInk,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sebelum mendaftar, siapkan dulu data berikut supaya proses pendaftaran usaha kamu lebih cepat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: kInk.withValues(alpha: 0.65),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: kInk,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final List<String> items;
  final String? note;
  const _RequirementCard({required this.items, this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ...List.generate(items.length, (index) {
            final isLastItem = index == items.length - 1;
            final isLast = isLastItem && note == null;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
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
                    Icons.check_circle_outline,
                    size: 16,
                    color: kGradientBottom,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[index],
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                note!,
                style: GoogleFonts.manrope(
                  color: kInk.withValues(alpha: 0.65),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerificationFlowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _FlowStep(
        title: 'Draft',
        subtitle: 'Form pendaftaran diisi',
        icon: Icons.edit_note,
      ),
      _FlowStep(
        title: 'Menunggu Verifikasi',
        subtitle: 'Data usaha diperiksa oleh admin',
        icon: Icons.hourglass_top,
      ),
      _FlowStep(
        title: 'Aktif',
        subtitle: 'Akun tampil dan siap bermitra di aplikasi',
        icon: Icons.check_circle,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: kGradientBottom,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(step.icon, size: 16, color: kCream),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: kInk.withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.manrope(
                            color: kInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          style: GoogleFonts.manrope(
                            color: kInk.withValues(alpha: 0.6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

class _FlowStep {
  final String title;
  final String subtitle;
  final IconData icon;
  _FlowStep({required this.title, required this.subtitle, required this.icon});
}