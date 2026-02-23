import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/score_header.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/sync_status_indicator.dart';
import 'package:cricscores/src/shared/data/sync/sync_service.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('SyncStatusIndicator', () {
    testWidgets('shows cloud_done icon when allSynced', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(syncStatus: SyncStatus.allSynced),
      ));

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows cloud_upload icon when pending', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(
          syncStatus: SyncStatus.pending,
          pendingCount: 3,
        ),
      ));

      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('shows pending count badge', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(
          syncStatus: SyncStatus.pending,
          pendingCount: 5,
        ),
      ));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('hides count when zero even if pending', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(
          syncStatus: SyncStatus.pending,
          pendingCount: 0,
        ),
      ));

      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      // No count text should be visible
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows cloud_off icon when error', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(syncStatus: SyncStatus.error),
      ));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('no count badge when allSynced', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(syncStatus: SyncStatus.allSynced),
      ));

      // Should not show any number text
      expect(find.text('0'), findsNothing);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('no count badge when error', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(
          syncStatus: SyncStatus.error,
          pendingCount: 2,
        ),
      ));

      // Count badge only shows in pending status
      expect(find.text('2'), findsNothing);
    });

    testWidgets('uses correct green color for synced', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SyncStatusIndicator(syncStatus: SyncStatus.allSynced),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.cloud_done));
      expect(icon.color, Colors.green);
    });
  });

  group('ScoreHeader with sync status', () {
    Widget buildHeader({
      SyncStatus? syncStatus,
      int pendingCount = 0,
    }) {
      return wrapWidget(ScoreHeader(
        battingTeamName: 'Team Alpha',
        inningsNumber: 1,
        totalRuns: 45,
        totalWickets: 2,
        oversDisplay: '7.3',
        runRate: 6.0,
        onBack: () {},
        syncStatus: syncStatus,
        pendingCount: pendingCount,
      ));
    }

    testWidgets('shows no sync indicator by default', (tester) async {
      await tester.pumpWidget(buildHeader());
      expect(find.byType(SyncStatusIndicator), findsNothing);
    });

    testWidgets('shows sync indicator when syncStatus provided',
        (tester) async {
      await tester.pumpWidget(
          buildHeader(syncStatus: SyncStatus.allSynced));
      expect(find.byType(SyncStatusIndicator), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows pending indicator with count', (tester) async {
      await tester.pumpWidget(buildHeader(
        syncStatus: SyncStatus.pending,
        pendingCount: 7,
      ));
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows error indicator', (tester) async {
      await tester.pumpWidget(
          buildHeader(syncStatus: SyncStatus.error));
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('team name still displayed alongside sync indicator',
        (tester) async {
      await tester.pumpWidget(
          buildHeader(syncStatus: SyncStatus.allSynced));
      expect(find.text('Team Alpha'), findsOneWidget);
    });

    testWidgets('score still displayed with sync indicator',
        (tester) async {
      await tester.pumpWidget(buildHeader(
        syncStatus: SyncStatus.pending,
        pendingCount: 3,
      ));
      expect(find.text('45/2'), findsOneWidget);
    });

    testWidgets('run rate still displayed with sync indicator',
        (tester) async {
      await tester.pumpWidget(
          buildHeader(syncStatus: SyncStatus.allSynced));
      expect(find.textContaining('CRR:'), findsOneWidget);
    });
  });
}
