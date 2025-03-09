import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/food_item.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'dart:io';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/menu_analysis_service.dart';
import 'menu_analysis_result_page.dart';

class MenuListPage extends StatefulWidget {
  final Function(List<FoodItem>) onMenuExtracted;
  final Function(Widget analysisResultWidget) onAnalysisComplete;

  const MenuListPage({
    super.key,
    required this.onMenuExtracted,
    required this.onAnalysisComplete,
  });

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  String? _selectedImagePath;
  List<String> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  XFile? _takenPhoto;
  Uint8List? _webImage;
  bool _isTakenPhotoSelected = false;
  final _menuAnalysisService = MenuAnalysisService();
  bool _isAnalyzingMenu = false;

  @override
  void initState() {
    super.initState();
    _loadImageList();
  }

  Future<void> _loadImageList() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final imagePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/image/'))
          .toList();

      setState(() {
        _imageFiles = imagePaths;
      });
    } catch (e) {
      print('Error loading image list: $e');
    }
  }

  Future<Map<String, dynamic>> _resizeImage(Uint8List bytes) async {
    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      return {
        'base64': base64Encode(bytes),
        'scale': 1.0,
        'width': 0,
        'height': 0
      };
    }

    // Store original dimensions
    int originalWidth = image.width;
    int originalHeight = image.height;

    // Calculate new dimensions
    double scale = 720 / math.max(originalWidth, originalHeight);

    // Only resize if image is larger than 720 pixels in any dimension
    if (scale < 1.0) {
      int newWidth = (originalWidth * scale).round();
      int newHeight = (originalHeight * scale).round();

      // Resize the image
      img.Image resized =
          img.copyResize(image, width: newWidth, height: newHeight);
      bytes = img.encodeJpg(resized);
    } else {
      // No resizing needed
      scale = 1.0;
    }

    return {
      'base64': base64Encode(bytes),
      'scale': scale,
      'width': originalWidth,
      'height': originalHeight
    };
  }

  Future<String> _getImageBase64(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    return base64Encode(bytes);
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          setState(() {
            _takenPhoto = photo;
            _webImage = bytes;
            _selectedImagePath = null;
            _isTakenPhotoSelected = true;
          });
        } else {
          setState(() {
            _takenPhoto = photo;
            _selectedImagePath = null;
            _isTakenPhotoSelected = true;
          });
        }
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _takenPhoto = image;
            _webImage = bytes;
            _selectedImagePath = null;
            _isTakenPhotoSelected = true;
          });
        } else {
          setState(() {
            _takenPhoto = image;
            _selectedImagePath = null;
            _isTakenPhotoSelected = true;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _analyzeMenu() async {
    if (!_isTakenPhotoSelected && _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an image or take a photo first')),
      );
      return;
    }

    setState(() {
      _isAnalyzingMenu = true;
    });

    try {
      dynamic imageForAnalysis;
      Map<String, dynamic> resizeResult;
      String imageBase64;
      int originalWidth = 0;
      int originalHeight = 0;
      double resizeScale = 1.0;

      if (_isTakenPhotoSelected && _takenPhoto != null) {
        final bytes = await _takenPhoto!.readAsBytes();
        resizeResult = await _resizeImage(bytes);
        imageBase64 = resizeResult['base64'];
        originalWidth = resizeResult['width'];
        originalHeight = resizeResult['height'];
        resizeScale = resizeResult['scale'];

        if (kIsWeb) {
          imageForAnalysis = _webImage;
        } else {
          imageForAnalysis = File(_takenPhoto!.path);
        }
      } else {
        final ByteData data = await rootBundle.load(_selectedImagePath!);
        final bytes = data.buffer.asUint8List();
        resizeResult = await _resizeImage(bytes);
        imageBase64 = resizeResult['base64'];
        originalWidth = resizeResult['width'];
        originalHeight = resizeResult['height'];
        resizeScale = resizeResult['scale'];

        imageForAnalysis = _selectedImagePath!;
      }

      final analysisResult =
          await _menuAnalysisService.analyzeMenu(imageBase64);

      if (!mounted) return;

      widget.onAnalysisComplete(
        MenuAnalysisResultPage(
          image: imageForAnalysis,
          boundingPolys: analysisResult['extractedList'],
          menuItems: analysisResult['menuItems'],
          originalWidth: originalWidth,
          originalHeight: originalHeight,
          resizeScale: resizeScale,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing menu: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzingMenu = false;
      });
    }
  }

  Widget _buildTakenPhotoPreview() {
    if (_takenPhoto == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImagePath = null;
          _isTakenPhotoSelected = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 300,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isTakenPhotoSelected
                    ? AppTheme.accentColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: Offset(0, _isTakenPhotoSelected ? 3 : 2),
              ),
            ],
            border: Border.all(
              color: _isTakenPhotoSelected
                  ? AppTheme.accentColor
                  : Colors.grey[300]!,
              width: _isTakenPhotoSelected ? 3 : 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (kIsWeb && _webImage != null)
                  Image.memory(
                    _webImage!,
                    fit: BoxFit.cover,
                  )
                else if (!kIsWeb)
                  Image.file(
                    File(_takenPhoto!.path),
                    fit: BoxFit.cover,
                  ),
                if (_isTakenPhotoSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      onPressed: () {
                        setState(() {
                          _takenPhoto = null;
                          _webImage = null;
                          _isTakenPhotoSelected = false;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    // Create a list of items to display in the grid
    final List<Widget> gridItems = [];

    // Add the taken photo as the first item if available
    if (_takenPhoto != null) {
      gridItems.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedImagePath = null;
              _isTakenPhotoSelected = true;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isTakenPhotoSelected
                    ? AppTheme.accentColor
                    : Colors.grey[300]!,
                width: _isTakenPhotoSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (kIsWeb && _webImage != null)
                    Image.memory(
                      _webImage!,
                      fit: BoxFit.cover,
                    )
                  else if (!kIsWeb)
                    Image.file(
                      File(_takenPhoto!.path),
                      fit: BoxFit.cover,
                    ),
                  if (_isTakenPhotoSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Add the sample images
    for (final imagePath in _imageFiles) {
      final isSelected = imagePath == _selectedImagePath;

      gridItems.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedImagePath = imagePath;
              _isTakenPhotoSelected = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.accentColor : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: gridItems.length,
      itemBuilder: (context, index) => gridItems[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a menu image',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textColor,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick Image'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Menu Images',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildImageGrid(),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed:
                    (_selectedImagePath != null || _takenPhoto != null) &&
                            !_isAnalyzingMenu
                        ? _analyzeMenu
                        : null,
                icon: _isAnalyzingMenu
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: const Text('Analyze Menu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
