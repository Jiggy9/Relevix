import 'package:flutter_test/flutter_test.dart';
import 'package:relevix/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RelevixApp());
    await tester.pump();

    expect(find.text('Data Interpolation & Mapping'), findsOneWidget);

    // Advance past the splash screen's Future.delayed timer
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
