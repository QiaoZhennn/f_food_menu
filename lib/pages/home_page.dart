import 'package:flutter/material.dart';
import '../models/food_item.dart';
import 'menu_list_page.dart';
import 'extracted_menu_page.dart';
import 'generated_image_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<FoodItem>? _extractedItems;
  String? _generatedImageUrl;
  String? _generatedPrompt;

  void onMenuExtracted(List<FoodItem> items) {
    setState(() {
      _extractedItems = items;
      _selectedIndex = 1; // Switch to extracted menu tab
    });
  }

  void onImageGenerated(String imageUrl, String prompt) {
    setState(() {
      _generatedImageUrl = imageUrl;
      _generatedPrompt = prompt;
      _selectedIndex = 2; // Switch to generated image tab
    });
  }

  @override
  Widget build(BuildContext context) {
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
          if (_generatedImageUrl != null && _generatedPrompt != null)
            GeneratedImagePage(
              imageUrl: _generatedImageUrl!,
              prompt: _generatedPrompt!,
            )
          else
            const Center(child: Text('No image generated yet')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Only allow navigation if data is available
          if (index == 1 && _extractedItems == null) return;
          if (index == 2 && _generatedImageUrl == null) return;
          setState(() {
            _selectedIndex = index;
          });
        },
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
