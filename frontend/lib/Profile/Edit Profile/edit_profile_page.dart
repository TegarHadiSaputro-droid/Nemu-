// edit_profile_page.dart
//
// Halaman Edit Profil — Flutter
// Gaya mengikuti account.dart & settings_page.dart:
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11
//
// CATATAN PERUBAHAN:
// - Fungsi ganti foto profil (image_picker + upload ke Firebase Storage)
//   sudah DIHAPUS dari halaman ini sesuai permintaan. Foto profil yang
//   tersimpan di Firestore tetap ditampilkan (read-only), tapi tidak ada
//   lagi tombol kamera / cara mengganti foto dari halaman ini.
// - Field "Username" dibaca & disimpan ke field Firestore 'nickname' —
//   field yang sama dengan yang dipakai di home_screen.dart (dialog
//   "Nama panggilan Anda?"), supaya nama panggilan di Beranda (mis.
//   "repan") selalu sinkron dengan yang ada di Edit Profil.
// - DITAMBAHKAN: mode Edit. Semua field awalnya read-only. Ada tombol
//   "Edit Profil" di top bar untuk mengaktifkan pengeditan. Setelah user
//   menekan "Simpan Perubahan", seluruh perubahan disimpan ke Firestore
//   sekaligus dan field kembali dikunci (read-only).
//
// Dependency yang dibutuhkan di pubspec.yaml:
//   dependencies:
//     flutter:
//       sdk: flutter
//     google_fonts: ^6.2.1
//     firebase_auth: ^5.x.x
//     cloud_firestore: ^5.x.x

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

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _usernameController = TextEditingController(); // = "nickname" di Firestore
  final _emailController = TextEditingController();
  final _teleponController = TextEditingController();
  final _bioController = TextEditingController();

  // Nilai lama disimpan untuk fitur "Batal" (membatalkan perubahan yang
  // belum disimpan dan mengembalikan field ke isi terakhir yang tersimpan).
  String _namaLama = '';
  String _usernameLama = '';
  String _emailLama = '';
  String _teleponLama = '';
  String _bioLama = '';

  // Foto profil ditampilkan saja (read-only) — tidak ada fungsi ganti foto
  // di halaman ini lagi.
  String? _photoUrl;
  bool _loading = true;
  bool _saving = false;

  // Menentukan apakah field form sedang bisa diedit atau tidak.
  // Awalnya false (read-only) — user harus menekan tombol "Edit Profil".
  bool _isEditing = false;

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
          // Dibaca dari field 'nickname' — sama dengan yang diisi lewat
          // dialog "Nama panggilan Anda?" di HomeScreen.
          _usernameController.text = (data?['nickname'] as String?) ?? '';
          _emailController.text =
              (data?['email'] as String?) ?? _auth.currentUser?.email ?? '';
          _teleponController.text = (data?['phone'] as String?) ?? '';
          _bioController.text = (data?['bio'] as String?) ?? '';
          _photoUrl = data?['photoUrl'] as String?;

          _simpanNilaiLama();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat data profil: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _simpanNilaiLama() {
    _namaLama = _namaController.text;
    _usernameLama = _usernameController.text;
    _emailLama = _emailController.text;
    _teleponLama = _teleponController.text;
    _bioLama = _bioController.text;
  }

  void _batalkanPerubahan() {
    setState(() {
      _namaController.text = _namaLama;
      _usernameController.text = _usernameLama;
      _emailController.text = _emailLama;
      _teleponController.text = _teleponLama;
      _bioController.text = _bioLama;
      _isEditing = false;
    });
  }

  void _mulaiEdit() {
    setState(() => _isEditing = true);
  }

  ImageProvider? get _avatarImage {
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

    setState(() => _saving = true);

    try {
      // Semua perubahan (nama, username/nickname, email, telepon, bio)
      // disimpan sekaligus dalam satu operasi write ke Firestore.
      await _firestore.collection('users').doc(uid).set(
        {
          'name': _namaController.text.trim(),
          // Disimpan ke field 'nickname' supaya sinkron dengan sapaan
          // yang tampil di HomeScreen (mis. "repan").
          'nickname': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _teleponController.text.trim(),
          'bio': _bioController.text.trim(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _simpanNilaiLama();
        _isEditing = false; // Kembali ke mode read-only setelah tersimpan.
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil berhasil disimpan',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: kGradientBottom,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        _AvatarDisplay(
                          avatarImage: _avatarImage,
                          initials: _avatarInitials,
                        ),
                        const SizedBox(height: 24),
                        _FormCard(
                          children: [
                            _FormField(
                              label: 'Nama lengkap',
                              icon: Icons.person_outline,
                              controller: _namaController,
                              enabled: _isEditing,
                            ),
                            _FormField(
                              label: 'Username',
                              icon: Icons.alternate_email,
                              controller: _usernameController,
                              enabled: _isEditing,
                            ),
                            _FormField(
                              label: 'Email',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: _isEditing,
                            ),
                            _FormField(
                              label: 'Nomor telepon',
                              icon: Icons.phone_outlined,
                              controller: _teleponController,
                              keyboardType: TextInputType.phone,
                              enabled: _isEditing,
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
                              enabled: _isEditing,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tombol berubah tergantung mode:
                        // - Belum edit  -> hanya ada di top bar ("Edit Profil")
                        // - Sedang edit -> tampil "Batal" & "Simpan Perubahan"
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      _saving ? null : _batalkanPerubahan,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kInk,
                                    side: BorderSide(
                                        color: kInk.withOpacity(0.4)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kInk,
                                    foregroundColor: kCream,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _saving
                                      ? SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
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
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _mulaiEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(
                                'Edit Profil',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
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
                            ),
                          ),
                        ],
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
// Top bar (tombol kembali + judul halaman + tombol Edit Profil)
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
// Avatar tampilan saja (read-only) — tidak ada tombol kamera / fungsi
// ganti foto di halaman ini.
// ---------------------------------------------------------------------------
class _AvatarDisplay extends StatelessWidget {
  final ImageProvider? avatarImage;
  final String initials;

  const _AvatarDisplay({
    required this.avatarImage,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
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
// Bisa dikunci (read-only) lewat parameter `enabled`.
// ---------------------------------------------------------------------------
class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isLast;
  final bool enabled;

  const _FormField({
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.isLast = false,
    this.enabled = true,
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
                  enabled: enabled,
                  style: GoogleFonts.manrope(
                    color: enabled ? kInk : kInk.withOpacity(0.55),
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
                    disabledBorder: InputBorder.none,
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