import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decoration.dart';
import 'login_screen.dart';
import 'terms_page.dart';

/// ============================================================
/// REGISTRATION SCREEN
/// ============================================================
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Wajib pakai AutofillGroup supaya Google Password Manager bisa
  // menyimpan & menyarankan email + password secara otomatis.
  final _autofillGroupKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  static const int _minPasswordLength = 8;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Harap setujui syarat & ketentuan terlebih dahulu',
            style: GoogleFonts.manrope(color: AppColors.beige),
          ),
          backgroundColor: AppColors.nightmare,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Ganti dengan pemanggilan API registrasi kamu
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Memberi tahu sistem (Google Password Manager) bahwa proses
    // autofill selesai dan data boleh disimpan.
    TextInput.finishAutofillContext(shouldSave: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registrasi berhasil!',
            style: GoogleFonts.manrope(color: AppColors.beige),
          ),
          backgroundColor: AppColors.gradientBottom,
        ),
      );
    }
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
                  const SizedBox(height: 4),
                  _buildLogo(),
                  const SizedBox(height: 20),
                  Text(
                    'Buat Akun Baru',
                    style: GoogleFonts.manrope(
                      color: AppColors.beige,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lengkapi data di bawah untuk mendaftar',
                    style: GoogleFonts.manrope(
                      color: AppColors.beige.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

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
                            controller: _nameController,
                            label: 'Nama Lengkap',
                            icon: Icons.person_outline,
                            autofillHints: const [AutofillHints.name],
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
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
                            controller: _phoneController,
                            label: 'Nomor HP',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [AutofillHints.telephoneNumber],
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Nomor HP wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ---------- PASSWORD (min 8 karakter) ----------
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Kata Sandi',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            // Hint ini yang memicu Google Password Manager
                            // untuk menawarkan pembuatan password otomatis.
                            autofillHints: const [AutofillHints.newPassword],
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
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Minimal $_minPasswordLength karakter',
                              style: GoogleFonts.manrope(
                                color: AppColors.nightmare.withOpacity(0.55),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Konfirmasi Kata Sandi',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            autofillHints: const [AutofillHints.newPassword],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.nightmare.withOpacity(0.5),
                              ),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (v != _passwordController.text) {
                                return 'Konfirmasi kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ---------- CHECKBOX TERMS ----------
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                activeColor: AppColors.gradientBottom,
                                onChanged: (v) =>
                                    setState(() => _agreeToTerms = v ?? false),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TermsPage(),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Saya menyetujui ',
                                      style: GoogleFonts.manrope(
                                        color: AppColors.nightmare,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Syarat & Ketentuan',
                                          style: GoogleFonts.manrope(
                                            color: AppColors.gradientBottom,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- REGISTER BUTTON ----------
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
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
                              'DAFTAR',
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

                  // ---------- LINK KE HALAMAN MASUK ----------
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: GoogleFonts.manrope(
                            color: AppColors.beige.withOpacity(0.85),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Masuk',
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

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        padding: const EdgeInsets.all(14),
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