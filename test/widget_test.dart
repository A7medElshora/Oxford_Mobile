import 'package:flutter_test/flutter_test.dart';
import 'package:tafra_learning/main.dart';

void main() {
  testWidgets('renders the Tafra authentication experience', (tester) async {
    await tester.pumpWidget(const TafraApp());
    await tester.pump();

    expect(find.text('طفرة التعليمية'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
  });
}
