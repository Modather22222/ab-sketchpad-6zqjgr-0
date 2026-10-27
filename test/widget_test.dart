import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sketchpad/main.dart';

void main() {
  testWidgets('SketchPad shows the gallery screen', (tester) async {
    await tester.pumpWidget(const SketchPadApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('SketchPad'), findsOneWidget);
    expect(find.text('New sketch'), findsOneWidget);
  });
}
