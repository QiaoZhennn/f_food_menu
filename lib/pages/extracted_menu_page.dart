import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_item.dart';
import '../constants.dart';
// import 'generated_image_page.dart';

class ExtractedMenuPage extends StatefulWidget {
  final List<FoodItem> foodItems;
  final Function(String imageUrl, String prompt) onImageGenerated;

  const ExtractedMenuPage({
    super.key,
    required this.foodItems,
    required this.onImageGenerated,
  });

  @override
  State<ExtractedMenuPage> createState() => _ExtractedMenuPageState();
}

class _ExtractedMenuPageState extends State<ExtractedMenuPage> {
  bool _isGeneratingImage = false;
  String? _processingItemName;

  Future<void> _generateImageForFood(FoodItem item) async {
    setState(() {
      _isGeneratingImage = true;
      _processingItemName = item.name;
    });

    try {
      final response = await http.post(
        Uri.parse(generateImageUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': item.name,
          'ingredients': item.ingredients,
          'drinkFlavor': item.drinkFlavor,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        widget.onImageGenerated(data['imageUrl'], data['prompt']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingImage = false;
        _processingItemName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extracted Menu Items')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: widget.foodItems.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = widget.foodItems[index];
          final isProcessing = item.name == _processingItemName;

          return ListTile(
            title: Text(item.name),
            subtitle: item.drinkFlavor.isNotEmpty
                ? Text(item.drinkFlavor)
                : item.ingredients.isNotEmpty
                    ? Text(item.ingredients.join(', '))
                    : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.price != null)
                  Text('\$${item.price!.toStringAsFixed(2)}'),
                if (isProcessing) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ],
            ),
            onTap: (_isGeneratingImage && !isProcessing)
                ? null
                : () => _generateImageForFood(item),
          );
        },
      ),
    );
  }
}
