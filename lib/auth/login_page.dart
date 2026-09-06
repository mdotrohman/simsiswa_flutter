import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/credential_store.dart';
import '../core/session.dart';
import '../shell/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'siswa';
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _prefillSaved();
  }

  Future<void> _prefillSaved() async {
    final saved = await CredentialStore.load();
    if (!mounted || saved == null) return;
    _username.text = saved.username;
    _password.text = saved.password;
    _role = saved.role;
    setState(() {});
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    final username = _username.text.trim();
    final password = _password.text.trim();

    setState(() => _error = null);

    if (username.isEmpty) {
      setState(() => _error = _role == 'siswa' ? 'NIS wajib diisi' : 'NISN wajib diisi');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Password wajib diisi');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final data =
          await Api.login(username: username, password: password, role: _role);
      Session.save(
        role: data.role,
        userId: data.userId,
        token: data.token,
        username: data.username,
        name: data.name,
        nis: data.nis,
        nisn: data.nisn,
        waliNama: data.waliNama,
      );
      if (!mounted) return;
      final saved = await CredentialStore.load();
      final shouldOffer = saved == null ||
          saved.username != data.username ||
          saved.password != password;
      if (shouldOffer) {
        await _offerSavePassword(
          username: data.username,
          role: data.role,
          password: password,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Login gagal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Penawaran gaya Google: simpan sandi untuk masuk berikutnya?
  Future<void> _offerSavePassword({
    required String username,
    required String role,
    required String password,
  }) async {
    final act = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.shield_outlined,
            color: Theme.of(ctx).colorScheme.primary),
        title: const Text('Simpan sandi?'),
        content: Text(
          'Simpan $username agar login berikutnya otomatis terisi? '
          'Sandi dienkripsi di keamanan perangkat (Keystore/Keychain).',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('no'),
            child: const Text('Tidak'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop('yes'),
            icon: const Icon(Icons.key, size: 18),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (act == 'yes') {
      await CredentialStore.save(
        username: username,
        role: role,
        password: password,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(s.primary, Colors.black, 0.35)!, s.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _Logo(),
                  const SizedBox(height: 20),
                  const Text(
                    'SIM Siswa MTsBU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'MTs Bustanul Ulum Tambakberas Jombang',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  _buildCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'v1.26 Premium',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masuk Akun',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'siswa',
                label: Text('Siswa'),
                icon: Icon(Icons.school_outlined),
              ),
              ButtonSegment(
                value: 'wali',
                label: Text('Wali'),
                icon: Icon(Icons.family_restroom_outlined),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (sel) => setState(() => _role = sel.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _username,
            enabled: !_loading,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: _role == 'siswa' ? 'NIS' : 'NISN',
              hintText: _role == 'siswa' ? 'Masukkan NIS siswa' : 'Masukkan NISN siswa',
              helperText: _role == 'wali' ? 'Isi dengan NISN anak Anda' : null,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            enabled: !_loading,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _attemptLogin(),
            decoration: InputDecoration(
              labelText: _role == 'wali' ? 'NIK Wali' : 'Password',
              hintText: _role == 'wali' ? 'Masukkan NIK orang tua/wali' : 'Masukkan password',
              helperText: _role == 'wali' ? 'NIK 16 digit pemilik akun wali' : null,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _loading ? null : _attemptLogin,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(_loading ? '' : 'MASUK'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: s.primary.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 2),
      ),
      child: const Icon(Icons.school, size: 48, color: Colors.white),
    );
  }
}