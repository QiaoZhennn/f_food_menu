import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class MenuAnalysisService {
  /// Analyzes a menu image and returns bounding boxes for detected elements
  ///
  /// Takes a base64-encoded image string and returns analysis results
  Future<List<Map<String, dynamic>>> analyzeMenu(String imageBase64) async {
    final response = await http.post(
      Uri.parse(menuAnalysisUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'imageBase64': imageBase64,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Based on the sample response, data contains text annotations
      if (data is Map &&
          data.containsKey('textAnnotations') &&
          data['textAnnotations'] is List) {
        return List<Map<String, dynamic>>.from(data['textAnnotations']);
      }

      // Alternative structure - single annotation
      if (data is Map && data.containsKey('boundingPoly')) {
        return [data as Map<String, dynamic>];
      }

      // Fallback - if we reached here, the structure is different than expected
      print('Unexpected API response format: $data');
      return [];
    } else {
      throw Exception('Failed to analyze menu: ${response.statusCode}');
    }
  }
}
