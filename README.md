# RUNWILD

Fondasi aplikasi mobile Flutter untuk Android dan iOS sesuai [PRD](docs/PRD.md).
Status: Fase 0 sudah diimplementasikan secara lokal, tetapi belum ditutup.
Proyek Firebase dev/prod belum dibuat; Android SDK dan perangkat mobile belum
tersedia. Fase 1 dan fitur tracking belum dimulai.

## Menjalankan

Toolchain terverifikasi: Flutter 3.50.0 / Dart 3.14.0. SDK lokal tersedia di
`.tooling/flutter` pada workspace ini, tidak disertakan dalam Git.

Windows pada workspace ini:

```powershell
./tool/flutter.ps1 pub get
./tool/flutter.ps1 test
./tool/flutter.ps1 run -d <id-perangkat>
```

Pada mesin lain dengan Flutter 3.50.0:

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter run
```

Android memerlukan SDK Android dan JDK 17. iOS memerlukan macOS, Xcode,
minimal iOS 15, dan signing untuk perangkat fisik. Package ID: id.runwild.app.
Tidak ada target web/desktop. Tanpa Firebase, shell dan katalog tetap berjalan
lokal. Tekan Buka katalog komponen pada Home versi debug untuk menguji komponen.

## Pemeriksaan

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --debug
```

Golden dibuat pada Windows dengan font Archivo dan Material Icons yang
benar-benar dimuat. Job verifikasi CI menggunakan Windows agar rasterisasi
baseline konsisten; build APK memakai Linux. Jangan memperbarui golden tanpa
memeriksa gambar hasil render.

## Dokumentasi

- [Hasil tes dan batas verifikasi](docs/TESTING.md)
- [Status fase](docs/CHANGELOG.md)
- [Delivery Gate](docs/DELIVERY_GATE.md)
- [Arah desain](DESIGN.md), [keputusan](docs/DECISIONS.md)
- [Arsitektur](docs/ARCHITECTURE.md), [layar](docs/SCREENS.md)
- [Konfigurasi Firebase](config/README.md), [model data](docs/DATA_MODEL.md)

Referensi implementasi: [migrasi Material resmi](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui),
[Riverpod](https://riverpod.dev/docs/introduction/getting_started),
[go_router](https://pub.dev/packages/go_router).

Ikon launcher bawaan scaffold adalah placeholder (PRD 14.3), bukan ikon rilis.
Konfigurasi Firebase, signing, cache SDK, dan build tidak masuk Git.
