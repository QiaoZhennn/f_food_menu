import 'package:flutter/material.dart';
import '../models/food_item.dart';
import 'menu_list_page.dart';
import 'extracted_menu_page.dart';
import 'generated_image_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_page.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.getBool('isSignedIn') ?? false;

    if (mounted) {
      setState(() {
        _isSignedIn = isSignedIn;
      });
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onTabChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Menu Images',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Extracted Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.generating_tokens),
            label: 'Generated Image',
          ),
        ],
      ),
    );
  }
}
