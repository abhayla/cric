import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/core/theme/app_colors.dart';
import 'package:cricapp/src/features/scoring/presentation/widgets/score_header.dart';
import 'package:cricapp/src/shared/data/sync/sync_service.dart';

void main() {
  Widget buildHeader({
    String battingTeamName = 'Mumbai Warriors',
    int inningsNumber = 1,
    int totalRuns = 150,
    int totalWickets = 4,
    String oversDisplay = '15.3',
    double runRate = 9.68,
    double? requiredRunRate,
    int? target,
    int? runsNeeded,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: ScoreHeader(
          battingTeamName: battingTeamName,
          inningsNumber: inningsNumber,
          totalRuns: totalRuns,
          totalWickets: totalWickets,
          oversDisplay: oversDisplay,
          runRate: runRate,
          requiredRunRate: requiredRunRate,
          target: target,
          runsNeeded: runsNeeded,
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  group('ScoreHeader', () {
    testWidgets('renders batting team name', (tester) async {
      await tester.pumpWidget(buildHeader());
      expect(find.text('Mumbai Warriors'), findsOneWidget);
    });

    testWidgets('renders innings label', (tester) async {
      await tester.pumpWidget(buildHeader(inningsNumber: 1));
      expect(find.text('1st Innings'), findsOneWidget);
    });

    testWidgets('renders second innings label', (tester) async {
      await tester.pumpWidget(buildHeader(inningsNumber: 2));
      expect(find.text('2nd Innings'), findsOneWidget);
    });

    testWidgets('renders score display', (tester) async {
      await tester.pumpWidget(buildHeader(totalRuns: 150, totalWickets: 4));
      expect(find.text('150/4'), findsOneWidget);
    });

    testWidgets('renders overs display', (tester) async {
      await tester.pumpWidget(buildHeader(oversDisplay: '15.3'));
      expect(find.text('(15.3)'), findsOneWidget);
    });

    testWidgets('renders current run rate', (tester) async {
      await tester.pumpWidget(buildHeader(runRate: 9.68));
      expect(find.text('CRR: 9.68'), findsOneWidget);
    });

    testWidgets('hides RRR/target/need for 1st innings', (tester) async {
      await tester.pumpWidget(buildHeader(inningsNumber: 1));
      expect(find.textContaining('RRR'), findsNothing);
      expect(find.textContaining('Target'), findsNothing);
      expect(find.textContaining('Need'), findsNothing);
    });

    testWidgets('shows target for 2nd innings', (tester) async {
      await tester.pumpWidget(buildHeader(
        inningsNumber: 2,
        target: 180,
        runsNeeded: 30,
        requiredRunRate: 10.5,
      ));
      expect(find.text('Target: 180'), findsOneWidget);
    });

    testWidgets('shows runs needed for 2nd innings', (tester) async {
      await tester.pumpWidget(buildHeader(
        inningsNumber: 2,
        target: 180,
        runsNeeded: 30,
        requiredRunRate: 10.5,
      ));
      expect(find.text('Need: 30'), findsOneWidget);
    });

    testWidgets('shows required run rate for 2nd innings', (tester) async {
      await tester.pumpWidget(buildHeader(
        inningsNumber: 2,
        target: 180,
        runsNeeded: 30,
        requiredRunRate: 10.5,
      ));
      expect(find.text('RRR: 10.50'), findsOneWidget);
    });

    testWidgets('calls onBack when back button tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(buildHeader(onBack: () => called = true));
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(called, isTrue);
    });

    testWidgets('renders 0/0 score', (tester) async {
      await tester.pumpWidget(buildHeader(
        totalRuns: 0,
        totalWickets: 0,
        oversDisplay: '0.0',
        runRate: 0.0,
      ));
      expect(find.text('0/0'), findsOneWidget);
      expect(find.text('(0.0)'), findsOneWidget);
      expect(find.text('CRR: 0.00'), findsOneWidget);
    });

    testWidgets('renders large score correctly', (tester) async {
      await tester.pumpWidget(buildHeader(
        totalRuns: 350,
        totalWickets: 10,
        oversDisplay: '50.0',
        runRate: 7.0,
      ));
      expect(find.text('350/10'), findsOneWidget);
      expect(find.text('(50.0)'), findsOneWidget);
    });
  });

  group('ScoreHeader — sync status', () {
    Widget buildHeaderWithSync({
      SyncStatus? syncStatus,
      int pendingCount = 0,
    }) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.seed,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: ScoreHeader(
            battingTeamName: 'Team A',
            inningsNumber: 1,
            totalRuns: 50,
            totalWickets: 2,
            oversDisplay: '8.3',
            runRate: 6.0,
            onBack: () {},
            syncStatus: syncStatus,
            pendingCount: pendingCount,
          ),
        ),
      );
    }

    testWidgets('no sync indicator when syncStatus is null', (tester) async {
      await tester.pumpWidget(buildHeaderWithSync(syncStatus: null));
      expect(find.byIcon(Icons.cloud_done), findsNothing);
      expect(find.byIcon(Icons.cloud_upload), findsNothing);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });

    testWidgets('shows cloud_done icon when allSynced', (tester) async {
      await tester
          .pumpWidget(buildHeaderWithSync(syncStatus: SyncStatus.allSynced));
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows cloud_upload icon when pending', (tester) async {
      await tester.pumpWidget(buildHeaderWithSync(
        syncStatus: SyncStatus.pending,
        pendingCount: 5,
      ));
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('shows pending count badge', (tester) async {
      await tester.pumpWidget(buildHeaderWithSync(
        syncStatus: SyncStatus.pending,
        pendingCount: 3,
      ));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows cloud_off icon when error', (tester) async {
      await tester
          .pumpWidget(buildHeaderWithSync(syncStatus: SyncStatus.error));
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('no count badge when allSynced', (tester) async {
      await tester
          .pumpWidget(buildHeaderWithSync(syncStatus: SyncStatus.allSynced));
      // No count text should appear next to the cloud icon
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      // Count badge should not be present
      expect(find.text('0'), findsNothing);
    });
  });
}
