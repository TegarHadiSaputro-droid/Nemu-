import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/privacy_page.dart';
import 'pages/security_page.dart';
import 'pages/notification_page.dart';
import 'pages/appearance_page.dart';
import 'pages/language_page.dart';
import 'pages/app_preference_page.dart';
import 'pages/help_center_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/terms_page.dart';
import 'pages/about_page.dart';

import 'widgets/setting_tile.dart';
import 'widgets/setting_section.dart';
import 'pages/monthly_spending_page.dart';
import 'package:provider/provider.dart';
import '../localization/language_provider.dart';
import '../localization/language_data.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

final text =
    LanguageData.text[language.locale.languageCode]!;
    return Scaffold(
body: Stack(
  children: [

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

    Positioned(
      top: -60,
      left: -50,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.10),
        ),
      ),
    ),

    Positioned(
      top: 40,
      right: -60,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
        ),
      ),
    ),

    Positioned(
      top: 340,
      left: -80,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.07),
        ),
      ),
    ),

    Positioned(
      top: 620,
      right: -90,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    ),

    Positioned(
      bottom: -80,
      left: -80,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.07),
        ),
      ),
    ),

    SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            children: [
              Text(
                text["settings"]!,
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F1B11),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                text["manage"]!,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: const Color(0xFF0F1B11),
                ),
              ),

              const SizedBox(height: 28),

              // =============================
              // PRIVACY & SECURITY
              // =============================

              SettingSection(
                title: text["privacy_security"]!,
              ),

SettingTile(
  title: text["privacy"]!,
  icon: Icons.privacy_tip_outlined,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacyPage(),
      ),
    );
  },
),

SettingTile(
  title: text["security"]!,
  icon: Icons.security,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SecurityPage(),
      ),
    );
  },
),

              const SizedBox(height: 10),

              // =============================
              // PREFERENCES
              // =============================

              SettingSection(
              title: text["preferences"]!,
              ),

SettingTile(
title: text["notification"]!,
  icon: Icons.notifications_none,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationPage(),
      ),
    );
  },
),

SettingTile(
  title: text["appearance"]!,
  icon: Icons.palette_outlined,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppearancePage(),
      ),
    );
  },
),

SettingTile(
title: text["language"]!,
  icon: Icons.language,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LanguagePage(),
      ),
    );
  },
),

SettingTile(
  title: text["app_preference"]!,
  icon: Icons.tune,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppPreferencePage(),
      ),
    );
  },
),

              const SizedBox(height: 10),

              // =============================
              // OTHERS
              // =============================

              SettingSection(
                title: text["others"]!,
              ),

SettingTile(
  title: text["help_center"]!,
  icon: Icons.help_outline,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpCenterPage(),
      ),
    );
  },
),

SettingTile(
  title: text["privacy_policy"]!,
  icon: Icons.policy_outlined,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyPage(),
      ),
    );
  },
),

SettingTile(
  title: text["terms"]!,
  icon: Icons.description_outlined,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TermsPage(),
      ),
    );
  },
),

SettingTile(
  title: text["about"]!,
  icon: Icons.info_outline,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutPage(),
      ),
    );
  },
),

const SizedBox(height: 10),

SettingSection(
  title: text["financial"]!,
),

SettingTile(
  title: text["monthly_spending"]!,
  icon: Icons.account_balance_wallet_outlined,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MonthlySpendingPage(),
      ),
    );
  },
),

const SizedBox(height: 10),

SettingTile(
  title: text["logout"]!,
  icon: Icons.logout,
  textColor: Colors.red,
  iconColor: Colors.red,
  onTap: () {},
),
            ],
          ),
        ),
]),
    );
  }
}