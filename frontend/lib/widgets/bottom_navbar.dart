import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  Bottom Navbar — Nemu! App
//  Clean, Rata, Playful Icon Micro-Interactions
// ─────────────────────────────────────────────

const Color _navGreen = Color(0xFF007C3F);
const Color _navDark  = Color(0xFF0B3D24);

class NemuBottomNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NemuBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<NemuBottomNavbar> createState() => _NemuBottomNavbarState();
}

class _NemuBottomNavbarState extends State<NemuBottomNavbar>
    with TickerProviderStateMixin {
  late List<AnimationController> _bounceControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _translateAnimations;

  // Active order badge indicator
  final bool _hasActiveOrder = true;
  final int _activeOrderCount = 1;

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
    _NavItem(icon: Icons.storefront_rounded, label: 'Pasar'),
    _NavItem(icon: Icons.search_rounded, label: 'Cari'),
    _NavItem(icon: Icons.waving_hand_rounded, label: 'Kang!'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Pesanan', hasBadge: true),
  ];

  @override
  void initState() {
    super.initState();

    _bounceControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnimations = _bounceControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();

    _translateAnimations = _bounceControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 50),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();

    _triggerBounce(widget.currentIndex);
  }

  void _triggerBounce(int index) {
    if (index >= 0 && index < _bounceControllers.length) {
      _bounceControllers[index].reset();
      _bounceControllers[index].forward();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _bounceControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.selectionClick();
    _triggerBounce(index);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = widget.currentIndex == i;
              return _buildNavItem(i, item, isActive);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, bool isActive) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleTap(index),
        splashColor: _navGreen.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: AnimatedBuilder(
          animation: _bounceControllers[index],
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _translateAnimations[index].value),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? _navGreen.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            size: 24,
                            color: isActive ? _navGreen : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      // Badge untuk Pesanan / Notif jika ada
                      if (item.hasBadge && _hasActiveOrder)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? _navGreen : Colors.grey.shade400,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool hasBadge;

  const _NavItem({
    required this.icon,
    required this.label,
    this.hasBadge = false,
  });
}
