import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _lanGreen   = Color(0xFF007C3F);
const Color _lanYellow  = Color(0xFFD9DF36);
const Color _lanDark    = Color(0xFF0F1B11);
const Color _lanAmber   = Color(0xFFF59E0B);

TextStyle _ls({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _lanDark,
  double? height,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

class SellerLanggananScreen extends StatefulWidget {
  const SellerLanggananScreen({super.key});

  @override
  State<SellerLanggananScreen> createState() => _SellerLanggananScreenState();
}

class _SellerLanggananScreenState extends State<SellerLanggananScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Icon Container with Glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_lanGreen, _lanGreen.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _lanGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: _lanYellow,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Coming Soon Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _lanAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _lanAmber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, color: _lanAmber, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'COMING SOON',
                      style: _ls(size: 11, weight: FontWeight.bold, color: _lanAmber),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Title
              Text(
                'Langganan Nemu+',
                style: _ls(size: 24, weight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Optimalkan Penjualan dan Jangkau Lebih Banyak Pembeli!',
                style: _ls(
                  size: 14,
                  weight: FontWeight.w600,
                  color: _lanYellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Glassmorphic Feature Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Fitur Langganan Nemu+ akan segera hadir untuk bantu optimalkan penjualanmu!',
                      style: _ls(
                        size: 13,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 20),

                    // Feature highlights list
                    _buildFeatureItem(
                      Icons.trending_up_rounded,
                      'Analitik Toko Mendalam',
                      'Pantau performa penjualan harian & tren produk terlaris secara real-time.',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.campaign_rounded,
                      'Promosi Prioritas',
                      'Produk Anda akan tampil di baris terdepan pada pencarian pembeli.',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.support_agent_rounded,
                      'Dukungan VIP Seller',
                      'Layanan bantuan prioritas 24/7 khusus untuk mitra Nemu+.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lanYellow,
                  foregroundColor: _lanDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Terima kasih! Kami akan memberi tahu Anda saat Nemu+ siap.',
                        style: _ls(size: 12, color: Colors.white),
                      ),
                      backgroundColor: _lanGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Beri Tahu Saya',
                      style: _ls(size: 13, weight: FontWeight.bold, color: _lanDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _lanYellow, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _ls(size: 13, weight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: _ls(size: 11, color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
