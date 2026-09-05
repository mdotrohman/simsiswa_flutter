# simsiswa_flutter

Aplikasi mobile **SIM Siswa MTs Bahrul Ulum Tambakberas** — pengganti aplikasi Java
lama untuk siswa & wali. Satu codebase Flutter.

- **Android**: API 21 (Android 5.0) → terbaru; ABI `arm64-v8a`, `armeabi-v7a` (32-bit),
  `x86_64` (emulator).
- **iOS**: iOS 13.0 (iPhone 6s/SE/7 ke atas) → terbaru; device & simulator.
- Login siswa (`NIS` + kata sandi) & wali (`NISN` siswa + `NIK` wali) ke SIM SIAPOS.
- "Simpan sandi?" gaya Google: kredensial terenkripsi di Keystore/Keychain
  (`lib/core/credential_store.dart`, `flutter_secure_storage`) dan terisi otomatis di login berikutnya.
- Backend: `https://sim.mtsbutambakberas.sch.id`
- Kontrak login: `POST app/api/apk/siswa/login` dengan JSON `{username, password, role}`.

## Cara Build (rekomendasi dari pengalaman nyata)

Ada **dua jalur**, dipakai sesuai kebutuhan:

| Kebutuhan | Jalur | Keterangan |
|---|---|---|
| **Development / iterasi cepat** | Lokal di HP (Termux/proot) | Cepat, privat, tanpa push. |
| **Rilis yang dipakai publik** | GitHub Actions (CI) | APK semua ABI + cek build iOS. |
| **Rilis final** | Lokal + injeksi lib dari artefak CI | Byte-identik dgn hasil CI. |
| **Satu file untuk semua** | Lokal (universal/fat APK) | Gabung lib arm64+v7a → 1 APK (±15MB). x86_64 tersedia terpisah. |

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

### 1) Development — build lokal (loop cepat)

```
bash /root/build_local.sh
```

Menghasilkan APK untuk **semua ABI** (`arm64-v8a`, `armeabi-v7a`, `x86_64`),
di-align, ditandatangani resmi, lalu disalin ke
`/storage/emulated/0/Download/SIMSiswaMTsBU*.apk`.

### 2) Rilis publik — lewat GitHub Actions

```bash
git add -A && git commit -m "..." && git push origin main
```

Workflow `.github/workflows/build-apk.yml` (Flutter stable) otomatis:
analyze, test, build **APK semua ABI** (`--split-per-abi`), plus job **iOS build**
di `macos-latest` (`flutter build ios --release --no-codesign`) untuk memastikan
codebase tetap kompatibel iPhone/iPad. Artefak APK diunduh lalu ditandatangani
lokal (keystore tidak pernah masuk repo — lihat di bawah).

### 3) Rilis final dari lokal (rekomendasi)

Karena AOT arm64-host rusak, untuk rilis lokal yang dijamin render gunakan biner
**yang sudah terbukti** dari artefak CI (kode identik saat HEAD sama):

```
# setelah CI sukses & artefak diunduh ke /tmp/ci_apk:
bash /root/build_local.sh /tmp/ci_apk
#   -> AOT lokal ditimpa biner terbukti dari CI per ABI (libapp.so + libflutter.so),
#      lalu zipalign + apksigner. Rincian: docs/build-arm64.md ("Rilis lokal dengan injeksi lib")
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

- `lib/auth/login_page.dart` — login siswa/wali (label sesuai kontrak server).
- `lib/tabs/beranda_tab.dart` — beranda + penanganan error dashboard.
- `lib/core/api.dart`, `lib/core/session.dart` — klien API & sesi.
- `lib/core/credential_store.dart` — sandi tersimpan terenkripsi (Keystore/Keychain).
- `docs/build-arm64.md` — resep lengkap build arm64 (termasuk injeksi lib).

## Testing

```bash
flutter analyze
flutter test
```