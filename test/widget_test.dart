import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:editor_imagens/app.dart';

void main() {
  testWidgets('Home screen shows camera and gallery actions', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Escolher da galeria'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
