import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/login_page.dart';
import '../core/api.dart';
import '../models/profil.dart';

/// Halaman index (portal) — hanya untuk pengguna yang belum login. Menampilkan
/// profil publik madrasah + brand aplikasi sebelum masuk ke login.
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

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // --- action pembuka tautan sesuai jenis data ---
  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast('Tidak dapat membuka tautan');
    } catch (_) {
      if (mounted) _toast('Tidak dapat membuka tautan');
    }
  }

  Future<void> _launchWeb(String raw) async {
    var url = raw.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    await _open(Uri.parse(url));
  }

  Future<void> _launchTel(String raw) async {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return;
    await _open(Uri(scheme: 'tel', path: digits));
  }

  Future<void> _launchMail(String raw) async {
    final email = raw.trim();
    if (email.isEmpty) return;
    await _open(Uri(scheme: 'mailto', path: email));
  }

  Future<void> _launchWa(String raw) async {
    var v = raw.trim();
    if (v.isEmpty) return;
    if (v.contains('wa.me') || v.contains('whatsapp')) {
      if (!v.startsWith('http')) v = 'https://$v';
      await _open(Uri.parse(v));
      return;
    }
    var digits = v.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return;
    if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
    await _open(Uri.parse('https://wa.me/$digits'));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final profil = _data?.profil;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - t)),
                    child: child,
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _hero(s, profil),
                    if (_loading)
                      _loadingCard(s)
                    else if (_error != null)
                      _errorCard(s, _error!)
                    else ...[
                      _brandCard(s),
                      _identityCard(s, profil),
                      _informasiCard(s, profil),
                      _kontakCard(s, profil),
                      _socialCard(s, profil),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            _bottomBar(s),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- hero
  Widget _hero(ColorScheme s, Profil? p) {
    final nama = p?.namaMadrasah.isNotEmpty == true ? p!.namaMadrasah : 'SIM Siswa MTsB.U';

    final taglineParts = <String>[
      if (p?.bentukPendidikan.isNotEmpty == true) p!.bentukPendidikan,
      if (p?.akreditasi.isNotEmpty == true) 'Akreditasi ${p!.akreditasi}',
    ];

    final alamatParts = <String>[
      if (p?.alamat.isNotEmpty == true) p!.alamat,
      if (p?.desaKelurahan.isNotEmpty == true) p!.desaKelurahan,
      if (p?.kabupaten.isNotEmpty == true) p!.kabupaten,
      if (p?.provinsi.isNotEmpty == true) p!.provinsi,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(s.primary, Colors.black, 0.4)!, s.primary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Emblem premium: cincin ganda + logo resmi
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/ic_logo.png',
                  fit: BoxFit.cover,
                  width: 96,
                  height: 96,
                ),
              ),
            ),
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
                Icon(Icons.place_rounded, size: 16, color: Colors.white.withValues(alpha: 0.85)),
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

  // ------------------------------------------------------- brand (pengganti statistik)
  Widget _brandCard(ColorScheme s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            s.primary.withValues(alpha: 0.12),
            s.primaryContainer.withValues(alpha: 0.5),
            s.surfaceContainerLow,
          ],
          stops: const [0, 0.4, 1],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: s.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Hub mark
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [s.primary, Color.lerp(s.primary, Colors.black, 0.35)!],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: s.primary.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.apps_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sistem Informasi Manajemen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pelayanan Terpadu Satu Pintu · Ekosistem Pendidikan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: s.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Text(
            'SIM adalah pusat kendali digital yang mengintegrasikan seluruh layanan '
            'administrasi dan akademik sekolah ke dalam satu pintu. Dirancang khusus '
            'untuk memudahkan pelaporan, menciptakan ekosistem pendidikan yang lebih '
            'efisien, transparan, dan kekinian.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: s.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ identitas
  Widget _identityCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final rows = <(IconData, String, String)>[];
    void add(IconData icon, String k, String v) {
      if (v.isNotEmpty) rows.add((icon, k, v));
    }

    add(Icons.badge_rounded, 'NPSN', p.npsn);
    add(Icons.school_rounded, 'NSM', p.nsm);
    add(Icons.stairs_rounded, 'Jenjang', p.jenjang);
    add(Icons.verified_rounded, 'Status', p.statusMadrasah);
    add(Icons.star_rounded, 'Akreditasi', p.akreditasi);
    add(Icons.calendar_month_rounded, 'Berdiri', p.tahunBerdiri);
    add(Icons.manage_accounts_rounded, 'Kepala Madrasah', p.namaKepala);
    add(Icons.menu_book_rounded, 'Kurikulum', p.namaKurikulum);

    return _sectionCard(
      s,
      title: 'Identitas Madrasah',
      icon: Icons.badge_rounded,
      child: _keyValueRows(s, rows),
    );
  }

  Widget _informasiCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final rows = <(IconData, String, String)>[];
    void add(IconData icon, String k, String v) {
      if (v.isNotEmpty) rows.add((icon, k, v));
    }

    add(Icons.apartment_rounded, 'Yayasan', p.namaYayasan);
    add(Icons.people_alt_rounded, 'Ketua Yayasan', p.ketuaYayasan);
    add(Icons.local_post_office_rounded, 'Kode Pos', p.kodePos);

    if (rows.isEmpty) return const SizedBox.shrink();
    return _sectionCard(
      s,
      title: 'Informasi',
      icon: Icons.info_outline_rounded,
      child: _keyValueRows(s, rows),
    );
  }

  // --------------------------------------------------------------- kontak
  Widget _kontakCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final items = <(String, String, IconData, Color, VoidCallback)>[];
    if (p.whatsapp.isNotEmpty) {
      items.add(('WhatsApp', p.whatsapp, Icons.chat_rounded, const Color(0xFF25D366),
          () => _launchWa(p.whatsapp)));
    }
    if (p.telepon.isNotEmpty) {
      items.add(('Telepon', p.telepon, Icons.call_rounded, s.primary,
          () => _launchTel(p.telepon)));
    }
    if (p.email.isNotEmpty) {
      items.add(('Email', p.email, Icons.mail_rounded, s.tertiary,
          () => _launchMail(p.email)));
    }
    if (p.websiteResmi.isNotEmpty) {
      items.add(('Website', p.websiteResmi, Icons.language_rounded, s.secondary,
          () => _launchWeb(p.websiteResmi)));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return _sectionCard(
      s,
      title: 'Kontak',
      icon: Icons.contact_phone_rounded,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.7, color: s.outlineVariant.withValues(alpha: 0.35)),
            _actionTile(
              s,
              color: items[i].$4,
              icon: items[i].$3,
              title: items[i].$1,
              subtitle: items[i].$2,
              onTap: items[i].$5,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------- media sosial
  Widget _socialCard(ColorScheme s, Profil? p) {
    if (p == null) return const SizedBox.shrink();
    final sosmed = <(String, IconData?, String?, List<Color>, String)>[
      ('Instagram', Icons.camera_alt, null,
          const [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)], p.instagram),
      ('Facebook', Icons.facebook, null, const [Color(0xFF1877F2), Color(0xFF0E5FC8)], p.facebook),
      ('YouTube', Icons.play_arrow_rounded, null,
          const [Color(0xFFFF0000), Color(0xFFC00000)], p.youtube),
      ('TikTok', Icons.music_note_rounded, null,
          const [Color(0xFF010101), Color(0xFF3A3A3A)], p.tiktok),
      ('X', null, 'X', const [Color(0xFF0F1419), Color(0xFF343A40)], p.twitter),
      ('WhatsApp', Icons.chat_rounded, null,
          const [Color(0xFF25D366), Color(0xFF128C7E)], p.whatsapp),
    ].where((e) => e.$5.isNotEmpty).toList();

    if (sosmed.isEmpty) return const SizedBox.shrink();
    return _sectionCard(
      s,
      title: 'Media Sosial',
      icon: Icons.public_rounded,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final e in sosmed)
              _socialBubble(
                s,
                name: e.$1,
                icon: e.$2,
                glyph: e.$3,
                colors: e.$4,
                onTap: () => _launchWeb(e.$5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _socialBubble(
    ColorScheme s, {
    required String name,
    IconData? icon,
    String? glyph,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    final brand = colors.first;
    return Tooltip(
      message: name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: brand.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: brand.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: brand.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: glyph != null
                ? Text(glyph,
                    style: TextStyle(
                        color: brand, fontSize: 18, fontWeight: FontWeight.w800))
                : Icon(icon, color: brand, size: 26),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- tile umum
  Widget _actionTile(
    ColorScheme s, {
    Color? color,
    IconData? icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    List<Color>? gradient,
    String? glyph,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _avatar(s, color: color, icon: icon, gradient: gradient, glyph: glyph),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: s.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: s.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _avatar(
    ColorScheme s, {
    Color? color,
    IconData? icon,
    List<Color>? gradient,
    String? glyph,
  }) {
    final box = BoxDecoration(
      gradient: gradient == null
          ? null
          : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
      color: gradient == null ? (color ?? Colors.transparent).withValues(alpha: 0.14) : null,
      borderRadius: BorderRadius.circular(13),
    );
    return Container(
      width: 42,
      height: 42,
      decoration: box,
      child: gradient != null
          ? Center(
              child: glyph != null
                  ? Text(glyph,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))
                  : Icon(icon, color: Colors.white, size: 21),
            )
          : Center(child: Icon(icon, color: color, size: 21)),
    );
  }

  Widget _keyValueRows(ColorScheme s, List<(IconData, String, String)> rows) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 0.7, color: s.outlineVariant.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: s.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(rows[i].$1, size: 18, color: s.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].$2,
                          style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)),
                      const SizedBox(height: 1),
                      Text(
                        rows[i].$3,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: s.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionCard(ColorScheme s, {required String title, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
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

  Widget _loadingCard(ColorScheme s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: 16),
          Text('Memuat profil madrasah…', style: TextStyle(color: s.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _errorCard(ColorScheme s, String msg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: s.error),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- bawah
  Widget _bottomBar(ColorScheme s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(top: BorderSide(color: s.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [s.primary, Color.lerp(s.primary, Colors.black, 0.3)!],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: s.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _goToLogin,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 17),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Masuk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                    ],
                  ),
                ),
              ),
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