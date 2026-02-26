import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/updates/domain/entities/activity_event.dart';
import 'package:cricscores/src/features/updates/domain/repositories/updates_repository.dart';
import 'package:cricscores/src/features/updates/presentation/notifiers/updates_preferences_notifier.dart';
import 'package:cricscores/src/features/updates/presentation/pages/updates_page.dart';
import 'package:cricscores/src/features/updates/providers.dart';

void main() {
  Widget buildTestWidget({
    AsyncValue<ActivityFeedResult>? feedState,
  }) {
    final state = feedState ??
        const AsyncValue.data(
            ActivityFeedResult(events: [], total: 0, page: 1));

    return ProviderScope(
      overrides: [
        activityFeedProvider.overrideWith((ref) {
          return state.when(
            data: (d) => Future.value(d),
            loading: () => Completer<ActivityFeedResult>().future,
            error: (e, s) => Future<ActivityFeedResult>.error(e, s),
          );
        }),
        unreadCountProvider.overrideWith((ref) async => 0),
        updatesPreferencesProvider
            .overrideWith(() => UpdatesPreferencesNotifier()),
      ],
      child: const MaterialApp(home: UpdatesPage()),
    );
  }

  group('UpdatesPage - Tabs', () {
    testWidgets('renders Feed and Settings tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('default tab is Feed showing feed content', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Feed tab shows empty state by default (no events)
      expect(find.text('No Updates Yet'), findsOneWidget);
    });

    testWidgets('can switch to Settings tab and see group headers',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // First two groups visible without scrolling
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Match'), findsOneWidget);

      // Scroll down to reveal remaining groups (ListView lazy-builds)
      await tester.scrollUntilVisible(
        find.text('Tournament'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.text('Team'), findsOneWidget);
      expect(find.text('Tournament'), findsOneWidget);
    });

    testWidgets('Settings tab has None button that hides all events',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Tap None button
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      // All switches should be off (not checked)
      // Find SwitchListTile widgets - all should have value: false
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches, isNotEmpty);
      for (final switchTile in switches) {
        expect(switchTile.value, isFalse,
            reason: 'All event type switches should be off after tapping None');
      }
    });

    testWidgets('Settings tab has All button that shows all events',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // First hide all
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      // Then show all
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // All switches should be on
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches, isNotEmpty);
      for (final switchTile in switches) {
        expect(switchTile.value, isTrue,
            reason: 'All event type switches should be on after tapping All');
      }
    });
  });

  group('UpdatesPage - Feed tab', () {
    testWidgets('renders Updates title in AppBar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Updates'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows loading spinner while fetching', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(feedState: const AsyncValue.loading()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Updates Yet'), findsOneWidget);
      expect(
        find.textContaining('Activity from your matches'),
        findsOneWidget,
      );
    });

    testWidgets('shows error state with retry button on failure',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          feedState: AsyncValue.error(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load updates'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows grouped events by date', (tester) async {
      final now = DateTime.now();
      final events = [
        ActivityEvent(
          id: '1',
          eventType: 'match_completed',
          title: 'Match Completed',
          createdAt: now,
        ),
        ActivityEvent(
          id: '2',
          eventType: 'player_added',
          title: 'Player Added',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          feedState: AsyncValue.data(
            ActivityFeedResult(events: events, total: 2, page: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Match Completed'), findsOneWidget);
      expect(find.text('Player Added'), findsOneWidget);
    });

    testWidgets('has pull-to-refresh on Feed tab', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
