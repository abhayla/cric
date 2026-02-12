import 'package:flutter/material.dart';

import '../../../../shared/widgets/cricket_ball_icon.dart';

/// Splash screen shown during app initialization.
///
/// Displays the app logo, name, tagline, and a loading indicator
/// while auth state is resolved by the router.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cricket ball icon
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: CricketBallIcon(),
            ),

            // App name — two-tone: "Cric" in primary, "App" in onSurface
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Cric',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'App',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Score every ball. Own every moment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
