import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../tabs/absensi_tab.dart';
import '../tabs/beranda_tab.dart';
import '../tabs/pembayaran_tab.dart';
import '../tabs/pengumuman_tab.dart';
import '../tabs/profil_tab.dart';

/// Tata letak nav bawah meniru app lama (Java): urutan/index
/// Home → Profil → Bayar → Absensi → Info → Menu (Menu = dialog daftar menu).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = [
    'Beranda',
    'Profil',
    'Pembayaran',
    'Absensi',
    'Pengumuman',
    'Menu',
  ];

  static const _menuItems = [
    'Beranda',
    'Profil',
    'Pembayaran',
    'Absensi',
    'Pengumuman',
  ];

  void _openMenu() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _menuItems.length; i++)
              ListTile(
                leading: Icon(
                  switch (i) {
                    0 => Icons.home_outlined,
                    1 => Icons.person_outline,
                    2 => Icons.payments_outlined,
                    3 => Icons.event_available_outlined,
                    _ => Icons.campaign_outlined,
                  },
                ),
                title: Text(_menuItems[i]),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _index = i);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BerandaTab(onNavigate: (i) => setState(() => _index = i)),
      const ProfilTab(),
      const PembayaranTab(),
      const AbsensiTab(),
      const PengumumanTab(),
      const SizedBox.shrink(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 5) {
            _openMenu();
            return;
          }
          setState(() => _index = i);
        },
        backgroundColor: Colors.white,
        indicatorColor: kPrimaryLight.withValues(alpha: 0.35),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: kPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: kPrimary),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments, color: kPrimary),
            label: 'Bayar',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available, color: kPrimary),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign, color: kPrimary),
            label: 'Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_outlined),
            selectedIcon: Icon(Icons.menu_open, color: kPrimary),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}