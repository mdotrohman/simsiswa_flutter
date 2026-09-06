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

/// Bilah nav bawah gaya app lama — warna mengikuti color scheme Android
/// (Material You): bar = primary wallpaper, piring aktif = tertiary.
class _OldBottomNav extends StatelessWidget {
  const _OldBottomNav({required this.selected, required this.onSelect});

  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: s.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
    final s = Theme.of(context).colorScheme;
    final rim = Color.lerp(s.primary, Colors.black, 0.35)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Blok ikon (piring aktif + ikon) melayang 50% ke atas saat aktif.
        AnimatedSlide(
          offset: active ? const Offset(0, -0.5) : Offset.zero,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 62,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Kilatan putih (mimikri splash/ink saat disentuh): semi-lingkaran
                // lembut di bawah menu aktif — TAMPIL PERSISTEN selama aktif,
                // tidak hanya saat disentuh. Ditahan tetap rendah (kompensasi
                // slide blok ikon yang naik) supaya "duduk" di bar hijau.
                AnimatedOpacity(
                  opacity: active ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut,
                  child: Transform.translate(
                    offset: const Offset(0, 36),
                    child: CustomPaint(
                      painter: const _WhiteFlashPainter(),
                      child: const SizedBox(width: 102, height: 102),
                    ),
                  ),
                ),
                // Ring "cradle" aktif: busur bawah tebal sewarna background
                // halaman (menempel ke bar, tanpa kesan mengambang), atas
                // sepenuhnya transparan.
                if (active)
                  CustomPaint(
                    painter: _CradleRingPainter(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      thickness: 16,
                    ),
                    child: const SizedBox(width: 82, height: 82),
                  ),
                // Piring aktif: aksen tertiary skema (ikut wallpaper) + rim.
                AnimatedScale(
                  scale: active ? 1.30 : 0.001,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.tertiary,
                      border: Border.all(color: rim, width: 2),
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
                    color: active ? s.onTertiary : s.onPrimary,
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
                  color: s.onPrimary,
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

/// Kilatan putih persisten — meniru splash/ink putih yang muncul saat
/// disentuh, tapi TETAP TAMPIL selama menu aktif. Digambar sebagai lingkaran
/// radial lembut (center pekat, tepi pudar); karena posisinya ditahan di
/// bagian bawah blok ikon, bagian yang terlihat adalah "setengah lingkaran
/// putih" yang duduk di bar hijau di bawah menu aktif.
class _WhiteFlashPainter extends CustomPainter {
  const _WhiteFlashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x4DFFFFFF), Color(0x22FFFFFF), Colors.transparent],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);

    // Inti kecil lebih pekat di area bawah-tengah (tempat "splash" terasa).
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2 + 8),
        radius: radius * 0.45,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 8),
      radius * 0.45,
      corePaint,
    );
  }

  @override
  bool shouldRepaint(_WhiteFlashPainter oldDelegate) => false;
}

/// Ring "cradle" aktif: busur setengah bawah (semi-circle) tebal, atas
/// transparan penuh — menyatu dengan background halaman.
class _CradleRingPainter extends CustomPainter {
  _CradleRingPainter({required this.color, required this.thickness});

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = color
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );
    // Busur bawah: dari kanan lewat dasar ke kiri (atas terbuka/transparan).
    canvas.drawArc(rect, 0, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(_CradleRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.thickness != thickness;
}