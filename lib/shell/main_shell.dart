import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../tabs/absensi_tab.dart';
import '../tabs/beranda_tab.dart';
import '../tabs/pembayaran_tab.dart';
import '../tabs/pengumuman_tab.dart';
import '../tabs/profil_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = [
    'Beranda',
    'Absensi',
    'Pembayaran',
    'Pengumuman',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      BerandaTab(onNavigate: (i) => setState(() => _index = i)),
      const AbsensiTab(),
      const PembayaranTab(),
      const PengumumanTab(),
      const ProfilTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: kPrimaryLight.withValues(alpha: 0.35),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: kPrimary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available, color: kPrimary),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments, color: kPrimary),
            label: 'Pembayaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign, color: kPrimary),
            label: 'Pengumuman',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: kPrimary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}