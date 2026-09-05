import 'package:flutter/material.dart';

import 'placeholder_tab.dart';

class AbsensiTab extends StatelessWidget {
  const AbsensiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      icon: Icons.event_available,
      title: 'Absensi',
      description:
          'Fitur rekap kehadiran siswa sedang disiapkan.\nMohon tunggu update berikutnya.',
    );
  }
}