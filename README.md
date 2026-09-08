# simsiswa_flutter

Aplikasi mobile **SIM Siswa MTs Bahrul Ulum Tambakberas** — pengganti aplikasi Java
lama untuk siswa & wali. Satu codebase Flutter.

## Fitur

- **Halaman index (portal)**: hanya untuk pengunjung yang **belum login** — menampilkan
  profil publik madrasah (nama, tagline, alamat) lengkap dengan kartu identitas,
  informasi, kontak (WhatsApp/Telepon/Email/Website presisi dengan ikon & aksi
  `wa.me`/`tel:`/`mailto:`/web), dan media sosial berkelir brand (IG, FB, YouTube,
  TikTok, X, WA) yang bisa dibuka langsung. Data dari `GET app/api/apk/siswa/public_profil`
  (kontrak sama dengan aplikasi versi lama). Ada kartu pengenalan brand **SIM —
  Sistem Informasi Manajemen**. Tombol **Masuk** menuju halaman login; dari login
  tersedia tombol **Beranda** untuk kembali ke index. Pengguna yang sudah login
  **langsung** masuk ke menu utama (index dilewati).
- **Beranda (home) premium**: hero profil siswa bergradien — badge **status** di ujung
  kanan baris salam, **2 kolom data** (NIS/NISN digabung | Tempat & Tanggal Lahir),
  dan **Alamat Rumah satu kolom full-width** (data diambil dari
  `POST app/api/apk/siswa/profil` saat login dengan fallback ke data login; kolom
  tetap tampil dengan "-" bila datanya belum tersedia). Menu layanan disusun sebagai
  kotak (card) berisi grid navigasi 5 kolom dengan ikon warna besar, tombol badge
  **Menu lainnya** di ujung kanan judul membuka menu dalam grup
  expand/collapse (Pembelajaran, Keuangan, Kehadiran, Informasi). Di bawahnya:
  Aktivitas Terakhir, Pengumuman, Lainnya (notifikasi/tema/pengaturan — semuanya
  kini membuka halaman sungguhan), dan Keluar.
- **Profil siswa (tab)**: tab Siswa / Sekolah / Ayah / Ibu / Wali / Lampiran /
  Riwayat. Tab yang datanya kosong tampil ramah ("belum dicatat") tanpa kartu
  diagnostik. Tombol **Edit** di header membuka halaman edit profil siswa
  (`lib/edit_profil/edit_profil_page.dart`) berisi form lengkap sesuai kolom
  tabel akhir (Siswa): Data Pribadi, Dokumen & Kontak, Fisik & Kesehatan,
  Pendidikan, Asrama, Alamat, dan Lain-lain. Simpan mengirim
  `POST app/api/apk/profil_siswa` dengan aksi `update` (lihat "Kontrak").
  Data krusial/administratif (NIS, NISN, Kelas, Tingkat, Tahun Ajaran,
  Semester, Tanggal Masuk, Tanggal Daftar, Status) **hanya bisa dilihat**
  (read-only, di-grey) — tidak bisa diubah siswa/wali, karena diisi oleh
  petugas/admin atau dihasilkan dari JOIN server.
- **Edit profil "baris per kolom"**: setiap field tampil sendiri satu baris
  penuh (bukan kolom berdampingan), dalam kartu section berjudul + icon +
  badge jumlah field; antar field dipisah garis halus — konsisten dengan tab
  Profil.
- **Lampiran dibuka di dalam aplikasi** (tanpa browser): file dari tab Lampiran
  Profil maupun daftar `_tabLampiran` Edit Profil dibuka lewat
  `lib/viewers/lampiran_viewer_page.dart` — gambar (png/jpg/jpeg/webp/gif/bmp)
  dengan pinch-zoom, dan PDF dirender via `pdfx` (`PdfViewPinch`); tipe lain
  ditampilkan sebagai "belum didukung" dengan tombol coba lagi.
- **Upload lampiran** (gambar/PDF, maks 5 MB): dari tab Lampiran Edit Profil
  (ikon + / upload per dokumen) maupun tombol **Unggah / Kelola** di tab
  Lampiran profil. Aplikasi memilih file (file_picker), kirim multipart ke
  `profil_siswa.php` aksi `upload` (token dari sesi), dan daftar lampiran
  di-refresh dari respons server.
