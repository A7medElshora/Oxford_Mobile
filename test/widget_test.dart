import 'package:flutter_test/flutter_test.dart';

import 'package:oxford_flutter_app/main.dart';

void main() {
  testWidgets('renders the Oxford visitor experience', (WidgetTester tester) async {
    await tester.pumpWidget(const OxfordApp());

    expect(find.text('اتصفح طريقك\nقبل أن تسجّل.'), findsOneWidget);
    expect(find.text('12k+  طالب يتعلمون بهدوء     48  مسار متاح'), findsOneWidget);
    await tester.tap(find.text('تسجيل الدخول').first);
    await tester.pumpAndSettle();
    expect(find.text('أهلًا بك من جديد'), findsOneWidget);
  });
}
