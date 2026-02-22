import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[CricApp] Initializing Firebase...');
  try {
    await Firebase.initializeApp()
        .timeout(const Duration(seconds: 10));
    debugPrint('[CricApp] Firebase initialized successfully');
  } catch (e) {
    debugPrint('[CricApp] Firebase init failed/timed out: $e');
    // Continue anyway — auth provider has its own 5s timeout
  }

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  debugPrint('[CricApp] Starting app...');
  runApp(
    const ProviderScope(
      child: CricApp(),
    ),
  );
}
