import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../constants.dart';
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

  Future<String> _getImageBase64(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    return base64Encode(bytes);
  }

  Future<void> _extractMenu() async {
    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isExtractingMenu = true;
    });

    try {
      final imageBase64 = await _getImageBase64(_selectedImagePath!);

      final response = await http.post(
        Uri.parse(apiBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'path': '/extract-menu',
          'imageBase64': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['menuItems']['items'] as List)
            .map((item) => FoodItem.fromJson(item))
            .toList();

        widget.onMenuExtracted(items);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to extract menu items')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isExtractingMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select a menu image:'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: _imageFiles.isEmpty
                  ? const Center(
                      child: Text('No images found in assets/image/'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageFiles.length,
                      itemBuilder: (context, index) {
                        final imagePath = _imageFiles[index];
                        final isSelected = imagePath == _selectedImagePath;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImagePath = imagePath;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              imagePath,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            if (_selectedImagePath != null)
              ElevatedButton(
                onPressed: _isExtractingMenu ? null : _extractMenu,
                child: _isExtractingMenu
                    ? const CircularProgressIndicator()
                    : const Text('Extract Menu'),
              ),
          ],
        ),
      ),
    );
  }
}
