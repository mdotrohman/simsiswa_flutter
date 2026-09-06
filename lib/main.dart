import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'index/index_page.dart';
import 'shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(initSession());
  runApp(const SimSiswaApp());
}

Future<void> initSession() async {
  try {
    await Session.init().timeout(const Duration(seconds: 8));
  } catch (_) {
    // Jika prefs gagal/gantung, tetap lanjut (login akan minta login ulang).
  }
}

class SimSiswaApp extends StatelessWidget {
  const SimSiswaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna adaptif wallpaper (Material You / Android 12+; di Android 16
    // mengikuti wallpaper). Saat tak tersedia, fallback seed emerald.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'SIM Siswa MTsBU',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light, dynamicScheme: lightDynamic),
          darkTheme: buildAppTheme(Brightness.dark, dynamicScheme: darkDynamic),
          themeMode: ThemeMode.system,
          home: const _Home(),
        );
      },
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  @override
  void initState() {
    super.initState();
    Session.revision.addListener(_onChanged);
  }

  @override
  void dispose() {
    Session.revision.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.ready) {
      return const _BootSplash();
    }
    // Halaman index hanya untuk yang belum login; yang sudah login langsung ke menu.
    return Session.isLoggedIn() ? const MainShell() : const IndexPage();
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(s.primary, Colors.black, 0.35)!, s.primary],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'SIM Siswa MTsBU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}