import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';

class BerandaTab extends StatefulWidget {
  final void Function(int index) onNavigate;
  const BerandaTab({super.key, required this.onNavigate});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  Map<String, dynamic>? _dashboard;
  bool _dashLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _dashLoading = true);
    try {
      final json = await Api.dashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = json;
        _dashLoading = false;
      });
    } catch (_) {
      // Dashboard bersifat opsional: bila gagal (mis. 404 / offline), home tetap
      // ditampilkan lengkap dengan statistik ringan internal alih-alih error card.
      if (!mounted) return;
      setState(() {
        _dashboard = null;
        _dashLoading = false;
      });
    }
  }

  String get _roleLabel => Session.role == 'wali' ? 'Wali Siswa' : 'Siswa';
  String get _initial =>
      Session.name.isEmpty ? 'S' : Session.name.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _greetingCard(),
        const SizedBox(height: 16),
        _statsSection(),
        const SizedBox(height: 20),
        _sectionHeader('Menu Layanan', 'Akses cepat fitur', Icons.grid_view_rounded),
        const SizedBox(height: 12),
        _menuGrid(),
        const SizedBox(height: 24),
        _sectionHeader('Info & Aktivitas', 'Tetap update', Icons.bolt_rounded),
        const SizedBox(height: 12),
        _activityCard(),
        const SizedBox(height: 16),
        _announcementsCard(),
        const SizedBox(height: 16),
        _featuresCard(),
        const SizedBox(height: 24),
        _logoutCard(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ------------------------------------------------------------------ header
  Widget _sectionHeader(String title, String subtitle, IconData icon) {
    final s = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [s.primary, Color.lerp(s.primary, Colors.black, 0.25)!],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- greeting
  Widget _greetingCard() {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(s.primary, Colors.black, 0.35)!, s.primary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: s.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(_initial,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang,',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                    ),
                    Text(
                      Session.name.isEmpty ? 'Siswa' : Session.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.waving_hand, color: Colors.white, size: 26),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.badge_outlined, _roleLabel),
              if (Session.nis.isNotEmpty) _chip(Icons.school_outlined, 'NIS ${Session.nis}'),
              if (Session.role == 'siswa' && Session.waliNama.isNotEmpty)
                _chip(Icons.family_restroom_outlined, 'Wali: ${Session.waliNama}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- stats
  Widget _statsSection() {
    if (_dashLoading) {
      return Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _statSkeleton()),
          ],
        ],
      );
    }
    final d = _dashboard;
    return Row(
      children: [
        _statCard(
          icon: Icons.school,
          color: Theme.of(context).colorScheme.primary,
          label: 'Siswa',
          value: (d?['total_siswa'] ?? 0).toString(),
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.people_alt,
          color: Theme.of(context).colorScheme.secondary,
          label: 'Guru',
          value: (d?['total_guru'] ?? 0).toString(),
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.meeting_room,
          color: Theme.of(context).colorScheme.tertiary,
          label: 'Kelas',
          value: (d?['total_kelas'] ?? 0).toString(),
        ),
      ],
    );
  }

  Widget _statSkeleton() {
    final s = Theme.of(context).colorScheme;
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final s = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: s.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(color: s.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- menu
  Widget _menuGrid() {
    final s = Theme.of(context).colorScheme;
    final accent = [
      s.primary,
      s.secondary,
      s.tertiary,
      Color.lerp(s.primary, Colors.black, 0.2)!,
      const Color(0xFF00796B),
    ];
    final items = [
      _MenuItem(Icons.payments_outlined, 'Pembayaran', Colors.green, () => widget.onNavigate(2)),
      _MenuItem(Icons.event_available_outlined, 'Absensi', Colors.indigo, () => widget.onNavigate(3)),
      _MenuItem(Icons.campaign_outlined, 'Pengumuman', Colors.orange, () => widget.onNavigate(4)),
      _MenuItem(Icons.person_outline, 'Profil', Colors.blue, () => widget.onNavigate(1)),
      _MenuItem(Icons.assignment_outlined, 'Tugas', Colors.purple, _sample),
      _MenuItem(Icons.schedule_rounded, 'Jadwal', Colors.teal, _sample),
      _MenuItem(Icons.book_outlined, 'E-Library', Colors.brown, _sample),
      _MenuItem(Icons.receipt_long_outlined, 'Keuangan', Colors.cyan, _sample),
      _MenuItem(Icons.fact_check_outlined, 'Hasil Ujian', Colors.deepOrange, _sample),
      _MenuItem(Icons.help_outline, 'Bantuan', Colors.blueGrey, _sample),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 14,
        crossAxisSpacing: 8,
        childAspectRatio: 0.68,
      ),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) => _menuTile(items[i], accent[i % accent.length]),
    );
  }

  void _sample() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini sedang disiapkan'), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _menuTile(_MenuItem m, Color color) {
    final s = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: m.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.08)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(m.icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              m.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: s.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- aktivitas
  Widget _activityCard() {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [s.primary.withValues(alpha: 0.14), s.primaryContainer.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timelapse_rounded, color: s.primary, size: 20),
              const SizedBox(width: 8),
              Text('Aktivitas Terakhir',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: s.onSurface)),
              const Spacer(),
              Text('Hari ini',
                  style: TextStyle(fontSize: 11.5, color: s.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _activityRow(s, Icons.check_circle_outline, 'Login berhasil',
              'Anda masuk sebagai ${_roleLabel.toLowerCase()}', isDone: true),
          _activityRow(s, Icons.lock_open_outlined, 'Sesi dimulai',
              'Sistem aman & terenkripsi (Keystore)', isDone: true),
          _activityRow(s, Icons.pending_outlined, 'Menunggu aktivitas',
              'Jelajahi menu layanan di atas', isDone: false),
        ],
      ),
    );
  }

  Widget _activityRow(ColorScheme s, IconData icon, String title, String sub, {required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isDone ? s.primary : s.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(sub, style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- pengumuman
  Widget _announcementsCard() {
    final s = Theme.of(context).colorScheme;
    return _sectionCard(
      s,
      icon: Icons.campaign_outlined,
      title: 'Pengumuman',
      trailing: TextButton(
        onPressed: () => widget.onNavigate(4),
        child: const Text('Lihat semua'),
      ),
      child: Column(
        children: [
          _announceTile(s, Icons.event_note_rounded, 'Jadwal Penilaian Akhir Semester',
              'Dimulai minggu depan — siapkan diri.', Colors.teal),
          _divider(s),
          _announceTile(s, Icons.school_outlined, 'Informasi Pembayaran SPP',
              'Pembayaran dapat dilakukan via menu Pembayaran.', Colors.orange),
          _divider(s),
          _announceTile(s, Icons.celebration_outlined, 'Semangat Belajar!',
              'Jaga kesehatan dan tetap rajin.', s.primary),
        ],
      ),
    );
  }

  Widget _announceTile(ColorScheme s, IconData icon, String title, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onNavigate(4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: s.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- fitur baru
  Widget _featuresCard() {
    final s = Theme.of(context).colorScheme;
    final features = [
      (Icons.notifications_active_outlined, 'Ganti Notifikasi', Colors.redAccent),
      (Icons.palette_outlined, 'Tema', Colors.purple),
      (Icons.security_outlined, 'Privasi & Keamanan', s.primary),
    ];
    return _sectionCard(
      s,
      icon: Icons.settings_suggest_outlined,
      title: 'Lainnya',
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) _divider(s),
            _featureTile(s, features[i].$1, features[i].$2, features[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _featureTile(ColorScheme s, IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _sample,
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, color: s.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- umum
  Widget _sectionCard(ColorScheme s,
      {required IconData icon, required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: s.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: s.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _divider(ColorScheme s) => Divider(
        height: 1,
        thickness: 0.7,
        color: s.outlineVariant.withValues(alpha: 0.35),
      );

  // ----------------------------------------------------------------- logout
  Widget _logoutCard() {
    final s = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.logout, color: s.error),
            title: const Text('Keluar?'),
            content: const Text('Anda yakin ingin keluar dari akun ini?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: s.error),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Session.logout();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: s.error,
          side: BorderSide(color: s.error.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Keluar dari Aplikasi'),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.color, this.onTap);
}