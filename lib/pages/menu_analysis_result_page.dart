import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import '../theme/app_theme.dart';

class MenuAnalysisResultPage extends StatefulWidget {
  final dynamic image;
  final List<Map<String, dynamic>> boundingPolys;
  final List<Map<String, dynamic>> menuItems;
  final int originalWidth;
  final int originalHeight;
  final double resizeScale;

  const MenuAnalysisResultPage({
    super.key,
    required this.image,
    required this.boundingPolys,
    required this.menuItems,
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
  int? _hoveredMenuItemIndex;
  Offset _mousePosition = Offset.zero;
  final tooltipAnimationDuration = const Duration(milliseconds: 150);
  final _hitDetectionKey = GlobalKey();

  // Add state variables for visibility
  bool _showOcrBoxes = false;
  bool _showMenuItemButtons = true;

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

  // Show dialog with menu item details
  void _showMenuItemDetails(Map<String, dynamic> menuItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          menuItem['name'] ?? 'Menu Item',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (menuItem['price'] != null) ...[
                const Text(
                  'Price:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('\$${menuItem['price']}'),
                const SizedBox(height: 12),
              ],
              if (menuItem['ingredients'] != null &&
                  (menuItem['ingredients'] as List).isNotEmpty) ...[
                const Text(
                  'Ingredients:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text((menuItem['ingredients'] as List).join(', ')),
                const SizedBox(height: 12),
              ],
              if (menuItem['drinkFlavor'] != null &&
                  menuItem['drinkFlavor'].toString().isNotEmpty) ...[
                const Text(
                  'Flavor:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(menuItem['drinkFlavor']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showOcrBoxes = !_showOcrBoxes;
          });
        },
        tooltip: _showOcrBoxes ? 'Hide OCR Boxes' : 'Show OCR Boxes',
        child: Icon(_showOcrBoxes ? Icons.visibility_off : Icons.visibility),
      ),
      body: Center(
        child: MouseRegion(
          onHover: (event) {
            final RenderBox? renderBox = _hitDetectionKey.currentContext
                ?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final localPosition = renderBox.globalToLocal(event.position);

              // Perform hit test outside of paint method
              _hitTest(localPosition);

              setState(() {
                _mousePosition = localPosition;
              });
            }
          },
          onExit: (event) {
            setState(() {
              _hoveredBoxIndex = null;
              _hoveredMenuItemIndex = null;
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

                // Overlay with bounding boxes
                RepaintBoundary(
                  child: SizedBox.expand(
                    key: _hitDetectionKey,
                    child: CustomPaint(
                      painter: BoundingBoxPainter(
                        boundingPolys: widget.boundingPolys,
                        menuItems: widget.menuItems,
                        resizeScale: widget.resizeScale,
                        displayScale: _displayScale,
                        hoveredBoxIndex: _hoveredBoxIndex,
                        hoveredMenuItemIndex: _hoveredMenuItemIndex,
                        showOcrBoxes: _showOcrBoxes,
                        showMenuItemBoxes:
                            false, // Hide green boxes, we'll use buttons instead
                      ),
                    ),
                  ),
                ),

                // Add transparent buttons for menu items
                if (_showMenuItemButtons)
                  ...widget.menuItems.map((menuItem) {
                    final vertices = menuItem['boundingBox'] as List?;
                    if (vertices == null || vertices.isEmpty)
                      return const SizedBox.shrink();

                    // Calculate bounding rectangle for the button
                    double minX = double.infinity;
                    double minY = double.infinity;
                    double maxX = 0;
                    double maxY = 0;

                    for (final vertex in vertices) {
                      final x = ((vertex['x'] as num?) ?? 0) /
                          widget.resizeScale *
                          _displayScale;
                      final y = ((vertex['y'] as num?) ?? 0) /
                          widget.resizeScale *
                          _displayScale;

                      minX = minX > x ? x : minX;
                      minY = minY > y ? y : minY;
                      maxX = maxX < x ? x : maxX;
                      maxY = maxY < y ? y : maxY;
                    }

                    final index = widget.menuItems.indexOf(menuItem);
                    final isHovered = index == _hoveredMenuItemIndex;

                    return Positioned(
                      left: minX,
                      top: minY,
                      width: maxX - minX,
                      height: maxY - minY,
                      child: GestureDetector(
                        onTap: () => _showMenuItemDetails(menuItem),
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _hoveredMenuItemIndex = index;
                              _hoveredBoxIndex = null;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _hoveredMenuItemIndex = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.accentColor,
                                width: 2,
                              ),
                              color: isHovered
                                  ? AppTheme.accentColor.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: isHovered
                                  ? Icon(
                                      Icons.info_outline,
                                      color: AppTheme.accentColor,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                // Tooltip for OCR text
                AnimatedOpacity(
                  opacity: _hoveredBoxIndex != null ? 1.0 : 0.0,
                  duration: tooltipAnimationDuration,
                  child: _hoveredBoxIndex != null &&
                          _hoveredBoxIndex! < widget.boundingPolys.length
                      ? Positioned(
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
                              widget.boundingPolys[_hoveredBoxIndex!]['text'] ??
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

  void _hitTest(Offset position) {
    // First check menu items
    for (int i = 0; i < widget.menuItems.length; i++) {
      final item = widget.menuItems[i];
      final vertices = item['boundingBox'] as List?;
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
        setState(() {
          _hoveredMenuItemIndex = i;
          _hoveredBoxIndex = null;
        });
        return;
      }
    }

    // Only check OCR boxes if they're visible
    if (_showOcrBoxes) {
      for (int i = 0; i < widget.boundingPolys.length; i++) {
        final poly = widget.boundingPolys[i];
        final vertices = poly['boundingBox'] as List?;
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
          setState(() {
            _hoveredBoxIndex = i;
            _hoveredMenuItemIndex = null;
          });
          return;
        }
      }
    }

    setState(() {
      _hoveredBoxIndex = null;
      _hoveredMenuItemIndex = null;
    });
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

// Update the CustomPainter to support visibility toggling
class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> boundingPolys;
  final List<Map<String, dynamic>> menuItems;
  final double resizeScale;
  final double displayScale;
  final int? hoveredBoxIndex;
  final int? hoveredMenuItemIndex;
  final bool showOcrBoxes;
  final bool showMenuItemBoxes;

  BoundingBoxPainter({
    required this.boundingPolys,
    required this.menuItems,
    required this.resizeScale,
    required this.displayScale,
    this.hoveredBoxIndex,
    this.hoveredMenuItemIndex,
    this.showOcrBoxes = true,
    this.showMenuItemBoxes = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // Paint for OCR boxes (red)
      final ocrPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final ocrHoverPaint = Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      // Paint for menu items (green)
      final menuItemPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final menuItemHoverPaint = Paint()
        ..color = Colors.green.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      // Draw OCR boxes if visible
      if (showOcrBoxes) {
        for (int i = 0; i < boundingPolys.length; i++) {
          final poly = boundingPolys[i];
          final vertices = poly['boundingBox'] as List?;
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
          if (i == hoveredBoxIndex) {
            canvas.drawPath(path, ocrHoverPaint);
          }

          // Draw outline for all boxes
          canvas.drawPath(path, ocrPaint);
        }
      }

      // Draw menu item boxes if visible
      if (showMenuItemBoxes) {
        for (int i = 0; i < menuItems.length; i++) {
          final item = menuItems[i];
          final vertices = item['boundingBox'] as List?;
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

          // Draw hover highlight if this is the hovered menu item
          if (i == hoveredMenuItemIndex) {
            canvas.drawPath(path, menuItemHoverPaint);
          }

          // Draw outline for all menu items
          canvas.drawPath(path, menuItemPaint);
        }
      }
    } catch (e) {
      print('Error in BoundingBoxPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) =>
      oldDelegate.hoveredBoxIndex != hoveredBoxIndex ||
      oldDelegate.hoveredMenuItemIndex != hoveredMenuItemIndex ||
      oldDelegate.displayScale != displayScale ||
      oldDelegate.showOcrBoxes != showOcrBoxes ||
      oldDelegate.showMenuItemBoxes != showMenuItemBoxes;
}
