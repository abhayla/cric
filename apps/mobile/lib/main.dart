import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global error handlers
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('[CricScores] FlutterError: ${details.exceptionAsString()}');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('[CricScores] Uncaught error: $error');
        debugPrint('[CricScores] Stack: $stack');
      }
      return true;
    };

    if (kDebugMode) {
      debugPrint('[CricScores] Initializing Firebase...');
    }
    try {
      await Firebase.initializeApp()
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint('[CricScores] Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CricScores] Firebase init failed/timed out: $e');
      }
      // Continue anyway — auth provider has its own 5s timeout
    }

    // Lock to portrait mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (kDebugMode) {
      debugPrint('[CricScores] Starting app...');
    }
    runApp(
      const ProviderScope(
        child: CricScores(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('[CricScores] Zoned error: $error');
      debugPrint('[CricScores] Stack: $stack');
    }
  });
}
