import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/login_page.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../models/profil.dart';
import '../shell/main_shell.dart';

/// Halaman index (portal) — menampilkan profil publik madrasah sebelum masuk ke
/// login (mengikuti konsep SplashActivity di aplikasi Java versi lama).
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  ProfilResponse? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await Api.publicProfil();
      if (!mounted) return;
      setState(() {
        _data = resp;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${e.code == 0 ? 'Koneksi gagal' : 'Gagal mengambil profil'}: ${e.message}';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan saat memuat profil madrasah.';
        _loading = false;
      });
    }
  }

  Future<void> _launch(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;
    var url = value;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast('Tidak dapat membuka $value');
    } catch (_) {
      if (mounted) _toast('Tidak dapat membuka $value');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  void _continueIntoApp() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => Session.isLoggedIn() ? const MainShell() : const LoginPage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final profil = _data?.profil;
    final statistik = _data?.statistik;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _hero(s, profil),
                  if (_loading)
                    _loadingCard(s)
                  else if (_error != null)
                    _errorCard(s, _error!)
                  else ...[
                    if (statistik != null) _statisticsCard(s, statistik),
                    _identityCard(s, profil),
                    _informasiCard(s, profil),
                    _kontakCard(s, profil),
                    _socialCard(s, profil),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            _bottomBar(s),
          ],
        ),
      ),
    );
  }

  Widget _hero(ColorScheme s, Profil? p) {
    final nama = p?.namaMadrasah.isNotEmpty == true ? p!.namaMadrasah : 'SIM Siswa MTsB.U';

    final taglineParts = <String>[
      if (p?.bentukPendidikan.isNotEmpty == true) p!.bentukPendidikan,
      if (p?.akreditasi.isNotEmpty == true) 'Akreditasi ${p!.akreditasi}',
    ];

    final alamatParts = <String>[
      if (p?.alamat.isNotEmpty == true) p!.alamat,
      if (p?.desaKelurahan.isNotEmpty == true) p!.desaKelurahan,
      if (p?.kecamatan.isNotEmpty == true) p!.kecamatan,
      if (p?.kabupaten.isNotEmpty == true) p!.kabupaten,
      if (p?.provinsi.isNotEmpty == true) p!.provinsi,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(s.primary, Colors.black, 0.35)!, s.primary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.school_rounded, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            nama,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (taglineParts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              taglineParts.join(' · '),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
            ),
          ],
          if (p?.slogan.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              '"${p!.slogan}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (alamatParts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_rounded,
                    size: 16, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    alamatParts.join(', '),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _loadingCard(ColorScheme s) {
    return _sectionShell(
      s,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text('Memuat profil madrasah…', style: TextStyle(color: s.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(ColorScheme s, String msg) {
    return _sectionShell(
      s,
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: s.error),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticsCard(ColorScheme s, Statistik st) {
    Widget stat(IconData icon, String value, String label) {
      return Expanded(
        child: _statTile(
          s,
          Column(
            children: [
              Icon(icon, size: 22, color: s.onPrimary),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final periode = [if (st.tahunAjaran.isNotEmpty) st.tahunAjaran, if (st.semester.isNotEmpty) st.semester];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          Row(children: [
            stat(Icons.people_alt_rounded, '${st.totalSiswa}', 'Siswa'),
            const SizedBox(width: 10),
            stat(Icons.school_rounded, '${st.jumlahGuru}', 'Guru'),
            const SizedBox(width: 10),
            stat(Icons.meeting_room_rounded, '${st.jumlahRombel}', 'Rombel'),
          ]),
          if (periode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: s.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 16, color: s.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    'Periode: ${periode.join(' · ')}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: s.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statTile(ColorScheme s, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [s.primary, Color.lerp(s.primary, Colors.black, 0.25)!],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: s.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: s.onPrimary),
        child: child,
      ),
    );
  }

  Widget _identityCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final rows = <(String, String)>[];
    void add(String k, String v) {
      if (v.isNotEmpty) rows.add((k, v));
    }

    add('NPSN', p.npsn);
    add('NSM', p.nsm);
    add('Jenjang', p.jenjang);
    add('Status', p.statusMadrasah);
    add('Akreditasi', p.akreditasi);
    add('Berdiri', p.tahunBerdiri);
    add('Kepala Madrasah', p.namaKepala);
    add('Kurikulum', p.namaKurikulum);

    return _sectionCard(
      s,
      title: 'Identitas Madrasah',
      icon: Icons.badge_rounded,
      child: _rowsList(s, rows),
    );
  }

  Widget _informasiCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final rows = <(String, String)>[];
    void add(String k, String v) {
      if (v.isNotEmpty) rows.add((k, v));
    }

    add('Yayasan', p.namaYayasan);
    add('Ketua Yayasan', p.ketuaYayasan);
    add('Kode Pos', p.kodePos);
    add('Email', p.email);
    add('Website', p.websiteResmi);

    return _sectionCard(
      s,
      title: 'Informasi',
      icon: Icons.info_outline_rounded,
      child: _rowsList(s, rows),
    );
  }

  Widget _kontakCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final kontak = <(String, String, String)>[];
    void add(String label, String v) {
      if (v.isNotEmpty) kontak.add((label, v, v));
    }

    add('WhatsApp', p.whatsapp);
    add('Telepon', p.telepon);
    add('Email', p.email);
    add('Website', p.websiteResmi);

    if (kontak.isEmpty) return const SizedBox.shrink();
    return _sectionCard(
      s,
      title: 'Kontak',
      icon: Icons.call_rounded,
      child: _dense(kontak),
    );
  }

  Widget _socialCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final sosmed = <(String, String, String)>[
      ('IG', 'Instagram', p.instagram),
      ('FB', 'Facebook', p.facebook),
      ('YT', 'YouTube', p.youtube),
      ('TT', 'TikTok', p.tiktok),
      ('X', 'X', p.twitter),
      ('WA', 'WhatsApp', p.whatsapp),
    ].where((e) => e.$3.isNotEmpty).toList();

    if (sosmed.isEmpty) return const SizedBox.shrink();
    return _sectionCard(
      s,
      title: 'Media Sosial',
      icon: Icons.public_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sosmed
            .map((e) => _socialBadge(s, symbol: e.$1, name: e.$2, url: e.$3))
            .toList(),
      ),
    );
  }

  Widget _socialBadge(ColorScheme s, {required String symbol, required String name, required String url}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _launch(url),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: s.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: s.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(symbol,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: s.primary)),
            const SizedBox(height: 2),
            Text(name,
                style: TextStyle(fontSize: 10.5, color: s.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _rowsList(ColorScheme s, List<(String, String)> rows) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 0.7, color: s.outlineVariant.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(rows[i].$1,
                      style: TextStyle(fontSize: 12.5, color: s.onSurfaceVariant)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: s.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dense(List<(String, String, String)> rows) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _launch(rows[i].$3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Text(rows[i].$1,
                        style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        rows[i].$2,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.open_in_new_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionCard(ColorScheme s, {required String title, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _sectionShell(
        s,
        Padding(
          padding: const EdgeInsets.all(16),
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
                  Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionShell(ColorScheme s, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }

  Widget _bottomBar(ColorScheme s) {
    final label = Session.isLoggedIn() ? 'Buka Aplikasi' : 'Masuk / Daftar';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(top: BorderSide(color: s.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: _continueIntoApp,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terhubung ke sim.mtsbutambakberas.sch.id',
            style: TextStyle(fontSize: 11, color: s.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}