import 'package:cricscores/src/features/player_profile/presentation/pages/player_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(String playerId) {
    return MaterialApp(
      home: PlayerProfilePage(playerId: playerId),
    );
  }

  group('PlayerProfilePage', () {
    testWidgets('shows AppBar with Player Profile title', (tester) async {
      await tester.pumpWidget(buildWidget('player-1'));

      expect(find.text('Player Profile'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Coming Soon text', (tester) async {
      await tester.pumpWidget(buildWidget('player-1'));

      expect(find.text('Coming Soon'), findsOneWidget);
    });

    testWidgets('shows person outline icon', (tester) async {
      await tester.pumpWidget(buildWidget('player-1'));

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });
}
