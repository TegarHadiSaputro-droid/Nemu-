import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isEnglish => _locale.languageCode == 'en';

  bool get isIndonesia => _locale.languageCode == 'id';

  void changeLanguage(String code) {
    _locale = Locale(code);
    notifyListeners();
  }
}