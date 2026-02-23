import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('[CricApp] FlutterError: ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('[CricApp] Uncaught error: $error');
      debugPrint('[CricApp] Stack: $stack');
    }
    return true;
  };

  runZonedGuarded(() async {
    if (kDebugMode) {
      debugPrint('[CricApp] Initializing Firebase...');
    }
    try {
      await Firebase.initializeApp()
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint('[CricApp] Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CricApp] Firebase init failed/timed out: $e');
      }
      // Continue anyway — auth provider has its own 5s timeout
    }

    // Lock to portrait mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (kDebugMode) {
      debugPrint('[CricApp] Starting app...');
    }
    runApp(
      const ProviderScope(
        child: CricApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('[CricApp] Zoned error: $error');
      debugPrint('[CricApp] Stack: $stack');
    }
  });
}
