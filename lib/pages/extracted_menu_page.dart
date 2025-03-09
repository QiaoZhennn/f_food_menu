import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
import '../models/food_item.dart';
// import '../constants.dart';
import '../services/image_search_service.dart';
// import 'generated_image_page.dart';

class ExtractedMenuPage extends StatelessWidget {
  final List<FoodItem> menuItems;
  final Function(FoodItem) onFoodItemSelected;
  final Widget? analysisResultWidget;

  const ExtractedMenuPage({
    super.key,
    required this.menuItems,
    required this.onFoodItemSelected,
    this.analysisResultWidget,
  });

  @override
  Widget build(BuildContext context) {
    // If we have an analysis result widget, show it
    if (analysisResultWidget != null) {
      return analysisResultWidget!;
    }

    // Otherwise show the list of extracted menu items
    return menuItems.isEmpty
        ? const Center(child: Text('No menu items extracted yet'))
        : ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(
                  item.drinkFlavor.isNotEmpty
                      ? 'Flavor: ${item.drinkFlavor}'
                      : item.ingredients.isNotEmpty
                          ? 'Ingredients: ${item.ingredients.join(", ")}'
                          : '',
                ),
                trailing: Text(
                  item.price != null
                      ? '\$${item.price!.toStringAsFixed(2)}'
                      : '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => onFoodItemSelected(item),
              );
            },
          );
  }
}
