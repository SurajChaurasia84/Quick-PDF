import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_controller.dart';
import '../utils/app_theme.dart';
import '../utils/theme_utils.dart';
import 'home_screen.dart';
import 'my_files_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final screens = <Widget>[
      const HomeScreen(),
      const ToolsScreen(),
      const MyFilesScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: controller.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && controller.currentIndex != 0) {
          controller.updateNavigation(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: controller.currentIndex,
              children: screens,
            ),
          ),
        ),
        bottomNavigationBar: _CradleBottomNavBar(
          currentIndex: controller.currentIndex,
          onTabSelected: (index) => controller.updateNavigation(index),
          onScanPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ScannerScreen()),
            );
          },
        ),
      ),
    );
  }
}

class _CradleBottomNavBar extends StatelessWidget {
  const _CradleBottomNavBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScanPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScanPressed;

  static const double topOffset = 26.0;
  static const double barHeight = 62.0;
  static const double notchWidth = 88.0;
  static const double notchDepth = 32.0;
  static const double buttonSize = 58.0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final totalHeight = topOffset + barHeight + bottomPadding;

    final barBgColor = context.panelBackground;
    final borderColor = context.borderColor;

    final shadowColor = context.isDarkMode
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.08);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: <Widget>[
          // 1. Curved Cradle Background & Top Highlight Stroke
          Positioned.fill(
            child: CustomPaint(
              painter: _CradleBarPainter(
                backgroundColor: barBgColor,
                borderColor: borderColor,
                topOffset: topOffset,
                notchWidth: notchWidth,
                notchDepth: notchDepth,
                shadowColor: shadowColor,
              ),
            ),
          ),

          // 2. Navigation Tabs (2 on left, 2 on right)
          Positioned(
            left: 0,
            right: 0,
            top: topOffset,
            height: barHeight,
            child: Row(
              children: <Widget>[
                _CradleTabItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                _CradleTabItem(
                  icon: Icons.auto_fix_high_outlined,
                  selectedIcon: Icons.auto_fix_high_rounded,
                  label: 'Tools',
                  selected: currentIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
                const SizedBox(width: notchWidth),
                _CradleTabItem(
                  icon: Icons.folder_outlined,
                  selectedIcon: Icons.folder_rounded,
                  label: 'Files',
                  selected: currentIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
                _CradleTabItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  selected: currentIndex == 3,
                  onTap: () => onTabSelected(3),
                ),
              ],
            ),
          ),

          // 3. Floating Hero Scan Button
          Positioned(
            top: 2.0,
            child: _HeroCenterScanButton(
              size: buttonSize,
              onTap: onScanPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _CradleTabItem extends StatelessWidget {
  const _CradleTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = context.isDarkMode
        ? AppTheme.cyan
        : (Theme.of(context).floatingActionButtonTheme.backgroundColor ??
            Theme.of(context).colorScheme.primary);
    final color = selected ? selectedColor : context.iconMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: selectedColor.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  selected ? selectedIcon : icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCenterScanButton extends StatefulWidget {
  const _HeroCenterScanButton({
    required this.onTap,
    this.size = 58.0,
  });

  final VoidCallback onTap;
  final double size;

  @override
  State<_HeroCenterScanButton> createState() => _HeroCenterScanButtonState();
}

class _HeroCenterScanButtonState extends State<_HeroCenterScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark
        ? AppTheme.cyan
        : (Theme.of(context).floatingActionButtonTheme.backgroundColor ??
            Theme.of(context).colorScheme.primary);

    final gradientStart = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB);
    final gradientEnd = isDark ? const Color(0xFF0091EA) : const Color(0xFF1D4ED8);
    final iconColor = isDark ? Colors.black : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientStart, gradientEnd],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.60),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.38),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: gradientStart.withValues(alpha: isDark ? 0.28 : 0.20),
                blurRadius: 8,
                spreadRadius: -1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.document_scanner_outlined,
              color: iconColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _CradleBarPainter extends CustomPainter {
  const _CradleBarPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.topOffset,
    required this.notchWidth,
    required this.notchDepth,
    this.shadowColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final double topOffset;
  final double notchWidth;
  final double notchDepth;
  final Color? shadowColor;

  Path _createBarPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final nw2 = notchWidth / 2;
    final x0 = cx - nw2;

    path.moveTo(0, h);
    path.lineTo(0, topOffset);
    path.lineTo(x0, topOffset);

    // Smooth concave cradle curve with 0-derivatives at borders and center
    const segments = 32;
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final x = x0 + t * notchWidth;
      final u = (x - cx) / nw2;
      final cosVal = math.cos(u * math.pi / 2);
      final y = topOffset + notchDepth * (cosVal * cosVal);
      path.lineTo(x, y);
    }

    path.lineTo(w, topOffset);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  Path _createTopBorderPath(Size size) {
    final path = Path();
    final w = size.width;
    final cx = w / 2;
    final nw2 = notchWidth / 2;
    final x0 = cx - nw2;

    path.moveTo(0, topOffset);
    path.lineTo(x0, topOffset);

    const segments = 32;
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final x = x0 + t * notchWidth;
      final u = (x - cx) / nw2;
      final cosVal = math.cos(u * math.pi / 2);
      final y = topOffset + notchDepth * (cosVal * cosVal);
      path.lineTo(x, y);
    }

    path.lineTo(w, topOffset);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barPath = _createBarPath(size);

    if (shadowColor != null) {
      canvas.drawShadow(barPath, shadowColor!, 4.0, true);
    }

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(barPath, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_createTopBorderPath(size), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CradleBarPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.topOffset != topOffset ||
        oldDelegate.notchWidth != notchWidth ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.shadowColor != shadowColor;
  }
}
