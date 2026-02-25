/// Navigation helpers — navigate to home, teams, matches, tournaments, live, updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../core/test_utils.dart';

/// Navigate to My Cricket page (first bottom nav tab).
Future<void> navigateToHome(WidgetTester tester) async {
  // Try "Back to Home" button first (match complete modal)
  final backHome = find.text('Back to Home');
  if (backHome.evaluate().isNotEmpty) {
    await tester.tap(backHome.first);
    await settle(tester);
    await visualPause(tester);
    return;
  }

  // Try navigating via GoRouter
  try {
    final context = tester.element(find.byType(Navigator).last);
    GoRouter.of(context).go('/home');
    await settle(tester);
    await visualPause(tester);
  } catch (_) {
    await goBack(tester);
  }
}

/// Ensure we're on the My Cricket page (first bottom nav tab).
Future<void> ensureOnMyCricketPage(WidgetTester tester) async {
  final myCricketTitle = find.textContaining('Cricket');
  if (myCricketTitle.evaluate().isNotEmpty) return;

  final navBar = find.byType(NavigationBar);
  final myCricketNav = find.text('My Cricket');
  if (navBar.evaluate().isNotEmpty && myCricketNav.evaluate().isNotEmpty) {
    await tester.tap(myCricketNav.first);
    await settle(tester);
    await visualPause(tester);
    return;
  }

  // Fallback: use GoRouter
  try {
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).go('/home');
    await settle(tester);
    await visualPause(tester);
    print('    [nav] Used GoRouter.go(/home)');
  } catch (e) {
    print('    [nav] WARNING: GoRouter navigation failed: $e');
  }
}

/// Navigate to Teams sub-tab within My Cricket page.
Future<void> navigateToTeams(WidgetTester tester) async {
  await ensureOnMyCricketPage(tester);

  final teamsTab = find.text('Teams');
  if (teamsTab.evaluate().isNotEmpty) {
    await tester.tap(teamsTab.first);
    await settle(tester);
    await visualPause(tester);
  }
}

/// Navigate to Matches sub-tab within My Cricket page.
Future<void> navigateToMatches(WidgetTester tester) async {
  await ensureOnMyCricketPage(tester);

  final matchesTab = find.text('Matches');
  if (matchesTab.evaluate().isNotEmpty) {
    await tester.tap(matchesTab.first);
    await settle(tester);
    await visualPause(tester);
  }
}

/// Navigate to Tournaments sub-tab within My Cricket page.
Future<void> navigateToTournaments(WidgetTester tester) async {
  await ensureOnMyCricketPage(tester);

  final tournamentsTab = find.text('Tournaments');
  if (tournamentsTab.evaluate().isNotEmpty) {
    await tester.tap(tournamentsTab.first);
    await settle(tester);
    await visualPause(tester);
  }
}

/// Navigate to Live page (second bottom nav tab).
Future<void> navigateToLive(WidgetTester tester) async {
  final navBar = find.byType(NavigationBar);
  final liveNav = find.text('Live');
  if (navBar.evaluate().isNotEmpty && liveNav.evaluate().isNotEmpty) {
    // Tap the one in the bottom nav bar (not any other "Live" text)
    final navBarLive = find.descendant(of: navBar, matching: liveNav);
    if (navBarLive.evaluate().isNotEmpty) {
      await tester.tap(navBarLive.first);
    } else {
      await tester.tap(liveNav.first);
    }
    await settle(tester);
    await visualPause(tester);
  }
}

/// Navigate to Updates page (third bottom nav tab).
Future<void> navigateToUpdates(WidgetTester tester) async {
  final navBar = find.byType(NavigationBar);
  final updatesNav = find.text('Updates');
  if (navBar.evaluate().isNotEmpty && updatesNav.evaluate().isNotEmpty) {
    final navBarUpdates = find.descendant(of: navBar, matching: updatesNav);
    if (navBarUpdates.evaluate().isNotEmpty) {
      await tester.tap(navBarUpdates.first);
    } else {
      await tester.tap(updatesNav.first);
    }
    await settle(tester);
    await visualPause(tester);
  }
}

/// Navigate to match setup page via GoRouter.
Future<void> navigateToMatchSetup(WidgetTester tester) async {
  try {
    final ctx = tester.element(find.byType(Navigator).last);
    GoRouter.of(ctx).push('/match-setup');
    await settle(tester);
    await visualPause(tester, 500);
    print('    [nav] Navigated to match setup via GoRouter');
  } catch (e) {
    print('    [nav] WARNING: GoRouter failed: $e');
  }
}

/// Tap the back button to go to the previous page.
Future<void> goBack(WidgetTester tester) async {
  final backButton = find.byIcon(Icons.arrow_back);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await settle(tester);
    await visualPause(tester);
  }
}

/// Switch to a specific tab in the nearest [TabBar] via [DefaultTabController].
///
/// Used for tournament detail tabs (0=Overview, 1=Fixtures, 2=Teams).
Future<void> switchToTab(WidgetTester tester, int index) async {
  final tabBarFinder = find.byType(TabBar);
  if (tabBarFinder.evaluate().isNotEmpty) {
    final tabBarContext = tester.element(tabBarFinder.first);
    DefaultTabController.of(tabBarContext).animateTo(index);
    await tester.pumpAndSettle();
    await visualPause(tester);
  }
}

/// Navigate back from team detail to the teams list.
Future<void> navigateBackToTeamsList(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await settle(tester);
    await visualPause(tester);
    return;
  }
  await navigateToTeams(tester);
}
