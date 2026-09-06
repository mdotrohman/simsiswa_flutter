import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simsiswa_flutter/core/session.dart';
import 'package:simsiswa_flutter/index/index_page.dart';
import 'package:simsiswa_flutter/main.dart';
import 'package:simsiswa_flutter/shell/main_shell.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Session.init();
  });

  testWidgets('Unlogged user boots to index portal, can go to login', (WidgetTester tester) async {
    await tester.pumpWidget(const SimSiswaApp());
    await tester.pump();

    expect(find.byType(IndexPage), findsOneWidget);
    expect(find.text('SIM Siswa MTsB.U'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('SIM Siswa MTsBU'), findsOneWidget);
  });

  testWidgets('Login page can go back to index (Beranda)', (WidgetTester tester) async {
    await tester.pumpWidget(const SimSiswaApp());
    await tester.pump();

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('SIM Siswa MTsBU'), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();

    expect(find.byType(IndexPage), findsOneWidget);
    expect(find.text('SIM Siswa MTsB.U'), findsOneWidget);
  });

  testWidgets('Logged-in user skips index and opens main menu', (WidgetTester tester) async {
    Session.save(
      role: 'siswa',
      userId: 1,
      token: 't',
      username: '1',
      name: 'Tes',
      nis: '1',
      nisn: '1',
      waliNama: '',
    );

    await tester.pumpWidget(const SimSiswaApp());
    await tester.pump();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(IndexPage), findsNothing);
  });
}