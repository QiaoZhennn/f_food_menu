import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/food_item.dart';

class ExtractMenuService {
  /// Extracts menu items from a base64-encoded image
  ///
  /// Returns a list of [FoodItem] objects if successful
  /// Throws an exception if the request fails
  Future<List<FoodItem>> extractMenuFromImage(String imageBase64) async {
    final response = await http.post(
      Uri.parse(extractMenuUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'imageBase64': imageBase64,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['menuItems']['items'] as List)
          .map((item) => FoodItem.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to extract menu items: ${response.statusCode}');
    }
  }
}