- **Tema Material You**: seluruh pewarnaan (background, appbar, nav, kartu, login)
  mengikuti color scheme wallpaper Android; fallback ke seed emerald brand bila
  dynamic color tak tersedia.
- **Bottom nav premium**: piring bercahaya dengan kilatan putih persisten di menu
  aktif (mengikuti warna ternary/primary dari wallpaper).
- **Android**: API 21 (Android 5.0) → terbaru; ABI `arm64-v8a`, `armeabi-v7a` (32-bit),
  `x86_64` (emulator).
- **iOS**: iOS 13.0 (iPhone 6s/SE/7 ke atas) → terbaru; device & simulator.
- Login siswa (`NIS` + kata sandi) & wali (`NISN` siswa + `NIK` wali) ke SIM SIAPOS.
- "Simpan sandi?" gaya Google: kredensial terenkripsi di Keystore/Keychain
  (`lib/core/credential_store.dart`, `flutter_secure_storage`) dan terisi otomatis di login berikutnya.
- Backend: `https://sim.mtsbutambakberas.sch.id`
- Kontrak login: `POST app/api/apk/siswa/login` dengan JSON `{username, password, role}`.
- Kontrak profil siswa: `POST app/api/apk/siswa/profil` dengan JSON `{siswa_id}` →
  `data.siswa` (nis, nisn, nama_lengkap, status, tempat_lahir, tanggal_lahir, alamat
  lengkap, dst.). Dipakai hero beranda; jatuh ke data login bila belum tersedia.
- Kontrak profil lengkap: `GET app/api/apk/profil_siswa` (token dari sesi) →
  `data` berisi `siswa`, `sekolah_asal`, `mutasi`, `orangtua` (ayah/ibu/wali),
  `lampiran`, `riwayat_kelas`.
- Kontrak edit profil (sama persis dengan kolom tabel `siswa`, mis. nama_lengkap,
  jenis_kelamin, tempat_lahir, tanggal_lahir, alamat, dst.): **dipakai endpoint
  `profil_siswa` yang sudah ada** — baca `GET`, simpan `POST app/api/apk/profil_siswa`
  dengan JSON `{aksi:'update', siswa_id, data}` → `success` boolean; app menampilkan
  pesan dari `message`. Tidak perlu file server baru.
- Kontrak upload lampiran: `POST app/api/apk/profil_siswa` **multipart/form-data**
  `{aksi:'upload', field}` + file `file` (gambar JPG/PNG/WebP/GIF/BMP atau PDF,
  maks 5 MB) → file disimpan di `<script_dir>/uploads_lampiran/<rand>.ext` (folder
  dibuat otomatis, **butuh izin tulis PHP**), url relatif `uploads_lampiran/<name>`
  di-resolve aplikasi ke base URL → respons `data.lampiran` = daftar terbaru.
- **Pengaturan** (`lib/settings/settings_page.dart`): hub aplikasi berisi sub-halaman
  Akun (data & logout), Tema (Sistem/Terang/Gelap — disimpan di preferensi & dipakai
  `MaterialApp.themeMode`), Notifikasi (toggle + register token FCM), Privasi
  (hapus data lokal), dan Tentang.
- Nomor versi memakai 3 digit belakang (mis. `v1.411`), naik satu per build.

## Cara Build (rekomendasi dari pengalaman nyata)

Ada **dua jalur**, dipakai sesuai kebutuhan:

| Kebutuhan | Jalur | Keterangan |
|---|---|---|
| **Development / iterasi cepat** | CI arm64 + `fetch_ci.sh` + `build_local.sh` | Push → CI ±3–4m → unduh (anti-race) → sign 4 detik. |
| **Rilis yang dipakai publik** | GitHub Actions (`build-full.yml`) | Workflow terpisah: semua ABI (dispatch manual / tag `v*`). |
| **Rilis final** | Lokal + injeksi lib dari artefak CI | Byte-identik dgn hasil CI. |
| **Satu file untuk semua** | Lokal (universal/fat APK) | Gabung lib arm64+v7a → 1 APK (±15MB); fast-path arm64 saja ±8,6MB. |

