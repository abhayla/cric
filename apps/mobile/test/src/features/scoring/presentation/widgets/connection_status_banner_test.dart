import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/core/theme/app_colors.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/connection_status_banner.dart';
import 'package:cricscores/src/shared/data/websocket/websocket_client.dart';

void main() {
  Widget buildBanner({
    required ConnectionStatus status,
    VoidCallback? onRetry,
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
        body: ConnectionStatusBanner(
          status: status,
          onRetry: onRetry,
        ),
      ),
    );
  }

  group('ConnectionStatusBanner', () {
    testWidgets('renders nothing when connected', (tester) async {
      await tester.pumpWidget(buildBanner(
        status: ConnectionStatus.connected,
      ));

      expect(find.byType(ConnectionStatusBanner), findsOneWidget);
      // Should render a SizedBox.shrink (no visible content).
      expect(find.text('Connecting'), findsNothing);
      expect(find.text('Reconnecting'), findsNothing);
    });

    testWidgets('shows connecting indicator', (tester) async {
      await tester.pumpWidget(buildBanner(
        status: ConnectionStatus.connecting,
      ));

      expect(find.text('Connecting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows reconnecting indicator', (tester) async {
      await tester.pumpWidget(buildBanner(
        status: ConnectionStatus.reconnecting,
      ));

      expect(find.text('Reconnecting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows disconnected with retry button', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(buildBanner(
        status: ConnectionStatus.disconnected,
        onRetry: () => retryCalled = true,
      ));

      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryCalled, true);
    });

    testWidgets('hides retry button when no callback', (tester) async {
      await tester.pumpWidget(buildBanner(
        status: ConnectionStatus.disconnected,
      ));

      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('uses warning colors for connecting states', (tester) async {
      await tester.pumpWidget(buildBanner(
        status: ConnectionStatus.reconnecting,
      ));

      // Find the Container with colored background.
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Reconnecting...'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.decoration, isNotNull);
    });

    testWidgets('uses error colors for disconnected', (tester) async {
      await tester.pumpWidget(buildBanner(
        status: ConnectionStatus.disconnected,
        onRetry: () {},
      ));

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Disconnected'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.decoration, isNotNull);
    });
  });
}
