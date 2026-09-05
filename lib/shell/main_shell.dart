import 'package:flutter/material.dart';

import '../core/session.dart';
import '../tabs/absensi_tab.dart';
import '../tabs/beranda_tab.dart';
import '../tabs/pembayaran_tab.dart';
import '../tabs/pengumuman_tab.dart';
import '../tabs/profil_tab.dart';

/// Bottom nav meniru app lama (Java): urutan/index
/// Home → Profil → Bayar → Absensi → Info → Menu (Menu = dialog daftar menu),
/// serta gaya desainnya: bar hijau tua #00664F, ikon putih, item aktif berupa
/// lingkaran putih + piring hijau yang membesar & melayang ke atas.
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

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.person_outline, 'Profil'),
    (Icons.payments_outlined, 'Bayar'),
    (Icons.event_available_outlined, 'Absensi'),
    (Icons.campaign_outlined, 'Info'),
    (Icons.menu, 'Menu'),
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
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Mode terang/gelap',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              Session.setThemeModePref(isDark ? 'l' : 'd');
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _OldBottomNav(
          selected: _index,
          onSelect: (i) {
            if (i == 5) {
              _openMenu();
              return;
            }
            setState(() => _index = i);
          },
        ),
      ),
    );
  }
}

const _kNavGreen = Color(0xFF00664F);
const _kNavRingGreen = Color(0xFF00483A);
const _kNavDiscGreen = Color(0xFF0FA576);

/// Bilah nav bawah gaya app lama.
class _OldBottomNav extends StatelessWidget {
  const _OldBottomNav({required this.selected, required this.onSelect});

  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: _kNavGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _MainShellState._items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(i),
                splashColor: Colors.white24,
                borderRadius: BorderRadius.circular(12),
                child: _OldNavItem(
                  icon: _MainShellState._items[i].$1,
                  label: _MainShellState._items[i].$2,
                  active: i == selected,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OldNavItem extends StatelessWidget {
  const _OldNavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Seluruh blok ikon (lingkaran + piring + ikon) melayang 50% ke atas
        // saat aktif; label tetap diam sangat dekat di bawahnya.
        AnimatedSlide(
          offset: active ? const Offset(0, -0.5) : Offset.zero,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Lingkaran luar (ring putih + anting tebal) yang membesar saat aktif.
                AnimatedScale(
                  scale: active ? 1.35 : 0.001,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: _kNavRingGreen, width: 8),
                    ),
                  ),
                ),
                // Piring dalam: warna BERBEDA dari bar (aksen emerald).
                AnimatedScale(
                  scale: active ? 1.35 : 0.001,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kNavDiscGreen,
                    ),
                  ),
                ),
                _NavIcon(icon: icon, active: active),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Label digeser naik sedikit agar lebih rapat ke blok ikon.
        Transform.translate(
          offset: const Offset(0, -4),
          child: AnimatedScale(
            scale: active ? 1.0 : 0.96,
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 0.3,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: active ? 30 : 24,
      color: Colors.white,
    );
  }
}