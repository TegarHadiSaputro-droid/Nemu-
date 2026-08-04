// edit_profile_page.dart
//
// Halaman Edit Profil — Flutter
// Gaya mengikuti account.dart & settings_page.dart:
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11
//
// Dependency yang dibutuhkan di pubspec.yaml:
//   dependencies:
//     flutter:
//       sdk: flutter
//     google_fonts: ^6.2.1

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/decor_background.dart';

// ---------------------------------------------------------------------------
// Halaman Edit Profil
// ---------------------------------------------------------------------------
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _teleponController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = true; // lagi ambil data dari Firestore
  bool _isSaving = false; // lagi nyimpen perubahan
  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      _namaController.text = (data?['name'] as String?) ?? '';
      _usernameController.text = (data?['username'] as String?) ?? '';
      _emailController.text =
          (data?['email'] as String?) ?? user.email ?? '';
      _teleponController.text = (data?['phone'] as String?) ?? '';
      _bioController.text = (data?['bio'] as String?) ?? '';
      _originalEmail = _emailController.text;
    } catch (e) {
      debugPrint('Gagal memuat data profil: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newEmail = _emailController.text.trim();
    final emailChanged = newEmail != _originalEmail;

    try {
      // 1) Simpan field profil ke Firestore (name, username, phone, bio).
      await _firestore.collection('users').doc(user.uid).set(
        {
          'name': _namaController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone': _teleponController.text.trim(),
          'bio': _bioController.text.trim(),
        },
        SetOptions(merge: true),
      );

      // 2) Kalau email diganti, kirim email verifikasi ke alamat baru.
      // Email login BARU berubah setelah user klik link verifikasi itu,
      // jadi field 'email' di Firestore sengaja belum ditimpa di sini
      // supaya nggak beda sama email login yang sebenarnya masih aktif.
      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(newEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profil disimpan. Link verifikasi juga sudah dikirim ke $newEmail — email login baru aktif setelah link itu di-klik.',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              backgroundColor: kGradientBottom,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profil berhasil disimpan',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              backgroundColor: kGradientBottom,
            ),
          );
        }
      }

      if (mounted) Navigator.maybePop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = e.code == 'requires-recent-login'
            ? 'Untuk ganti email, kamu perlu login ulang dulu demi keamanan akun.'
            : 'Gagal memperbarui email: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kGradientTop, kGradientBottom],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: kCream),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kGradientTop, kGradientBottom],
          ),
        ),
        child: Stack(
          children: [
            ...decorCircles(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _TopBar(),
                  const SizedBox(height: 20),
                  _AvatarEditor(name: _namaController.text),
                  const SizedBox(height: 24),
                  _FormCard(
                    children: [
                      _FormField(
                        label: 'Nama lengkap',
                        icon: Icons.person_outline,
                        controller: _namaController,
                      ),
                      _FormField(
                        label: 'Username',
                        icon: Icons.alternate_email,
                        controller: _usernameController,
                      ),
                      _FormField(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _FormField(
                        label: 'Nomor telepon',
                        icon: Icons.phone_outlined,
                        controller: _teleponController,
                        keyboardType: TextInputType.phone,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormCard(
                    children: [
                      _FormField(
                        label: 'Bio',
                        icon: Icons.info_outline,
                        controller: _bioController,
                        hint: 'Ceritakan sedikit tentang tokomu',
                        maxLines: 3,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kInk,
                        foregroundColor: kCream,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: kCream,
                              ),
                            )
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar (tombol kembali + judul halaman)
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.arrow_back, color: kInk),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Edit Profil',
          style: GoogleFonts.manrope(
            color: kInk,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar + tombol ganti foto
// ---------------------------------------------------------------------------
class _AvatarEditor extends StatelessWidget {
  final String name;
  const _AvatarEditor({required this.name});

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: kCream,
            child: Text(
              _initials,
              style: GoogleFonts.manrope(
                color: kInk,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: () {},
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kInk,
                  shape: BoxShape.circle,
                  border: Border.all(color: kCream, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 14,
                  color: kCream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu form (bungkus beberapa _FormField dalam satu card cream)
// ---------------------------------------------------------------------------
class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// Satu baris field form (label kecil + input teks)
// ---------------------------------------------------------------------------
class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isLast;

  const _FormField({
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: kInk.withOpacity(0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 4 : 0),
            child: Icon(icon, size: 18, color: kInk.withOpacity(0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    color: kInk.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
                    hintStyle: GoogleFonts.manrope(
                      color: kInk.withOpacity(0.35),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}