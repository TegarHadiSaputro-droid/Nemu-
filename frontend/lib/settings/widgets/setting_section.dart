import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingSection extends StatelessWidget {
  final String title;

  const SettingSection({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        top: 20,
        bottom: 12,
      ),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: const Color(0xFF0F1B11),
        ),
      ),
    );
  }
}