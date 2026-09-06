import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../auth/login_page.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  Map<String, dynamic>? _siswa;
  Map<String, dynamic>? _orangtua;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loaded = false);
    try {
      final data = await Api.profil();
      if (!mounted) return;
      setState(() {
        _siswa = data['siswa'] is Map
            ? Map<String, dynamic>.from(data['siswa'] as Map)
            : null;
        final ot = data['orangtua'];
        _orangtua = ot is Map ? Map<String, dynamic>.from(ot) : null;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  String _s(String key, [String fb = '']) {
    final v = _siswa?[key];
    if (v == null) return fb;
    final t = v.toString().trim();
    return t.isEmpty ? fb : t;
  }

  String get _name =>
      _s('nama_lengkap', Session.name.isEmpty ? 'Siswa' : Session.name);
  String get _roleLabel => Session.role == 'wali' ? 'Wali Siswa' : 'Siswa';
  String get _status =>
      _s('status', Session.status.isEmpty ? 'Aktif' : Session.status);
  String get _kelas => _s('kelas', Session.kelas);
  String get _ttl {
    final t = _s('tempat_lahir', Session.tempatLahir).trim();
    final d = _s('tanggal_lahir', Session.tanggalLahir).trim();
    if (t.isEmpty && d.isEmpty) return '';
    if (t.isEmpty) return d;
    if (d.isEmpty) return t;
    return '$t, $d';
  }

  String get _fullAlamat {
    final a = _s('alamat').trim();
    if (a.isNotEmpty) return a;
    final parts = <String>[
      Session.alamat.trim(),
      _s('rt_rw'),
      _s('desa_kelurahan'),
      _s('kecamatan'),
      _s('kabupaten'),
      _s('provinsi'),
      _s('kode_pos'),
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return _buildSkeleton();
    final s = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildSection(
            context,
            accent: s.tertiary,
            icon: Icons.person_outline,
            title: 'Data Pribadi',
            rows: [
              (Icons.cake_outlined, 'Tempat & Tanggal Lahir', _ttl),
              (Icons.wc_outlined, 'Jenis Kelamin', _s('jenis_kelamin')),
              (Icons.church_outlined, 'Agama', _s('agama')),
              (Icons.self_improvement_outlined, 'Status Santri',
                  _s('status_santri')),
              (Icons.water_drop_outlined, 'Golongan Darah', _s('golongan_darah')),
              (Icons.exposure_outlined, 'Anak Ke', _s('anak_ke')),
              (Icons.groups_outlined, 'Jumlah Saudara', _s('jumlah_saudara')),
              (Icons.sports_esports_outlined, 'Hobi', _s('hobi')),
              (Icons.flag_outlined, 'Cita-cita', _s('cita_cita')),
              (Icons.phone_outlined, 'No. HP', _s('no_hp')),
              (Icons.email_outlined, 'Email', _s('email')),
              (Icons.credit_card_outlined, 'NIK', _s('nik')),
              (Icons.folder_shared_outlined, 'No. KK', _s('no_kk')),
              (Icons.description_outlined, 'Akta Lahir', _s('akta_lahir')),
              (Icons.commute_outlined, 'Transportasi', _s('transportasi')),
              (Icons.route_outlined, 'Jarak ke Sekolah', _s('jarak')),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            accent: const Color(0xFF00897B),
            icon: Icons.home_outlined,
            title: 'Alamat',
            rows: [
              (Icons.location_on_outlined, 'Alamat Rumah', _fullAlamat),
              (Icons.signpost_outlined, 'RT / RW', _s('rt_rw')),
              (Icons.location_city_outlined, 'Desa / Kelurahan',
                  _s('desa_kelurahan')),
              (Icons.map_outlined, 'Kecamatan', _s('kecamatan')),
              (Icons.map_rounded, 'Kabupaten / Kota', _s('kabupaten')),
              (Icons.public_outlined, 'Provinsi', _s('provinsi')),
              (Icons.mail_outlined, 'Kode Pos', _s('kode_pos')),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            accent: const Color(0xFFF57C00),
            icon: Icons.school_outlined,
            title: 'Pendidikan',
            rows: [
              (Icons.segment_outlined, 'Kelas', _kelas),
              (Icons.format_list_numbered_outlined, 'Tingkat', _s('tingkat')),
              (Icons.calendar_month_outlined, 'Tahun Ajaran',
                  _s('tahun_ajaran')),
              (Icons.event_note_outlined, 'Semester', _s('semester')),
              (Icons.date_range_outlined, 'Tanggal Masuk',
                  _s('tanggal_masuk')),
              (Icons.verified_user_outlined, 'Status', _status),
            ],
          ),
          if (_buildOrangTuaHeader(context) != null) ...[
            const SizedBox(height: 16),
            _buildOrangTua(context),
          ],
          const SizedBox(height: 16),
          _buildAccount(context),
          const SizedBox(height: 16),
          _buildLogout(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- header
  Widget _buildHeader(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final foto = _s('foto_url').trim();
    final useFoto = foto.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(s.primary, Colors.black, 0.35)!, s.primary],
        ),
        borderRadius: BorderRadius.circular(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: useFoto
                    ? ClipOval(
                        child: Image.network(
                          foto,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroInitial,
                        ),
                      )
                    : _heroInitial,
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
                            _name,
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
                value: _heroNisNisn,
              ),
              const SizedBox(width: 8),
              _heroTile(
                icon: Icons.cake_outlined,
                label: 'Tempat & Tanggal Lahir',
                value: _ttl.isEmpty ? '-' : _ttl,
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
                value: _fullAlamat.isEmpty ? '-' : _fullAlamat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _initial =>
      _name.isEmpty ? 'S' : _name.trim().characters.first.toUpperCase();

  Widget get _heroInitial => Center(
        child: Text(_initial,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
      );

  String get _heroNisNisn {
    final n = _s('nis', Session.nis).trim();
    final nn = _s('nisn', Session.nisn).trim();
    if (n.isEmpty && nn.isEmpty) return '-';
    if (n.isEmpty) return nn;
    if (nn.isEmpty) return n;
    return '$n / $nn';
  }

  Widget _identityBadge() {
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
          Text(_status.isEmpty ? 'Aktif' : _status,
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

  // ----------------------------------------------------------------- section
  Widget _buildSection(
    BuildContext context, {
    required Color accent,
    required IconData icon,
    required String title,
    required List<(IconData, String, String)> rows,
  }) {
    final s = Theme.of(context).colorScheme;
    final tiles = <Widget>[];
    for (final (ic, label, value) in rows) {
      if (value.trim().isEmpty) continue;
      if (tiles.isNotEmpty) tiles.add(_divider(s));
      tiles.add(_infoTile(ic, label, value, accent));
    }
    if (tiles.isEmpty) return const SizedBox.shrink();
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${tiles.length ~/ 2 + tiles.length % 2} item',
                    style: TextStyle(fontSize: 11, color: accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tiles,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color accent) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: s.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme s) => Divider(
        height: 1,
        thickness: 0.7,
        color: s.outlineVariant.withValues(alpha: 0.35),
      );

  // -------------------------------------------------------------- orang tua
  bool get _hasOrangTua {
    final ot = _orangtua;
    if (ot == null) return false;
    return ['ayah', 'ibu', 'wali'].any((k) => ot[k] is Map);
  }

  Widget? _buildOrangTuaHeader(BuildContext context) {
    return _hasOrangTua ? const SizedBox.shrink() : null;
  }

  Widget _buildOrangTua(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final ot = _orangtua!;
    const accent = Color(0xFF3949AB);
    final cards = <Widget>[];
    final labels = {'ayah': 'Ayah', 'ibu': 'Ibu', 'wali': 'Wali'};
    for (final entry in labels.entries) {
      final p = ot[entry.key];
      if (p is! Map) continue;
      final pm = Map<String, dynamic>.from(p);
      final n = parenString(pm, 'nama', entry.value);
      final tiles = <(IconData, String, String)>[
        for (final (ic, key) in [
          (Icons.work_outline, 'Pekerjaan'),
          (Icons.school_outlined, 'Pendidikan'),
          (Icons.phone_outlined, 'No. HP'),
          (Icons.payments_outlined, 'Penghasilan'),
          (Icons.home_outlined, 'Alamat'),
        ])
          if (parenString(pm, _byKeys(key), '').isNotEmpty)
            (ic, key, parenString(pm, _byKeys(key), '')),
      ];
      if (tiles.isEmpty) continue;
      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: s.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.black, 0.2)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        n.isEmpty ? '?' : n.trim().characters.first.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.value,
                            style: TextStyle(
                                fontSize: 11,
                                color: s.onSurfaceVariant)),
                        Text(n,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final (ic, label, value) in tiles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(ic, size: 18, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: s.onSurfaceVariant)),
                            Text(value.trim(),
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (cards.isEmpty) return const SizedBox.shrink();
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child:
                    Icon(Icons.family_restroom_outlined, size: 19, color: accent),
              ),
              const SizedBox(width: 10),
              Text('Orang Tua / Wali',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ...cards,
        ],
      ),
    );
  }

  String parenString(Map<String, dynamic> m, String key, String fb) {
    final v = m[key];
    if (v == null) return fb;
    final t = v.toString().trim();
    return t.isEmpty ? fb : t;
  }

  String _byKeys(String label) => switch (label) {
        'Pekerjaan' => 'pekerjaan',
        'Pendidikan' => 'pendidikan',
        'No. HP' => 'no_hp',
        'Penghasilan' => 'penghasilan',
        'Alamat' => 'alamat',
        _ => 'nama',
      };

  // ------------------------------------------------------------------ akun
  Widget _buildAccount(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final rows = <(IconData, String, String)>[
      (Icons.alternate_email, 'Username', Session.username),
      (Icons.badge_outlined, 'Peran', _roleLabel),
      (Icons.family_restroom_outlined, 'Wali', Session.waliNama.trim()),
    ];
    final tiles = <Widget>[];
    for (final (ic, label, value) in rows) {
      if (value.trim().isEmpty) continue;
      if (tiles.isNotEmpty) tiles.add(_divider(s));
      tiles.add(_infoTile(ic, label, value, s.primary));
    }
    if (tiles.isEmpty) return const SizedBox.shrink();
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
                child:
                    Icon(Icons.manage_accounts_outlined, size: 19, color: s.primary),
              ),
              const SizedBox(width: 10),
              Text('Akun',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ...tiles,
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: s.error),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  Navigator.of(ctx).pop();
                  await Session.logout();
                  if (!mounted) return;
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
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

  Widget _buildSkeleton() {
    final s = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: s.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        for (var i = 0; i < 3; i++) ...[
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: s.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ],
    );
  }
}