### Kenapa dua jalur? (pelajaran yang sudah dibuktikan)

- Build release di **host arm64** (Flutter SDK arm64 di HP) menghasilkan `libapp.so`
  AOT yang **tidak standar** → layar blank setelah splash. Ini cacat distribusi SDK,
  bukan bug aplikasi.
- Build release di **host x64** (GitHub Actions, `ubuntu-latest` + Flutter stable)
  menghasilkan APK yang **renders dengan benar** (libflutter.so ±11,7MB,
  libapp.so ±5,1MB, total ±8,4MB).
- Versi debug di HP berjalan normal; hanya AOT release dari host arm64 yang rusak.
- Engine Flutter **stable** (3.47.2) juga bisa dipasang di HP: `git clone -b stable`.
  Perlu 2 perbaikan tambahan (lihat `docs/build-arm64.md`): menyediakan
  `gen_snapshot` arm64 dari Dart SDK, dan override `aapt2` arm64.

### 1) Development — loop cepat (CI arm64, tanpa build Gradle lokal)

```bash
git add -A && git commit -m "..." && git push origin main   # memicu workflow arm64+caching
bash /root/fetch_ci.sh                                        # unduh artefak run yang cocok dgn HEAD (anti-race)
bash /root/build_local.sh /tmp/ci_apk                         # ambil APK arm64 dari CI → sign langsung (±4 dtk)
```

Karena `libapp.so` arm64 dari host x64 CI sudah benar, tidak perlu build AOT
lokal maupun injeksi manual — cukup sign ulang. Output di
`/storage/emulated/0/Download/SIMSiswaMTsBU.apk` (±8,6MB, arm64; bila artefak
full tersedia, otomatis digabung v7a menjadi ±15MB universal).

### 2) Rilis publik — lewat GitHub Actions

```bash
git add -A && git commit -m "..." && git push origin main
```

Workflow `.github/workflows/build-apk.yml` (Flutter stable) otomatis:
analyze, test, build **APK arm64-v8a saja** (cepat; caching Flutter/Gradle), plus
job **iOS build** di `macos-latest` (`flutter build ios --release --no-codesign`)
untuk memastikan codebase tetap kompatibel iPhone/iPad. Artefak APK diunduh lalu
ditandatangani lokal (keystore tidak pernah masuk repo — lihat di bawah). Untuk
**semua ABI** (rilis publik), jalankan `.github/workflows/build-full.yml`
(dispatch manual atau tag `v*`) yang tetap menghasilkan split `arm64/v7a/x64`.

### 3) Rilis final dari lokal (rekomendasi)

Karena AOT arm64-host rusak, untuk rilis lokal yang dijamin render gunakan biner
**yang sudah terbukti** dari artefak CI (kode identik saat HEAD sama):

```
# setelah CI sukses & artefak diunduh ke /tmp/ci_apk:
bash /root/build_local.sh /tmp/ci_apk
#   -> mode cepat: APK CI dipakai langsung (libapp benar) → zipalign + apksigner.
#      Bila artefak 'build-full', lib/ armeabi-v7a ikut digabung → universal dua ABI.
```

Hasil akhir: APK split ±8,4MB per ABI, atau **satu universal** ±15MB (arm64-v8a +
armeabi-v7a; x86_64 dipisah untuk emulator) — sertifikat resmi SHA-256
`84fa49a1…` (over-install antar versi aman). Alternatif pemangkasan lebih lanjut:
`--obfuscate`, atau App Bundle (`.aab`) agar Play hanya mengirim ABI yang dibutuhkan.

## Keystore & Keamanan

- `android/release.keystore` + `android/keystore.properties` + `android/local.properties`
  bersifat lokal, **di-gitignore**, tidak pernah di-push.
- Build CI menghasilkan APK **tanpa tanda tangan**; penandatanganan selalu dilakukan
  lokal: `zipalign -p -f 4` lalu `apksigner sign` dengan keystore resmi.
- `android/gradle.properties` lokal memuat override `android.aapt2FromMavenOverride`
  ke aapt2 arm64 — baris ini juga jangan di-push (di CI pakai aapt2 bawaan x64).

## Struktur Proyek

