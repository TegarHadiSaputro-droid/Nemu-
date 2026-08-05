import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/app_theme.dart';

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  final Color? iconColor;
  final Color? textColor;
  final bool isLast;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDanger = textColor == Colors.red;

    return InkWell(
      onTap: onTap,
      child: Container(
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
            Icon(
              icon,
              size: 18,
              color: iconColor ?? kInk.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  color: textColor ?? kInk,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isDanger)
              Icon(
                Icons.chevron_right,
                size: 16,
                color: kInk.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}