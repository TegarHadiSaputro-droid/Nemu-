import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/quick_summary_card.dart';
import '../widgets/spending_summary_card.dart';
import '../widgets/category_tile.dart';
import '../widgets/spending_chart.dart';
import '../widgets/statistics_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/insight_card.dart';
import '../widgets/budget_progress_card.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class MonthlySpendingPage extends StatefulWidget {
  const MonthlySpendingPage({super.key});

  @override
  State<MonthlySpendingPage> createState() =>
      _MonthlySpendingPageState();
}

class _MonthlySpendingPageState
    extends State<MonthlySpendingPage> {
      final TextEditingController categoryController =
    TextEditingController();

final TextEditingController amountController =
    TextEditingController();

final TextEditingController descriptionController =
    TextEditingController();
    final List<Map<String, dynamic>> transactions = [
  {
    "title": "Shopping",
    "date": "Today • 10:15",
    "amount": "Rp120.000",
    "icon": Icons.shopping_bag_outlined,
    "color": const Color(0xFFD9DF36),
  },
  {
    "title": "Home Service",
    "date": "Yesterday • 14:30",
    "amount": "Rp250.000",
    "icon": Icons.home_repair_service_outlined,
    "color": const Color(0xFF16A34A),
  },
];

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

final text =
    LanguageData.text[language.locale.languageCode]!;                                                                                                                                       
return Scaffold(
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Add New Spending",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  decoration: InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    prefixText: "Rp ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007C3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
onPressed: () {
  setState(() {
    transactions.insert(0, {
      "title": categoryController.text,
      "date": "Today",
      "amount": "Rp${amountController.text}",
      "icon": Icons.receipt_long,
      "color": const Color(0xFF007C3F),
    });
  });

  categoryController.clear();
  amountController.clear();
  descriptionController.clear();

  Navigator.pop(context);
},
                    child: Text(
                      "Save Spending",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom,
                ),
              ],
            ),
          ),
        );
      },
    );
  },
    backgroundColor: const Color(0xFF007C3F),
    foregroundColor: Colors.white,
    icon: const Icon(Icons.add),
    label: const Text("Add Spending"),
  ),
      body: Stack(
        children: [

          // ==========================
          // BACKGROUND
          // ==========================

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFD9DF36),
                  Color(0xFF007C3F),
                ],
              ),
            ),
          ),

          // Circle 1
          Positioned(
            top: -70,
            left: -50,
            child: _circle(
              220,
              Colors.white.withOpacity(.10),
            ),
          ),

          // Circle 2
          Positioned(
            top: 60,
            right: -60,
            child: _circle(
              180,
              Colors.white.withOpacity(.08),
            ),
          ),

          // Circle 3
          Positioned(
            top: 340,
            left: -90,
            child: _circle(
              260,
              Colors.white.withOpacity(.07),
            ),
          ),

          // Circle 4
          Positioned(
            bottom: 120,
            right: -80,
            child: _circle(
              210,
              Colors.white.withOpacity(.07),
            ),
          ),

          // Circle 5
          Positioned(
            bottom: -90,
            left: -70,
            child: _circle(
              230,
              Colors.white.withOpacity(.08),
            ),
          ),

          // ==========================
          // CONTENT
          // ==========================

          SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [

InkWell(
  borderRadius: BorderRadius.circular(18),
  onTap: () {
    Navigator.pop(context);
  },
  child: Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.18),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.white.withOpacity(.25),
      ),
    ),
    child: const Icon(
      Icons.arrow_back_ios_new_rounded,
      color: Color(0xFF0F1B11),
      size: 20,
    ),
  ),
),

                      const SizedBox(width: 18),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

Text(
text["monthly_spending"]!,
  style: GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF0F1B11),
  ),
),

const SizedBox(height: 4),

Text(
text["track_spending"]!,
  style: GoogleFonts.manrope(
    fontSize: 14,
    color: const Color(0xFF0F1B11).withOpacity(.75),
  ),
),

