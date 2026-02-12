import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricapp/src/app/app.dart';

void main() {
  testWidgets('CricApp renders with router', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CricApp(),
      ),
    );

    // Initial route is splash — 'Splash' appears in both AppBar and body
    expect(find.text('Splash'), findsNWidgets(2));
  });
}
