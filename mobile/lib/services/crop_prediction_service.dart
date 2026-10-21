import 'package:http/http.dart' as http;
import 'dart:convert';

class CropPredictionService {
  // For Web/Chrome: http://localhost:8000
  // For Android Emulator: http://10.0.2.2:8000
  // For Real Device: Pass with --dart-define=BACKEND_URL=http://<YOUR_PC_IP>:8000
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Fetch current NPK sensor data from backend (sent by ESP32)
  static Future<Map<String, dynamic>?> getNPKData() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/sensor/npk'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching NPK data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
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
  }) async {
    try {
      final payload = {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'rainfall': rainfall,
      };

      final response = await http
          .post(
            Uri.parse('$backendUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error predicting crop: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
