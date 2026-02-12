import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/app/app.dart';

void main() {
  testWidgets('CricApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CricApp(),
      ),
    );

    expect(find.text('CricApp'), findsOneWidget);
  });
}
