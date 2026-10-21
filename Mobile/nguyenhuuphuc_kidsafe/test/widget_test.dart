import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenhuuphuc_kidsafe/main.dart';

void main() {
  testWidgets('KidSafe smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KidSafeApp());
    expect(find.byType(KidSafeApp), findsOneWidget);
  });
}
