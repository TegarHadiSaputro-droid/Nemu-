import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickSummaryCard extends StatelessWidget {
  const QuickSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Quick Summary",
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F1B11),
            ),
          ),

          const SizedBox(height: 18),

          _item(
            Icons.calendar_today_outlined,
            "This Month",
            "Rp2.450.000",
          ),

          const Divider(height: 28),

          _item(
            Icons.trending_up,
            "Highest Spending",
            "Shopping",
          ),

          const Divider(height: 28),

          _item(
            Icons.receipt_long_outlined,
            "Transactions",
            "35",
          ),

          const Divider(height: 28),

          _item(
            Icons.savings_outlined,
            "Estimated Remaining Budget",
            "Rp550.000",
          ),
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [

        Icon(
          icon,
          color: const Color(0xFF007C3F),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15,
            ),
          ),
        ),

        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F1B11),
          ),
        ),
      ],
    );
  }
}