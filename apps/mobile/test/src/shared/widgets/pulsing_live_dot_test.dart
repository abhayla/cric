import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/shared/widgets/pulsing_live_dot.dart';

void main() {
  Widget buildTestWidget({double size = 8.0, Color color = Colors.green}) {
    return MaterialApp(
      home: Scaffold(
        body: PulsingLiveDot(size: size, color: color),
      ),
    );
  }

  group('PulsingLiveDot', () {
    testWidgets('renders a circular container with default green color',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, Colors.green);
    });

    testWidgets('uses custom size', (tester) async {
      await tester.pumpWidget(buildTestWidget(size: 12.0));

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.constraints?.maxWidth, 12.0);
      expect(container.constraints?.maxHeight, 12.0);
    });

    testWidgets('uses custom color', (tester) async {
      await tester.pumpWidget(buildTestWidget(color: Colors.red));

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });

    testWidgets('has FadeTransition for pulsing animation', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.descendant(
          of: find.byType(PulsingLiveDot),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
    });

    testWidgets('animation controller is disposed on widget removal',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Pump a frame to start animation
      await tester.pump(const Duration(milliseconds: 100));

      // Replace with a different widget — should not throw
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
    });
  });
}
