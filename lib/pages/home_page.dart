import 'package:flutter/material.dart';
import '../models/food_item.dart';
import 'menu_list_page.dart';
import 'extracted_menu_page.dart';
import 'generated_image_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'menu_analysis_result_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<FoodItem> _extractedMenuItems = [];
  Widget? _analysisResultWidget;
  FoodItem? _selectedFoodItem;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    if (kIsWeb) {
      // For web, check Firebase Auth directly
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _isSignedIn = user != null;
        });
      }
    } else {
      // For mobile, use SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isSignedIn = prefs.getBool('isSignedIn') ?? false;
      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
        });
      }
    }
  }

  void _onSignedIn() {
    setState(() {
      _isSignedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignedIn) {
      return AuthPage(onSignedIn: _onSignedIn);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Visualizer'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MenuListPage(
            onMenuExtracted: (menuItems) {
              setState(() {
                _extractedMenuItems = menuItems;
              });
            },
            onAnalysisComplete: (widget) {
              setState(() {
                _analysisResultWidget = widget;
                _selectedIndex = 1; // Navigate to Extracted Menu tab
              });
            },
          ),
          _analysisResultWidget != null
              ? MenuAnalysisResultPage(
                  image:
                      (_analysisResultWidget as MenuAnalysisResultPage).image,
                  boundingPolys:
                      (_analysisResultWidget as MenuAnalysisResultPage)
                          .boundingPolys,
                  menuItems: (_analysisResultWidget as MenuAnalysisResultPage)
                      .menuItems,
                  originalWidth:
                      (_analysisResultWidget as MenuAnalysisResultPage)
                          .originalWidth,
                  originalHeight:
                      (_analysisResultWidget as MenuAnalysisResultPage)
                          .originalHeight,
                  resizeScale: (_analysisResultWidget as MenuAnalysisResultPage)
                      .resizeScale,
                  onMenuItemSelected: (foodItem) {
                    setState(() {
                      _selectedFoodItem = foodItem;
                      _selectedIndex = 2; // Navigate to Generated Image tab
                    });
                  },
                )
              : ExtractedMenuPage(
                  menuItems: _extractedMenuItems,
                  onFoodItemSelected: (foodItem) {
                    setState(() {
                      _selectedFoodItem = foodItem;
                      _selectedIndex = 2; // Navigate to Generated Image tab
                    });
                  },
                ),
          GeneratedImagePage(foodItem: _selectedFoodItem),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Extracted Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Generated Image',
          ),
        ],
      ),
    );
  }
}
