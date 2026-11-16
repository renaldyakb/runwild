# Arsitektur Fase 0

`main.dart` → `bootstrap.dart` → `ProviderScope` → `RunwildApp`.
`app/router.dart` memiliki shell go_router, tiga rute tab, sheet Lari, katalog
debug, dan error route. `app/providers.dart` mengelola tema serta bootstrap
Firebase melalui `BackendInitializer`; presentasi tidak memanggil plugin.

`design/` berisi tokens, theme, components, dan decor. Teks UI berasal dari
`l10n/app_id.arb`, dihasilkan Flutter gen-l10n. File generated tidak diedit
manual; null assertion yang dihasilkan generator mengikuti kontrak delegate.
Tipe dynamic dalam daftar delegate adalah keluaran gen-l10n resmi; pengecualian
R-DEV-01 ini hanya berlaku pada kode generated, bukan kode aplikasi tulisan tangan.
Teks brand, warna, ukuran, radius dan durasi dipusatkan.

`features/<fitur>/presentation` untuk widget. Controller/repository/domain
ditambahkan ketika fitur fasenya dikerjakan, bukan class kosong yang tidak
dipakai. Direktori cadangan mengikuti PRD 8.2:

- core/constants, core/error, core/utils: konstanta/format/error Fase 1+.
- data/models, local, remote, repositories: model immutable dan storage Fase 1+.
- domain: logika Dart murni Fase 2+, tanpa impor Flutter atau Firebase.
- features/onboarding, auth: Fase 1; activities, progress, profile, settings:
  Fase 4; plans: Fase 5.

Tidak ada tracking, database, auth, sinkron, analytics, atau data personal
yang diinisialisasi pada Fase 0. Firebase Core saja bersifat opsional.
Konfigurasi lengkap memungkinkan inisialisasi Core, bukan bukti rules,
auth, atau layanan Firebase lain telah berfungsi.
