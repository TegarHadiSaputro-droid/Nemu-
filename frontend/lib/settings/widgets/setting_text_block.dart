import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/app_theme.dart';

class SettingSectionTitle extends StatelessWidget {
  final String text;
  const SettingSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: kInk,
        ),
      ),
    );
  }
}

class SettingParagraph extends StatelessWidget {
  final String text;
  const SettingParagraph(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 13.5,
          height: 1.6,
          color: kInk.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}