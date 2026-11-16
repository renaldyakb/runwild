# Changelog

## 2026-11-14 | Fase 0, belum ditutup

Implementasi lokal:

- Scaffold Flutter 3.50.0/Dart 3.14.0 untuk Android dan iOS, id.runwild.app.
- Riverpod, go_router, Firebase Core opsional, lokalisasi ARB Indonesia.
- Token warna, tipografi Archivo offline, spasi, radius, motion; tema gelap/terang.
- RwButton, RwCard, RwChip, RwStatTile, RwBottomNav, RwStateView, RwPage.
- Motif gunung CustomPainter dan katalog komponen debug.
- Shell Home/Aktivitas/Profil, sheet Lari, navigasi kembali, unknown-route recovery.
- Firebase bootstrap melalui service dengan state eksplisit; rules awal deny-all
  dan indeks sesuai model. Belum ada auth/database/analytics.
- CI format, analyze, widget/golden tests, Android debug APK dan iOS tanpa signing.
- Dokumentasi PRD, desain, keputusan, model data, layar, pengujian, dan gate.
- Verifikasi lokal: analyze bersih, 38 tes lulus, enam golden diperiksa,
  bundle Dart/asset Android ARM64 berhasil dikompilasi (belum APK).

Belum selesai:

- Proyek Firebase dev/prod belum ada (dikonfirmasi pemilik).
- Build APK/run Android: Android SDK dan perangkat belum tersedia.
- Build/run iOS: perlu macOS/Xcode dan iPhone; sesi ini Windows.
- CI belum dijalankan di GitHub; folder belum terhubung remote.
- Gambar referensi dan aset final belum tersedia; launcher memakai placeholder
  bawaan scaffold. Lihat docs/reference/README.md.

Tidak memberi tag v0.1.0: DoD fase belum terpenuhi. Nomor 0.1.0+1 dalam
pubspec adalah versi kerja. Fase 1 sampai 8 belum dimulai, mengikuti PRD 0.2.
PRD v1.0 disalin verbatim dari root ke docs/PRD.md; isi PRD tidak diubah.
