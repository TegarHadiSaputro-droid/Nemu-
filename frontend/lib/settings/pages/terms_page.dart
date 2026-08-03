import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

final text =
    LanguageData.text[language.locale.languageCode]!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0F1B11),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      text["terms_and_conditions"]!,
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F1B11),
                      ),
                    ),
                  ],
                ),
              ),

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
                    padding: const EdgeInsets.all(24),
                    children: [

  _title(text["acceptance"]!),

  _paragraph(
    text["acceptance_details"]!,
  ),

  _title(text["user_responsibilities"]!),

  _paragraph(
    text["user_responsibilities_details"]!,
  ),

  _title(text["transactions"]!),

  _paragraph(
    text["transactions_details"]!,
  ),

  _title(text["prohibited_activities"]!),

  _paragraph(
    text["prohibited_activities_details"]!,
  ),

  _title(text["changes"]!),

  _paragraph(
    text["changes_details"]!,
  ),

  _title(text["contact"]!),

  _paragraph(
    text["contact_details"]!,
  ),

],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F1B11),
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 15,
        height: 1.7,
        color: const Color(0xFF0F1B11),
      ),
    );
  }
}