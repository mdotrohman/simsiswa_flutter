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
  bool _profilLoaded = false;

  String get _roleLabel => Session.role == 'wali' ? 'Wali Siswa' : 'Siswa';
  String get _initial =>
      Session.name.isEmpty ? 'S' : Session.name.characters.first.toUpperCase();

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    if (Session.role != 'siswa' || Session.userId <= 0 || _profilLoaded) return;
    _profilLoaded = true;
    try {
      final data = await Api.profil();
      final siswa = data['siswa'];
      if (siswa is Map) {
        await Session.applyProfil(
          status: (siswa['status'] ?? '').toString(),
          kelas: (siswa['kelas'] ?? '').toString(),
          tempatLahir: (siswa['tempat_lahir'] ?? '').toString(),
          tanggalLahir: (siswa['tanggal_lahir'] ?? '').toString(),
          alamat: (siswa['alamat'] ?? '').toString(),
        );
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Profil siswa bersifat opsional; hero tetap tampil dari data login.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _greetingCard(),
            const SizedBox(height: 20),
            _sectionHeader('Menu Layanan', 'Akses cepat fitur', Icons.grid_view_rounded,
                trailing: _allMenusBadge()),
            const SizedBox(height: 12),
            _menuBox(),
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
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ header
  Widget _sectionHeader(String title, String subtitle, IconData icon,
      {Widget? trailing}) {
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
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _allMenusBadge() {
    final s = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _showAllMenus,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(s.primary, Colors.black, 0.25)!, s.primary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: s.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps_rounded, color: Colors.white, size: 15),
            SizedBox(width: 5),
            Text('Menu lainnya',
                style: TextStyle(
                    color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(_initial,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            Session.name.isEmpty ? 'Siswa' : Session.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _identityBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_roleLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroTile(
                icon: Icons.badge_outlined,
                label: 'NIS / NISN',
                value: _nisNisn,
              ),
              const SizedBox(width: 8),
              _heroTile(
                icon: Icons.cake_outlined,
                label: 'Tempat & Tanggal Lahir',
                value: _ttl,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroTile(
                icon: Icons.home_outlined,
                label: 'Alamat Rumah',
                value: Session.alamat.isEmpty ? '-' : Session.alamat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _nisNisn {
    final n = Session.nis.trim();
    final nn = Session.nisn.trim();
    if (n.isEmpty && nn.isEmpty) return '-';
    if (n.isEmpty) return nn;
    if (nn.isEmpty) return n;
    return '$n / $nn';
  }

  String get _ttl {
    final t = Session.tempatLahir.trim();
    final d = Session.tanggalLahir.trim();
    if (t.isEmpty && d.isEmpty) return '-';
    if (t.isEmpty) return d;
    if (d.isEmpty) return t;
    return '$t, $d';
  }

  Widget _identityBadge() {
    final status = Session.status.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, size: 13, color: Color(0xFF4ADE80)),
          const SizedBox(width: 4),
          Text(status.isEmpty ? 'Aktif' : status,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _heroTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 10.5)),
                  const SizedBox(height: 2),
                  Text(value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- menu
  Widget _menuBox() {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: _menuGrid(),
    );
  }

  Widget _menuGrid() {
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) => _menuTile(items[i]),
    );
  }

  void _sample() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini sedang disiapkan'), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _menuTile(_MenuItem m) {
    final s = Theme.of(context).colorScheme;
    return InkResponse(
      radius: 42,
      onTap: m.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(m.icon, color: m.color, size: 40),
          const SizedBox(height: 8),
          Text(
            m.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: s.onSurface,
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

  // ------------------------------------------------------ semua menu (17)
  List<_MenuGroup> get _menuGroups => [
        _MenuGroup('Pembelajaran', Icons.school_outlined, Colors.purple, [
          _MenuItem(Icons.edit_note_rounded, 'Tugas', Colors.purple, _sample),
          _MenuItem(Icons.schedule_rounded, 'Jadwal', Colors.blueGrey, _sample),
          _MenuItem(Icons.menu_book_outlined, 'E-Library', Colors.brown, _sample),
          _MenuItem(Icons.fact_check_outlined, 'Hasil Ujian', Colors.deepOrange, _sample),
          _MenuItem(Icons.assignment_turned_in_outlined, 'Raport', Colors.green, _sample),
        ]),
        _MenuGroup('Keuangan', Icons.account_balance_wallet_outlined, Colors.green, [
          _MenuItem(Icons.payments_outlined, 'Pembayaran', Colors.green, () => widget.onNavigate(2)),
          _MenuItem(Icons.receipt_long_outlined, 'Riwayat Pembayaran', Colors.teal, _sample),
          _MenuItem(Icons.savings_outlined, 'Saldo & Keuangan', Colors.cyan, _sample),
        ]),
        _MenuGroup('Kehadiran', Icons.event_available_outlined, Colors.indigo, [
          _MenuItem(Icons.event_available_outlined, 'Absensi', Colors.indigo, () => widget.onNavigate(3)),
          _MenuItem(Icons.note_add_outlined, 'Izin / Sakit', Colors.redAccent, _sample),
        ]),
        _MenuGroup('Informasi & Lainnya', Icons.apps_outlined, Colors.orange, [
          _MenuItem(Icons.campaign_outlined, 'Pengumuman', Colors.orange, () => widget.onNavigate(4)),
          _MenuItem(Icons.person_outline, 'Profil', Colors.blue, () => widget.onNavigate(1)),
          _MenuItem(Icons.event_note_outlined, 'Agenda Kegiatan', Colors.pink, _sample),
          _MenuItem(Icons.newspaper_outlined, 'Berita Madrasah', Colors.blueGrey, _sample),
          _MenuItem(Icons.emoji_events_outlined, 'Prestasi', Colors.amber, _sample),
          _MenuItem(Icons.sports_soccer_outlined, 'Ekstrakurikuler', Colors.teal, _sample),
          _MenuItem(Icons.help_outline, 'Bantuan', Colors.brown, _sample),
        ]),
      ];

  void _showAllMenus() {
    final s = Theme.of(context).colorScheme;
    final groups = _menuGroups;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: s.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            s.primary,
                            Color.lerp(s.primary, Colors.black, 0.25)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                          child: Icon(Icons.apps_rounded, color: Colors.white, size: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Semua Menu',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          Text('${_menuCount(groups)} layanan . Ketuk grup untuk perluas',
                              style: TextStyle(
                                  fontSize: 12, color: s.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, color: s.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (var g = 0; g < groups.length; g++) ...[
                      _menuGroupTile(groups[g], initiallyExpanded: g == 0),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _menuCount(List<_MenuGroup> groups) =>
      groups.fold(0, (sum, g) => sum + g.items.length);

  Widget _menuGroupTile(_MenuGroup g, {required bool initiallyExpanded}) {
    final s = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          iconColor: s.onSurfaceVariant,
          collapsedIconColor: s.onSurfaceVariant,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: g.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(g.icon, color: g.color, size: 20),
          ),
          title: Text(g.name,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          subtitle: Text('${g.items.length} menu',
              style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          children: [
            for (final m in g.items)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 62, right: 16),
                dense: true,
                leading: Icon(m.icon, color: m.color, size: 24),
                title: Text(m.label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.chevron_right,
                    size: 18, color: s.onSurfaceVariant),
                onTap: () {
                  Navigator.of(context).pop();
                  m.onTap();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuGroup {
  final String name;
  final IconData icon;
  final Color color;
  final List<_MenuItem> items;
  _MenuGroup(this.name, this.icon, this.color, this.items);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.color, this.onTap);
}