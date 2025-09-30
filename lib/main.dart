import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vjitstudyvault/pages/contribute_page.dart';
import 'package:vjitstudyvault/pages/feedback_and_report_page.dart';
import 'package:vjitstudyvault/pages/homepage.dart';
import 'package:vjitstudyvault/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vjitstudyvault/theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    print('🚀 Starting VJIT Study Vault PWA...');
  }

  // Initialize Firebase with proper web configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print(
        '✅ Firebase initialized successfully for ${kIsWeb ? 'Web' : 'Mobile'}',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase initialization failed: $e');
    }
    // Continue without Firebase for now - can be configured later
  }

  if (kDebugMode) {
    print('🎯 Running Flutter app...');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  SharedPreferences? prefs;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('📱 MyApp initState started...');
    }

    _initSharedPreferences();

    // Firebase Analytics with error handling
    try {
      FirebaseAnalytics.instance.logAppOpen();
      if (kDebugMode) {
        print('📊 Firebase Analytics logged app open');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Analytics error: $e');
      }
    }

    logDeviceInfo(); // Log device information during app initialization

    // Check internet connectivity on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkInternetOnAppStart(context);
    });
  }

  Future<void> _initSharedPreferences() async {
    if (kDebugMode) {
      print('🔧 Initializing SharedPreferences...');
    }
    try {
      prefs = await SharedPreferences.getInstance();
      if (kDebugMode) {
        print('✅ SharedPreferences initialized successfully');
      }
      setState(() {
        _isLoaded = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ SharedPreferences error: $e');
      }
      // Still mark as loaded to prevent infinite loading
      setState(() {
        _isLoaded = true;
      });
    }
  }

  Future<void> logDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown';

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceName = '${webInfo.browserName.name} on ${webInfo.platform}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} (${iosInfo.model})';
      }
    } catch (e) {
      deviceName = kIsWeb ? 'Web Browser' : 'Unknown Device';
    }

    // Log device name with Firebase Analytics error handling
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'device_name',
        value: deviceName,
      );

      await FirebaseAnalytics.instance.logEvent(
        name: 'device_info',
        parameters: {'device_name': deviceName},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Analytics logging failed: $e');
      }
    }
  }

  Future<void> checkInternetOnAppStart(BuildContext context) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No internet connection. Please check your network.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Connectivity check failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🎨 Building MyApp widget, _isLoaded: $_isLoaded');
    }

    if (!_isLoaded) {
      return MaterialApp(
        title: 'VJIT Study Vault',
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  'Loading VJIT Study Vault...',
                  style: TextStyle(fontSize: 16),
                ),
                if (kDebugMode) ...[
                  SizedBox(height: 20),
                  Text(
                    'Debug Mode: Web PWA',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final bool? onboardingComplete = prefs?.getBool('onboardingComplete');

    if (kDebugMode) {
      print('🎯 Onboarding complete: $onboardingComplete');
    }

    return MaterialApp(
      title: 'VJIT Study Vault',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routes: {
        'onboarding': (context) => const OnboardingPage(),
        'home': (context) => const Homepage(),
        '/feedback_report_bug': (context) => const FeedbackAndReportPage(),
        '/contribute': (context) => const ContributePage(),
      },
      home: onboardingComplete == true
          ? const Homepage()
          : const OnboardingPage(),
    );
  }
}
