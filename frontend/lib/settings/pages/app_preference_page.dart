import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class AppPreferencePage extends StatefulWidget {
  const AppPreferencePage({super.key});

  @override
  State<AppPreferencePage> createState() => _AppPreferencePageState();
}

class _AppPreferencePageState extends State<AppPreferencePage> {

  bool autoLocation = true;
  bool saveRecentAddress = true;
  bool autoRefresh = true;
  bool lowDataMode = false;

String distanceUnit = "Kilometer";

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
                      text["app_preference"]!,
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

                      Text(
                        text["general"]!,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1B11),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _switchTile(
                        text["auto_detect_location"]!,
                        autoLocation,
                        (v){
                          setState(() {
                            autoLocation = v;
                          });
                        },
                      ),

                      _switchTile(
                        text["save_recent_address"]!,
                        saveRecentAddress,
                        (v){
                          setState(() {
                            saveRecentAddress = v;
                          });
                        },
                      ),

                      _switchTile(
                        text["auto_refresh"]!,
                        autoRefresh,
                        (v){
                          setState(() {
                            autoRefresh = v;
                          });
                        },
                      ),

                      _switchTile(
                        text["low_data_mode"]!,
                        lowDataMode,
                        (v){
                          setState(() {
                            lowDataMode = v;
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      Text(
                        text["distance_unit"]!,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1B11),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Card(
                        elevation: 2,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: ListTile(

                          title: Text(
                            text["distance"]!,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F1B11),
                            ),
                          ),

                          trailing: DropdownButton<String>(

                            underline: const SizedBox(),

                            value: distanceUnit,

                            items: [

                              DropdownMenuItem(
                                value: text["kilometer"]!,
                                child: Text(text["kilometer"]!),
                              ),

                              DropdownMenuItem(
                                value: text["meter"]!,
                                child: Text(text["meter"]!),
                              ),

                            ],

                            onChanged: (value){
                              setState(() {
                                distanceUnit = value!;
                              });
                            },

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

  Widget _switchTile(
      String title,
      bool value,
      ValueChanged<bool> onChanged){

    return Card(

      margin: const EdgeInsets.only(bottom: 14),

      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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