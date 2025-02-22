import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class ImageSearchService {
  static Future<List<String>> searchImages(String query) async {
    try {
      final response = await http.post(
        Uri.parse(searchImagesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['thumbnails'] != null) {
          return List<String>.from(data['thumbnails']);
        }
      }
      print('Error: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error searching image: $e');
      return [];
    }
  }
}
