import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final instance =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    return instance ?? AppLocalizations(const Locale('en'));
  }

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
      'dashboardTitle': 'Agri Expert Dashboard',
      'welcomeTitle': 'Welcome to Agri Expert',
      'welcomeSubtitle':
          'Sign in with your phone number to access smart crop insights.',
      'mobileNumber': 'Mobile Number',
      'mobileHint': 'Enter 10-digit number',
      'verificationCode': 'Verification Code',
      'verificationHint': 'Enter 6-digit OTP',
      'sendOtp': 'Send OTP',
      'sendingOtp': 'Sending OTP...',
      'verifyOtp': 'Verify OTP',
      'verifying': 'Verifying...',
      'backToPhone': 'Back to phone number',
      'invalidOtpLength': 'Please enter a valid 6-digit OTP',
      'loginSuccess': 'Login successful!',
      'loginInvalid': 'Invalid OTP. Please try again.',
      'otpSentTo': 'OTP sent to {phone}',
      'dashboardBlurb':
          'Analyze your field conditions and get confident crop recommendations in seconds.',
      'npkInputs': 'NPK Inputs',
      'liveLocation': 'Live Location',
      'weatherInsights': 'Weather Insights',
      'getLocationWeather': 'Get Location & Weather',
      'locationWeatherTitle': 'Location & Weather',
      'tapToGetLocation': 'Tap to get location',
      'locationServicesDisabled': 'Location services are disabled',
      'locationPermissionDenied': 'Location permission denied',
      'errorPrefix': 'Error: {error}',
      'weatherErrorPrefix': 'Weather error: {error}',
      'weatherUnavailable':
          'Unable to fetch weather. Start backend at {backendUrl} or check internet connection.',
      'coordinates': 'Coordinates: {coordinates}',
      'detectingLocation': 'Detecting location...',
      'refreshLocation': 'Refresh Location',
      'unknown': 'Unknown',
      'backend': 'Backend',
      'fallback': 'Fallback',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'wind': 'Wind',
      'pressure': 'Pressure',
      'visibility': 'Visibility',
      'cloudCover': 'Cloud Cover',
      'locationLabel': 'Location: {location}',
      'continueRecommendation': 'Continue to Crop Recommendation',
      'cropRecommendationTitle': 'Crop Recommendation',
      'soilInputs': 'Soil Inputs (mg/kg)',
      'nitrogen': 'Nitrogen (N)',
      'phosphorus': 'Phosphorus (P)',
      'potassium': 'Potassium (K)',
      'analyzingField': 'Analyzing field conditions...',
      'getCropRecommendation': 'Get Crop Recommendation',
      'recommendedCrop': 'Recommended Crop',
      'confidenceLevel': 'Confidence Level',
      'whyThisCrop': 'Why this crop?',
      'analysisParameters': 'Analysis Parameters',
      'summaryN': 'N (Nitrogen)',
      'summaryP': 'P (Phosphorus)',
      'summaryK': 'K (Potassium)',
      'summaryTemperature': 'Temperature',
      'summaryHumidity': 'Humidity',
      'summaryRainfall': 'Rainfall',
      'recommendedSnack': 'Recommended: {crop} ({confidence}%)',
      'predictionUnavailable':
          'Could not fetch crop recommendation. Ensure backend is reachable at {backendUrl}.',
    },
    'hi': {
      'language': 'भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिंदी',
      'dashboardTitle': 'एग्री एक्सपर्ट डैशबोर्ड',
      'welcomeTitle': 'एग्री एक्सपर्ट में आपका स्वागत है',
      'welcomeSubtitle':
          'स्मार्ट फसल सुझाव पाने के लिए अपने फोन नंबर से लॉगिन करें।',
      'mobileNumber': 'मोबाइल नंबर',
      'mobileHint': '10 अंकों का नंबर दर्ज करें',
      'verificationCode': 'सत्यापन कोड',
      'verificationHint': '6 अंकों का OTP दर्ज करें',
      'sendOtp': 'OTP भेजें',
      'sendingOtp': 'OTP भेजा जा रहा है...',
      'verifyOtp': 'OTP सत्यापित करें',
      'verifying': 'सत्यापन हो रहा है...',
      'backToPhone': 'मोबाइल नंबर पर वापस जाएँ',
      'invalidOtpLength': 'कृपया 6 अंकों का सही OTP दर्ज करें',
      'loginSuccess': 'लॉगिन सफल!',
      'loginInvalid': 'OTP गलत है। कृपया फिर से कोशिश करें।',
      'otpSentTo': '{phone} पर OTP भेज दिया गया है',
      'dashboardBlurb':
          'अपने खेत की स्थिति का विश्लेषण करें और तुरंत भरोसेमंद फसल सुझाव पाएं।',
      'npkInputs': 'NPK इनपुट',
      'liveLocation': 'लाइव लोकेशन',
      'weatherInsights': 'मौसम जानकारी',
      'getLocationWeather': 'लोकेशन और मौसम प्राप्त करें',
      'locationWeatherTitle': 'लोकेशन और मौसम',
      'tapToGetLocation': 'लोकेशन पाने के लिए टैप करें',
      'locationServicesDisabled': 'लोकेशन सेवाएं बंद हैं',
      'locationPermissionDenied': 'लोकेशन अनुमति अस्वीकार की गई',
      'errorPrefix': 'त्रुटि: {error}',
      'weatherErrorPrefix': 'मौसम त्रुटि: {error}',
      'weatherUnavailable':
          'मौसम प्राप्त नहीं हो सका। {backendUrl} पर बैकएंड शुरू करें या इंटरनेट कनेक्शन जांचें।',
      'coordinates': 'निर्देशांक: {coordinates}',
      'detectingLocation': 'लोकेशन पता की जा रही है...',
      'refreshLocation': 'लोकेशन फिर से प्राप्त करें',
      'unknown': 'अज्ञात',
      'backend': 'बैकएंड',
      'fallback': 'फॉलबैक',
      'temperature': 'तापमान',
      'humidity': 'नमी',
      'wind': 'हवा',
      'pressure': 'दबाव',
      'visibility': 'दृश्यता',
      'cloudCover': 'बादल',
      'locationLabel': 'स्थान: {location}',
      'continueRecommendation': 'फसल सुझाव पर आगे बढ़ें',
      'cropRecommendationTitle': 'फसल सुझाव',
      'soilInputs': 'मिट्टी इनपुट (mg/kg)',
      'nitrogen': 'नाइट्रोजन (N)',
      'phosphorus': 'फॉस्फोरस (P)',
      'potassium': 'पोटैशियम (K)',
      'analyzingField': 'खेत की स्थिति का विश्लेषण हो रहा है...',
      'getCropRecommendation': 'फसल सुझाव प्राप्त करें',
      'recommendedCrop': 'सुझाई गई फसल',
      'confidenceLevel': 'विश्वास स्तर',
      'whyThisCrop': 'यह फसल क्यों?',
      'analysisParameters': 'विश्लेषण पैरामीटर',
      'summaryN': 'N (नाइट्रोजन)',
      'summaryP': 'P (फॉस्फोरस)',
      'summaryK': 'K (पोटैशियम)',
      'summaryTemperature': 'तापमान',
      'summaryHumidity': 'नमी',
      'summaryRainfall': 'वर्षा',
      'recommendedSnack': 'सुझाव: {crop} ({confidence}%)',
      'predictionUnavailable':
          'फसल सुझाव प्राप्त नहीं हो सका। कृपया सुनिश्चित करें कि बैकएंड {backendUrl} पर उपलब्ध है।',
    },
  };

  String tr(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String trArgs(String key, Map<String, String> args) {
    var text = tr(key);
    args.forEach((placeholder, value) {
      text = text.replaceAll('{$placeholder}', value);
    });
    return text;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
