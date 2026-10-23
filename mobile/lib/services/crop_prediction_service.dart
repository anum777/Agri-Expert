import 'package:http/http.dart' as http;
import 'dart:convert';

class CropPredictionService {
  // ============================================================
  // BACKEND URL CONFIGURATION
  // Set the deployed Render URL here after deployment:
  // ============================================================
  static const String _deployedUrl = 'https://REPLACE_WITH_YOUR_RENDER_URL.onrender.com';

  // For local development override: pass --dart-define=BACKEND_URL=http://localhost:8000
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _deployedUrl,
  );

  /// Fetch current NPK sensor data from backend (sent by ESP32)
  static Future<Map<String, dynamic>?> getNPKData() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/sensor/npk'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching NPK data: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on http.ClientException catch (e) {
      print('Network error fetching NPK data: $e');
      return null;
    } catch (e) {
      print('Error fetching NPK data: $e');
      return null;
    }
  }

  /// Send crop prediction request with NPK + Weather data
  static Future<Map<String, dynamic>?> predictCrop({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double rainfall,
    double ph = 6.5,
  }) async {
    try {
      final payload = {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'rainfall': rainfall,
        'ph': ph,
      };

      print('[CropService] Sending prediction request to $backendUrl/predict');
      print('[CropService] Payload: $payload');

      final response = await http
          .post(
            Uri.parse('$backendUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 20));

      print('[CropService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('[CropService] Prediction: ${result['recommended_crop']} (${result['confidence']})');
        return result;
      } else if (response.statusCode == 422) {
        print('[CropService] Validation error: ${response.body}');
        return {'error': 'Invalid input parameters', 'detail': response.body};
      } else if (response.statusCode >= 500) {
        print('[CropService] Server error: ${response.statusCode} - ${response.body}');
        return {'error': 'Server error. Please try again.', 'status': response.statusCode};
      } else {
        print('[CropService] Unexpected status: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on http.ClientException catch (e) {
      print('[CropService] Network error: $e');
      return {'error': 'Cannot connect to server. Check your internet connection.'};
    } catch (e) {
      print('[CropService] Unexpected error: $e');
      return {'error': 'Unexpected error: $e'};
    }
  }

  /// Check if backend is reachable
  static Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
