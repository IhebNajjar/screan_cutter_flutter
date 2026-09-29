import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screan_cutter/main.dart';

void main() {
  testWidgets('clicking the canvas creates a colored cut',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Cuts: 0'), findsOneWidget);

    await tester.tapAt(const Offset(200, 300));
    await tester.pump();

    expect(find.text('Cuts: 1'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(find.text('Cuts: 0'), findsOneWidget);
  });
}
