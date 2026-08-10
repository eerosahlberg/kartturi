import 'package:flutter_test/flutter_test.dart';

import 'package:kartturi/main.dart';

void main() {
  testWidgets('App renders map screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KartturiApp());
    expect(find.byType(KartturiApp), findsOneWidget);
  });
}
