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
import '../services/extract_menu_service.dart';
import '../services/menu_analysis_service.dart';
import 'menu_analysis_result_page.dart';
// import 'extracted_menu_page.dart';

class MenuListPage extends StatefulWidget {
  final Function(List<FoodItem>) onMenuExtracted;

  const MenuListPage({
    super.key,
    required this.onMenuExtracted,
  });

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  String? _selectedImagePath;
  List<String> _imageFiles = [];
  bool _isExtractingMenu = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _takenPhoto;
  Uint8List? _webImage;
  bool _isTakenPhotoSelected = false;
  final _extractMenuService = ExtractMenuService();
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
            _webImage = bytes;
            _takenPhoto = photo;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _extractMenu() async {
    if (!_isTakenPhotoSelected && _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an image or take a photo first')),
      );
      return;
    }

    setState(() {
      _isExtractingMenu = true;
    });

    try {
      String imageBase64;
      if (_isTakenPhotoSelected && _takenPhoto != null) {
        final bytes = await _takenPhoto!.readAsBytes();
        final resizeResult = await _resizeImage(bytes);
        imageBase64 = resizeResult['base64'];
      } else {
        imageBase64 = await _getImageBase64(_selectedImagePath!);
      }

      final items = await _extractMenuService.extractMenuFromImage(imageBase64);
      widget.onMenuExtracted(items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isExtractingMenu = false;
      });
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuAnalysisResultPage(
            image: imageForAnalysis,
            boundingPolys: analysisResult['extractedList'],
            menuItems: analysisResult['menuItems'],
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            resizeScale: resizeScale,
          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Visualizer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Take a photo of menu OR choose an example menu:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Container(
              height: 350,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_takenPhoto != null) _buildTakenPhotoPreview(),
                  ..._imageFiles.map((imagePath) {
                    final isSelected = imagePath == _selectedImagePath;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImagePath = imagePath;
                          _isTakenPhotoSelected = false;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 300,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.identity()
                            ..translate(0.0, isSelected ? -8.0 : 0.0, 0.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppTheme.accentColor.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: Offset(0, isSelected ? 3 : 2),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : Colors.grey[300]!,
                              width: isSelected ? 3 : 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                ),
                                if (isSelected)
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isExtractingMenu ? null : _takePhoto,
                    child: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isExtractingMenu || _selectedImagePath == null)
                        ? null
                        : _extractMenu,
                    child: _isExtractingMenu
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Extract Menu'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isExtractingMenu || _isAnalyzingMenu)
                        ? null
                        : _analyzeMenu,
                    child: _isAnalyzingMenu
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Analyze Menu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
