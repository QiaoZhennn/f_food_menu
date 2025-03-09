import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
// import '../theme/app_theme.dart';
// import 'dart:ui';
import '../components/water_drop_button.dart';
import '../models/food_item.dart';

class MenuAnalysisResultPage extends StatefulWidget {
  final dynamic image;
  final List<Map<String, dynamic>> boundingPolys;
  final List<Map<String, dynamic>> menuItems;
  final int originalWidth;
  final int originalHeight;
  final double resizeScale;
  final Function(FoodItem)? onMenuItemSelected;

  const MenuAnalysisResultPage({
    super.key,
    required this.image,
    required this.boundingPolys,
    required this.menuItems,
    required this.originalWidth,
    required this.originalHeight,
    required this.resizeScale,
    this.onMenuItemSelected,
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
    // If we have a navigation callback, use it
    if (widget.onMenuItemSelected != null) {
      // Convert the menu item to a FoodItem
      final foodItem = FoodItem(
        name: menuItem['name'] ?? '',
        ingredients: menuItem['ingredients'] != null
            ? List<String>.from(menuItem['ingredients'])
            : [],
        drinkFlavor: menuItem['drinkFlavor'] ?? '',
        price: menuItem['price'] != null ? menuItem['price'].toDouble() : 0.0,
      );

      widget.onMenuItemSelected!(foodItem);
      return;
    }

    // Otherwise show the dialog as before
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
                  child: _buildImage(),
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
                        showMenuItemBoxes: false,
                      ),
                    ),
                  ),
                ),

                // Add water drop buttons for menu items
                if (_showMenuItemButtons)
                  ...widget.menuItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final menuItem = entry.value;
                    final vertices = menuItem['boundingBox'] as List?;

                    if (vertices == null || vertices.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return WaterDropButton(
                      parentImageWidth: widget.originalWidth,
                      parentImageHeight: widget.originalHeight,
                      displayScale: _displayScale,
                      resizeScale: widget.resizeScale,
                      boundingBox: vertices,
                      onTap: () => _showMenuItemDetails(menuItem),
                      isHovered: index == _hoveredMenuItemIndex,
                      onHoverChanged: (isHovered) {
                        setState(() {
                          _hoveredMenuItemIndex = isHovered ? index : null;
                          if (isHovered) {
                            _hoveredBoxIndex = null;
                          }
                        });
                      },
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

  Widget _buildImage() {
    Widget imageWidget;

    if (widget.image is String) {
      // Asset image
      imageWidget = Image.asset(
        widget.image as String,
        fit: BoxFit.contain, // Use contain to maintain aspect ratio
        width: widget.originalWidth * _displayScale,
        height: widget.originalHeight * _displayScale,
      );
    } else if (widget.image is File) {
      // File image (from camera or gallery on mobile)
      imageWidget = Image.file(
        widget.image as File,
        fit: BoxFit.contain,
        width: widget.originalWidth * _displayScale,
        height: widget.originalHeight * _displayScale,
      );
    } else if (widget.image is Uint8List) {
      // Memory image (from camera or gallery on web)
      imageWidget = Image.memory(
        widget.image as Uint8List,
        fit: BoxFit.contain,
        width: widget.originalWidth * _displayScale,
        height: widget.originalHeight * _displayScale,
      );
    } else {
      // Fallback
      imageWidget = const Center(child: Text('Unsupported image format'));
    }

    return Container(
      width: widget.originalWidth * _displayScale,
      height: widget.originalHeight * _displayScale,
      child: imageWidget,
    );
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
