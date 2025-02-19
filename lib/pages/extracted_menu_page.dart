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

  String _constructPrompt(FoodItem item) {
    final ingredientsText =
        item.ingredients.isNotEmpty ? ', ${item.ingredients.join(", ")}' : '';
    return 'Generate a realistic food image: ${item.name}$ingredientsText';
  }

  Future<void> _generateImageForFood(FoodItem item) async {
    setState(() {
      _isGeneratingImage = true;
      _processingItemName = item.name;
    });

    try {
      final prompt = _constructPrompt(item);
      final response = await http.post(
        Uri.parse(apiBaseUrl + '/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;

        widget.onImageGenerated(data['imageUrl'], prompt);
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
            subtitle: item.ingredients.isNotEmpty
                ? Text('Ingredients: ${item.ingredients.join(", ")}')
                : null,
            trailing: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('\$${item.price.toStringAsFixed(2)}'),
            onTap: (_isGeneratingImage && !isProcessing)
                ? null
                : () => _generateImageForFood(item),
          );
        },
      ),
    );
  }
}
