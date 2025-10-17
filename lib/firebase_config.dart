import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Activate Firebase App Check (debug provider for development)
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      print('Firebase App Check activated (debug provider)');
    } catch (e) {
      print('App Check activation failed: $e');
    }
  }
}
