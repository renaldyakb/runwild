# Inventaris layar

Status 2026-11-14. Shell bukan implementasi fitur MVP.

| Layar | Status | Lokasi/perilaku |
| --- | --- | --- |
| Katalog debug Fase 0 | Implementasi lokal | `/catalog`, hanya kDebugMode |
| S-10 Home | Shell Fase 0 | `/`, penjelasan fondasi dan akses katalog |
| S-20 Pra-sesi | Shell Fase 0 | Sheet dari tab Lari; menjelaskan GPS belum tersedia |
| S-30 Aktivitas | Shell Fase 0 | `/activities`, belum ada daftar/sinkron |
| S-50 Profil | Shell Fase 0 | `/profile`, belum ada akun/pengaturan |
| Rute tak ditemukan | Implementasi lokal | Pesan dan aksi kembali ke Home |
| S-01 sampai S-07 | Belum dimulai | Fase 1 |
| S-23 sampai S-25, S-90 | Belum dimulai | Fase 2 |
| S-21, S-22, S-26, S-27 | Belum dimulai | Fase 3 |
| S-11, S-31, S-32, S-40, S-41, S-51 sampai S-57 | Belum dimulai | Fase 4 |
| S-60 sampai S-64 | Belum dimulai | Fase 5 |
| S-91 | Komponen state saja | RwStateView, belum ada offline repository |
| S-92 | Belum dimulai | Persiapan rilis |

State data loading, empty, error, offline, content dapat dipilih di katalog.
Skeleton tidak beranimasi agar tidak mengganggu dan aman pada reduced motion.
BackendPanel menangani belum dikonfigurasi, konfigurasi parsial, loading,
berhasil, error, dan retry. Halaman shell sendiri statis; tidak berpura-pura
melakukan fetch data aktivitas.

Kontrol katalog: tema Sistem/Terang/Gelap, tombol utama dengan feedback,
dialog, tombol disabled/loading, chip Bebas/Interval, metric placeholder,
semua state, retry simulasi, sheet persiapan lari. Tidak ada data latihan palsu.
