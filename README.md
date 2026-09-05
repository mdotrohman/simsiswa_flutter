# simsiswa_flutter

Aplikasi mobile **SIM Siswa MTs Bahrul Ulum Tambakberas** — pengganti aplikasi Java
lama untuk siswa & wali. Satu codebase Flutter, target Android (arm64) untuk saat ini;
iOS bisa menyusul via CI.

- Login siswa (`NIS` + kata sandi) & wali (`NISN` siswa + `NIK` wali) ke SIM SIAPOS.
- Backend: `https://sim.mtsbutambakberas.sch.id`
- Kontrak login: `POST app/api/apk/siswa/login` dengan JSON `{username, password, role}`.

## Cara Build (rekomendasi dari pengalaman nyata)

Ada **dua jalur**, dipakai sesuai kebutuhan:

| Kebutuhan | Jalur | Keterangan |
|---|---|---|
| **Development / iterasi cepat** | Lokal di HP (Termux/proot) | Cepat, privat, tanpa push. |
| **Rilis yang dipakai publik** | GitHub Actions (CI) | Menghasilkan APK yang benar-benar render. |
| **Rilis final** | Lokal, injeksi lib dari artefak CI | Byte-identik dgn hasil CI. |

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

Build → align → tanda tangan resmi → salin ke `/storage/emulated/0/Download/SIMSiswaMTsBU.apk`.

### 2) Rilis publik — lewat GitHub Actions

```bash
git add -A && git commit -m "..." && git push origin main
```

Workflow `.github/workflows/build-apk.yml` (Flutter stable, split-per-ABI) otomatis:
analyze, test, build. Artefak `apk-release` diunduh lalu ditandatangani lokal
(keystore tidak pernah masuk repo — lihat di bawah).

### 3) Rilis final dari lokal (rekomendasi)

Karena AOT arm64-host rusak, untuk rilis lokal yang dijamin render gunakan biner
**yang sudah terbukti** dari artefak CI (kode identik saat HEAD sama):

```
# setelah CI sukses & artefak diunduh:
#  - ganti lib/arm64-v8a/libapp.so dan libflutter.so di APK lokal
#    dengan isi artefak CI, lalu zipalign + apksigner ulang.
# Skrip lengkap: docs/build-arm64.md ("Rilis lokal dengan injeksi lib")
```

Hasil akhir APK ±8,4MB, sertifikat SHA-256 `84fa49a1…` (over-install antar versi aman).

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
- `docs/build-arm64.md` — resep lengkap build arm64 (termasuk injeksi lib).

## Testing

```bash
flutter analyze
flutter test
```