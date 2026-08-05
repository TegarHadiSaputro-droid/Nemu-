import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';
import '../widgets/setting_detail_scaffold.dart';
import '../widgets/language_option_card.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final text = LanguageData.text[language.locale.languageCode]!;

    return SettingDetailScaffold(
      title: text["language"]!,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            LanguageOptionCard(
              flagEmoji: '🇮🇩',
              title: text["bahasa_indonesia"]!,
              subtitle: text["use_bahasa_indonesia"]!,
              selected: language.isIndonesia,
              iconBackground: const Color(0xFFD9DF36),
              onTap: () {
                Provider.of<LanguageProvider>(context, listen: false)
                    .changeLanguage('id');
              },
            ),
            LanguageOptionCard(
              flagEmoji: '🇬🇧',
              title: text["english"]!,
              subtitle: text["use_english_language"]!,
              selected: language.isEnglish,
              iconBackground: const Color(0xFFCDEEDB),
              onTap: () {
                Provider.of<LanguageProvider>(context, listen: false)
                    .changeLanguage('en');
              },
            ),
          ],
        ),
      ),
    );
  }
}