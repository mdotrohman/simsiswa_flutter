import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../core/api.dart';
import '../core/session.dart';

/// Membuka lampiran di dalam aplikasi (tanpa browser/plikator luar):
/// gambar (png/jpg/jpeg/webp/gif/bmp) tampil dengan pinch-zoom,
/// PDF dirender di `PdfViewPinch`.
Future<void> openLampiran(BuildContext context, String raw, String label) async {
  final url = raw.startsWith('http')
      ? raw
      : Uri.parse(kApiBaseUrl)
          .resolve(raw.startsWith('/') ? raw.substring(1) : raw)
          .toString();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LampiranViewerPage(url: url, title: label),
    ),
  );
}

class LampiranViewerPage extends StatefulWidget {
  const LampiranViewerPage({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<LampiranViewerPage> createState() => _LampiranViewerPageState();
}

enum _DocType { image, pdf, other }

class _LampiranViewerPageState extends State<LampiranViewerPage> {
  Uint8List? _bytes;
  _DocType? _type;
  String _error = '';
  bool _loading = true;
  Future<PdfDocument>? _pdfFuture;
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _applyFullscreen(false);
    super.dispose();
  }

  /// Aktifkan mode immersive (sembunyikan status/navigation bar) supaya
  /// pratinjau lampiran memakai seluruh layar; dikembalikan saat ditutup.
  void _applyFullscreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
        enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final headers = <String, String>{'Accept': '*/*'};
      final token = Session.token;
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final res = await http
          .get(Uri.parse(widget.url), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = res.statusCode == 401
              ? 'Sesi berakhir. Silakan login ulang.'
              : 'Gagal mengunduh dokumen (kode ${res.statusCode}).';
        });
        return;
      }

      final ctype = (res.headers['content-type'] ?? '')
          .toLowerCase()
          .split(';')
          .first
          .trim();
      final type = _guessType(widget.url, ctype);
      if (!mounted) return;
      setState(() {
        _bytes = res.bodyBytes;
        _type = type;
        _pdfFuture = (type == _DocType.pdf)
            ? PdfDocument.openData(res.bodyBytes)
            : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Tidak dapat mengunduh dokumen. Periksa koneksi Anda.';
      });
    }
  }

  _DocType _guessType(String url, String ctype) {
    final ext = url.split('?').first.split('/').last.split('.').last
        .toLowerCase();
    if (ext == 'pdf' || ctype == 'application/pdf') return _DocType.pdf;
    if (ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'webp' ||
        ext == 'gif' ||
        ext == 'bmp' ||
        ctype.startsWith('image/')) {
      return _DocType.image;
    }
    return _DocType.other;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      _applyFullscreen(false);
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (_error.isNotEmpty) {
      _applyFullscreen(false);
      return _errorView();
    }
    final bytes = _bytes;
    if (bytes == null) {
      _applyFullscreen(false);
      return _errorView();
    }
    final Widget? viewer = switch (_type) {
      _DocType.image => _imageView(bytes),
      _DocType.pdf => _pdfView(),
      _ => null,
    };
    if (viewer == null) {
      _applyFullscreen(false);
      return _otherView();
    }
    _applyFullscreen(true);
    return viewer;
  }

  Widget _errorView() {
    final s = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 42, color: s.error),
            const SizedBox(height: 12),
            Text(_error,
                textAlign: TextAlign.center,
                style: TextStyle(color: s.onSurfaceVariant, fontSize: 13.5)),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageView(Uint8List bytes) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 6,
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _unsupported(
            Icons.broken_image_outlined,
            'Format gambar tidak dikenali.',
          ),
        ),
      ),
    );
  }

  Widget _pdfView() {
    return FutureBuilder<PdfDocument>(
      future: _pdfFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 3));
        }
        if (snap.hasError || snap.data == null) {
          return _unsupported(
              Icons.picture_as_pdf_outlined, 'Gagal membuka dokumen PDF.');
        }
        final controller = _pdfController ??
            PdfControllerPinch(document: _pdfFuture!, initialPage: 1);
        _pdfController = controller;
        return PdfViewPinch(
          controller: controller,
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
        );
      },
    );
  }

  Widget _otherView() {
    return _unsupported(
      Icons.insert_drive_file_outlined,
      'Jenis dokumen ini belum didukung untuk dibuka di aplikasi.',
    );
  }

  Widget _unsupported(IconData icon, String msg) {
    final s = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: s.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: s.onSurfaceVariant, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}