import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const StatisticsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
          BoxShadow(
  color: color.withOpacity(.12),
  blurRadius: 18,
  spreadRadius: 1,
  offset: const Offset(0, 8),
),
          ],
        ),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child:Icon(
                  icon,
              color: color,
              size: 30,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              value,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: const Color(0xFF0F1B11),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            ),
          ],
        ),
      ),
    );
  }
}