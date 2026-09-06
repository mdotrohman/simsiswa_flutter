import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simsiswa_flutter/core/session.dart';
import 'package:simsiswa_flutter/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Session.init();
  });

  testWidgets('App boots to index portal then goes to login', (WidgetTester tester) async {
    await tester.pumpWidget(const SimSiswaApp());
    await tester.pump();

    expect(find.text('SIM Siswa MTsB.U'), findsOneWidget);
    expect(find.text('Masuk / Daftar'), findsOneWidget);

    await tester.tap(find.text('Masuk / Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('SIM Siswa MTsBU'), findsOneWidget);
  });
}