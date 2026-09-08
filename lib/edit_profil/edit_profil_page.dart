import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../viewers/lampiran_viewer_page.dart';

/// Halaman edit profil siswa.
///
/// Struktur & urutan meniru persis halaman Profil (`lib/tabs/profil_tab.dart`):
/// tab Siswa / Sekolah / Ayah / Ibu / Wali / Lampiran / Riwayat, dengan
/// section dan urutan field yang sama. Simpan mengirim seluruh objek `data`
/// (siswa, sekolah_asal, mutasi, orangtua, lampiran, riwayat_kelas) ke
/// POST app/api/apk/profil_siswa (aksi `update`) — endpoint yang sama dengan
/// pembacaan profil, tidak perlu file server baru.
class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key, this.data, this.initialTab = 0});

  /// Respons `data` dari GET profil_siswa.
  final Map<String, dynamic>? data;

  /// Tab yang aktif saat halaman dibuka (indeks `_tabs`; 5 = Lampiran).
  final int initialTab;

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  static const _tabs = [
    (Icons.person_outline, 'Siswa'),
    (Icons.school_outlined, 'Sekolah'),
    (Icons.man_outlined, 'Ayah'),
    (Icons.woman_outlined, 'Ibu'),
    (Icons.verified_user_outlined, 'Wali'),
    (Icons.folder_outlined, 'Lampiran'),
    (Icons.history_edu_outlined, 'Riwayat'),
  ];

  /// Field siswa yang bersifat administratif/identitas — hanya boleh dilihat,
  /// tidak bisa diubah siswa/wali (server juga tidak menyimpannya: hasil JOIN
  /// atau diisi petugas/admin).
  static const _readOnly = {
    'nis', 'nisn', 'kelas', 'tingkat', 'tahun_ajaran', 'semester',
    'tanggal_masuk', 'tanggal_daftar', 'status',
  };

  static const _ortuMeta = {'id', 'siswa_id', 'jenis'};
  static const _ortuLabels = {
    'nama': 'Nama',
    'nik': 'NIK',
    'status_hidup': 'Status Hidup',
    'tempat_lahir': 'Tempat Lahir',
    'tanggal_lahir': 'Tanggal Lahir',
    'pendidikan': 'Pendidikan',
    'pekerjaan': 'Pekerjaan',
    'penghasilan': 'Penghasilan',
    'telepon': 'Telepon',
    'alamat': 'Alamat',
    'hubungan': 'Hubungan',
    'agama': 'Agama',
    'no_kk': 'No. KK',
    'rt': 'RT',
    'rw': 'RW',
    'kelurahan': 'Kelurahan',
    'desa': 'Desa',
    'kecamatan': 'Kecamatan',
    'kabupaten': 'Kabupaten',
    'kota': 'Kota/Kab',
    'provinsi': 'Provinsi',
    'kode_pos': 'Kode Pos',
    'status_perkawinan': 'Status Perkawinan',
  };
  static const _sekolahLabels = {
    'jenis_sekolah': 'Jenis Sekolah',
    'nama_sekolah': 'Nama Sekolah',
    'npsn': 'NPSN',
    'nsm': 'NSM',
    'alamat': 'Alamat',
  };

  int _tab = 0;
  bool _saving = false;
  String _uploadingField = '';

  late final Map<String, dynamic> _d;
  late final Map<String, dynamic> _siswa;
  Map<String, dynamic>? _sekolah;
  Map<String, dynamic>? _mutasi;
  Map<String, dynamic>? _ortu;

  late final List<Map<String, dynamic>> _lampiran;
  late final List<Map<String, dynamic>> _riwayat;

  late final Map<String, TextEditingController> _siswaC;
  final Map<String, TextEditingController> _sekolahC = {};
  final Map<String, TextEditingController> _mutasiC = {};
  final Map<String, TextEditingController> _ayahC = {};
  final Map<String, TextEditingController> _ibuC = {};
  final Map<String, TextEditingController> _waliC = {};

  // urutan key asli ortu (dipertahankan dari respons server).
  late final List<String> _ayahKeys;
  late final List<String> _ibuKeys;
  late final List<String> _waliKeys;

  String _jk = 'L';

  Map<String, dynamic> _asMap(Object? v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  String _s(Map<String, dynamic> m, String k, [String fb = '']) =>
      (m[k]?.toString() ?? fb).trim();

  TextEditingController _c(Map<String, dynamic> m, String k) =>
      TextEditingController(text: _s(m, k));

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, _tabs.length - 1);
    _d = _asMap(widget.data);
    _siswa = _asMap(_d['siswa']);
    _sekolah = _d['sekolah_asal'] is Map ? _asMap(_d['sekolah_asal']) : null;
    _mutasi = _d['mutasi'] is Map ? _asMap(_d['mutasi']) : null;
    _ortu = _d['orangtua'] is Map ? _asMap(_d['orangtua']) : null;

    final l = _d['lampiran'];
    _lampiran = l is List
        ? l.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];

    final r = _d['riwayat_kelas'];
    _riwayat = r is List
        ? r.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];

    // ---- siswa: map controller per key
    final siswaKeys = <String>{};
    for (final k in [
      'nama_lengkap', 'nama_panggilan', 'nis', 'nisn', 'jenis_kelamin',
      'tempat_lahir', 'tanggal_lahir', 'agama', 'no_hp', 'email', 'nik',
      'no_kk', 'akta_lahir', 'anak_ke', 'jumlah_saudara', 'golongan_darah',
      'tinggi_badan', 'berat_badan', 'tinggi_badan_saat_masuk',
      'berat_badan_saat_masuk', 'disabilitas', 'alergi', 'riwayat_penyakit',
      'pondok', 'status', 'status_santri', 'status_asrama', 'kategori',
      'kelas', 'tingkat', 'tahun_ajaran', 'semester', 'tanggal_masuk',
      'tanggal_daftar', 'alamat', 'rt', 'rw', 'desa_kelurahan', 'kecamatan',
      'kabupaten', 'provinsi', 'kode_pos', 'transportasi',
      'jarak_rumah_ke_sekolah', 'waktu_perjalanan', 'no_kip', 'kip', 'pkh',
      'hobi', 'cita_cita',
    ]) {
      siswaKeys.add(k);
    }
    _siswaC = {for (final k in siswaKeys) k: _c(_siswa, k)};
    final alamatRaw = _asMap(_siswa)['alamat_raw'];
    if (alamatRaw is String && alamatRaw.trim().isNotEmpty) {
      _siswaC['alamat']!.text = alamatRaw.trim();
    }
    _jk = _s(_siswa, 'jenis_kelamin', 'L');

    // ---- sekolah & mutasi
    for (final k in _sekolahLabels.keys) {
      if (_sekolah?.containsKey(k) ?? false) _sekolahC[k] = _c(_sekolah!, k);
    }
    for (final k in _sekolahLabels.keys) {
      if (_mutasi?.containsKey(k) ?? false) _mutasiC[k] = _c(_mutasi!, k);
    }

    // ---- ortu
    _ayahKeys = _ortuKeys(_ortu?['ayah']);
    _ibuKeys = _ortuKeys(_ortu?['ibu']);
    _waliKeys = _ortuKeys(_ortu?['wali']);
    for (final k in _ayahKeys) {
      _ayahC[k] = _c(_asMap(_ortu?['ayah']), k);
    }
    for (final k in _ibuKeys) {
      _ibuC[k] = _c(_asMap(_ortu?['ibu']), k);
    }
    for (final k in _waliKeys) {
      _waliC[k] = _c(_asMap(_ortu?['wali']), k);
    }
  }

  List<String> _ortuKeys(Object? m) {
    final o = _asMap(m);
    return o.keys
        .where((k) => !_ortuMeta.contains(k))
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final c in _siswaC.values) {
      c.dispose();
    }
    for (final c in _sekolahC.values) {
      c.dispose();
    }
    for (final c in _mutasiC.values) {
      c.dispose();
    }
    for (final c in _ayahC.values) {
      c.dispose();
    }
    for (final c in _ibuC.values) {
      c.dispose();
    }
    for (final c in _waliC.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------ label & col
  String _cap(String k) {
    const acr = {'nik': 'NIK', 'kk': 'KK', 'hp': 'HP', 'rt': 'RT', 'rw': 'RW',
        'npsn': 'NPSN', 'nsm': 'NSM', 'kip': 'KIP', 'pkh': 'PKH'};
    final w = k.toLowerCase();
    if (acr.containsKey(w)) return acr[w]!;
    return k.split('_').map((x) {
      if (x.isEmpty) return x;
      return x[0].toUpperCase() + x.substring(1);
    }).join(' ');
  }

  String _ortuLabel(String k) => _ortuLabels[k] ?? _cap(k);
  String _sekolahLabel(String k) => _sekolahLabels[k] ?? _cap(k);

  Map<String, dynamic> _collect() {
    String? nn(String key, String v) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final siswa = <String, dynamic>{for (final k in _siswaC.keys) k: _siswaC[k]!.text};
    siswa['jenis_kelamin'] = _jk;
    if (siswa['tanggal_lahir'] == '') siswa['tanggal_lahir'] = null;
    for (final k in ['anak_ke', 'jumlah_saudara', 'tinggi_badan', 'berat_badan',
        'tinggi_badan_saat_masuk', 'berat_badan_saat_masuk',
        'jarak_rumah_ke_sekolah']) {
      if (siswa.containsKey(k)) siswa[k] = nn(k, siswa[k]!.toString());
    }

    Map<String, dynamic>? emptyToNull(Map<String, TextEditingController> c) {
      if (c.isEmpty) return null;
      return {
        for (final e in c.entries) e.key: e.value.text == '' ? null : e.value.text
      };
    }

    final ortu = <String, dynamic>{};
    Map<String, dynamic>? asOrtu(Map<String, TextEditingController> c,
        List<String> keys) {
      if (keys.isEmpty) return null;
      return {
        for (final k in keys) k: (c[k]?.text ?? '').isEmpty ? null : c[k]!.text,
      };
    }

    final a = asOrtu(_ayahC, _ayahKeys);
    final b = asOrtu(_ibuC, _ibuKeys);
    final w = asOrtu(_waliC, _waliKeys);
    if (a != null) ortu['ayah'] = a;
    if (b != null) ortu['ibu'] = b;
    if (w != null) ortu['wali'] = w;

    return {
      'siswa': siswa,
      'sekolah_asal': emptyToNull(_sekolahC),
      'mutasi': emptyToNull(_mutasiC),
      'orangtua': ortu,
      'lampiran': _lampiran,
      'riwayat_kelas': _riwayat,
    };
  }

  // ------------------------------------------------------------ date helper
  Future<void> _pickDate(TextEditingController c, {String? initialText}) async {
    DateTime? parsed;
    try {
      final t = (initialText ?? c.text).trim();
      parsed = t.isEmpty ? null : DateTime.tryParse(t);
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Pilih tanggal',
    );
    if (picked != null) {
      final s = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() => c.text = s);
    }
  }

  // ------------------------------------------------------------ field widgets
  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    bool number = false,
    bool email = false,
    bool phone = false,
    bool multiline = false,
    bool readOnly = false,
  }) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: TextFormField(
        controller: c,
        readOnly: readOnly,
        maxLines: multiline ? 3 : 1,
        keyboardType: number
            ? TextInputType.number
            : email
                ? TextInputType.emailAddress
                : phone
                    ? TextInputType.phone
                    : TextInputType.text,
        style: readOnly ? TextStyle(color: s.onSurfaceVariant) : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint ?? (readOnly && c.text.isEmpty ? '—' : null),
          filled: true,
          fillColor: readOnly
              ? s.surfaceContainerHighest.withValues(alpha: 0.55)
              : s.surface,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          enabledBorder: _outline(s.outlineVariant),
          disabledBorder: _outline(s.outlineVariant.withValues(alpha: 0.5)),
          focusedBorder: _outline(s.primary, width: 1.6),
        ),
      ),
    );
  }

  InputBorder _outline(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _dropdown(TextEditingController c, String label,
      List<String> options) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: DropdownButtonFormField<String>(
        initialValue: c.text.isNotEmpty && options.contains(c.text) ? c.text : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: s.surface,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          enabledBorder: _outline(s.outlineVariant),
          focusedBorder: _outline(s.primary, width: 1.6),
        ),
        items: [
          for (final o in options)
            DropdownMenuItem(value: o, child: Text(o.isEmpty ? '—' : o)),
        ],
        onChanged: (v) => setState(() => c.text = v ?? ''),
      ),
    );
  }

  Widget _dateField(TextEditingController c, String label,
      {bool readOnly = false}) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        onTap: readOnly ? null : () => _pickDate(c),
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: readOnly
                ? s.surfaceContainerHighest.withValues(alpha: 0.55)
                : s.surface,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: _outline(s.outlineVariant),
            focusedBorder: _outline(s.primary, width: 1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.text.isEmpty ? '—' : c.text,
                  style: const TextStyle(fontSize: 15)),
              Icon(readOnly ? Icons.lock_outline : Icons.calendar_today_outlined,
                  size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(
      String title, IconData icon, Color accent, List<Widget> fields,
      {String? badge}) {
    final s = Theme.of(context).colorScheme;
    final content = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      if (i > 0) {
        content.add(
          Divider(height: 1, thickness: 0.7,
              color: s.outlineVariant.withValues(alpha: 0.35)),
        );
      }
      content.add(fields[i]);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
              Expanded(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge ?? '${fields.length} field',
                    style: TextStyle(fontSize: 11, color: accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...content,
        ],
      ),
    );
  }

  Widget _emptyNote(String title, String sub) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_outlined, size: 26, color: s.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5, color: s.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ tabs
  Widget _tabBar(ColorScheme s) {
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
    return Material(
      color: active ? s.primary : s.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? s.primary : s.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? s.onPrimary : s.primary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: active ? s.onPrimary : s.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- tab bodies
  Widget _tabSiswa() {
    final s = Theme.of(context).colorScheme;
    final c = _siswaC;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Data Pribadi', Icons.person_outline, s.tertiary, [
          _field(c['nama_lengkap']!, 'Nama Lengkap'),
          _field(c['nis']!, 'NIS', readOnly: _readOnly.contains('nis')),
          _field(c['nisn']!, 'NISN', readOnly: _readOnly.contains('nisn')),
          _field(c['tempat_lahir']!, 'Tempat Lahir'),
          _dateField(c['tanggal_lahir']!, 'Tanggal Lahir'),
          _dropdown(c['jenis_kelamin']!, 'Jenis Kelamin', const ['L', 'P']),
          _field(c['agama']!, 'Agama'),
          _field(c['nama_panggilan']!, 'Nama Panggilan'),
          _dropdown(c['status_santri']!, 'Status Santri',
              const ['', 'Santri', 'Non-Santri']),
          _dropdown(c['status_asrama']!, 'Status Asrama',
              const ['', 'Asrama', 'Non-Asrama']),
          _field(c['kategori']!, 'Kategori'),
          _dropdown(c['golongan_darah']!, 'Golongan Darah',
              const ['', 'A', 'B', 'AB', 'O', 'A+', 'A-', 'B+', 'B-', 'AB+',
                  'AB-', 'O+', 'O-']),
          _field(c['anak_ke']!, 'Anak Ke', number: true),
          _field(c['jumlah_saudara']!, 'Jumlah Saudara', number: true),
          _field(c['hobi']!, 'Hobi'),
          _field(c['cita_cita']!, 'Cita-cita'),
        ]),
        _section('Alamat', Icons.home_outlined, const Color(0xFF00897B), [
          _field(c['alamat']!, 'Alamat (Jalan / Dusun)', multiline: true),
          _field(c['rt']!, 'RT'),
          _field(c['rw']!, 'RW'),
          _field(c['desa_kelurahan']!, 'Desa / Kelurahan'),
          _field(c['kecamatan']!, 'Kecamatan'),
          _field(c['kabupaten']!, 'Kabupaten / Kota'),
          _field(c['provinsi']!, 'Provinsi'),
          _field(c['kode_pos']!, 'Kode Pos'),
        ]),
        _section('Pendidikan', Icons.school_outlined, const Color(0xFFF57C00), [
          _field(c['kelas']!, 'Kelas',
              readOnly: _readOnly.contains('kelas')),
          _field(c['tingkat']!, 'Tingkat',
              readOnly: _readOnly.contains('tingkat')),
          _field(c['tahun_ajaran']!, 'Tahun Ajaran',
              readOnly: _readOnly.contains('tahun_ajaran')),
          _field(c['semester']!, 'Semester',
              readOnly: _readOnly.contains('semester')),
          _dateField(c['tanggal_masuk']!, 'Tanggal Masuk',
              readOnly: _readOnly.contains('tanggal_masuk')),
          _dateField(c['tanggal_daftar']!, 'Tanggal Daftar',
              readOnly: _readOnly.contains('tanggal_daftar')),
          _field(c['status']!, 'Status',
              readOnly: _readOnly.contains('status')),
          _field(c['transportasi']!, 'Transportasi'),
          _field(c['jarak_rumah_ke_sekolah']!, 'Jarak Rumah → Sekolah',
              number: true),
          _field(c['waktu_perjalanan']!, 'Waktu Perjalanan'),
        ]),
        _section('Kesehatan', Icons.favorite_outline, const Color(0xFF4E342E), [
          _field(c['disabilitas']!, 'Disabilitas'),
          _field(c['alergi']!, 'Alergi'),
          _field(c['riwayat_penyakit']!, 'Riwayat Penyakit'),
          _field(c['tinggi_badan']!, 'Tinggi Badan (cm)', number: true),
          _field(c['berat_badan']!, 'Berat Badan (kg)', number: true),
          _field(c['tinggi_badan_saat_masuk']!, 'TB Saat Masuk (cm)',
              number: true),
          _field(c['berat_badan_saat_masuk']!, 'BB Saat Masuk (kg)',
              number: true),
          _field(c['pondok']!, 'Pondok'),
        ]),
        _section('Kontak & Dokumen', Icons.contact_page_outlined,
            const Color(0xFF3949AB), [
          _field(c['no_hp']!, 'No. HP', phone: true),
          _field(c['email']!, 'Email', email: true),
          _field(c['nik']!, 'NIK', number: true),
          _field(c['no_kk']!, 'No. KK'),
          _field(c['akta_lahir']!, 'Akta Lahir'),
          _field(c['no_kip']!, 'No. KIP', number: true),
          _field(c['kip']!, 'KIP'),
          _field(c['pkh']!, 'PKH'),
        ]),
      ],
    );
  }

  Widget _tabSekolah() {
    final s = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Sekolah Asal', Icons.school_outlined, s.primary, [
          if (_sekolah == null)
            _emptyNote('Sekolah asal belum dicatat.',
                'Isi data sekolah asal siswa di sini.')
          else ...[
            for (final k in _sekolah!.keys)
              if (_sekolahC.containsKey(k))
                _field(_sekolahC[k]!, _sekolahLabel(k)),
          ],
        ]),
        _section('Riwayat Mutasi', Icons.swap_vert_circle_outlined,
            const Color(0xFF6D4C41), [
          if (_mutasi == null)
            _emptyNote('Belum ada riwayat mutasi.',
                'Data mutasi siswa akan tampil di sini.')
          else ...[
            for (final k in _mutasi!.keys)
              if (_mutasiC.containsKey(k))
                _field(_mutasiC[k]!, _sekolahLabel(k)),
          ],
        ]),
      ],
    );
  }

  Widget _tabOrtu(String jenis, Map<String, TextEditingController> c,
      List<String> keys) {
    final label = switch (jenis) {
      'ayah' => 'Ayah',
      'ibu' => 'Ibu',
      _ => 'Wali',
    };
    final icon = switch (jenis) {
      'ayah' => Icons.man_outlined,
      'ibu' => Icons.woman_outlined,
      _ => Icons.verified_user_outlined,
    };
    if (keys.isEmpty) {
      return _emptyNote('Data $label belum tercatat.',
          'Biodata $label siswa akan tampil di sini.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Data $label', icon, const Color(0xFF6A1B9A), [
          for (final k in keys)
            if (k == 'tanggal_lahir')
              _dateField(c[k]!, _ortuLabel(k))
            else if (k == 'telepon')
              _field(c[k]!, _ortuLabel(k), phone: true)
            else if (k == 'nik' || k == 'no_kk')
              _field(c[k]!, _ortuLabel(k), number: true)
            else if (k == 'alamat')
              _field(c[k]!, _ortuLabel(k), multiline: true)
            else
              _field(c[k]!, _ortuLabel(k)),
        ]),
      ],
    );
  }

  Widget _tabLampiran() {
    final s = Theme.of(context).colorScheme;
    final total = _lampiran.length;
    final unggah =
        _lampiran.where((e) => (e['url']?.toString().isNotEmpty ?? false)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Dokumen Lampiran', Icons.folder_outlined, s.tertiary, [
          if (_lampiran.isEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.folder_open_outlined,
                  color: s.onSurfaceVariant),
              title: const Text('Belum ada dokumen lampiran.'),
              subtitle: const Text(
                  'Dokumen siswa akan tampil di sini dan bisa diunggah.'),
            )
          else
            for (final d in _lampiran) _lampRow(s, d),
        ], badge: '$unggah/$total terunggah'),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 15, color: s.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ketuk baris yang belum terunggah untuk memilih file. Gambar '
                  'JPG/PNG/WebP/GIF/BMP atau PDF, maksimal 5 MB.',
                  style: TextStyle(
                      fontSize: 11.5, color: s.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lampRow(ColorScheme s, Map<String, dynamic> d) {
    final field = d['field']?.toString() ?? '';
    final label = d['label']?.toString() ?? 'Dokumen';
    final url = d['url']?.toString() ?? '';
    final hasUrl = url.isNotEmpty;
    final uploading = _uploadingField == field;
    final (icon, color) = _lampStyle(field, s);
    const orange = Color(0xFFF59E0B);
    const ok = Color(0xFF43A047);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: hasUrl
            ? s.surface
            : s.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: uploading
              ? null
              : () => hasUrl
                  ? _openLampiran(url, label)
                  : _pickAndUpload(d),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasUrl
                    ? s.outlineVariant.withValues(alpha: 0.5)
                    : orange.withValues(alpha: 0.6),
                width: hasUrl ? 1 : 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasUrl
                        ? color.withValues(alpha: 0.14)
                        : s.outlineVariant.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 22,
                      color: hasUrl ? color : s.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                              uploading
                                  ? Icons.hourglass_top
                                  : hasUrl
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                              size: 14,
                              color: uploading
                                  ? s.primary
                                  : hasUrl
                                      ? ok
                                      : orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                                uploading
                                    ? 'Mengunggah…'
                                    : hasUrl
                                        ? 'Tersimpan — ketuk untuk lihat'
                                        : 'Belum unggah — ketuk untuk pilih file',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: uploading
                                        ? s.primary
                                        : hasUrl
                                            ? ok
                                            : orange)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                uploading
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: s.primary),
                        ),
                      )
                    : Icon(
                        hasUrl
                            ? Icons.check_circle
                            : Icons.add_circle,
                        size: hasUrl ? 30 : 36,
                        color: hasUrl ? ok : orange),
              ],
            ),
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
      'file_ktp_ibu' =>
          (Icons.face_retouching_natural_outlined, const Color(0xFFAD1457)),
      'file_ktp_wali' =>
          (Icons.verified_user_outlined, const Color(0xFF546E7A)),
      'file_kip' => (Icons.savings_outlined, const Color(0xFFE53935)),
      'file_rapor_asal' =>
          (Icons.receipt_long_outlined, const Color(0xFF00ACC1)),
      _ => (Icons.attach_file, s.tertiary),
    };
  }

  Future<void> _pickAndUpload(Map<String, dynamic> d) async {
    final field = d['field']?.toString();
    final label = d['label']?.toString() ?? 'Dokumen';
    if (field == null || field.isEmpty) return;
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'pdf',
        ],
      );
    } catch (_) {
      _toast('Gagal membuka pemilih file.');
      return;
    }
    if (files.isEmpty) return;
    final file = files.first;
    final size = file.lengthSync() ?? await file.length();
    if (size > 5 * 1024 * 1024) {
      _toast('Ukuran file maksimal 5 MB.');
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploadingField = field);
    try {
      final bytes = await file.readAsBytes();
      final data = await Api.uploadLampiran(field, bytes, file.name);
      final l = data['lampiran'];
      if (!mounted) return;
      setState(() {
        if (l is List) {
          _lampiran = l
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        _uploadingField = '';
      });
      messenger.showSnackBar(
          SnackBar(content: Text('$label berhasil diunggah.')));
    } on Exception catch (e) {
      if (mounted) setState(() => _uploadingField = '');
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _tabRiwayat() {
    final s = Theme.of(context).colorScheme;
    if (_riwayat.isEmpty) {
      return _emptyNote('Belum ada riwayat kelas.',
          'Perjalanan kelas siswa akan tampil di sini.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Riwayat Kelas', Icons.history_edu_outlined, s.primary, [
          for (final r in _riwayat) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.radio_button_checked, color: s.primary),
              title: Text(r['kelas']?.toString() ?? 'Kelas'),
              subtitle: Text([
                if ((r['tahun_ajaran']?.toString() ?? '') != '')
                  r['tahun_ajaran']!.toString(),
                if ((r['semester']?.toString() ?? '') != '')
                  r['semester']!.toString(),
              ].join(' • ')),
              trailing: Text(r['status']?.toString() ?? ''),
            ),
            if ((r['tanggal_masuk']?.toString() ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${r['tanggal_masuk']} → ${r['tanggal_keluar'] ?? 'sekarang'}',
                  style: TextStyle(
                      fontSize: 11, color: s.onSurfaceVariant)),
                ),
            if (!identical(r, _riwayat.last)) const SizedBox(height: 4),
          ],
        ]),
      ],
    );
  }

  // ------------------------------------------------------------------ save
  void _openLampiran(String raw, String label) {
    openLampiran(context, raw, label);
  }

  Future<void> _save() async {
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
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  _tabBar(Theme.of(context).colorScheme),
                  const SizedBox(height: 14),
                  switch (_tab) {
                    0 => _tabSiswa(),
                    1 => _tabSekolah(),
                    2 => _tabOrtu('ayah', _ayahC, _ayahKeys),
                    3 => _tabOrtu('ibu', _ibuC, _ibuKeys),
                    4 => _tabOrtu('wali', _waliC, _waliKeys),
                    5 => _tabLampiran(),
                    _ => _tabRiwayat(),
                  },
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2))
              : const Icon(Icons.check_circle_outline),
          label: Text(_saving ? 'Menyimpan…' : 'Simpan Data',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}