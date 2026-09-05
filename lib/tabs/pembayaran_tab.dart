import 'package:flutter/material.dart';

import 'placeholder_tab.dart';

class PembayaranTab extends StatelessWidget {
  const PembayaranTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      icon: Icons.payments,
      title: 'Pembayaran',
      description:
          'Fitur riwayat pembayaran SPP sedang disiapkan.\nMohon tunggu update berikutnya.',
    );
  }
}