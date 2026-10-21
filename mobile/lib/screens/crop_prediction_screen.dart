import 'package:flutter/material.dart';
import '../services/crop_prediction_service.dart';
import '../services/weather_service.dart';

class CropPredictionScreen extends StatefulWidget {
  @override
  _CropPredictionScreenState createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  // NPK sensor data
  double _nitrogen = 0;
  double _phosphorus = 0;
  double _potassium = 0;

  // Weather data
  double _temperature = 0;
  double _humidity = 0;
  double _rainfall = 0;

  // Prediction result
  String _recommendedCrop = '';
  double _confidence = 0;
  bool _predictionMade = false;

  @override
  void initState() {
    super.initState();
    _fetchDataAndPredict();
  }

  Future<void> _fetchDataAndPredict() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch NPK data from backend (sent by ESP32)
      final npkData = await CropPredictionService.getNPKData();
      if (npkData != null) {
        setState(() {
          _nitrogen = (npkData['nitrogen'] ?? 0).toDouble();
          _phosphorus = (npkData['phosphorus'] ?? 0).toDouble();
          _potassium = (npkData['potassium'] ?? 0).toDouble();
        });
      } else {
        setState(() => _errorMessage = 'Failed to fetch NPK sensor data');
        return;
      }

      // Fetch weather data
      // You'll need to get latitude/longitude from your app's LocationScreen
      final weatherData = await WeatherService().fetchWeather(
        28.7041,
        77.1025,
      );

      if (weatherData != null) {
        setState(() {
          _temperature = (weatherData['main']['temp'] ?? 20).toDouble();
          _humidity = (weatherData['main']['humidity'] ?? 50).toDouble();
          // Rainfall - check if available
          _rainfall = 0.0;
          if (weatherData['rain'] != null) {
            if (weatherData['rain']['1h'] != null) {
              _rainfall = (weatherData['rain']['1h'] ?? 0).toDouble();
            } else if (weatherData['rain']['3h'] != null) {
              _rainfall = (weatherData['rain']['3h'] ?? 0).toDouble();
            }
          }
        });
      } else {
        setState(() => _errorMessage = 'Failed to fetch weather data');
        return;
      }

      // Make crop prediction
      final prediction = await CropPredictionService.predictCrop(
        nitrogen: _nitrogen,
        phosphorus: _phosphorus,
        potassium: _potassium,
        temperature: _temperature,
        humidity: _humidity,
        rainfall: _rainfall,
      );

      if (prediction != null) {
        setState(() {
          _recommendedCrop = prediction['recommended_crop'] ?? 'Unknown';
          _confidence = (prediction['confidence'] ?? 0).toDouble();
          _predictionMade = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to get crop prediction';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Recommendation'),
        backgroundColor: Color(0xFF795548),
      ),
      backgroundColor: Color(0xFFF5E9E2),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(_errorMessage, textAlign: TextAlign.center),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchDataAndPredict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8D6E63),
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sensor Data Card
                        Card(
                          color: Color(0xFFD7CCC8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NPK Sensor Data (from ESP32)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6D4C41),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _sensorDataColumn('N', _nitrogen),
                                    _sensorDataColumn('P', _phosphorus),
                                    _sensorDataColumn('K', _potassium),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Weather Data Card
                        Card(
                          color: Color(0xFFBCAAA4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weather Data',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6D4C41),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _weatherDataColumn(
                                      'Temp',
                                      '${_temperature.toStringAsFixed(1)}°C',
                                      Icons.thermostat,
                                    ),
                                    _weatherDataColumn(
                                      'Humidity',
                                      '${_humidity.toStringAsFixed(0)}%',
                                      Icons.water_drop,
                                    ),
                                    _weatherDataColumn(
                                      'Rainfall',
                                      '${_rainfall.toStringAsFixed(1)} mm',
                                      Icons.grain,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Prediction Result Card
                        if (_predictionMade)
                          Card(
                            color: Color(0xFFE8D4C4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 64,
                                    color: Colors.green[700],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Recommended Crop',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _recommendedCrop.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _confidence,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green[700]!,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDataAndPredict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8D6E63),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Refresh',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _sensorDataColumn(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6D4C41),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
      ],
    );
  }

  Widget _weatherDataColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF6D4C41), size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6D4C41),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
      ],
    );
  }
}
