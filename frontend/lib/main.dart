import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings/setting_page.dart';
import 'localization/language_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: language.locale,
      home: const SettingPage(),
    );
  }
}