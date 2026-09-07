import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../auth/login_page.dart';
import '../core/credential_store.dart';
import '../core/fcm.dart';
import '../core/session.dart';

/// Versi aplikasi — ikuti versi terbaru di pubspec/footer login.
const kAppVersion = '1.423';

// ----------------------------------------------------------------------------
// Pengaturan (daftar gaya aplikasi: navigasi ke Akun, Tema, Notifikasi, dll.)
// ----------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Preferensi', Icons.tune_rounded),
          const SizedBox(height: 8),
          _card(context, children: [
            _tile(
              context,
              icon: Icons.account_circle_outlined,
              color: s.primary,
              title: 'Akun',
              subtitle: 'Profil login & keluar',
              onTap: () => _push(context, const AccountPage()),
            ),
            _divider(s),
            _tile(
              context,
              icon: Icons.palette_outlined,
              color: Colors.purple,
              title: 'Tema',
              subtitle: 'Terang, gelap, atau ikuti sistem',
              onTap: () => _push(context, const ThemeModePage()),
            ),
            _divider(s),
            _tile(
              context,
              icon: Icons.notifications_outlined,
              color: Colors.redAccent,
              title: 'Notifikasi',
              subtitle: 'Izin & pengujian push',
              onTap: () => _push(context, const NotificationPage()),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Keamanan', Icons.security_rounded),
          const SizedBox(height: 8),
          _card(context, children: [
            _tile(
              context,
              icon: Icons.lock_outline,
              color: s.tertiary,
              title: 'Privasi & Keamanan',
              subtitle: 'Sandi tersimpan & data lokal',
              onTap: () => _push(context, const PrivacyPage()),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Tentang', Icons.info_outline),
          const SizedBox(height: 8),
          _card(context, children: [
            _tile(
              context,
              icon: Icons.android,
              color: Colors.teal,
              title: 'Tentang Aplikasi',
              subtitle: 'v$kAppVersion Premium • SIM Siswa MTsBU',
              onTap: () => _aboutDialog(context),
            ),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: s.error,
              side: BorderSide(color: s.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar dari Aplikasi'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _aboutDialog(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.school, color: s.primary),
        title: const Text('SIM Siswa MTsBU'),
        content: Text(
          'Aplikasi siswa & wali MTs Bahrul Ulum Tambakberas.\n'
          'Versi: v$kAppVersion Premium\n'
          'Backend: sim.mtsbutambakberas.sch.id',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final s = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.logout, color: s.error),
        title: const Text('Keluar?'),
        content: const Text('Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: s.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    await Session.logout();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _header(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(s.primary, Colors.black, 0.3)!, s.primary],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pengaturan Aplikasi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                Text('Atur akun, tema, dan notifikasi',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final s = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: s.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    final s = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      String subtitle = '',
      required VoidCallback onTap}) {
    final s = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle,
              style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right, color: s.onSurfaceVariant, size: 20),
    );
  }

  Widget _divider(ColorScheme s) => Divider(
        height: 1,
        thickness: 0.7,
        indent: 72,
        color: s.outlineVariant.withValues(alpha: 0.35),
      );
}

// ----------------------------------------------------------------------------
// Akun — isi card akun yang lama dipindah dari tab Profil.
// ----------------------------------------------------------------------------
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  String get _roleLabel => Session.role == 'wali' ? 'Wali Siswa' : 'Siswa';
  String get _initial =>
      Session.name.isEmpty ? 'S' : Session.name.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final rows = <(IconData, String, String)>[
      (Icons.alternate_email, 'Username', Session.username),
      (Icons.badge_outlined, 'Peran', _roleLabel),
      (Icons.family_restroom_outlined, 'Wali', Session.waliNama.trim()),
      (Icons.badge_outlined, 'NIS / NISN', _nisNisn),
    ];
    final tiles = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      final (ic, label, value) = rows[i];
      if (value.trim().isEmpty) continue;
      if (tiles.isNotEmpty) tiles.add(_divider(s));
      tiles.add(_infoTile(context, ic, label, value));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(s.primary, Colors.black, 0.35)!, s.primary],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(_initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  Session.name.isEmpty ? 'Siswa' : Session.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_roleLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                      child: Icon(Icons.manage_accounts_outlined,
                          size: 19, color: s.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text('Data Akun',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                ...tiles,
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: s.error,
              side: BorderSide(color: s.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar dari Aplikasi'),
          ),
          const SizedBox(height: 8),
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

  Future<void> _confirmLogout(BuildContext context) async {
    final s = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.logout, color: s.error),
        title: const Text('Keluar?'),
        content: const Text('Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: s.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    await Session.logout();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _infoTile(BuildContext context, IconData icon, String label, String value) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: s.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5, color: s.onSurfaceVariant)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
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
}

// ----------------------------------------------------------------------------
// Tema — pilih Terang / Gelap / Ikuti Sistem.
// ----------------------------------------------------------------------------
class ThemeModePage extends StatelessWidget {
  const ThemeModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final current = Session.themeModePref;
    final options = <(String, String, IconData)>[
      ('', 'Ikuti Sistem', Icons.brightness_auto),
      ('l', 'Terang', Icons.light_mode_outlined),
      ('d', 'Gelap', Icons.dark_mode_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Tema')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Warna mengikuti wallpaper (Material You) dan mode terang/gelap.',
            style: TextStyle(fontSize: 12.5, color: s.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: s.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: RadioGroup<String>(
              groupValue: current,
              onChanged: (v) {
                if (v != null) Session.setThemeModePref(v);
              },
              child: Column(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0)
                      Divider(
                          height: 1,
                          thickness: 0.7,
                          indent: 60,
                          color: s.outlineVariant.withValues(alpha: 0.35)),
                    RadioListTile<String>(
                      value: options[i].$1,
                      secondary: Icon(options[i].$3, color: s.primary),
                      title: Text(options[i].$2,
                          style: const TextStyle(fontSize: 14.5)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Notifikasi — izin, saklar, dan uji coba push.
// ----------------------------------------------------------------------------
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _saving = false;

  Future<void> _requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Izin notifikasi diperbarui sesuai pilihan Anda'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      _err('Gagal meminta izin: $e');
    }
  }

  Future<void> _test() async {
    if (!Session.notifEnabled) {
      _err('Aktifkan notifikasi terlebih dahulu.');
      return;
    }
    try {
      await localNotifications.show(
        id: 999001,
        title: 'SIM Siswa MTsBU',
        body: 'Notifikasi uji coba berhasil dikirim di perangkat ini.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pengumuman',
            'Pengumuman',
            channelDescription: 'Notifikasi pengumuman madrasah',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Notifikasi uji dikirim — cek panel notifikasi'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      _err('Gagal mengirim notifikasi uji: $e');
    }
  }

  void _err(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(context, children: [
            SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.notifications_active_outlined,
                        color: Colors.redAccent, size: 21),
              ),
              title: const Text('Aktifkan Notifikasi',
                  style:
                      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              subtitle: Text('Terima pengumuman dari madrasah',
                  style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)),
              value: Session.notifEnabled,
              onChanged: (v) async {
                setState(() => _saving = true);
                await Session.setNotifEnabled(v);
                if (mounted) setState(() => _saving = false);
              },
            ),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _requestPermission,
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('Minta izin notifikasi'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _test,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Kirim notifikasi uji'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: s.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.tertiary.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: s.tertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Push dari server butuh google-services.json asli dan '
                    'endpoint fcm_token.php. Tanpa itu, notifikasi uji tetap '
                    'bisa dipakai untuk memastikan tampilan di perangkat.',
                    style: TextStyle(fontSize: 12, color: s.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    final s = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(children: children),
    );
  }
}

// ----------------------------------------------------------------------------
// Privasi & Keamanan — data lokal & sandi tersimpan.
// ----------------------------------------------------------------------------
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool? _hasSaved;

  @override
  void initState() {
    super.initState();
    CredentialStore.load().then((v) {
      if (mounted) setState(() => _hasSaved = v != null);
    });
  }

  Future<void> _clear() async {
    await CredentialStore.clear();
    if (!mounted) return;
    setState(() => _hasSaved = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sandi tersimpan telah dihapus dari perangkat'),
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privasi & Keamanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                    Icon(Icons.lock_outline, color: s.tertiary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Penyimpanan Lokal',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Kredensial login disimpan terenkripsi di Keystore perangkat '
                  '(bukan di preferensi biasa), sehingga aman dari backup '
                  'sederhana. Token sesi & data sesi disimpan di preferensi lokal '
                  'dan dihapus total saat keluar.',
                  style: TextStyle(fontSize: 12.5, color: s.onSurfaceVariant,
                      height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: s.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: s.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.key_outlined, color: s.tertiary, size: 21),
              ),
              title: const Text('Sandi Tersimpan',
                  style:
                      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              subtitle: Text(_hasSaved == null
                  ? 'Memeriksa…'
                  : (_hasSaved!
                      ? 'Tersimpan untuk login otomatis'
                      : 'Belum ada sandi tersimpan')),
              trailing: TextButton(
                onPressed: (_hasSaved ?? false) ? _clear : null,
                child: const Text('Hapus'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}