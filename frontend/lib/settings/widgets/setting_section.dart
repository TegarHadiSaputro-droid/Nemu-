import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/app_theme.dart';

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
        top: 18,
        bottom: 10,
        left: 4,
      ),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          color: kInk.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}