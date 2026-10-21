import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'l10n/app_localizations.dart';
import 'services/firebase_service.dart';
import 'services/crop_prediction_service.dart';
import 'services/weather_service.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signOut();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?._setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agri Expert',
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AuthWrapper(),
    );
  }
}

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      tooltip: l10n.tr('language'),
      icon: const Icon(Icons.language_rounded),
      onSelected: (value) {
        MyApp.setLocale(context, Locale(value));
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Icon(
                localeCode == 'en' ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(l10n.tr('english')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'hi',
          child: Row(
            children: [
              Icon(
                localeCode == 'hi' ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(l10n.tr('hindi')),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return DashboardScreen();
        }
        return AuthScreen();
      },
    );
  }
}

// ============= AUTH SCREEN =============
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showOTPInput = false;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _verificationId = '';
  bool _isLoading = false;
  String _message = '';

  void _sendOTP() async {
    final l10n = context.l10n;
    setState(() => _isLoading = true);
    String phone = '+91' + _phoneController.text.trim();

    await FirebaseService().verifyPhoneNumber(
      phone,
      (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _showOTPInput = true;
          _isLoading = false;
          _message = l10n.trArgs('otpSentTo', {'phone': _phoneController.text});
        });
      },
      (errorMessage) {
        setState(() {
          _isLoading = false;
          _message = errorMessage;
        });
      },
    );
  }

  void _verifyOTP() async {
    final l10n = context.l10n;
    setState(() => _isLoading = true);
    String otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      setState(() {
        _isLoading = false;
        _message = l10n.tr('invalidOtpLength');
      });
      return;
    }

    UserCredential? result =
        await FirebaseService().signInWithOTP(_verificationId, otp);
    setState(() {
      _isLoading = false;
      _message =
          result != null ? l10n.tr('loginSuccess') : l10n.tr('loginInvalid');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F6EF),
              Color(0xFFE5F0E3),
              Color(0xFFF7F4EE),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.topRight,
                          child: LanguageSwitcherButton(),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.leaf.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            color: AppTheme.forest,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.tr('welcomeTitle'),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tr('welcomeSubtitle'),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!_showOTPInput) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: l10n.tr('mobileNumber'),
                              hintText: l10n.tr('mobileHint'),
                              prefixText: '+91 ',
                              prefixIcon: const Icon(Icons.phone_iphone),
                            ),
                            maxLength: 10,
                          ),
                          const SizedBox(height: 14),
                          if (_message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(
                                _message,
                                style: TextStyle(
                                  color: AppTheme.soil,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _sendOTP,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sms_outlined),
                            label: Text(
                              _isLoading
                                  ? l10n.tr('sendingOtp')
                                  : l10n.tr('sendOtp'),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.tr('verificationCode'),
                              hintText: l10n.tr('verificationHint'),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            maxLength: 6,
                          ),
                          const SizedBox(height: 14),
                          if (_message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(
                                _message,
                                style: TextStyle(
                                  color: AppTheme.soil,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _verifyOTP,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.verified_user_outlined),
                            label: Text(
                              _isLoading
                                  ? l10n.tr('verifying')
                                  : l10n.tr('verifyOtp'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showOTPInput = false;
                                _message = '';
                                _phoneController.clear();
                                _otpController.clear();
                              });
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(l10n.tr('backToPhone')),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============= DASHBOARD SCREEN =============
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _logout() async {
    await FirebaseService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('dashboardTitle')),
        actions: [
          const LanguageSwitcherButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3E8), Color(0xFFF7F4EE)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.forest.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.grass_rounded,
                              size: 40,
                              color: AppTheme.forest,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.tr('welcomeTitle'),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.tr('dashboardBlurb'),
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.ink.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _FeatureChip(
                                  icon: Icons.science_outlined,
                                  label: l10n.tr('npkInputs')),
                              _FeatureChip(
                                  icon: Icons.location_on_outlined,
                                  label: l10n.tr('liveLocation')),
                              _FeatureChip(
                                  icon: Icons.cloud_outlined,
                                  label: l10n.tr('weatherInsights')),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationWeatherScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.explore_outlined),
                            label: Text(l10n.tr('getLocationWeather')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.forest.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.forest.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.forest),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.forest,
            ),
          ),
        ],
      ),
    );
  }
}

// ============= LOCATION & WEATHER SCREEN =============
class LocationWeatherScreen extends StatefulWidget {
  @override
  _LocationWeatherScreenState createState() => _LocationWeatherScreenState();
}

