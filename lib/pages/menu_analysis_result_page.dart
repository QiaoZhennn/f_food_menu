import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

class MenuAnalysisResultPage extends StatefulWidget {
  final dynamic image;
  final List<Map<String, dynamic>> boundingPolys;
  final int originalWidth;
  final int originalHeight;
  final double resizeScale;

  const MenuAnalysisResultPage({
    super.key,
    required this.image,
    required this.boundingPolys,
    required this.originalWidth,
    required this.originalHeight,
    required this.resizeScale,
  });

  @override
  State<MenuAnalysisResultPage> createState() => _MenuAnalysisResultPageState();
}

class _MenuAnalysisResultPageState extends State<MenuAnalysisResultPage> {
  double _displayScale = 1.0;
  Size _currentSize = Size.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateDisplayScale();
  }

  void _calculateDisplayScale() {
    // Get current screen size
    final screenSize = MediaQuery.of(context).size;
    final availableWidth = screenSize.width * 0.9;
    final availableHeight = screenSize.height * 0.8;

    // Calculate scale to fit screen
    final widthScale = availableWidth / widget.originalWidth;
    final heightScale = availableHeight / widget.originalHeight;

    setState(() {
      _displayScale = widthScale < heightScale ? widthScale : heightScale;
      _currentSize = screenSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if screen size changed (for web)
    final currentSize = MediaQuery.of(context).size;
    if (_currentSize != currentSize) {
      // Schedule recalculation on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateDisplayScale();
      });
    }

    // Calculate dimensions for display
    final displayWidth = widget.originalWidth * _displayScale;
    final displayHeight = widget.originalHeight * _displayScale;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Analysis Result'),
      ),
      body: Center(
        child: SizedBox(
          width: displayWidth,
          height: displayHeight,
          child: Stack(
            children: [
              // Display the image
              SizedBox.expand(
                child: _buildImage(displayWidth, displayHeight),
              ),

              // Overlay with bounding boxes
              SizedBox.expand(
                child: CustomPaint(
                  painter: BoundingBoxPainter(
                    boundingPolys: widget.boundingPolys,
                    resizeScale: widget.resizeScale,
                    displayScale: _displayScale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double width, double height) {
    if (widget.image is String) {
      if ((widget.image as String).startsWith('assets/')) {
        return Image.asset(
          widget.image,
          width: width,
          height: height,
          fit: BoxFit.fill,
        );
      } else {
        return Image.file(
          File(widget.image),
          width: width,
          height: height,
          fit: BoxFit.fill,
        );
      }
    } else if (widget.image is File) {
      return Image.file(
        widget.image,
        width: width,
        height: height,
        fit: BoxFit.fill,
      );
    } else if (widget.image is Uint8List) {
      return Image.memory(
        widget.image,
        width: width,
        height: height,
        fit: BoxFit.fill,
      );
    }
    return const SizedBox.shrink();
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> boundingPolys;
  final double resizeScale; // Scale applied during image resize before analysis
  final double displayScale; // Scale applied for UI display

  BoundingBoxPainter({
    required this.boundingPolys,
    required this.resizeScale,
    required this.displayScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final poly in boundingPolys) {
      final vertices = poly['boundingPoly']?['vertices'] as List?;
      if (vertices == null || vertices.isEmpty) continue;

      final path = Path();
      bool firstPoint = true;

      for (final vertex in vertices) {
        // First convert back to original coordinates, then apply display scale
        // API coordinates are based on the resized image (720px max)
        final x = (vertex['x'] ?? 0) / resizeScale * displayScale;
        final y = (vertex['y'] ?? 0) / resizeScale * displayScale;

        if (firstPoint) {
          path.moveTo(x, y);
          firstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
