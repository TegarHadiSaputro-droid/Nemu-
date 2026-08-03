import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD9DF36),
            Color(0xFF9FD84D),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF0F1B11),
              size: 30,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Smart Insight",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F1B11),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Shopping menjadi kategori terbesar bulan ini dengan total Rp720.000. Pengeluaran meningkat 12% dibanding bulan lalu. Kurangi belanja impulsif agar anggaran tetap sehat.",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    height: 1.6,
                    color: const Color(0xFF0F1B11),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "💡 Save around Rp150K next month",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F1B11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}