class _LocationWeatherScreenState extends State<LocationWeatherScreen> {
  bool _isLoadingLocation = false;
  bool _isLoadingWeather = false;

  double? _latitude;
  double? _longitude;
  String _locationName = '';

  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _getLocation();
      }
    });
  }

  Future<void> _getLocation() async {
    final l10n = context.l10n;
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('locationServicesDisabled'))),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.tr('locationPermissionDenied'))),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName =
            'Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}';
      });

      final readableLocation = await _reverseGeocode(_latitude!, _longitude!);
      if (readableLocation != null && mounted) {
        setState(() {
          _locationName = readableLocation;
        });
      }

      await _getWeather();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trArgs('errorPrefix', {'error': '$e'}))),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getWeather() async {
    final l10n = context.l10n;
    if (_latitude == null || _longitude == null) return;

    setState(() => _isLoadingWeather = true);
    try {
      final backendUrl = CropPredictionService.backendUrl;
      final backendUri = Uri.parse(
        '$backendUrl/weather?latitude=$_latitude&longitude=$_longitude',
      );

      Map<String, dynamic>? normalizedWeather;

      try {
        final response =
            await http.get(backendUri).timeout(Duration(seconds: 10));
        if (response.statusCode == 200) {
          final rawData = json.decode(response.body) as Map<String, dynamic>;
          normalizedWeather = _normalizeWeatherData(rawData);
        }
      } catch (_) {
        // Fallback is handled below; no-op here.
      }

      if (normalizedWeather == null) {
        final fallbackWeather = await WeatherService().fetchWeather(
          _latitude!,
          _longitude!,
        );

        if (fallbackWeather == null) {
          throw Exception(
            l10n.trArgs('weatherUnavailable', {'backendUrl': backendUrl}),
          );
        }

        normalizedWeather = _normalizeWeatherData(fallbackWeather);
      }

      if (mounted) {
        setState(() {
          _weatherData = normalizedWeather;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.trArgs('weatherErrorPrefix', {'error': '$e'})),
        ),
      );
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=jsonv2',
    );

    try {
      final response = await http.get(url, headers: {
        'Accept-Language': 'en',
      }).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final address =
          (data['address'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final city = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['county'];
      final state = address['state'];
      final country = address['country'];

      final parts = [city, state, country]
          .where((part) => part != null && '$part'.isNotEmpty)
          .toList();
      if (parts.isEmpty) {
        final displayName = data['display_name']?.toString();
        return (displayName != null && displayName.isNotEmpty)
            ? displayName
            : null;
      }

      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalizeWeatherData(Map<String, dynamic> raw) {
    final main = (raw['main'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final rain = (raw['rain'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final wind = (raw['wind'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final clouds =
        (raw['clouds'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final source = (raw['source'] as String?)?.toLowerCase() ?? '';

    if (source == 'open-meteo') {
      return {
        'weather': raw['weather'] ?? 'Clear',
        'description': raw['description'] ?? '',
        'temperature': (main['temp'] as num?)?.toDouble() ?? 0.0,
        'humidity': (main['humidity'] as num?)?.toDouble() ?? 0.0,
        'rainfall': (rain['1h'] as num?)?.toDouble() ?? 0.0,
        'wind_speed': (wind['speed'] as num?)?.toDouble() ?? 0.0,
        'pressure': (main['pressure'] as num?)?.toDouble() ?? 0.0,
        'visibility': (raw['visibility'] as num?)?.toDouble() ?? 10000.0,
        'cloudiness': (clouds['all'] as num?)?.toDouble() ?? 0.0,
        'name': raw['location'] ?? raw['name'] ?? 'Current location',
        'sys': {'country': raw['country'] ?? ''},
        'source': 'fallback',
      };
    }

    if (raw.containsKey('temperature') || raw.containsKey('humidity')) {
      return {
        'weather': raw['weather'] ?? 'Clear',
        'description': raw['description'] ?? '',
        'temperature': (raw['temperature'] as num?)?.toDouble() ?? 0.0,
        'humidity': (raw['humidity'] as num?)?.toDouble() ?? 0.0,
        'rainfall': (raw['rainfall'] as num?)?.toDouble() ?? 0.0,
        'wind_speed': (raw['wind_speed'] as num?)?.toDouble() ?? 0.0,
        'pressure': (raw['pressure'] as num?)?.toDouble() ?? 0.0,
        'visibility': (raw['visibility'] as num?)?.toDouble() ?? 10000.0,
        'cloudiness': (raw['cloudiness'] as num?)?.toDouble() ?? 0.0,
        'name': raw['location'] ?? raw['name'] ?? 'Current location',
        'sys': {'country': raw['country'] ?? ''},
        'source': (raw['source'] ?? 'fallback').toString(),
      };
    }

    return {
      'weather': raw['weather'] ?? 'Clear',
      'description': raw['description'] ?? '',
      'temperature': (main['temp'] as num?)?.toDouble() ?? 0.0,
      'humidity': (main['humidity'] as num?)?.toDouble() ?? 0.0,
      'rainfall': (rain['1h'] as num?)?.toDouble() ?? 0.0,
      'wind_speed': (wind['speed'] as num?)?.toDouble() ?? 0.0,
      'pressure': (main['pressure'] as num?)?.toDouble() ?? 0.0,
      'visibility': (raw['visibility'] as num?)?.toDouble() ?? 10000.0,
      'cloudiness': (clouds['all'] as num?)?.toDouble() ?? 0.0,
      'name': raw['name'] ?? 'Current location',
      'sys': raw['sys'] ?? {'country': ''},
      'source': 'backend',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final displayLocationName =
        _locationName.isEmpty ? l10n.tr('tapToGetLocation') : _locationName;
    final coordinates = _latitude != null && _longitude != null
        ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
        : '--';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('locationWeatherTitle')),
        actions: const [LanguageSwitcherButton()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3E8), Color(0xFFF7F4EE)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.forest.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.forest,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayLocationName,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.trArgs(
                            'coordinates', {'coordinates': coordinates}),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoadingLocation ? null : _getLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location_outlined),
                        label: Text(
                          _isLoadingLocation
                              ? l10n.tr('detectingLocation')
                              : l10n.tr('refreshLocation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingWeather)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_weatherData != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (_weatherData?['weather'] ??
                                            l10n.tr('unknown'))
                                        .toString(),
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    (_weatherData?['description'] ?? '')
                                        .toString(),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color:
                                          AppTheme.ink.withValues(alpha: 0.72),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: AppTheme.forest.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                _weatherData?['source'] == 'backend'
                                    ? l10n.tr('backend')
                                    : l10n.tr('fallback'),
                                style: const TextStyle(
                                  color: AppTheme.forest,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _WeatherMetric(
                              icon: Icons.thermostat_outlined,
                              label: l10n.tr('temperature'),
                              value:
                                  '${_weatherData?['temperature']?.toStringAsFixed(1) ?? '--'}°C',
                            ),
                            _WeatherMetric(
                              icon: Icons.opacity_outlined,
                              label: l10n.tr('humidity'),
                              value: '${_weatherData?['humidity'] ?? '--'}%',
                            ),
                            _WeatherMetric(
                              icon: Icons.air_outlined,
                              label: l10n.tr('wind'),
                              value:
                                  '${_weatherData?['wind_speed']?.toStringAsFixed(2) ?? '--'} m/s',
                            ),
                            _WeatherMetric(
                              icon: Icons.speed_outlined,
                              label: l10n.tr('pressure'),
                              value: '${_weatherData?['pressure'] ?? '--'} hPa',
                            ),
                            _WeatherMetric(
                              icon: Icons.visibility_outlined,
                              label: l10n.tr('visibility'),
                              value:
                                  '${((_weatherData?['visibility'] as num?) ?? 10000).toInt() ~/ 1000} km',
                            ),
                            _WeatherMetric(
                              icon: Icons.cloud_outlined,
                              label: l10n.tr('cloudCover'),
                              value: '${_weatherData?['cloudiness'] ?? '--'}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.trArgs('locationLabel', {
                            'location': (() {
                              final weatherLocation =
                                  _weatherData?['name']?.toString() ?? '';
                              if (weatherLocation.isEmpty ||
                                  weatherLocation.toLowerCase() ==
                                      'current location') {
                                return displayLocationName;
                              }
                              return weatherLocation;
                            })(),
                          }),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.soil,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CropPredictionScreen(weatherData: _weatherData!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(l10n.tr('continueRecommendation')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============= CROP PREDICTION SCREEN =============
class CropPredictionScreen extends StatefulWidget {
  final Map<String, dynamic> weatherData;

  CropPredictionScreen({required this.weatherData});

  @override
  _CropPredictionScreenState createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen> {
  final _nitrogenController = TextEditingController(text: '50');
  final _phosphorusController = TextEditingController(text: '40');
  final _potassiumController = TextEditingController(text: '30');

  bool _isPredicting = false;
  String _recommendedCrop = '';
  double _confidence = 0;
  String _reasoning = '';
  Map<String, dynamic>? _inputSummary;

  Future<void> _getPrediction() async {
    final l10n = context.l10n;
    setState(() => _isPredicting = true);

    try {
      final nitrogen = double.parse(_nitrogenController.text);
      final phosphorus = double.parse(_phosphorusController.text);
      final potassium = double.parse(_potassiumController.text);

      final temperature = (widget.weatherData['temperature'] ?? 25).toDouble();
      final humidity = (widget.weatherData['humidity'] ?? 80).toDouble();
      final rainfall = (widget.weatherData['rainfall'] ?? 0).toDouble();

      final result = await CropPredictionService.predictCrop(
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        temperature: temperature,
        humidity: humidity,
        rainfall: rainfall,
      );

      if (result == null || result['recommended_crop'] == null) {
        throw Exception(
          l10n.trArgs('predictionUnavailable', {
            'backendUrl': CropPredictionService.backendUrl,
          }),
        );
      }

      setState(() {
        _recommendedCrop = result['recommended_crop'].toString();
        _confidence = (result['confidence'] as num?)?.toDouble() ?? 0;
        _reasoning = result['reasoning']?.toString() ?? '';
        _inputSummary =
            (result['input_summary'] as Map<String, dynamic>?) ?? {};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.trArgs('recommendedSnack', {
            'crop': _recommendedCrop,
            'confidence': (_confidence * 100).toStringAsFixed(1),
          })),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trArgs('errorPrefix', {'error': '$e'}))),
      );
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final confidencePercent = (_confidence * 100).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('cropRecommendationTitle')),
        actions: const [LanguageSwitcherButton()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3E8), Color(0xFFF7F4EE)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('soilInputs'),
                        style: textTheme.titleLarge?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nitrogenController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.tr('nitrogen'),
                          prefixIcon: const Icon(Icons.grass_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phosphorusController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.tr('phosphorus'),
                          prefixIcon: const Icon(Icons.science_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _potassiumController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.tr('potassium'),
                          prefixIcon: const Icon(Icons.eco_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _isPredicting ? null : _getPrediction,
                icon: _isPredicting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.psychology_alt_outlined),
                label: Text(
                  _isPredicting
                      ? l10n.tr('analyzingField')
                      : l10n.tr('getCropRecommendation'),
                ),
              ),
              if (_recommendedCrop.isNotEmpty) ...[
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.leaf.withValues(alpha: 0.14),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.forest,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.tr('recommendedCrop'),
                                    style: textTheme.bodySmall?.copyWith(
                                      color:
                                          AppTheme.ink.withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _recommendedCrop,
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: AppTheme.forest,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.forest.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.tr('confidenceLevel'),
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTheme.forest,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: _confidence,
                                        minHeight: 10,
                                        backgroundColor: AppTheme.forest
                                            .withValues(alpha: 0.15),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                AppTheme.leaf),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${confidencePercent.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: AppTheme.forest,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_reasoning.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            l10n.tr('whyThisCrop'),
                            style: textTheme.titleSmall?.copyWith(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _reasoning,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.82),
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (_inputSummary != null &&
                            _inputSummary!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            l10n.tr('analysisParameters'),
                            style: textTheme.titleSmall?.copyWith(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.forest.withValues(alpha: 0.14)),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow(l10n.tr('summaryN'),
                                    '${_inputSummary?['nitrogen']?.toStringAsFixed(1) ?? '-'} mg/kg'),
                                _buildSummaryRow(l10n.tr('summaryP'),
                                    '${_inputSummary?['phosphorus']?.toStringAsFixed(1) ?? '-'} mg/kg'),
                                _buildSummaryRow(l10n.tr('summaryK'),
                                    '${_inputSummary?['potassium']?.toStringAsFixed(1) ?? '-'} mg/kg'),
                                const Divider(),
                                _buildSummaryRow(l10n.tr('summaryTemperature'),
                                    '${_inputSummary?['temperature']?.toStringAsFixed(1) ?? '-'}°C'),
                                _buildSummaryRow(l10n.tr('summaryHumidity'),
                                    '${_inputSummary?['humidity']?.toStringAsFixed(0) ?? '-'}%'),
                                _buildSummaryRow(l10n.tr('summaryRainfall'),
                                    '${_inputSummary?['rainfall']?.toStringAsFixed(1) ?? '-'} mm'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.ink.withValues(alpha: 0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.forest.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.forest, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.ink.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
