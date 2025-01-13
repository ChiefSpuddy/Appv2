import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';
import 'utils/pointer_event_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SafePointerEventHandler.initializePointerEventHandling();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

Future<void> reloadApp() async {
  await Firebase.initializeApp();
  // Clear any cached Firestore data
  FirebaseFirestore.instance.clearPersistence();
  
  // Force refresh the main app
  runApp(const MyApp());
}

Future<void> clearFirebaseCache() async {
  await FirebaseFirestore.instance.clearPersistence();
  await FirebaseAuth.instance.signOut();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TCG Collection Manager',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
            routes: {
              '/search': (context) => SearchScreen(
                initialQuery: ModalRoute.of(context)?.settings.arguments as String?,
              ),
              // ...other existing routes...
            },
          );
        },
      ),
    );
  }
}