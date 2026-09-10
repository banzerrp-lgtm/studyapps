import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/main.dart';

void main() {
  testWidgets('StudyApp inicia correctamente', (tester) async {
    await tester.pumpWidget(const StudyApp());

    expect(find.text('¡Hola! 👋'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
  });
}