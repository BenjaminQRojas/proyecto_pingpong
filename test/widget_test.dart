import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pingpong/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PingPongApp());
    await tester.pumpAndSettle();
    expect(find.text('PingPong IoT Control'), findsOneWidget);
  });
}
