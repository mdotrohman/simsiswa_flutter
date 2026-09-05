# Build arm64 di Android (Termux/proot) — modus operandi yang terbukti

Ringkasan alur build di HP Android (host arm64, Flutter stable), lengkap dengan
dua perbaikan yang diperlukan dan cara rilis final yang dijamin render.

## 1. Pasang Flutter stable di HP

> Toolchain master/dev (mis. `/opt/flutter-a64`) menghasilkan release blank di
> perangkat ini. Gunakan stable resmi.

```bash
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter-stable
export PATH="/opt/flutter-stable/bin:$PATH"
flutter --version                 # bootstrap Dart SDK + engine (arm64)
flutter precache --android        # unduh artifact engine android
```

Setelah `precache --android`, pastikan artifact ini ada:

```
bin/cache/artifacts/engine/android-arm64-release/linux-arm64/gen_snapshot
```

Jika belum ada (host arm64), buat manual dari Dart SDK (gen_snapshot arm64):

```bash
mkdir -p bin/cache/artifacts/engine/android-arm64-release/linux-arm64
cp -a bin/cache/artifacts/engine/linux-arm64/. bin/cache/artifacts/engine/android-arm64-release/linux-arm64/
cp -a bin/cache/dart-sdk/bin/utils/gen_snapshot bin/cache/artifacts/engine/android-arm64-release/linux-arm64/gen_snapshot
```

## 2. Override aapt2 arm64

Aapt2 yang diunduh Maven adalah biner x64 → SIGILL di HP. Letakkan di
`android/gradle.properties` setempat (JANGAN di-push):

```
android.aapt2FromMavenOverride=/opt/android-sdk/build-tools/36.0.0/aapt2
```

## 3. Build release lokal (semua ABI)

```bash
cd /root/simsiswa_flutter
flutter build apk --release --split-per-abi
```

Menghasilkan tiga APK: `arm64-v8a`, `armeabi-v7a`, `x86_64`. Skrip
`build_local.sh` menggabungkan: pub get → build → (opsional injeksi lib) →
zipalign → apksigner → salin ke `/storage/emulated/0/Download/SIMSiswaMTsBU*.apk`.

> ⚠️ AOT release yang dihasilkan host arm64 **belum tentu render** (blank).
> Penyebab: `libapp.so` lokal ±10,8MB, tidak normal; versi jalan ±5,1MB.

## 4. Rilis final lokal — injeksi lib dari artefak CI (jamin render)

Karena biner arm64-host bermasalah, seduh APK lokal dengan biner yang **terbukti
jalan** dari artefak GitHub Actions ketika **HEAD sama** (codebase identik):

```bash
# 1. Unduh artefak hasil CI:
#    gh api repos/<you>/simsiswa_flutter/actions/artifacts/.../zip → unzip

# 2. Ekstrak lib asli dari APK CI:
unzip -o app-arm64-v8a-release.apk "lib/arm64-v8a/*" -d ci_x

# 3. Tampal ke APK hasil flutter build lokal (ganti libapp.so & libflutter.so):
python3 - <<'EOF'
import zipfile, shutil
apk   = "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
libapp = "ci_x/lib/arm64-v8a/libapp.so"
libfl  = "ci_x/lib/arm64-v8a/libflutter.so"
with zipfile.ZipFile(apk) as z, zipfile.ZipFile("patched.apk","w",zipfile.ZIP_DEFLATED) as o:
    for it in z.infolist():
        d = z.read(it.filename)
        if it.filename == "lib/arm64-v8a/libapp.so":     d=open(libapp,'rb').read(); it.file_size=len(d)
        elif it.filename == "lib/arm64-v8a/libflutter.so": d=open(libfl,'rb').read(); it.file_size=len(d)
        o.writestr(it, d)
EOF

# 4. Align + tanda tangan ulang (keystore lokal):
zipalign -p -f 4 patched.apk final.apk
apksigner sign --ks android/release.keystore --ks-key-alias simsiswa \
  --ks-pass pass:simsiswa2026 --key-pass pass:simsiswa2026 \
  --out /storage/emulated/0/Download/SIMSiswaMTsBU.apk final.apk
```

Hasil: APK ±8,4MB per ABI, render normal, sertifikat resmi SHA-256 `84fa49a1…`;
dilakukan per ABI (arm64-v8a, armeabi-v7a, x86_64).

### 4a. Alternatif satu file universal (fat APK)

`build_local.sh &lt;CISRC&gt;` otomatis menyusun **satu APK universal** ke
`SIMSiswaMTsBU.apk` (±15MB): basis split arm64-v8a lokal (ter-injeksi) + folder
`lib/armeabi-v7a/` dari split CI. Dipakai bila hanya ingin **satu file** yang jalan
di semua perangkat Android (arm64/v7a). `x86_64` (emulator) tetap disediakan
terpisah `SIMSiswaMTsBU-x86_64.apk`. Trade-off: ukuran lebih besar; split per-ABI
tetap lebih ringan bila distribusi via store yang mendukung multi-APK, atau pakai
App Bundle (`.aab`) agar pengguna mengunduh ABI yang dibutuhkan saja.

## 5. Batas minimal versi OS

- **Android**: `minSdk = 21` (Android 5.0 Lollipop) di `android/app/build.gradle.kts`
  — batas terendah yang didukung Flutter & plugin `shared_preferences`.
- **iOS**: `IPHONEOS_DEPLOYMENT_TARGET = 13.0` di `ios/Runner.xcodeproj/project.pbxproj`
  (iPhone 6s/SE/7 ke atas). Validasi build iOS di CI via job `ios-build`
  (`flutter build ios --release --no-codesign`). Menandatangani & distribusi App Store
  perlu Apple developer account di mesin macOS.

## Ukuran yang sehat (patokan)

| Komponen APK arm64-v8a | Ukuran normal |
|---|---|
| `libapp.so` (AOT) | ±5,1MB |
| `libflutter.so` | ±11,7MB |
| Total APK release | ±8,4MB |

Jika `libapp.so` ±10,8MB atau `libflutter.so` ±165MB → build-nya perlu injeksi lib
dari CI (bagian 4) atau dibangun ulang di CI.