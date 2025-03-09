import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class MenuAnalysisService {
  /// Analyzes a menu image and returns bounding boxes for detected elements
  ///
  /// Takes a base64-encoded image string and returns analysis results
  Future<Map<String, dynamic>> analyzeMenu(String imageBase64) async {
    final response = await http.post(
      Uri.parse(menuAnalysisUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'imageBase64': imageBase64,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = {
        'extractedList': <Map<String, dynamic>>[],
        'menuItems': <Map<String, dynamic>>[],
      };

      // Parse extracted list
      if (data is Map &&
          data.containsKey('extractedList') &&
          data['extractedList'] is List) {
        result['extractedList'] =
            List<Map<String, dynamic>>.from(data['extractedList']);
      }

      // Parse menu items from GPT
      if (data is Map &&
          data.containsKey('menuItems') &&
          data['menuItems'] is Map &&
          data['menuItems'].containsKey('items') &&
          data['menuItems']['items'] is List) {
        result['menuItems'] =
            List<Map<String, dynamic>>.from(data['menuItems']['items']);
      }

      return result;
    } else {
      throw Exception('Failed to analyze menu: ${response.statusCode}');
    }
  }
}
