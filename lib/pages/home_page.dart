import 'package:flutter/material.dart';
import '../models/food_item.dart';
import 'menu_list_page.dart';
import 'extracted_menu_page.dart';
import 'generated_image_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_page.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<FoodItem>? _extractedItems;
  bool _isSignedIn = false;
  FoodItem? _selectedFoodItem;

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

  void onMenuExtracted(List<FoodItem> items) {
    setState(() {
      _extractedItems = items;
      _selectedIndex = 1; // Switch to extracted menu tab
    });
  }

  void onImageGenerated(String imageUrl, String prompt, FoodItem foodItem) {
    setState(() {
      _selectedFoodItem = foodItem;
      _selectedIndex = 2;
    });
  }

  void _onTabChanged(int index) {
    if (index == 1) {
      setState(() {
        _selectedFoodItem = null;
      });
    }

    if (index == 1 && _extractedItems == null) return;
    if (index == 2 && _selectedFoodItem == null) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignedIn) {
      return AuthPage(onSignedIn: _onSignedIn);
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MenuListPage(onMenuExtracted: onMenuExtracted),
          if (_extractedItems != null)
            ExtractedMenuPage(
              foodItems: _extractedItems!,
              onImageGenerated: onImageGenerated,
            )
          else
            const Center(child: Text('No menu items extracted yet')),
          if (_selectedFoodItem != null)
            GeneratedImagePage(
              foodItem: _selectedFoodItem,
            )
          else
            const Center(child: Text('No food item selected')),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.accentColor,
            unselectedItemColor: AppTheme.primaryColor.withOpacity(0.5),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            elevation: 0,
            onTap: _onTabChanged,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.camera_alt_outlined,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
                activeIcon: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.accentColor,
                ),
                label: 'Menu Scanner',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.restaurant_menu_outlined,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
                activeIcon: const Icon(
                  Icons.restaurant_menu,
                  color: AppTheme.accentColor,
                ),
                label: 'Menu Items',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.image_outlined,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
                activeIcon: const Icon(
                  Icons.image,
                  color: AppTheme.accentColor,
                ),
                label: 'Generated Image',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
