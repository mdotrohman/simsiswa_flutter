import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';

class BerandaTab extends StatefulWidget {
  final void Function(int index) onNavigate;
  const BerandaTab({super.key, required this.onNavigate});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  Map<String, dynamic>? _dashboard;
  String? _dashError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _dashError = null);
    try {
      final json = await Api.dashboard();
      if (!mounted) return;
      setState(() => _dashboard = json);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dashError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dashError = 'Gagal memuat data dashboard');
    }
  }

  String get _roleLabel => Session.role == 'wali' ? 'Wali Siswa' : 'Siswa';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _greetingCard(),
        const SizedBox(height: 16),
        _statsSection(),
        const SizedBox(height: 16),
        _menuGrid(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _greetingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, kPrimary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waving_hand, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Selamat datang,',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Session.name.isEmpty ? 'Siswa' : Session.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _statsSection() {
    if (_dashboard == null) {
      if (_dashError != null) {
        return _sneakErrorCard(_dashError!);
      }
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    final d = _dashboard!;
    return Row(
      children: [
        _statCard(
          icon: Icons.school,
          color: kPrimary,
          label: 'Siswa',
          value: (d['total_siswa'] ?? 0).toString(),
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.people_alt,
          color: const Color(0xFF7C3AED),
          label: 'Guru',
          value: (d['total_guru'] ?? 0).toString(),
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.meeting_room,
          color: const Color(0xFFF59E0B),
          label: 'Kelas',
          value: (d['total_kelas'] ?? 0).toString(),
        ),
      ],
    );
  }

  Widget _sneakErrorCard(String message) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _loadDashboard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
              const Icon(Icons.refresh, color: kPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuGrid() {
    final items = [
      _MenuItem(Icons.payments, 'Pembayaran', () => widget.onNavigate(2)),
      _MenuItem(Icons.event_available, 'Absensi', () => widget.onNavigate(3)),
      _MenuItem(Icons.campaign, 'Pengumuman', () => widget.onNavigate(4)),
      _MenuItem(Icons.person, 'Profil', () => widget.onNavigate(1)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((m) => _menuTile(m)).toList(),
    );
  }

  Widget _menuTile(_MenuItem m) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: m.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(m.icon, color: kPrimary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.onTap);
}