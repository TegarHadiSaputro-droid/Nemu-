import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {

  bool onlineStatus = true;
  bool locationAccess = true;
  bool searchHistory = true;
  bool personalizedAds = false;

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

              //======================
              // APP BAR
              //======================

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
                      text["privacy"]!,
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

                      _switchTile(
                        text["show_online_status"]!,
                        onlineStatus,
                        (value){
                          setState(() {
                            onlineStatus = value;
                          });
                        },
                      ),

                      _switchTile(
                        text["location_access"]!,
                        locationAccess,
                        (value){
                          setState(() {
                            locationAccess = value;
                          });
                        },
                      ),

                      _switchTile(
                        text["save_search_history"]!,
                        searchHistory,
                        (value){
                          setState(() {
                            searchHistory = value;
                          });
                        },
                      ),

                      _switchTile(
                        text["personalized_ads"]!,
                        personalizedAds,
                        (value){
                          setState(() {
                            personalizedAds = value;
                          });
                        },
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

  Widget _switchTile(
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      ){

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

      child: SwitchListTile(

        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F1B11),
          ),
        ),

        value: value,

        activeThumbColor: const Color(0xFF007C3F),

        onChanged: onChanged,

      ),
    );
  }

}