import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../auth/login_page.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  bool _loggingOut = false;

  void _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await Session.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = Session.name;
    final nis = Session.nis;
    final nisn = Session.nisn;
    final username = Session.username;
    final wali = Session.waliNama;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: kPrimary.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, size: 40, color: kPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  name.isEmpty ? 'Akun' : name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  Session.role == 'wali' ? 'Wali Siswa' : 'Siswa',
                  style: const TextStyle(color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                if (nis.isNotEmpty)
                  Text('NIS $nis', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              if (username.isNotEmpty) _infoTile(Icons.alternate_email, 'Username', username),
              if (nis.isNotEmpty) _infoTile(Icons.badge_outlined, 'NIS', nis),
              if (nisn.isNotEmpty) _infoTile(Icons.credit_card, 'NISN', nisn),
              if (Session.role == 'siswa' && wali.isNotEmpty)
                _infoTile(Icons.family_restroom_outlined, 'Wali', wali),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _loggingOut ? null : _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFB91C1C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(_loggingOut ? '' : 'KELUAR'),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}