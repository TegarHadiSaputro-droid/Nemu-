import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Weekly Spending",
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F1B11),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "Last 4 Weeks",
          style: GoogleFonts.manrope(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),

      ],
    ),

    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD9DF36).withValues(alpha: .18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "Monthly",
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF007C3F),
        ),
      ),
    ),

  ],
),

          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 800000,

                borderData: FlBorderData(show: false),

gridData: FlGridData(
  show: true,
  horizontalInterval: 100000,
  drawVerticalLine: false,
),

                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      reservedSize: 45,
                      showTitles: true,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {

                        switch (value.toInt()) {
                          case 0:
                            return const Text("W1");
                          case 1:
                            return const Text("W2");
                          case 2:
                            return const Text("W3");
                          case 3:
                            return const Text("W4");
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                ),

                barGroups: [

                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 600000,
                        color: const Color(0xFFD9DF36),
                        width: 30,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ],
                  ),

                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 450000,
                        color: const Color(0xFF72D95A),
                        width: 30,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ],
                  ),

                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 720000,
                        color: const Color(0xFF2BA84A),
                        width: 30,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ],
                  ),

                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 520000,
                        color: const Color(0xFF007C3F),
                        width: 30,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}