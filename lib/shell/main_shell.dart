import 'dart:math' as math;

import 'package:flutter/material.dart';

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
      appBar: AppBar(title: Text(_titles[_index])),
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
const _kNavRim = Color(0xFF004A3A);
const _kActiveDisc = Color(0xFF10B981);

/// Bilah nav bawah gaya app lama.
class _OldBottomNav extends StatelessWidget {
  const _OldBottomNav({required this.selected, required this.onSelect});

  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bowlColor = dark ? const Color(0xFF00543F) : const Color(0xFF00755A);

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: _kNavGreen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.16),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Busur penuh di belakang item aktif: semi-circle besar menonjol
          // keluar dari tepi atas bar hijau (efek "notch"/V yang jelas).
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (selected >= _MainShellState._items.length ||
                    selected == 5) {
                  return const SizedBox.shrink();
                }
                final cell = constraints.maxWidth /
                    _MainShellState._items.length;
                final cx = selected * cell + cell / 2;
                // Busur ditarik pada tepi atas bar, membesar ke atas halaman.
                return CustomPaint(
                  painter: _BowlAtEdgePainter(
                    cx: cx,
                    bandColor: bowlColor,
                    glowColor: _kActiveDisc.withValues(alpha: 0.22),
                    rimColor: const Color(0xFF34D399),
                    arcRadius: 46,
                    bandThickness: 16,
                    rimThickness: 3.5,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                );
              },
            ),
          ),
          // Ikon/ring aktif render di atas busur.
          Positioned.fill(
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
          ),
        ],
      ),
    );
  }
}

/// Busur "notch" yang ditarik pada tepi atas bar hijau, mengelilingi item
/// aktif (semi-circle penuh membesar ke atas halaman). Pita tebal + rim
/// + glow → lengkungannya sangat kontras dan terlihat seperti "V".
class _BowlAtEdgePainter extends CustomPainter {
  _BowlAtEdgePainter({
    required this.cx,
    required this.bandColor,
    required this.glowColor,
    required this.rimColor,
    required this.arcRadius,
    required this.bandThickness,
    required this.rimThickness,
  });

  final double cx;
  final Color bandColor;
  final Color glowColor;
  final Color rimColor;
  final double arcRadius;
  final double bandThickness;
  final double rimThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final r = arcRadius;
    // Pusat busur tepat di tepi atas bar (y=0) → setengah-lingkaran membesar
    // ke ATAS halaman, sehingga lengkungannya muncul jelas seperti "V"/notch
    // dari belakang menu aktif. Busur atas: dari (cx-r, 0) membalik ke atas
    // lalu turun ke (cx+r, 0), "mulut" terbuka rata di dasar bar.
    final rect = Rect.fromCircle(center: Offset(cx, 0), radius: r);

    // 1. Glow lembut semi-circle menonjol ke atas halaman.
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final glowPath = Path()
      ..addArc(rect.inflate(14), math.pi, math.pi)
      ..close();
    canvas.drawPath(glowPath, glow);

    // 2. Pita tebal hijau lebih terang: busur setengah-atas.
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bandThickness
      ..strokeCap = StrokeCap.round
      ..color = bandColor;
    canvas.drawArc(rect, math.pi, math.pi, false, band);

    // 3. Rim emerald di sisi dalam — bingkai tajam pemisah antara busur dan
    //    piring ikon.
    final rimRect = rect.deflate(bandThickness / 2 - 1);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimThickness
      ..strokeCap = StrokeCap.round
      ..color = rimColor;
    canvas.drawArc(rimRect, math.pi, math.pi, false, rim);
  }

  @override
  bool shouldRepaint(_BowlAtEdgePainter oldDelegate) =>
      oldDelegate.cx != cx ||
      oldDelegate.bandColor != bandColor ||
      oldDelegate.arcRadius != arcRadius;
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
        // Blok ikon (piring aktif + ikon) melayang ~35% ke atas saat aktif
        // (tidak terlalu tinggi agar busur setengah-lingkaran masih menyilang
        // area bar hijau dan terlihat jelas).
        AnimatedSlide(
          offset: active ? const Offset(0, -0.22) : Offset.zero,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 62,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
children: [
                // Piring aktif: satu aksen emerald bersih + rim tipis.
                AnimatedScale(
                  scale: active ? 1.30 : 0.001,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kActiveDisc,
                      border: Border.all(color: _kNavRim, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: active ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    icon,
                    size: active ? 30 : 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Label dinaikkan agar menempel rapat di bawah piring ikon.
        Transform.translate(
          offset: const Offset(0, -8),
          child: AnimatedSlide(
            offset: active ? const Offset(0, -0.25) : const Offset(0, -0.05),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
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
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
