// edit_profile_page.dart
//
// Halaman Edit Profil — Flutter
// Gaya mengikuti account.dart & settings_page.dart:
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11
//
// Fungsi ganti foto profil (pilih dari galeri + upload ke Firebase Storage)
// ada di sini — dipindah dari account.dart karena tombol kamera di halaman
// akun sudah dihapus (sudah ada tanda panah yang menuju kesini).
//
// Dependency yang dibutuhkan di pubspec.yaml:
//   dependencies:
//     flutter:
//       sdk: flutter
//     google_fonts: ^6.2.1
//     image_picker: ^1.1.2
//     firebase_auth: ^5.x.x
//     cloud_firestore: ^5.x.x
//     firebase_storage: ^12.x.x

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // State untuk avatar (dipindah dari account.dart)
  Uint8List? _localPreviewBytes; // preview lokal segera setelah dipilih
  String? _photoUrl; // URL foto dari Firestore
  bool _uploading = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _namaController.text = (data?['name'] as String?) ?? '';
          _usernameController.text = (data?['username'] as String?) ?? '';
          _emailController.text =
              (data?['email'] as String?) ?? _auth.currentUser?.email ?? '';
          _teleponController.text = (data?['phone'] as String?) ?? '';
          _bioController.text = (data?['bio'] as String?) ?? '';
          _photoUrl = data?['photoUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat data profil: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------------------------------------------------------------------
  // Pilih foto dari galeri lalu upload ke Firebase Storage, terus
  // simpan URL-nya ke Firestore. Dipindah dari _pickAndUploadImage yang
  // sebelumnya ada di account.dart.
  // -------------------------------------------------------------------
  Future<void> _pickAndUploadImage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamu belum login.')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    // readAsBytes() aman dipakai di web maupun mobile, beda dengan dart:io
    // File yang cuma bisa dipakai di mobile/desktop.
    final bytes = await picked.readAsBytes();
    setState(() {
      _localPreviewBytes = bytes; // tampil langsung tanpa nunggu upload
      _uploading = true;
    });

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$uid.jpg');

      await ref.putData(
        bytes,
        SettableMetadata(contentType: picked.mimeType ?? 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).set(
        {'photoUrl': downloadUrl},
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah foto: $e')),
        );
      }
    }
  }

  ImageProvider? get _avatarImage {
    if (_localPreviewBytes != null) return MemoryImage(_localPreviewBytes!);
    if (_photoUrl != null) return NetworkImage(_photoUrl!);
    return null;
  }

  // Inisial avatar diambil otomatis dari nama yang ter-load, bukan hardcode.
  String get _avatarInitials {
    final name = _namaController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamu belum login.')),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'name': _namaController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _teleponController.text.trim(),
          'bio': _bioController.text.trim(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil berhasil disimpan',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: kGradientBottom,
        ),
      );
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    }
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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kInk),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        _TopBar(),
                        const SizedBox(height: 20),
                        _AvatarEditor(
                          avatarImage: _avatarImage,
                          initials: _avatarInitials,
                          uploading: _uploading,
                          onTapCamera: _pickAndUploadImage,
                        ),
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
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kInk,
                              foregroundColor: kCream,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
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
// Avatar + tombol ganti foto (sekarang beneran nyambung ke image_picker +
// Firebase Storage, dipindah dari account.dart). Inisial memakai nama asli
// dari data yang sudah di-load, bukan hardcode "NP".
// ---------------------------------------------------------------------------
class _AvatarEditor extends StatelessWidget {
  final ImageProvider? avatarImage;
  final String initials;
  final bool uploading;
  final VoidCallback onTapCamera;

  const _AvatarEditor({
    required this.avatarImage,
    required this.initials,
    required this.uploading,
    required this.onTapCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: kCream,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? Text(
                    initials,
                    style: GoogleFonts.manrope(
                      color: kInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: uploading ? null : onTapCamera,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kInk,
                  shape: BoxShape.circle,
                  border: Border.all(color: kCream, width: 2),
                ),
                child: uploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: kCream,
                        ),
                      )
                    : const Icon(
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