/// Fixture scanning helpers — find unplayed fixtures, tap fixture cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/presentation/widgets/fixture_card.dart';

import '../core/test_utils.dart';
import 'navigation.dart';

/// Info about an unplayed fixture.
class FixtureInfo {
  FixtureInfo({required this.homeTeamName, required this.awayTeamName});
  final String homeTeamName;
  final String awayTeamName;
}

/// Find the first unplayed fixture on the Fixtures tab.
///
/// Returns a [FixtureInfo] with team names, or null if none found.
/// If [scoredPairs] is provided, skips fixtures whose "home|away" key is
/// already in the set (safety net for stale provider data).
Future<FixtureInfo?> findFirstUnplayedFixture(
  WidgetTester tester, {
  Set<String>? scoredPairs,
}) async {
  // Switch to Fixtures tab
  await switchToTab(tester, 1);

  // Scan FixtureCard widgets, scrolling through the list
  for (var scroll = 0; scroll < 20; scroll++) {
    final allCards = find.byType(FixtureCard).evaluate().toList();

    for (final cardElement in allCards) {
      final fixtureCard = cardElement.widget as FixtureCard;
      final fixture = fixtureCard.fixture;

      // Unplayed = no matchId, both teams assigned
      if (!fixture.hasMatch &&
          fixture.homeTeamName != null &&
          fixture.awayTeamName != null) {
        // Skip if we already scored this pair (stale data safety net)
        final pairKey = '${fixture.homeTeamName}|${fixture.awayTeamName}';
        if (scoredPairs != null && scoredPairs.contains(pairKey)) {
          continue;
        }
        return FixtureInfo(
          homeTeamName: fixture.homeTeamName!,
          awayTeamName: fixture.awayTeamName!,
        );
      }
    }

    // Scroll down
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.last, const Offset(0, -300));
      await settle(tester);
    } else {
      break;
    }
  }

  return null;
}

/// Tap on a fixture card to start a match from the Fixtures tab.
Future<void> tapFixtureCard(
  WidgetTester tester, {
  required String homeTeamName,
  required String awayTeamName,
}) async {
  clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 300));

  // Switch to Fixtures tab
  await switchToTab(tester, 1);
  print('    [tapFixtureCard] Switched to Fixtures tab');

  bool tapped = false;

  for (var scroll = 0; scroll < 15 && !tapped; scroll++) {
    final allCards = find.byType(FixtureCard).evaluate().toList();

    for (final cardElement in allCards) {
      final fixtureCard = cardElement.widget as FixtureCard;
      final fixture = fixtureCard.fixture;

      if (fixture.homeTeamName == homeTeamName &&
          fixture.awayTeamName == awayTeamName) {
        final cardFinder = find.byWidget(fixtureCard);
        await tester.ensureVisible(cardFinder);
        await settle(tester);

        // Check if behind pinned header
        final renderBox = cardElement.renderObject! as RenderBox;
        final yPosition = renderBox.localToGlobal(Offset.zero).dy;
        print('    [tapFixtureCard] Found "$homeTeamName vs $awayTeamName" at y=$yPosition');

        if (yPosition < 200) {
          final scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isNotEmpty) {
            final dragAmount = 200 - yPosition + 50;
            await tester.drag(scrollable.last, Offset(0, dragAmount));
            await settle(tester);
          }
        }

        // SliverAppBar absorbs taps in integration tests when it overlaps content.
        // Invoking onTap directly is the standard workaround.
        final inkWell = find.descendant(
          of: cardFinder,
          matching: find.byType(InkWell),
        );
        if (inkWell.evaluate().isNotEmpty) {
          final inkWellWidget = tester.widget<InkWell>(inkWell.first);
          if (inkWellWidget.onTap != null) {
            inkWellWidget.onTap!();
            print('    [tapFixtureCard] Invoked onTap for $homeTeamName vs $awayTeamName');
          } else {
            await tester.tap(inkWell.first, warnIfMissed: false);
            print('    [tapFixtureCard] Tapped InkWell for $homeTeamName vs $awayTeamName');
          }
        } else {
          await tester.tap(cardFinder, warnIfMissed: false);
          print('    [tapFixtureCard] Tapped card for $homeTeamName vs $awayTeamName');
        }
        await settle(tester);
        await visualPause(tester);
        tapped = true;
        break;
      }
    }

    if (!tapped) {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.last, const Offset(0, -300));
        await settle(tester);
      } else {
        break;
      }
    }
  }

  if (!tapped) {
    print('    [tapFixtureCard] WARNING: Fixture "$homeTeamName vs $awayTeamName" not found!');
    dumpVisibleTexts(tester, 'tapFixtureCard', 30);
  }
}
