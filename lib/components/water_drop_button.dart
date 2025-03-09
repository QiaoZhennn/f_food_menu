import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class WaterDropButton extends StatefulWidget {
  final int parentImageWidth;
  final int parentImageHeight;
  final double displayScale;
  final double resizeScale;
  final List<dynamic> boundingBox;
  final VoidCallback onTap;
  final bool isHovered;
  final Function(bool) onHoverChanged;

  const WaterDropButton({
    super.key,
    required this.parentImageWidth,
    required this.parentImageHeight,
    required this.displayScale,
    required this.resizeScale,
    required this.boundingBox,
    required this.onTap,
    required this.isHovered,
    required this.onHoverChanged,
  });

  @override
  State<WaterDropButton> createState() => _WaterDropButtonState();
}

class _WaterDropButtonState extends State<WaterDropButton> {
  late Rect _buttonRect;

  @override
  void initState() {
    super.initState();
    _calculateButtonRect();
  }

  @override
  void didUpdateWidget(WaterDropButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boundingBox != widget.boundingBox ||
        oldWidget.displayScale != widget.displayScale ||
        oldWidget.resizeScale != widget.resizeScale) {
      _calculateButtonRect();
    }
  }

  void _calculateButtonRect() {
    // Calculate bounding rectangle for the button
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = 0;
    double maxY = 0;

    for (final vertex in widget.boundingBox) {
      final x = ((vertex['x'] as num?) ?? 0) /
          widget.resizeScale *
          widget.displayScale;
      final y = ((vertex['y'] as num?) ?? 0) /
          widget.resizeScale *
          widget.displayScale;

      minX = minX > x ? x : minX;
      minY = minY > y ? y : minY;
      maxX = maxX < x ? x : maxX;
      maxY = maxY < y ? y : maxY;
    }

    _buttonRect = Rect.fromLTWH(minX, minY, maxX - minX, maxY - minY);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _buttonRect.left,
      top: _buttonRect.top,
      width: _buttonRect.width,
      height: _buttonRect.height,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => widget.onHoverChanged(true),
          onExit: (_) => widget.onHoverChanged(false),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentColor
                      .withOpacity(widget.isHovered ? 0.2 : 0.05),
                  AppTheme.accentColor
                      .withOpacity(widget.isHovered ? 0.4 : 0.15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor
                      .withOpacity(widget.isHovered ? 0.5 : 0.3),
                  blurRadius: widget.isHovered ? 15 : 10,
                  spreadRadius: widget.isHovered ? 3 : 2,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipPath(
              clipper: WaterDropClipper(),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isHovered
                      ? AppTheme.accentColor.withOpacity(0.05)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaterDropClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Create a more organic shape with bezier curves
    path.moveTo(w * 0.1, h * 0.3); // Start point

    // Top edge with wave
    path.quadraticBezierTo(w * 0.2, h * 0.1, w * 0.5, h * 0.15);
    path.quadraticBezierTo(w * 0.8, h * 0.2, w * 0.9, h * 0.3);

    // Right edge with slight curve
    path.quadraticBezierTo(w * 0.95, h * 0.5, w * 0.9, h * 0.7);

    // Bottom edge with wave
    path.quadraticBezierTo(w * 0.8, h * 0.9, w * 0.5, h * 0.85);
    path.quadraticBezierTo(w * 0.2, h * 0.8, w * 0.1, h * 0.7);

    // Left edge with slight curve
    path.quadraticBezierTo(w * 0.05, h * 0.5, w * 0.1, h * 0.3);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
