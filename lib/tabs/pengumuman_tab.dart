import 'package:flutter/material.dart';

import 'placeholder_tab.dart';

class PengumumanTab extends StatelessWidget {
  const PengumumanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      icon: Icons.campaign,
      title: 'Pengumuman',
      description:
          'Pengumuman terbaru dari madrasah akan tampil di sini.\nMohon tunggu update berikutnya.',
    );
  }
}