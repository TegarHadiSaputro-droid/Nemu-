import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/app_theme.dart';

/// Box bahasa terpisah, gaya sama seperti CategoryTile di Monthly Spending —
/// icon kotak berwarna + judul + subtitle + switch, masing-masing pilihan
/// punya box sendiri (bukan digabung dengan divider).
class LanguageOptionCard extends StatelessWidget {
  final String flagEmoji;
  final String title;
  final String subtitle;
  final bool selected;
  final Color iconBackground;
  final VoidCallback onTap;

  const LanguageOptionCard({
    super.key,
    required this.flagEmoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(flagEmoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      color: kInk.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: selected,
              activeThumbColor: kGradientBottom,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}