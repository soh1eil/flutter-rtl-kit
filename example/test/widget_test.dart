import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_rtl_kit_example/main.dart';

void main() {
  testWidgets('the example renders and steps through days', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('جمعه ۱ فروردین ۱۴۰۴'), findsOneWidget);
    await tester.tap(find.byTooltip('Next day'));
    await tester.pump();
    expect(find.text('شنبه ۲ فروردین ۱۴۰۴'), findsOneWidget);
  });
}
