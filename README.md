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
  **Menu lainnya** di ujung kanan judul membuka **17 menu** dalam grup
  expand/collapse (Pembelajaran, Keuangan, Kehadiran, Informasi). Di bawahnya:
  Aktivitas Terakhir, Pengumuman, Lainnya (notifikasi/tema/privasi), dan Keluar.
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
- `lib/core/api.dart`, `lib/core/session.dart` — klien API & sesi.
- `lib/models/login.dart`, `lib/models/profil.dart` — model kontrak API (login & profil publik).
- `lib/core/credential_store.dart` — sandi tersimpan terenkripsi (Keystore/Keychain).
- `lib/core/theme.dart` — tema Material You (color scheme adaptif + fallback brand).
- `docs/build-arm64.md` — resep lengkap build arm64 (termasuk injeksi lib).

## Testing

```bash
flutter analyze
flutter test
```