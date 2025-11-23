import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipool/home_page.dart';

void main() {
  testWidgets("HomePage shows Home Page text", (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text("Home Page"), findsOneWidget);
  });
}
