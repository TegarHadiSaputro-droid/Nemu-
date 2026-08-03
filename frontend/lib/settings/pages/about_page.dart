import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0F1B11),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      text["about"]!,
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

                      const SizedBox(height: 10),

                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF007C3F),
                        child: const Icon(
                          Icons.storefront,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          text["app_name"]!,
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F1B11),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          text["app_description"]!,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      _infoTile(
                        Icons.verified,
                        text["version"]!,
                        "1.0.0",
                      ),

                      _infoTile(
                        Icons.person,
                        text["developer"]!,
                        "Nemu Team",
                      ),

                      _infoTile(
                        Icons.language,
                        text["website"]!,
                        "www.nemu.com",
                      ),

                      _infoTile(
                        Icons.email_outlined,
                        text["email"]!,
                        "support@nemu.com",
                      ),

                      _infoTile(
                        Icons.copyright,
                        text["copyright"]!,
                        "© 2025 Nemu",
                      ),

                      const SizedBox(height: 25),

                      Center(
                        child: Text(
                          text["made_with_flutter"]!,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F1B11),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 15),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF007C3F),
        ),

        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F1B11),
          ),
        ),

        subtitle: Text(
          value,
          style: GoogleFonts.manrope(),
        ),
      ),
    );
  }
}