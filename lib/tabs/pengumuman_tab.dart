import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/app_nav.dart';

class PengumumanTab extends StatefulWidget {
  const PengumumanTab({super.key});

  @override
  State<PengumumanTab> createState() => _PengumumanTabState();
}

class _PengumumanTabState extends State<PengumumanTab> {
  final List<Map<String, dynamic>> _items = [];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _initialError = false;
  String _error = '';
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    AppNav.openPengumuman.addListener(_onOpenPengumuman);
    _onOpenPengumuman();
  }

  @override
  void dispose() {
    AppNav.openPengumuman.removeListener(_onOpenPengumuman);
    super.dispose();
  }

  void _onOpenPengumuman() {
    final id = AppNav.openPengumuman.value;
    if (id <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _PengumumanDetailPage(id: id),
        ),
      );
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _initialError = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    final next = reset ? 1 : _page + 1;
    try {
      final data = await Api.pengumumanList(page: next, perPage: 20);
      if (!mounted) return;
      final list = (data['list'] as List).cast<Map<String, dynamic>>();
      final total = (data['total'] as num?)?.toInt() ?? 0;
      setState(() {
        if (reset) {
          _items..clear()..addAll(list);
        } else {
          _items.addAll(list);
        }
        _page = next;
        _hasMore = _items.length < total;
        _loading = false;
        _loadingMore = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      if (reset && _items.isEmpty) {
        setState(() {
          _initialError = true;
          _error = e.toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pengumuman: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _refresh() => _load(reset: true);

  void _open(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PengumumanDetailPage(
          id: _str(item, 'id').isEmpty ? 0 : int.parse(_str(item, 'id')),
          title: _str(item, 'judul'),
        ),
      ),
    );
  }

  String _str(Map<String, dynamic> m, String key) {
    final v = m[key];
    return v == null ? '' : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_loading) {
      body = _quickList(_skeleton(context));
    } else if (_initialError) {
      body = _quickList(_errorView(context, _error, _refresh));
    } else if (_items.isEmpty) {
      body = _quickList(_emptyView(context));
    } else {
      body = _listView(context);
    }
    return SafeArea(
      top: false,
      child: RefreshIndicator(onRefresh: _refresh, child: body),
    );
  }

  // --------------------------------------------------------- daftar/normal
  Widget _listView(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: _loadingMore
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : OutlinedButton.icon(
                      onPressed: () => _load(),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Muat lebih banyak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: s.primary,
                        side: BorderSide(color: s.outlineVariant),
                      ),
                    ),
            ),
          );
        }
        return _card(context, _items[i]);
      },
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> p) {
    final s = Theme.of(context).colorScheme;
    final prio = _str(p, 'prioritas').trim().toLowerCase();
    final (color, label) = switch (prio) {
      'urgent' => (const Color(0xFFE53935), 'Urgent'),
      'penting' => (const Color(0xFFFB8C00), 'Penting'),
      _ => (s.primary, 'Biasa'),
    };
    final judul = _str(p, 'judul').trim();
    final isi = _preview(_str(p, 'isi'));
    final tanggal = _fmt(_str(p, 'created_at'));
    final pengirim = _str(p, 'pengirim_nama').trim();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _open(p),
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(label,
                          style: TextStyle(
                              color: color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(tanggal,
                    style: TextStyle(
                        fontSize: 11,
                        color: s.onSurfaceVariant)),
              ],
            ),
            if (judul.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
            ],
            if (isi.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: s.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.7,
              color: s.outlineVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(Icons.person_outline, size: 15, color: s.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pengirim.isEmpty ? 'Madrasah' : pengirim,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: s.onSurfaceVariant),
                  ),
                ),
                Text('Baca',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s.primary)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 18, color: s.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- state kosong
  Widget _quickList(Widget child) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [child],
      );

  Widget _emptyView(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: s.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.campaign_outlined, size: 34, color: s.primary),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada pengumuman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Pengumuman terbaru dari madrasah akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: s.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context, String error, VoidCallback retry) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 44, color: s.outline),
          const SizedBox(height: 14),
          const Text('Gagal memuat pengumuman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final box = s.onSurface.withValues(alpha: 0.07);
    Widget placeholder(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: box,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    Widget card() => Container(
          margin: const EdgeInsets.only(bottom: 10),
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
                  placeholder(64, 18),
                  const Spacer(),
                  placeholder(90, 12),
                ],
              ),
              const SizedBox(height: 12),
              placeholder(double.infinity, 16),
              const SizedBox(height: 8),
              placeholder(double.infinity, 14),
              const SizedBox(height: 16),
              placeholder(120, 14),
            ],
          ),
        );
    return Column(children: [card(), card(), card()]);
  }

  // ------------------------------------------------------------ bantu
  String _preview(String raw) {
    final clean = _stripHtml(raw)
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\u00a0'), ' ')
        .trim();
    return clean;
  }

  String _stripHtml(String input) {
    var out = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    out = out
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return out;
  }

  static const _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];
  static const _bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  String _fmt(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.split(' ');
    final datePart = parts.isNotEmpty ? parts.first : '';
    final timePart = parts.length > 1 ? parts[1] : '';
    final d = datePart.split('-');
    if (d.length != 3) return raw;
    final y = int.tryParse(d[0]);
    final m = int.tryParse(d[1]);
    final day = int.tryParse(d[2]);
    if (y == null || m == null || day == null) return raw;
    if (y < 1 || m < 1 || m > 12 || day < 1 || day > 31) return raw;
    final dt = DateTime(y, m, day);
    final label =
        '${_hari[dt.weekday - 1]}, $day ${_bulan[m - 1]} $y';
    if (timePart.isNotEmpty && timePart.contains(':')) {
      final hm = timePart.split(':');
      if (hm.length >= 2) {
        return '$label • ${hm[0].padLeft(2, '0')}:${hm[1].padLeft(2, '0')}';
      }
    }
    return label;
  }
}

