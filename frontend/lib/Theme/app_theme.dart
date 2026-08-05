// app_theme.dart
//
// Warna & style dasar yang dipakai bersama oleh AccountPage, SettingsPage,
// dan main.dart. Ditaruh di satu file supaya tidak terjadi duplikat
// deklarasi (error "defined in multiple libraries") saat lebih dari satu
// halaman di-import ke file yang sama.

import 'package:flutter/material.dart';

const Color kInk = Color(0xFF0F1B11); // teks gelap
const Color kCream = Color(0xFFF5F5DC); // elemen putih/cream
const Color kGradientTop = Color(0xFFD9DF36);
const Color kGradientBottom = Color(0xFF007C3F);