- `lib/index/index_page.dart` — halaman index (portal profil madrasah) sebelum login.
- `lib/auth/login_page.dart` — login siswa/wali (label sesuai kontrak server).
- `lib/tabs/beranda_tab.dart` — beranda premium: hero profil siswa, menu layanan
  (kotak navigasi 5 kolom + badge "Menu lainnya" 17 menu expand/collapse),
  aktivitas, pengumuman, dan keluar.
- `lib/tabs/profil_tab.dart` — profil lengkap siswa (gaya tab premium): tab
  Siswa / Sekolah / Ayah / Ibu / Wali / Lampiran / Riwayat. Data dari
  `GET app/api/apk/profil_siswa` (token dari sesi; siswa_id dari guard server).
  Berisi hero gradien dengan tombol Edit, Data Pribadi, Alamat, Pendidikan +
  Riwayat Kelas (timeline), Kesehatan, Kontak & Dokumen, Sekolah Asal & Mutasi,
  orang tua/wali, grid lampiran dokumen (buka gambar/PDF **di dalam aplikasi**
  via `lib/viewers/lampiran_viewer_page.dart`), pull-to-refresh.
- `lib/viewers/lampiran_viewer_page.dart` — penampil lampiran in-app: unduh
  bytes dengan token sesi, deteksi tipe dari ekstensi/Content-Type, gambar
  dengan zoom, PDF via `pdfx` `PdfViewPinch` (`lib/viewers`).
- `lib/edit_profil/edit_profil_page.dart` — form edit profil siswa (semua kolom
  tabel `siswa`), kirim `POST app/api/apk/profil_siswa` (aksi `update`), reload
  otomatis saat kembali ke tab Profil. Tab Lampiran mendukung **upload** dokumen
  per field (ikon + / upload, file_picker, multipart aksi `upload`).
- `lib/tabs/pengumuman_tab.dart` — pengumuman madrasah dari
  `POST app/api/apk/siswa/pengumuman` (aksi `list`/`detail`): kartu prioritas
  (Urgent/Penting/Biasa), pratinjau isi, tanggal Indonesia, pembuat, lampiran,
  paginasi "Muat lebih banyak", pull-to-refresh, detail halaman terpisah.
- `lib/core/fcm.dart` — notifikasi push FCM: inisialisasi Firebase, izin
  Android 13+, channel & banner lokal (flutter_local_notifications) saat app
  terbuka, registrasi token ke server (`POST app/api/apk/siswa/fcm_token`),
  tap notifikasi → buka detail pengumuman.

## Notifikasi push (FCM)

**Server** menyediakan `app/api/apk/siswa/pengumuman.php` (aksi `send_notif`,
`cron_send`, auto-kirim) + `fcm_helper.php` + `firebase-service-account.json`.

**App Android** butuh konfigurasi project Firebase dari Firebase console
`sim-mts-bu-tambakberas`:
1. `android/app/google-services.json` — **wajib diisi nilai asli**
   (project_number, mobilesdk_app_id, api_key). File saat ini masih template:
   `GANTI_PROJECT_NUMBER`, `GANTI_MOBILE_SDK_APP_ID`, `GANTI_API_KEY`.
2. Server perlu endpoint `POST app/api/apk/siswa/fcm_token`
   (`{aksi:'simpan', siswa_id, token_hp}`) agar token HP tersimpan di tabel
   `notifikasi_hp` yang dibaca `kirimFCM()`.

Tanpa google-services.json asli, aplikasi tetap normal (FCM init ditangkap
aman), tapi tidak bisa menerima push.
- `lib/core/api.dart`, `lib/core/session.dart` — klien API & sesi.
- `lib/models/login.dart`, `lib/models/profil.dart` — model kontrak API (login & profil publik).
- `lib/core/credential_store.dart` — sandi tersimpan terenkripsi (Keystore/Keychain).
- `lib/core/theme.dart` — tema Material You (color scheme adaptif + fallback brand).
- `lib/settings/settings_page.dart` — halaman Pengaturan (Akun, Tema, Notifikasi,
  Privasi, Tentang) beserta sub-halamannya.
- `docs/build-arm64.md` — resep lengkap build arm64 (termasuk injeksi lib).

## Testing

```bash
flutter analyze
flutter test
```