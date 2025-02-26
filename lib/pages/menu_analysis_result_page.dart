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
  int? _hoveredBoxIndex;
  Offset _mousePosition = Offset.zero;
  final tooltipAnimationDuration = const Duration(milliseconds: 150);

  // Define this helper for hit testing separately from painting
  final _hitDetectionKey = GlobalKey();

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
        child: MouseRegion(
          onHover: (event) {
            final RenderBox? renderBox = _hitDetectionKey.currentContext
                ?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final localPosition = renderBox.globalToLocal(event.position);

              // Perform hit test outside of paint method
              int? hitIndex = _hitTest(localPosition);

              setState(() {
                _mousePosition = localPosition;
                _hoveredBoxIndex = hitIndex;
              });
            }
          },
          onExit: (event) {
            setState(() {
              _hoveredBoxIndex = null;
            });
          },
          child: SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: Stack(
              children: [
                // Display the image
                SizedBox.expand(
                  child: _buildImage(displayWidth, displayHeight),
                ),

                // Overlay with bounding boxes (only for display, not hit testing)
                RepaintBoundary(
                  child: SizedBox.expand(
                    key: _hitDetectionKey,
                    child: CustomPaint(
                      painter: BoundingBoxPainter(
                        boundingPolys: widget.boundingPolys,
                        resizeScale: widget.resizeScale,
                        displayScale: _displayScale,
                        hoveredIndex: _hoveredBoxIndex,
                      ),
                    ),
                  ),
                ),

                // Tooltip for text with improved animation and positioning
                AnimatedOpacity(
                  opacity: _hoveredBoxIndex != null ? 1.0 : 0.0,
                  duration: tooltipAnimationDuration,
                  child: _hoveredBoxIndex != null &&
                          _hoveredBoxIndex! < widget.boundingPolys.length
                      ? Positioned(
                          // Position tooltip so it doesn't cover the text
                          top: _mousePosition.dy + 20,
                          left: _mousePosition.dx + 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.3,
                            ),
                            child: Text(
                              widget.boundingPolys[_hoveredBoxIndex!]
                                      ['description'] ??
                                  'No text',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
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

  // Add this helper method for hit testing
  int? _hitTest(Offset position) {
    // Loop through bounding polys to find hit
    for (int i = 0; i < widget.boundingPolys.length; i++) {
      final poly = widget.boundingPolys[i];
      final vertices = poly['boundingPoly']?['vertices'] as List?;
      if (vertices == null || vertices.isEmpty) continue;

      final points = <Offset>[];
      for (final vertex in vertices) {
        final x =
            ((vertex['x'] as num?) ?? 0) / widget.resizeScale * _displayScale;
        final y =
            ((vertex['y'] as num?) ?? 0) / widget.resizeScale * _displayScale;
        points.add(Offset(x, y));
      }

      if (points.length >= 3 && _isPointInPolygon(position, points)) {
        return i;
      }
    }
    return null;
  }

  bool _isPointInPolygon(Offset point, List<Offset> vertices) {
    if (vertices.length < 3) return false;

    bool isInside = false;
    int i = 0, j = vertices.length - 1;

    for (i = 0; i < vertices.length; i++) {
      if (vertices[j].dy == vertices[i].dy) {
        j = i;
        continue;
      }

      if (((vertices[i].dy > point.dy) != (vertices[j].dy > point.dy)) &&
          (point.dx <
              (vertices[j].dx - vertices[i].dx) *
                      (point.dy - vertices[i].dy) /
                      (vertices[j].dy - vertices[i].dy) +
                  vertices[i].dx)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }
}

// Update the CustomPainter to only handle painting
class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> boundingPolys;
  final double resizeScale;
  final double displayScale;
  final int? hoveredIndex;

  BoundingBoxPainter({
    required this.boundingPolys,
    required this.resizeScale,
    required this.displayScale,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final hoverPaint = Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < boundingPolys.length; i++) {
        final poly = boundingPolys[i];
        final vertices = poly['boundingPoly']?['vertices'] as List?;
        if (vertices == null || vertices.isEmpty) continue;

        final path = Path();
        bool firstPoint = true;

        for (final vertex in vertices) {
          final x = ((vertex['x'] as num?) ?? 0) / resizeScale * displayScale;
          final y = ((vertex['y'] as num?) ?? 0) / resizeScale * displayScale;

          if (firstPoint) {
            path.moveTo(x, y);
            firstPoint = false;
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();

        // Draw hover highlight if this is the hovered box
        if (i == hoveredIndex) {
          canvas.drawPath(path, hoverPaint);
        }

        // Draw outline for all boxes
        canvas.drawPath(path, paint);
      }
    } catch (e) {
      print('Error in BoundingBoxPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) =>
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.displayScale != displayScale;
}
