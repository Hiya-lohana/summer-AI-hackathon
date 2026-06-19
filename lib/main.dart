import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file. Running with fallback values. Details: $e");
    try {
      dotenv.loadFromString(isOptional: true);
    } catch (_) {}
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize Anonymous Auth for secure, isolated backend session management
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint("Logged in anonymously: ${FirebaseAuth.instance.currentUser?.uid}");
    }
  } catch (e) {
    debugPrint("Firebase initialization/auth failed: $e");
  }
  
  // Initialize Supabase Connection
  await SupabaseService().init();
  
  runApp(const SafenetApp());
}

class SafenetApp extends StatelessWidget {
  const SafenetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Safenet AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(
            nextScreen: DashboardScreen(),
          ),
        );
      },
    );
  }
}