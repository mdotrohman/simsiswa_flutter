import 'package:flutter/material.dart';

import '../core/api.dart';

/// Halaman edit profil siswa. Semua kolom tabel `siswa` (sama dengan data yang
/// dikirim GET app/api/apk/profil_siswa pada `data.siswa`). Simpan mengirim
/// POST app/api/apk/siswa/update_siswa dan menutup halaman setelah sukses.
class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key, this.data});

  /// Respons `data` dari GET profil_siswa (berisi `siswa` map).
  final Map<String, dynamic>? data;

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late final Map<String, dynamic> _siswa;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _namaLengkap;
  late final TextEditingController _namaPanggilan;
  late final TextEditingController _nisn;
  late final TextEditingController _nis;
  late final TextEditingController _tempatLahir;
  late final TextEditingController _agama;
  late final TextEditingController _noHp;
  late final TextEditingController _email;
  late final TextEditingController _nik;
  late final TextEditingController _noKk;
  late final TextEditingController _anakKe;
  late final TextEditingController _jumlahSaudara;
  late final TextEditingController _golonganDarah;
  late final TextEditingController _tinggi;
  late final TextEditingController _berat;
  late final TextEditingController _disabilitas;
  late final TextEditingController _alergi;
  late final TextEditingController _riwayatPenyakit;
  late final TextEditingController _pondok;
  late final TextEditingController _status;
  late final TextEditingController _statusSantri;
  late final TextEditingController _statusAsrama;
  late final TextEditingController _kategori;
  late final TextEditingController _tanggalMasuk;
  late final TextEditingController _alamat;
  late final TextEditingController _rt;
  late final TextEditingController _rw;
  late final TextEditingController _desaKelurahan;
  late final TextEditingController _kecamatan;
  late final TextEditingController _kabupaten;
  late final TextEditingController _provinsi;
  late final TextEditingController _kodePos;
  late final TextEditingController _transportasi;
  late final TextEditingController _jarak;
  late final TextEditingController _noKip;
  late final TextEditingController _kip;
  late final TextEditingController _pkh;
  late final TextEditingController _hobi;
  late final TextEditingController _citaCita;
  late final TextEditingController _tanggalDaftar;

  String _jenisKelamin = 'L';
  String? _tanggalLahir;

  String _v(String key, [String fb = '']) => (_siswa[key]?.toString() ?? fb).trim();

  @override
  void initState() {
    super.initState();
    final s = widget.data?['siswa'];
    _siswa = s is Map<String, dynamic>
        ? s
        : s is Map
            ? Map<String, dynamic>.from(s)
            : <String, dynamic>{};

    _namaLengkap = _c('nama_lengkap');
    _namaPanggilan = _c('nama_panggilan');
    _nisn = _c('nisn');
    _nis = _c('nis');
    _tempatLahir = _c('tempat_lahir');
    _agama = _c('agama');
    _noHp = _c('no_hp');
    _email = _c('email');
    _nik = _c('nik');
    _noKk = _c('no_kk');
    _anakKe = _c('anak_ke');
    _jumlahSaudara = _c('jumlah_saudara');
    _golonganDarah = _c('golongan_darah');
    _tinggi = _c('tinggi_badan');
    _berat = _c('berat_badan');
    _disabilitas = _c('disabilitas');
    _alergi = _c('alergi');
    _riwayatPenyakit = _c('riwayat_penyakit');
    _pondok = _c('pondok');
    _status = _c('status');
    _statusSantri = _c('status_santri');
    _statusAsrama = _c('status_asrama');
    _kategori = _c('kategori');
    _tanggalMasuk = _c('tanggal_masuk');
    _alamat = _c('alamat');
    _rt = _c('rt');
    _rw = _c('rw');
    _desaKelurahan = _c('desa_kelurahan');
    _kecamatan = _c('kecamatan');
    _kabupaten = _c('kabupaten');
    _provinsi = _c('provinsi');
    _kodePos = _c('kode_pos');
    _transportasi = _c('transportasi');
    _jarak = _c('jarak_rumah_ke_sekolah');
    _noKip = _c('no_kip');
    _kip = _c('kip');
    _pkh = _c('pkh');
    _hobi = _c('hobi');
    _citaCita = _c('cita_cita');
    _tanggalDaftar = _c('tanggal_daftar');

    _jenisKelamin = _v('jenis_kelamin', 'L');
    final tl = _v('tanggal_lahir');
    if (tl.isNotEmpty) _tanggalLahir = tl;
  }

  TextEditingController _c(String key) {
    final v = _v(key);
    return TextEditingController(text: v);
  }

  DateTime? _tryParseDate(String s) {
    try {
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  void _disposeAll() {
    final all = [
      _namaLengkap, _namaPanggilan, _nisn, _nis, _tempatLahir, _agama, _noHp,
      _email, _nik, _noKk, _anakKe, _jumlahSaudara, _golonganDarah, _tinggi,
      _berat, _disabilitas, _alergi, _riwayatPenyakit, _pondok, _status,
      _statusSantri, _statusAsrama, _kategori, _tanggalMasuk, _alamat, _rt, _rw,
      _desaKelurahan, _kecamatan, _kabupaten, _provinsi, _kodePos, _transportasi,
      _jarak, _noKip, _kip, _pkh, _hobi, _citaCita, _tanggalDaftar,
    ];
    for (final c in all) {
      c.dispose();
    }
  }

  Map<String, dynamic> _collect() {
    String? num(String key, String v) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    return {
      'nama_lengkap': _namaLengkap.text,
      'nama_panggilan': _namaPanggilan.text,
      'nisn': _nisn.text,
      'nis': _nis.text,
      'jenis_kelamin': _jenisKelamin,
      'tempat_lahir': _tempatLahir.text,
      'tanggal_lahir': _tanggalLahir,
      'agama': _agama.text,
      'no_hp': _noHp.text,
      'email': _email.text,
      'nik': _nik.text,
      'no_kk': _noKk.text,
      'anak_ke': num('anak_ke', _anakKe.text),
      'jumlah_saudara': num('jumlah_saudara', _jumlahSaudara.text),
      'golongan_darah': _golonganDarah.text,
      'tinggi_badan': num('tinggi_badan', _tinggi.text),
      'berat_badan': num('berat_badan', _berat.text),
      'disabilitas': _disabilitas.text,
      'alergi': _alergi.text,
      'riwayat_penyakit': _riwayatPenyakit.text,
      'pondok': _pondok.text,
      'status': _status.text,
      'status_santri': _statusSantri.text,
      'status_asrama': _statusAsrama.text,
      'kategori': _kategori.text,
      'tanggal_masuk': _tanggalMasuk.text,
      'alamat': _alamat.text,
      'rt': _rt.text,
      'rw': _rw.text,
      'desa_kelurahan': _desaKelurahan.text,
      'kecamatan': _kecamatan.text,
      'kabupaten': _kabupaten.text,
      'provinsi': _provinsi.text,
      'kode_pos': _kodePos.text,
      'transportasi': _transportasi.text,
      'jarak_rumah_ke_sekolah': num('jarak_rumah_ke_sekolah', _jarak.text),
      'no_kip': _noKip.text,
      'kip': _kip.text,
      'pkh': _pkh.text,
      'hobi': _hobi.text,
      'cita_cita': _citaCita.text,
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final msg = await Api.updateSiswa(_collect());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.replaceAll('ApiException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _tryParseDate(_tanggalLahir ?? '') ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.year < 1900 ? DateTime(2000) : initial,
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _tanggalLahir =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _section(String title, IconData icon, List<Widget> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c, {
    required String label,
    String? hint,
    TextInputType? keyboard,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : keyboard,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final o in options)
            DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('Data Pribadi', Icons.person_outline, [
                    _field(_namaLengkap, label: 'Nama Lengkap',
                        hint: 'Nama lengkap siswa'),
                    _field(_namaPanggilan, label: 'Nama Panggilan'),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_nisn, label: 'NISN',
                              keyboard: TextInputType.number),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_nis, label: 'NIS',
                              keyboard: TextInputType.number),
                        ),
                      ],
                    ),
                    _dropdownField(
                      label: 'Jenis Kelamin',
                      value: _jenisKelamin,
                      options: const ['L', 'P'],
                      onChanged: (v) => setState(() => _jenisKelamin = v),
                    ),
                    _field(_tempatLahir, label: 'Tempat Lahir'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Tanggal Lahir'),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _tanggalLahir?.isEmpty ?? true
                                    ? 'Pilih tanggal'
                                    : _tanggalLahir!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _field(_agama, label: 'Agama'),
                  ]),
                  _section('Dokumen & Kontak', Icons.contact_page_outlined, [
                    _field(_noHp, label: 'No. HP', keyboard: TextInputType.phone),
                    _field(_email, label: 'Email', keyboard: TextInputType.emailAddress),
                    _field(_nik, label: 'NIK', keyboard: TextInputType.number),
                    _field(_noKk, label: 'No. KK'),
                    _field(_noKip, label: 'No. KIP', keyboard: TextInputType.number),
                    _field(_kip, label: 'KIP'),
                    _field(_pkh, label: 'PKH'),
                  ]),
                  _section('Fisik & Kesehatan', Icons.accessibility_new, [
                    Row(
                      children: [
                        Expanded(
                          child: _field(_anakKe, label: 'Anak ke-', number: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_jumlahSaudara, label: 'Jumlah Saudara', number: true),
                        ),
                      ],
                    ),
                    _dropdownField(
                      label: 'Golongan Darah',
                      value: _golonganDarah.text,
                      options: const ['', 'A', 'B', 'AB', 'O', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                      onChanged: (v) => setState(() => _golonganDarah.text = v),
                    ),
                    Row(
                      children: [
                        Expanded(child: _field(_tinggi, label: 'Tinggi Badan (cm)', number: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_berat, label: 'Berat Badan (kg)', number: true)),
                      ],
                    ),
                    _field(_disabilitas, label: 'Disabilitas'),
                    _field(_alergi, label: 'Alergi'),
                    _field(_riwayatPenyakit, label: 'Riwayat Penyakit'),
                  ]),
                  _section('Pendidikan & Asrama', Icons.school_outlined, [
                    _field(_pondok, label: 'Pondok'),
                    _field(_kategori, label: 'Kategori'),
                    _field(_tanggalMasuk, label: 'Tanggal Masuk'),
                    _dropdownField(
                      label: 'Status',
                      value: _status.text,
                      options: const ['', 'Aktif', 'Lulus', 'Keluar', 'Pindah', 'Cuti'],
                      onChanged: (v) => setState(() => _status.text = v),
                    ),
                    _dropdownField(
                      label: 'Status Santri',
                      value: _statusSantri.text,
                      options: const ['', 'Santri', 'Non-Santri'],
                      onChanged: (v) => setState(() => _statusSantri.text = v),
                    ),
                    _dropdownField(
                      label: 'Status Asrama',
                      value: _statusAsrama.text,
                      options: const ['', 'Asrama', 'Non-Asrama'],
                      onChanged: (v) => setState(() => _statusAsrama.text = v),
                    ),
                    _field(_tanggalDaftar, label: 'Tanggal Daftar'),
                  ]),
                  _section('Alamat', Icons.home_outlined, [
                    _field(_alamat, label: 'Alamat', hint: 'Alamat lengkap'),
                    Row(
                      children: [
                        Expanded(child: _field(_rt, label: 'RT')),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_rw, label: 'RW')),
                      ],
                    ),
                    _field(_desaKelurahan, label: 'Desa / Kelurahan'),
                    _field(_kecamatan, label: 'Kecamatan'),
                    Row(
                      children: [
                        Expanded(child: _field(_kabupaten, label: 'Kabupaten')),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_kodePos, label: 'Kode Pos')),
                      ],
                    ),
                    _field(_provinsi, label: 'Provinsi'),
                    _field(_transportasi, label: 'Transportasi'),
                    _field(_jarak, label: 'Jarak Rumah ke Sekolah', number: true),
                  ]),
                  _section('Lain-lain', Icons.interests_outlined, [
                    _field(_hobi, label: 'Hobi'),
                    _field(_citaCita, label: 'Cita-cita'),
                  ]),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Simpan Data',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}