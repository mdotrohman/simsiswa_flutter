import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/session.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  static const _tabs = [
    (Icons.person_outline, 'Siswa'),
    (Icons.school_outlined, 'Sekolah'),
    (Icons.man_outlined, 'Ayah'),
    (Icons.woman_outlined, 'Ibu'),
    (Icons.verified_user_outlined, 'Wali'),
    (Icons.folder_outlined, 'Lampiran'),
    (Icons.history_edu_outlined, 'Riwayat'),
  ];

  Map<String, dynamic>? _data;
  int _tab = 0;
  bool _loaded = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loaded = false;
      _error = '';
    });
    try {
      final data = await Api.profil();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loaded = true;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _error = e.toString();
      });
    }
  }

  // ------------------------------------------------------------- accessor
  Map<String, dynamic>? _m(Object? v) => v is Map
      ? Map<String, dynamic>.from(v)
      : null;

  Map<String, dynamic>? get _siswa => _m(_data?['siswa']);

  Map<String, dynamic>? get _sekolah => _m(_data?['sekolah_asal']);

  Map<String, dynamic>? get _mutasi => _m(_data?['mutasi']);

  Map<String, dynamic>? _ortu(String key) {
    final o = _data?['orangtua'];
    if (o is Map) {
      for (final e in o.entries) {
        if (_norm(e.key) == key) return _m(e.value);
      }
    } else if (o is List) {
      for (final e in o.whereType<Map>()) {
        final j = e['jenis']?.toString().toLowerCase() ??
            e['hubungan']?.toString().toLowerCase() ??
            '';
        if (j.trim() == key) return _m(e);
      }
    }
    return null;
  }

  String _norm(String s) => s.trim().toLowerCase();

  Map<String, dynamic>? get _ayah => _ortu('ayah');
  Map<String, dynamic>? get _ibu => _ortu('ibu');
  Map<String, dynamic>? get _wali => _ortu('wali');

  List<Map<String, dynamic>> get _lampiran {
    final l = _data?['lampiran'];
    if (l is! List) return const [];
    return l.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> get _riwayat {
    final l = _data?['riwayat_kelas'];
    if (l is! List) return const [];
    return l.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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
      _s('rt', ''),
      _s('desa_kelurahan'),
      _s('kecamatan'),
      _s('kabupaten'),
      _s('provinsi'),
      _s('kode_pos'),
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get _rtRw {
    final r = _s('rt').trim();
    final w = _s('rw').trim();
    if (r.isEmpty && w.isEmpty) return '';
    if (r.isEmpty) return 'RW $w';
    if (w.isEmpty) return 'RT $r';
    return 'RT $r / RW $w';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return _buildSkeleton();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildHeader(context),
          const SizedBox(height: 14),
          _buildTabBar(context),
          const SizedBox(height: 14),
          if (_data == null && _error.isNotEmpty) ...[
            _buildErrorBanner(context),
            const SizedBox(height: 14),
          ],
          _buildTabBody(context),
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

  // -------------------------------------------------------------- tab bar
  Widget _buildTabBar(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 8),
              child: _tabChip(s, i),
            ),
        ],
      ),
    );
  }

  Widget _tabChip(ColorScheme s, int i) {
    final active = i == _tab;
    final (icon, label) = _tabs[i];
    final count = switch (i) {
      0 => _siswa == null ? 0 : 1,
      1 => (_sekolah != null ? 1 : 0) + (_mutasi != null ? 1 : 0),
      2 => _ayah == null ? 0 : 1,
      3 => _ibu == null ? 0 : 1,
      4 => _wali == null ? 0 : 1,
      5 => _lampiran.where((e) => (e['tersedia'] ?? false) == true).length,
      _ => _riwayat.length,
    };
    return Material(
      color: active
          ? s.primary
          : s.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? s.primary
                  : s.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16,
                  color: active
                      ? s.onPrimary
                      : count > 0
                          ? s.primary
                          : s.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: active ? s.onPrimary : s.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.25)
                        : s.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : s.primary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- konten
  Widget _buildTabBody(BuildContext context) {
    return switch (_tab) {
      0 => _buildSiswaTab(context),
      1 => _buildSekolahTab(context),
      2 => _buildOrtuTab(context, 'ayah', _ayah),
      3 => _buildOrtuTab(context, 'ibu', _ibu),
      4 => _buildOrtuTab(context, 'wali', _wali),
      5 => _buildLampiranTab(context),
      _ => _buildRiwayatTab(context),
    };
  }

  Widget _buildSiswaTab(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSection(
          context,
          accent: s.tertiary,
          icon: Icons.person_outline,
          title: 'Data Pribadi',
          rows: [
            (Icons.cake_outlined, 'Tempat & Tanggal Lahir', _ttl),
            (Icons.wc_outlined, 'Jenis Kelamin', _s('jenis_kelamin')),
            (Icons.church_outlined, 'Agama', _s('agama')),
            (Icons.alternate_email, 'Nama Panggilan', _s('nama_panggilan')),
            (Icons.self_improvement_outlined, 'Status Santri',
                _s('status_santri')),
            (Icons.bed_outlined, 'Status Asrama', _s('status_asrama')),
            (Icons.label_outlined, 'Kategori', _s('kategori')),
            (Icons.water_drop_outlined, 'Golongan Darah', _s('golongan_darah')),
            (Icons.exposure_outlined, 'Anak Ke', _s('anak_ke')),
            (Icons.groups_outlined, 'Jumlah Saudara', _s('jumlah_saudara')),
            (Icons.sports_esports_outlined, 'Hobi', _s('hobi')),
            (Icons.flag_outlined, 'Cita-cita', _s('cita_cita')),
          ],
        ),
        const SizedBox(height: 14),
        _buildSection(
          context,
          accent: const Color(0xFF00897B),
          icon: Icons.home_outlined,
          title: 'Alamat',
          rows: [
            (Icons.location_on_outlined, 'Alamat Rumah', _fullAlamat),
            (Icons.signpost_outlined, 'RT / RW', _rtRw),
            (Icons.location_city_outlined, 'Desa / Kelurahan',
                _s('desa_kelurahan')),
            (Icons.map_outlined, 'Kecamatan', _s('kecamatan')),
            (Icons.map_rounded, 'Kabupaten / Kota', _s('kabupaten')),
            (Icons.public_outlined, 'Provinsi', _s('provinsi')),
            (Icons.mail_outlined, 'Kode Pos', _s('kode_pos')),
          ],
        ),
        const SizedBox(height: 14),
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
            (Icons.date_range_outlined, 'Tanggal Masuk', _s('tanggal_masuk')),
            (Icons.event_available_outlined, 'Tanggal Daftar',
                _s('tanggal_daftar')),
            (Icons.verified_user_outlined, 'Status', _status),
            (Icons.commute_outlined, 'Transportasi', _s('transportasi')),
            (Icons.route_outlined, 'Jarak Rumah → Sekolah',
                _s('jarak_rumah_ke_sekolah')),
            (Icons.timer_outlined, 'Waktu Perjalanan', _s('waktu_perjalanan')),
          ],
        ),
        const SizedBox(height: 14),
        _buildSection(
          context,
          accent: const Color(0xFF4E342E),
          icon: Icons.favorite_outline,
          title: 'Kesehatan',
          rows: [
            (Icons.accessibility_new_outlined, 'Disabilitas',
                _s('disabilitas')),
            (Icons.sick_outlined, 'Alergi', _s('alergi')),
            (Icons.medical_information_outlined, 'Riwayat Penyakit',
                _s('riwayat_penyakit')),
            (Icons.height_outlined, 'Tinggi Badan (cm)',
                _s('tinggi_badan')),
            (Icons.monitor_weight_outlined, 'Berat Badan (kg)',
                _s('berat_badan')),
            (Icons.trending_up, 'TB Saat Masuk (cm)',
                _s('tinggi_badan_saat_masuk')),
            (Icons.scale_outlined, 'BB Saat Masuk (kg)',
                _s('berat_badan_saat_masuk')),
            (Icons.apartment_outlined, 'Pondok', _s('pondok')),
          ],
        ),
        const SizedBox(height: 14),
        _buildSection(
          context,
          accent: const Color(0xFF3949AB),
          icon: Icons.contact_page_outlined,
          title: 'Kontak & Dokumen',
          rows: [
            (Icons.phone_outlined, 'No. HP', _s('no_hp')),
            (Icons.email_outlined, 'Email', _s('email')),
            (Icons.credit_card_outlined, 'NIK', _s('nik')),
            (Icons.folder_shared_outlined, 'No. KK', _s('no_kk')),
            (Icons.description_outlined, 'Akta Lahir', _s('akta_lahir')),
            (Icons.savings_outlined, 'No. KIP', _s('no_kip')),
            (Icons.card_membership_outlined, 'KIP', _s('kip')),
            (Icons.volunteer_activism_outlined, 'PKH', _s('pkh')),
          ],
        ),
      ],
    );
  }

  Widget _buildRiwayatTab(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    if (_riwayat.isEmpty) {
      return _emptyCard(s, Icons.history_edu_outlined,
          'Belum ada riwayat kelas.', 'Perjalanan kelas siswa akan tampil di sini.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildRiwayat(context)],
    );
  }

  Widget _buildRiwayat(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final items = <Widget>[];
    for (var i = 0; i < _riwayat.length; i++) {
      final r = _riwayat[i];
      final kelas = r['kelas']?.toString() ?? '';
      final tahun = r['tahun_ajaran']?.toString() ?? '';
      final smt = r['semester']?.toString() ?? '';
      final status = r['status']?.toString() ?? '';
      final from = r['tanggal_masuk']?.toString() ?? '';
      final to = r['tanggal_keluar']?.toString() ?? '';
      final isLast = i == _riwayat.length - 1;
      items.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.primary,
                      boxShadow: [
                        BoxShadow(
                          color: s.primary.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: s.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            kelas.isEmpty ? 'Kelas' : kelas,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: s.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: s.primary)),
                          ),
                      ],
                    ),
                    if (tahun.isNotEmpty || smt.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [tahun, smt].where((e) => e.isNotEmpty).join(' • '),
                        style: TextStyle(
                            fontSize: 11.5, color: s.onSurfaceVariant),
                      ),
                    ],
                    if (from.isNotEmpty || to.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        ['$from (masuk)', '$to (keluar)']
                            .where((e) => !e.startsWith(' ('))
                            .join(' — '),
                        style: TextStyle(
                            fontSize: 11,
                            color: s.onSurfaceVariant.withValues(alpha: 0.8)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ));
    }
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
                child: Icon(Icons.history_edu_outlined, size: 19, color: s.primary),
              ),
              const SizedBox(width: 10),
              const Text('Riwayat Kelas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSekolahTab(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final sk = _sekolah;
    final mu = _mutasi;
    if (sk == null && mu == null) {
      return _emptyCard(s, Icons.school_outlined, 'Sekolah asal belum dicatat.',
          'Data sekolah asal & mutasi siswa.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sk != null)
          _buildSection(
            context,
            accent: s.primary,
            icon: Icons.school_outlined,
            title: 'Sekolah Asal',
            rows: [
              (Icons.account_balance_outlined, 'Jenis Sekolah',
                  sk['jenis_sekolah']?.toString() ?? ''),
              (Icons.business_outlined, 'Nama Sekolah',
                  sk['nama_sekolah']?.toString() ?? ''),
              (Icons.qr_code_outlined, 'NPSN', sk['npsn']?.toString() ?? ''),
              (Icons.tag_outlined, 'NSM', sk['nsm']?.toString() ?? ''),
              (Icons.location_on_outlined, 'Alamat',
                  sk['alamat']?.toString() ?? ''),
            ],
          ),
        if (sk != null && mu != null) const SizedBox(height: 14),
        if (mu != null)
          _buildSection(
            context,
            accent: const Color(0xFF6D4C41),
            icon: Icons.swap_vert_circle_outlined,
            title: 'Riwayat Mutasi',
            rows: [
              (Icons.business_outlined, 'Nama Sekolah',
                  mu['nama_sekolah']?.toString() ?? ''),
              (Icons.qr_code_outlined, 'NPSN', mu['npsn']?.toString() ?? ''),
              (Icons.tag_outlined, 'NSM', mu['nsm']?.toString() ?? ''),
              (Icons.location_on_outlined, 'Alamat',
                  mu['alamat']?.toString() ?? ''),
            ],
          ),
      ],
    );
  }

  Widget _buildOrtuTab(
      BuildContext context, String jenis, Map<String, dynamic>? p) {
    final s = Theme.of(context).colorScheme;
    final label = switch (jenis) {
      'ayah' => 'Ayah',
      'ibu' => 'Ibu',
      _ => 'Wali',
    };
    if (p == null || !_ortuHasData(p)) {
      return _emptyCard(
        s,
        Icons.person_off_outlined,
        'Data $label belum tercatat di sistem.',
        'Siswa ini berstatus aktif. Hubungi operator madrasah untuk melengkapi data $label.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSection(
          context,
          accent: const Color(0xFF6A1B9A),
          icon: switch (jenis) {
            'ayah' => Icons.man_outlined,
            'ibu' => Icons.woman_outlined,
            _ => Icons.verified_user_outlined,
          },
          title: 'Data $label',
          rows: _ortuRows(p),
        ),
        if (_ortuExtra(p).isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSection(
            context,
            accent: const Color(0xFF00695C),
            icon: Icons.fact_check_outlined,
            title: 'Data Lengkap $label',
            rows: _ortuExtra(p),
          ),
        ],
      ],
    );
  }

  List<(IconData, String, String)> _ortuRows(Map<String, dynamic> p) {
    final out = <(IconData, String, String)>[];
    final known = <String, (IconData, String)>{
      'nama': (Icons.badge_outlined, 'Nama'),
      'nik': (Icons.credit_card_outlined, 'NIK'),
      'status_hidup': (Icons.favorite_outline, 'Status Hidup'),
      'tempat_lahir': (Icons.cake_outlined, 'Tempat Lahir'),
      'tanggal_lahir': (Icons.event_outlined, 'Tanggal Lahir'),
      'pendidikan': (Icons.school_outlined, 'Pendidikan'),
      'pekerjaan': (Icons.work_outline, 'Pekerjaan'),
      'penghasilan': (Icons.payments_outlined, 'Penghasilan'),
      'telepon': (Icons.phone_outlined, 'Telepon'),
      'alamat': (Icons.home_outlined, 'Alamat'),
      'hubungan': (Icons.deck_outlined, 'Hubungan'),
      'agama': (Icons.church_outlined, 'Agama'),
      'no_kk': (Icons.family_restroom_outlined, 'No. KK'),
      'rt': (Icons.house_outlined, 'RT'),
      'rw': (Icons.house_outlined, 'RW'),
      'kelurahan': (Icons.location_city_outlined, 'Kelurahan'),
      'desa': (Icons.location_city_outlined, 'Desa'),
      'kecamatan': (Icons.map_outlined, 'Kecamatan'),
      'kabupaten': (Icons.map_outlined, 'Kabupaten'),
      'kota': (Icons.map_outlined, 'Kota/Kab'),
      'provinsi': (Icons.public_outlined, 'Provinsi'),
      'kode_pos': (Icons.mail_outline, 'Kode Pos'),
      'status_perkawinan': (Icons.favorite_border, 'Status Perkawinan'),
    };
    for (final e in p.entries) {
      final spec = known[e.key.trim().toLowerCase()];
      final v = e.value?.toString().trim() ?? '';
      if (spec != null && v.isNotEmpty) {
        out.add((spec.$1, spec.$2, v));
      }
    }
    return out;
  }

  List<(IconData, String, String)> _ortuExtra(Map<String, dynamic> p) {
    const meta = {'id', 'siswa_id', 'jenis'};
    final shown = {
      'nama', 'nik', 'status_hidup', 'tempat_lahir', 'tanggal_lahir',
      'pendidikan', 'pekerjaan', 'penghasilan', 'telepon', 'alamat',
      'hubungan', 'agama', 'no_kk', 'rt', 'rw', 'kelurahan', 'desa',
      'kecamatan', 'kabupaten', 'kota', 'provinsi', 'kode_pos',
      'status_perkawinan',
    };
    final out = <(IconData, String, String)>[];
    for (final e in p.entries) {
      final key = e.key.trim().toLowerCase();
      final v = e.value?.toString().trim() ?? '';
      if (v.isEmpty || meta.contains(key) || shown.contains(key)) continue;
      out.add((Icons.info_outline, _fieldLabel(e.key), v));
    }
    return out;
  }

  String _fieldLabel(String key) {
    const acronyms = {
      'nik': 'NIK', 'kk': 'KK', 'ktp': 'KTP', 'hp': 'HP', 'rt': 'RT',
      'rw': 'RW', 'nisn': 'NISN', 'nis': 'NIS',
    };
    final words = key
        .split(RegExp(r'[_\s-]+'))
        .where((w) => w.isNotEmpty)
        .map((w) {
      final low = w.toLowerCase();
      if (acronyms.containsKey(low)) return acronyms[low]!;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
    return words;
  }

  Widget _buildLampiranTab(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final docs =
        _lampiran.where((e) => (e['tersedia'] ?? false) == true).toList();
    if (docs.isEmpty) {
      return _emptyCard(s, Icons.folder_open_outlined,
          'Belum ada dokumen lampiran.', 'Dokumen siswa akan tampil di sini.');
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final d in docs) SizedBox(width: w, child: _lampCard(s, d)),
          ],
        );
      },
    );
  }

  Widget _lampCard(ColorScheme s, Map<String, dynamic> d) {
    final field = d['field']?.toString() ?? '';
    final label = d['label']?.toString() ?? 'Dokumen';
    final url = d['url']?.toString() ?? '';
    final (icon, color) = _lampStyle(field, s);
    return Material(
      color: s.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: url.isNotEmpty
            ? () => _openLampiran(url, label)
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const Spacer(),
                  if (url.isNotEmpty)
                    Icon(Icons.open_in_new, size: 15,
                        color: s.onSurfaceVariant)
                  else
                    Icon(Icons.lock_outline, size: 15,
                        color: s.onSurfaceVariant.withValues(alpha: 0.4)),
                ],
              ),
              const SizedBox(height: 10),
              Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(url.isNotEmpty ? 'Buka dokumen' : 'Belum dilampirkan',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: url.isNotEmpty
                          ? color
                          : s.onSurfaceVariant.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _lampStyle(String field, ColorScheme s) {
    return switch (field) {
      'file_foto' => (Icons.face_outlined, s.primary),
      'file_kk' => (Icons.family_restroom_outlined, const Color(0xFF00897B)),
      'file_akta' => (Icons.description_outlined, const Color(0xFF3949AB)),
      'file_ijazah' => (Icons.school_outlined, const Color(0xFFF57C00)),
      'file_skl' => (Icons.verified_outlined, const Color(0xFF43A047)),
      'file_ktp_ayah' => (Icons.man_outlined, const Color(0xFF6D4C41)),
      'file_ktp_ibu' => (Icons.face_retouching_natural_outlined,
          const Color(0xFFAD1457)),
      'file_ktp_wali' => (Icons.verified_user_outlined, const Color(0xFF546E7A)),
      'file_kip' => (Icons.savings_outlined, const Color(0xFFE53935)),
      'file_rapor_asal' => (Icons.receipt_long_outlined,
          const Color(0xFF00ACC1)),
      _ => (Icons.attach_file, s.tertiary),
    };
  }

  Future<void> _openLampiran(String raw, String label) async {
    try {
      final url = raw.startsWith('http')
          ? raw
          : Uri.parse(kApiBaseUrl)
              .resolve(raw.startsWith('/') ? raw.substring(1) : raw)
              .toString();
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka $label.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka dokumen.')),
        );
      }
    }
  }

  // ----------------------------------------------------------------- bantu
  bool _ortuHasData(Map<String, dynamic> p) {
    const keys = {
      'nama', 'nik', 'status_hidup', 'tempat_lahir', 'tanggal_lahir',
      'pendidikan', 'pekerjaan', 'penghasilan', 'telepon', 'alamat',
      'hubungan',
    };
    return keys.any((k) {
      final v = p[k];
      return v != null && v.toString().trim().isNotEmpty;
    });
  }

  Widget _buildErrorBanner(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: s.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gagal memuat profil dari server',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(_error,
                    style:
                        TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            color: s.error,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(
      ColorScheme s, IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: s.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: s.primary),
          ),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
        ],
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
    var shown = 0;
    for (final (ic, label, value) in rows) {
      if (value.trim().isEmpty) continue;
      if (tiles.isNotEmpty) tiles.add(_divider(s));
      tiles.add(_infoTile(ic, label, value, accent));
      shown++;
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
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$shown item',
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
                    style: TextStyle(color: s.onSurfaceVariant, fontSize: 12)),
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
            height: 180,
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