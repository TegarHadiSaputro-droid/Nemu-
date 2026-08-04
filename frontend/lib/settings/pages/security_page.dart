import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool fingerprint = true;
  bool faceId = false;
  bool twoFactor = true;

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
              //==========================
              // HEADER
              //==========================

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
                      text["security"]!,
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

                      //==================
                      // SWITCH
                      //==================

                      _switchTile(
                        text["fingerprint_login"]!,
                        fingerprint,
                        (value){
                          setState(() {
                            fingerprint = value;
                          });
                        },
                      ),

                      _switchTile(
                        text["face_id"]!,
                        faceId,
                        (value){
                          setState(() {
                            faceId = value;
                          });
                        },
                      ),

                      _switchTile(
                        text["two_factor_authentication"]!,
                        twoFactor,
                        (value){
                          setState(() {
                            twoFactor = value;
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      Text(
                        text["account_security"]!,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1B11),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _menuTile(
                        Icons.lock_reset,
                        text["change_password"]!,
                      ),

                      _menuTile(
                        Icons.password,
                        text["change_pin"]!,
                      ),

                      _menuTile(
                        Icons.devices,
                        text["connected_devices"]!,
                      ),

                      _menuTile(
                        Icons.history,
                        text["login_history"]!,
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
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: SwitchListTile(
        value: value,
        activeThumbColor: const Color(0xFF007C3F),

        onChanged: onChanged,

        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F1B11),
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
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
          Icons.chevron_right_rounded,
        ),

        onTap: () {},
      ),
    );
  }
}