import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:ioslab_app/main.dart';

void main() {
  testWidgets('renders the lab summary and updates when a check runs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IosLabApp());
    await tester.pumpAndSettle();

    expect(find.text('iOS Lab'), findsOneWidget);
    expect(find.text('2/3 CHECKS PASSING'), findsOneWidget);
    expect(find.text('Run next check'), findsOneWidget);

    await tester.tap(find.text('Run next check'));
    await tester.pumpAndSettle();

    expect(find.text('3/3 CHECKS PASSING'), findsOneWidget);
    expect(find.text('All checks passed'), findsOneWidget);
  });

  testWidgets('keeps the fixed iPhone-width layout free of overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const IosLabApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
