import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0F1B11),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      text["help_center"]!,
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
                    padding: const EdgeInsets.all(20),
                    children: [

                      _menuTile(
                        Icons.question_answer_outlined,
                        text["frequently_asked_questions"]!,
                      ),

                      _menuTile(
                        Icons.support_agent,
                        text["contact_customer_service"]!,
                      ),

                      _menuTile(
                        Icons.chat_bubble_outline,
                        text["live_chat"]!,
                      ),

                      _menuTile(
                        Icons.bug_report_outlined,
                        text["report_a_bug"]!,
                      ),

                      _menuTile(
                        Icons.feedback_outlined,
                        text["send_feedback"]!,
                      ),

                      _menuTile(
                        Icons.email_outlined,
                        text["contact_via_email"]!,
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

  Widget _menuTile(
      IconData icon,
      String title,
      ) {

    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0,5),
          ),
        ],
      ),

      child: ListTile(

        leading: Icon(
          icon,
          color: const Color(0xFF0F1B11),
        ),

        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F1B11),
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: () {},

      ),
    );
  }
}