class _PengumumanDetailPage extends StatefulWidget {
  const _PengumumanDetailPage({required this.id, this.title = ''});

  final int id;
  final String title;

  @override
  State<_PengumumanDetailPage> createState() => _PengumumanDetailPageState();
}

class _PengumumanDetailPageState extends State<_PengumumanDetailPage> {
  Map<String, dynamic>? _item;
  bool _loading = true;
  bool _error = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final detail = await Api.pengumumanDetail(widget.id);
      if (!mounted) return;
      setState(() {
        _item = detail;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _errorMsg = e.toString();
      });
    }
  }

  String _str(Map<String, dynamic>? m, String key) {
    if (m == null) return '';
    final v = m[key];
    return v == null ? '' : v.toString();
  }

  String _stripHtml(String input) {
    var out = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    out = out
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final item = _item;
    final judul = _str(item, 'judul');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(judul.isEmpty ? widget.title : judul,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? _errorView(s)
              : _content(s, item!),
    );
  }

  Widget _errorView(ColorScheme s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: s.outline),
            const SizedBox(height: 12),
            const Text('Gagal memuat detail pengumuman',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(_errorMsg,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ColorScheme s, Map<String, dynamic> item) {
    final prio = _str(item, 'prioritas').trim().toLowerCase();
    final (color, label) = switch (prio) {
      'urgent' => (const Color(0xFFE53935), 'Urgent'),
      'penting' => (const Color(0xFFFB8C00), 'Penting'),
      _ => (s.primary, 'Biasa'),
    };
    final judul = _str(item, 'judul').trim();
    final isi = _stripHtml(_str(item, 'isi')).replaceAll(RegExp(r'\s+'), ' ').trim();
    final tanggal = _fmt(_str(item, 'created_at'));
    final mulai = _fmt(_str(item, 'tanggal_mulai'));
    final selesai = _fmt(_str(item, 'tanggal_selesai'));
    final pengirim = _str(item, 'pengirim_nama').trim();

    final lampiran = item['lampiran_files'];
    final files = lampiran is List ? lampiran : <dynamic>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(label,
                            style: TextStyle(
                                color: color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              if (judul.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(judul,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, height: 1.25)),
              ],
              if (tanggal.isNotEmpty) ...[
                const SizedBox(height: 10),
                _meta(s, Icons.schedule, tanggal),
              ],
              if (pengirim.isNotEmpty) ...[
                const SizedBox(height: 6),
                _meta(s, Icons.person_outline,
                    pengirim.isEmpty ? 'Madrasah' : pengirim),
              ],
              if (mulai.isNotEmpty) ...[
                const SizedBox(height: 6),
                _meta(s, Icons.event_outlined, 'Mulai $mulai'),
              ],
              if (selesai.isNotEmpty) ...[
                const SizedBox(height: 6),
                _meta(s, Icons.event_available_outlined, 'Berakhir $selesai'),
              ],
            ],
          ),
        ),
        if (isi.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: s.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: s.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Text(isi,
                style: TextStyle(
                    fontSize: 13.5, height: 1.55, color: s.onSurface)),
          ),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height: 12),
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
                    Icon(Icons.attach_file, size: 18, color: s.primary),
                    const SizedBox(width: 8),
                    const Text('Lampiran',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final f in files) _fileChip(s, f)],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text('Terakhir diperbarui: ${_fmt(_str(item, 'updated_at'))}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: s.outline)),
      ],
    );
  }

  Widget _meta(ColorScheme s, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: s.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12.5, color: s.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _fileChip(ColorScheme s, dynamic f) {
    String nama = '';
    if (f is Map) {
      nama = (f['nama'] ?? f['name'] ?? f['file'] ?? f['url'] ?? '').toString();
    } else if (f != null) {
      nama = f.toString();
    }
    nama = nama.trim();
    if (nama.startsWith('http')) {
      nama = nama.split('/').last;
    }
    if (nama.isEmpty) nama = 'File';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: s.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 16, color: s.primary),
          const SizedBox(width: 6),
          Text(nama,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: s.primary)),
        ],
      ),
    );
  }

  static const _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];
  static const _bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  String _fmt(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.trim().split(' ');
    final d = parts.isNotEmpty ? parts.first.split('-') : <String>[];
    if (d.length != 3) return raw;
    final y = int.tryParse(d[0]);
    final m = int.tryParse(d[1]);
    final day = int.tryParse(d[2]);
    if (y == null || m == null || day == null) return raw;
    if (y < 1 || m < 1 || m > 12 || day < 1 || day > 31) return raw;
    final dt = DateTime(y, m, day);
    final label = '${_hari[dt.weekday - 1]}, $day ${_bulan[m - 1]} $y';
    if (parts.length > 1) {
      final hm = parts[1].split(':');
      if (hm.length >= 2) {
        return '$label • ${hm[0].padLeft(2, '0')}:${hm[1].padLeft(2, '0')}';
      }
    }
    return label;
  }
}