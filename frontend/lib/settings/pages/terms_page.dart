import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart';
import '../../localization/language_data.dart';
import '../widgets/setting_detail_scaffold.dart';
import '../widgets/setting_box_card.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final text = LanguageData.text[language.locale.languageCode]!;

    return SettingDetailScaffold(
      title: text["terms_and_conditions"]!,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: SettingBoxCard(
          children: [
            // TODO: isi konten Terms and Conditions di sini
          ],
        ),
      ),
    );
  }
}