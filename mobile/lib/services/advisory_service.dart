import 'dart:convert';
import 'package:http/http.dart' as http;
import 'crop_prediction_service.dart';

class AdvisoryService {
  static String get _baseUrl => CropPredictionService.backendUrl;

  static Future<Map<String, dynamic>> fertilizerRecommendation({
    required String crop,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    double ph = 6.5,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/fertilizer/recommend'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'crop': crop,
            'nitrogen': nitrogen,
            'phosphorus': phosphorus,
            'potassium': potassium,
            'ph': ph,
          }),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> marketPrices({
    required String crop,
    String location = 'India',
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/market-prices'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'crop': crop, 'location': location}),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> chat({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message, 'history': history}),
        )
        .timeout(const Duration(seconds: 40));
    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map ? body['detail'] : null;
      throw Exception(
          detail ?? 'Server request failed (${response.statusCode})');
    }
    if (body is! Map<String, dynamic>) {
      throw Exception('Server returned an invalid response.');
    }
    return body;
  }
}
