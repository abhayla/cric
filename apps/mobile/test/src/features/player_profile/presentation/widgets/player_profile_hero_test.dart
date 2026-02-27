import 'package:cricscores/src/features/auth/domain/entities/app_user.dart';
import 'package:cricscores/src/features/player_profile/domain/entities/player_profile.dart';
import 'package:cricscores/src/features/player_profile/presentation/widgets/player_profile_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(PlayerProfile profile) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PlayerProfileHero(profile: profile),
        ),
      ),
    );
  }

  group('PlayerProfileHero', () {
    testWidgets('displays player name', (tester) async {
      const profile = PlayerProfile(
        id: 'p1',
        displayName: 'Virat Kohli',
      );
      await tester.pumpWidget(buildWidget(profile));
      expect(find.text('Virat Kohli'), findsOneWidget);
    });

    testWidgets('displays initials when no avatar', (tester) async {
      const profile = PlayerProfile(
        id: 'p1',
        displayName: 'Virat Kohli',
      );
      await tester.pumpWidget(buildWidget(profile));
      expect(find.text('VK'), findsOneWidget);
    });

    testWidgets('displays role and style', (tester) async {
      const profile = PlayerProfile(
        id: 'p1',
        displayName: 'Virat Kohli',
        playerRole: PlayerRole.batter,
        battingStyle: BattingStyle.rightHand,
      );
      await tester.pumpWidget(buildWidget(profile));
      // Should show "Batter • Right Hand Bat"
      expect(find.textContaining('Batter'), findsOneWidget);
    });

    testWidgets('does not show team chip', (tester) async {
      const profile = PlayerProfile(
        id: 'p1',
        displayName: 'Test Player',
        teams: [
          TeamAffiliation(teamId: 't1', teamName: 'Mumbai Warriors', role: 'player'),
        ],
      );
      await tester.pumpWidget(buildWidget(profile));
      // Team chip was removed — team name should not appear
      expect(find.text('Mumbai Warriors'), findsNothing);
    });

    testWidgets('hides role section when no role', (tester) async {
      const profile = PlayerProfile(
        id: 'p1',
        displayName: 'Test Player',
      );
      await tester.pumpWidget(buildWidget(profile));
      expect(find.textContaining('Batter'), findsNothing);
    });
  });
}
