import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/app/app.dart';
import 'package:cricapp/src/features/home/domain/repositories/home_repository.dart';
import 'package:cricapp/src/features/home/providers.dart';

void main() {
  testWidgets('CricApp renders with router', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override network providers to prevent real HTTP calls
          liveMatchesProvider.overrideWith(
            (ref) async => const MatchListResult(matches: [], total: 0, page: 1),
          ),
          recentMatchesProvider.overrideWith(
            (ref) async => const MatchListResult(matches: [], total: 0, page: 1),
          ),
        ],
        child: const CricApp(),
      ),
    );

    // Debug mode redirects splash → home. Verify app renders.
    await tester.pump();
    expect(find.textContaining('Home'), findsWidgets);
  });
}
