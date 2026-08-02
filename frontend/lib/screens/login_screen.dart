import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decoration.dart';
import '../services/auth_service.dart';

/// ============================================================
/// LOGIN SCREEN (halaman "Masuk" terpisah dari registrasi)
/// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const int _minPasswordLength = 8;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Panggil API login ke backend Laragon
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Memberi tahu Google Password Manager bahwa proses autofill selesai.
      TextInput.finishAutofillContext(shouldSave: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Berhasil masuk!',
              style: GoogleFonts.manrope(color: AppColors.beige),
            ),
            backgroundColor: AppColors.gradientBottom,
          ),
        );

        // TODO: simpan data user (result['user']) ke local storage/session
        // lalu arahkan ke halaman utama, contoh:
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      // Menampilkan pesan error dari backend (misal: "Email tidak ditemukan")
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.manrope(color: AppColors.beige),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Popup kecil (bukan fullscreen) untuk alur "Lupa kata sandi?".
  /// Berisi satu kolom email, tombol kirim, dan tombol X untuk menutup.
  void _showForgotPasswordDialog(BuildContext parentContext) {
    final resetEmailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- TOMBOL X ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Icon(
                          Icons.close,
                          size: 22,
                          color: AppColors.nightmare.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Lupa Kata Sandi?',
                    style: GoogleFonts.manrope(
                      color: AppColors.nightmare,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masukkan email kamu, kami akan kirim tautan untuk atur ulang kata sandi.',
                    style: GoogleFonts.manrope(
                      color: AppColors.nightmare.withOpacity(0.65),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ---------- KOLOM EMAIL ----------
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: GoogleFonts.manrope(color: AppColors.nightmare),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: GoogleFonts.manrope(
                        color: AppColors.nightmare.withOpacity(0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.gradientBottom,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.4),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.gradientBottom.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.gradientBottom.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.gradientBottom, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ---------- TOMBOL KIRIM ----------
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!dialogFormKey.currentState!.validate()) return;

                        // TODO: panggil API kirim link reset password di sini
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tautan reset kata sandi telah dikirim ke email kamu',
                              style: GoogleFonts.manrope(color: AppColors.beige),
                            ),
                            backgroundColor: AppColors.gradientBottom,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nightmare,
                        foregroundColor: AppColors.beige,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Kirim',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.beige,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: BackgroundDecoration()),
            SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- TOMBOL KEMBALI ----------
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.beige),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.beige,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Selamat Datang Kembali',
                    style: GoogleFonts.manrope(
                      color: AppColors.beige,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masuk untuk melanjutkan ke akun kamu',
                    style: GoogleFonts.manrope(
                      color: AppColors.beige.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ---------- FORM CARD ----------
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email wajib diisi';
                              if (!v.contains('@')) return 'Format email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Kata Sandi',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            // Hint password (bukan newPassword) supaya Google
                            // Password Manager menyarankan kredensial tersimpan.
                            autofillHints: const [AutofillHints.password],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.nightmare.withOpacity(0.5),
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              if (v.length < _minPasswordLength) {
                                return 'Minimal $_minPasswordLength karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showForgotPasswordDialog(context),
                              child: Text(
                                'Lupa kata sandi?',
                                style: GoogleFonts.manrope(
                                  color: AppColors.gradientBottom,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- LOGIN BUTTON ----------
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nightmare,
                        foregroundColor: AppColors.beige,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.beige,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'MASUK',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: AppColors.beige,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------- LINK KE REGISTRASI ----------
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Belum punya akun? ',
                          style: GoogleFonts.manrope(
                            color: AppColors.beige.withOpacity(0.85),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Daftar',
                              style: GoogleFonts.manrope(
                                color: AppColors.beige,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Iterable<String>? autofillHints,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      validator: validator,
      style: GoogleFonts.manrope(color: AppColors.nightmare),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: AppColors.nightmare.withOpacity(0.5),
        ),
        prefixIcon: Icon(icon, color: AppColors.gradientBottom),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gradientBottom.withOpacity(0.25),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gradientBottom.withOpacity(0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gradientBottom, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
    );
  }
}