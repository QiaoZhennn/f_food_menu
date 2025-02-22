import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../models/food_item.dart';

class ImageGenerationService {
  static Future<Map<String, String>> generateImage(FoodItem item) async {
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
        return {
          'imageUrl': data['imageUrl'],
          'prompt': data['prompt'],
        };
      }
      throw 'Failed to generate image';
    } catch (e) {
      throw 'Error generating image: $e';
    }
  }
}
