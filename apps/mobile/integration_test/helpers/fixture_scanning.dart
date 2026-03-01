/// Fixture scanning helpers — find unplayed fixtures, tap fixture cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/tournaments/presentation/widgets/fixture_card.dart';

import '../core/test_utils.dart';
import 'navigation.dart';

/// Info about an unplayed fixture.
class FixtureInfo {
  FixtureInfo({
    required this.fixtureId,
    required this.homeTeamName,
    required this.awayTeamName,
  });
  final String fixtureId;
  final String homeTeamName;
  final String awayTeamName;
}

/// Find the first unplayed fixture on the Fixtures tab.
///
/// Returns a [FixtureInfo] with team names, or null if none found.
/// If [scoredFixtureIds] is provided, skips fixtures whose ID is
/// already in the set (safety net for stale provider data).
Future<FixtureInfo?> findFirstUnplayedFixture(
  WidgetTester tester, {
  Set<String>? scoredFixtureIds,
}) async {
  // Switch to Fixtures tab
  await switchToTab(tester, 1);

  // Scroll to top first to ensure we scan from the beginning
  final scrollable = _fixturesScrollable();
  if (scrollable.evaluate().isNotEmpty) {
    // Scroll up aggressively to reach top
    for (var i = 0; i < 10; i++) {
      await tester.drag(scrollable.first, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
  }

  // Scan FixtureCard widgets, scrolling through the list
  for (var scroll = 0; scroll < 25; scroll++) {
    final allCards = find.byType(FixtureCard).evaluate().toList();

    for (final cardElement in allCards) {
      final fixtureCard = cardElement.widget as FixtureCard;
      final fixture = fixtureCard.fixture;

      // Unplayed = no matchId, both teams assigned
      if (!fixture.hasMatch &&
          fixture.homeTeamName != null &&
          fixture.awayTeamName != null) {
        // Skip if we already scored this fixture (stale data safety net)
        if (scoredFixtureIds != null && scoredFixtureIds.contains(fixture.id)) {
          continue;
        }
        return FixtureInfo(
          fixtureId: fixture.id,
          homeTeamName: fixture.homeTeamName!,
          awayTeamName: fixture.awayTeamName!,
        );
      }
    }

    // Scroll down using the fixtures ListView scrollable
    final currentScrollable = _fixturesScrollable();
    if (currentScrollable.evaluate().isNotEmpty) {
      await tester.drag(currentScrollable.first, const Offset(0, -300));
      await settle(tester);
    } else {
      break;
    }
  }

  return null;
}

/// Find the innermost Scrollable that contains FixtureCards (the ListView),
/// avoiding the outer TabBarView scrollable.
Finder _fixturesScrollable() {
  final cards = find.byType(FixtureCard);
  if (cards.evaluate().isNotEmpty) {
    final scrollableAncestor = find.ancestor(
      of: cards.first,
      matching: find.byType(Scrollable),
    );
    if (scrollableAncestor.evaluate().isNotEmpty) {
      return scrollableAncestor;
    }
  }
  return find.byType(Scrollable);
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

  // Scroll to top first
  final topScrollable = _fixturesScrollable();
  if (topScrollable.evaluate().isNotEmpty) {
    for (var i = 0; i < 10; i++) {
      await tester.drag(topScrollable.first, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
  }

  bool tapped = false;

  for (var scroll = 0; scroll < 25 && !tapped; scroll++) {
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
          final scrollable = _fixturesScrollable();
          if (scrollable.evaluate().isNotEmpty) {
            final dragAmount = 200 - yPosition + 50;
            await tester.drag(scrollable.first, Offset(0, dragAmount));
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
      final scrollable = _fixturesScrollable();
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
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
