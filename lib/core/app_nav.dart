import 'package:flutter/foundation.dart';

/// Hub navigasi global untuk aksi dari luar widget (mis. tap notifikasi):
/// pindah tab bawah dan/atau membuka id pengumuman tertentu.
class AppNav {
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
  static final ValueNotifier<int> openPengumuman = ValueNotifier<int>(0);

  static void openTab(int index) {
    openPengumuman.value = 0;
    tabIndex.value = index;
  }

  /// Buka detail pengumuman [id] (otomatis pindah ke tab Pengumuman).
  static void openPengumumanId(int id) {
    tabIndex.value = 4;
    openPengumuman.value = id;
  }
}