const SizedBox(height: 12),

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(.18),
    borderRadius: BorderRadius.circular(30),
    border: Border.all(
      color: Colors.white.withOpacity(.25),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.calendar_month,
        size: 18,
        color: Color(0xFF0F1B11),
      ),
      const SizedBox(width: 8),
      Text(
        "August 2026",
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F1B11),
        ),
      ),
    ],
  ),
),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(35),
                      ),
                    ),
child: ListView(
  padding: const EdgeInsets.all(22),
  children: [

TweenAnimationBuilder<double>(
  duration: const Duration(milliseconds: 700),
  tween: Tween(begin: 0, end: 1),
  builder: (context, value, child) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: child,
      ),
    );
  },
  child: const SpendingSummaryCard(),
),

    const SizedBox(height: 24),

    const SizedBox(height: 24),

TweenAnimationBuilder<double>(
  duration: const Duration(milliseconds: 900),
  tween: Tween(begin: 0, end: 1),
  builder: (context, value, child) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 40 * (1 - value)),
        child: child,
      ),
    );
  },
  child: const BudgetProgressCard(),
),

    const SpendingChart(),


    const SizedBox(height: 28),

    Text(
      "Spending Categories",
      style: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F1B11),
      ),
    ),

    const SizedBox(height: 18),

    const CategoryTile(
      icon: Icons.shopping_bag_outlined,
      title: "Shopping",
      amount: "Rp720.000",
      progress: .56,
      color: Color(0xFFD9DF36),
    ),

    const CategoryTile(
      icon: Icons.home_repair_service_outlined,
      title: "Services",
      amount: "Rp350.000",
      progress: .27,
      color: Color(0xFF16A34A),
    ),

    const CategoryTile(
      icon: Icons.inventory_2_outlined,
      title: "Others",
      amount: "Rp205.000",
      progress: .17,
      color: Color(0xFF007C3F),
    ),

    const SizedBox(height: 28),

    Text(
      "Statistics",
      style: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F1B11),
      ),
    ),

    const SizedBox(height: 18),

    const Row(
      children: [

        StatisticsCard(
          icon: Icons.bar_chart,
          title: "Average",
          value: "Rp36K",
          color: Color(0xFFD9DF36),
        ),

        SizedBox(width: 15),

        StatisticsCard(
          icon: Icons.trending_up,
          title: "Highest",
          value: "Rp250K",
          color: Color(0xFF007C3F),
        ),

      ],
    ),

    const SizedBox(height: 15),

    const Row(
      children: [

        StatisticsCard(
          icon: Icons.star_outline,
          title: "Favorite",
          value: "Shopping",
          color: Colors.orange,
        ),

        SizedBox(width: 15),

        StatisticsCard(
          icon: Icons.receipt_long_outlined,
          title: "Transactions",
          value: "35",
          color: Colors.blue,
        ),

      ],
    ),

    const SizedBox(height: 30),

    Text(
      "Recent Transactions",
      style: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F1B11),
      ),
    ),

    const SizedBox(height: 18),

...transactions.map(
  (item) => TransactionTile(
    icon: item["icon"],
    title: item["title"],
    date: item["date"],
    amount: item["amount"],
    color: item["color"],
  ),
),

const InsightCard(),

const SizedBox(height: 24),

const QuickSummaryCard(),

const SizedBox(height: 35),

Center(
  child: Text(
    "Keep tracking your spending wisely 🌱",
    style: GoogleFonts.manrope(
      fontSize: 13,
      color: Colors.grey,
      fontWeight: FontWeight.w600,
    ),
  ),
),

const SizedBox(height: 10),

Center(
  child: Text(
    "Made with ❤ by Nemu",
    style: GoogleFonts.manrope(
      fontSize: 12,
      color: Colors.grey.shade500,
    ),
  ),
),

const SizedBox(height: 90),
  ],
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

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}