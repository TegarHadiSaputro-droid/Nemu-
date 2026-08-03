import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {

  bool darkMode = false;
  bool dynamicColor = true;
  bool animation = true;
  bool compactMode = false;

  String fontSize = "Medium";

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
                      text["appearance"]!,
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
                        text["display"]!,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1B11),
                        ),
                      ),

                      const SizedBox(height: 18),

                      _switchTile(
                        text["dark_mode"]!,
                        darkMode,
                        (v){
                          setState(() {
                            darkMode = v;
                          });
                        },
                      ),

                      _switchTile(
                        text["dynamic_color"]!,
                        dynamicColor,
                        (v){
                          setState(() {
                            dynamicColor = v;
                          });
                        },
                      ),

                      _switchTile(
                        text["animation"]!,
                        animation,
                        (v){
                          setState(() {
                            animation = v;
                          });
                        },
                      ),

                      _switchTile(
                        text["compact_mode"]!,
                        compactMode,
                        (v){
                          setState(() {
                            compactMode = v;
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      Text(
                        text["font_size"]!,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
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
                            text["font_size"]!,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F1B11),
                            ),
                          ),

                          trailing: DropdownButton<String>(
                            value: fontSize,
                            underline: const SizedBox(),

                            items: const [
                              DropdownMenuItem(
                                value: "Small",
                                child: Text("Small"),
                              ),

                              DropdownMenuItem(
                                value: "Medium",
                                child: Text("Medium"),
                              ),

                              DropdownMenuItem(
                                value: "Large",
                                child: Text("Large"),
                              ),
                            ],

                            onChanged: (value){
                              setState(() {
                                fontSize = value!;
                              });
                            },
                          ),
                        ),
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

  Widget _switchTile(
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      ){

    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 14),

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