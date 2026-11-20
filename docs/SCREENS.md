# Inventaris layar

Status 20 November 2026, setelah rombak beranda dan halaman jadwal. Rute mengacu
`lib/app/router.dart`, file mengacu `lib/features/`. Dokumen ini menggantikan
status shell Fase 0.

| Layar | Status | Lokasi/perilaku |
| --- | --- | --- |
| Katalog debug | Implementasi lokal | `/catalog`, hanya `kDebugMode` |
| S-01 Splash | Implementasi | `/splash` → `onboarding/presentation/startup_screen.dart` |
| S-02 Intro | Implementasi | `/intro`, tiga slide, bisa Lewati (`intro_preferences.dart`) |
| S-03 Get Started | Implementasi | `/start` |
| S-04/05/06 Auth | Implementasi | `/auth/sign-in`, `/auth/register`, `/auth/reset`; tamu `/auth/guest`; Google `/auth/google` (Android); Apple `/auth/apple` (iOS) |
| S-07 Profil awal | Implementasi | `/profile/setup` |
| S-10 Home | Implementasi | `/` → `foundation/presentation/home_dashboard.dart`: hero (sapaan per jam, cuaca piktogram 12 jam, satu CTA), kartu "Minggu ini" (grafik + target + rentetan), saran sesi, baris jadwal, tautan Progress |
| S-11 Ringkasan minggu | Sebagian | Kartu target mingguan ada di Home; layar detail terpisah belum dibuat |
| S-20 Pra-sesi | Implementasi | Bottom sheet `run/presentation/run_permission_sheet.dart`: hanya izin yang belum aktif, plus kartu kalibrasi GPS saat jatuh tempo |
| S-21/S-22 Preset & kustom interval | Implementasi | `run/presentation/interval_options.dart` + `run_setup_sheet.dart`: Bebas ↔ Interval, preset, form kustom |
| S-23 Penjelasan izin | Implementasi | `run/presentation/run_permission_sheet.dart`, status izin per sensor dan status layanan lokasi |
| Kalibrasi GPS | Implementasi | `run/presentation/gps_calibration_sheet.dart`: 12–20 detik, grade bagus/cukup/lemah, animasi Lottie dengan fallback ikon |
| S-24 Countdown | Implementasi | Bagian awal `run/presentation/run_active_screen.dart` |
| S-25 Lari aktif | Implementasi | `/run/active`: HUD jarak/durasi/pace, panel fase interval, Live/Rute/Riwayat, kunci layar |
| S-26 Ringkasan sesi | Implementasi | `/run/summary` |
| S-27 Kartu bagikan | Implementasi | `/run/share`: tiga tema × dua rasio, foto kamera/galeri, privasi rute |
| S-30 Daftar aktivitas | Implementasi | `/activities`: filter, kelompok bulan, 20 per halaman, pull-to-refresh |
| S-31 Detail aktivitas | Implementasi | `/activities/:id`: peta OSM, split, interval, catatan |
| S-32 Edit aktivitas | Implementasi | Drawer di detail: ubah judul/catatan, hapus dengan konfirmasi |
| S-40 Progress | Implementasi | `/progress`: minggu/bulan/semua + grafik |
| S-41 Rekor pribadi | Implementasi | Bagian dalam `/progress` |
| S-50 Profil | Implementasi | `/profile` → `profile/presentation/profile_screen.dart` |
| S-51–S-56 Pengaturan | Implementasi | Bagian dalam profil: data diri & target, satuan, suara/getar, privasi, target mingguan, akun & hapus akun |
| S-57 Tentang | Sebagian | Versi/build tampil dari `package_info_plus`; lisensi dan kebijakan privasi belum ada |
| S-58 Jadwal lari | Implementasi | `/reminders` → `foundation/presentation/run_reminders_screen.dart`: banyak jadwal bergaya kalender, kelompok Hari ini/Besok/Berikutnya, notifikasi bersuara walau aplikasi tertutup |
| S-60–S-64 Fase 5 | Belum dimulai | Program, detail program, tantangan, badge |
| S-90 Pemulihan sesi | Implementasi | `/run/recover`: lanjut, simpan, atau buang sesi tertunda |
| S-91 Offline/error | Komponen | `RwStateView`; offline ditangani per layar, belum ada halaman khusus |
| S-92 Update wajib | Dialog | `foundation/presentation/app_update_dialog.dart` |
| Rute tak ditemukan | Implementasi | `errorBuilder` di router: pesan + kembali ke Home |

Kelima state (loading, empty, error, offline, content) tersedia di katalog debug
dan dipakai layar data. Skeleton tidak beranimasi agar aman pada reduced motion.
`BackendPanel` menangani Firebase belum dikonfigurasi, parsial, loading, error,
dan retry. Tidak ada data latihan rekaan di layar mana pun.
