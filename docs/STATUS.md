# Status RUNWILD

- 23 Nov 2026: rilis `0.1.6+7` disiapkan dan didorong ke `main`; catatan pengguna `docs/releases/0.1.6.md`.
  - Isi: perombakan Fase 5 lengkap (T5.1–T5.7): loading selesai lari & HUD aktif baru, auth Google langsung berlogo resmi tanpa tamu, Lottie splash screen, Hero Card & detail cuaca baru + geocoding kota BigDataCloud/Nominatim (Lhokseumawe), poles ringkasan/kartu bagikan + tombol Simpan, hapus double AppBar profil & pembersihan anti-slop, serta sistem motion `rw_motion.dart`.
  - GitHub Actions akan menjalankan verifikasi, membangun APK rilis, dan memublikasikan tag `v0.1.6`.

- 23 Nov 2026: T5.7 selesai — **Seluruh Fase 5 Perombakan UI/UX, Auth, Cuaca & Animasi (T5.1–T5.7) tuntas 100%** (`docs/phases/phase-5-revamp.md`).
  - Sistem motion baru (`lib/design/components/rw_motion.dart`): `RwEntrance` (staggered slide+fade 320 ms), `RwCountUp` (counter angka tabular 420 ms), `RwPressScale` (micro press feedback 0.975 pada kartu interaktif `RwCard`), dan `RwPhaseSwitcher` (skala+fade untuk countdown 3-2-1 dan pergantian fase interval LARI ↔ JALAN). Seluruhnya otomatis nonaktif saat `MediaQuery.disableAnimations` aktif (`DESIGN.md` §9.3).
  - Diterapkan di `RwCard`, `HomeDashboard`, `RunActiveScreen`, `RunSummaryScreen`, dan `ProgressScreen`.
  - Bukti verifikasi akhir Fase 5: `flutter analyze --fatal-infos` proyek penuh bersih (0 issues), `dart format` 137 file 0 perubahan, **103/103 tes lulus** (seluruh 14 berkas tes CI + `rw_motion_test`, `auth_screen_test`, `intro_screen_test`, `profile_setup_test`, `run_hold_to_finish_test`, `live_route_test`).
  - Uji perangkat nyata (GPS 60 menit, picker Google Auth, audio background, lokasi Lhokseumawe nyata, animasi 60fps di perangkat) tetap berada di checklist `docs/TESTING.md`.

- 23 Nov 2026: T5.6 selesai (Poles Aktivitas, Detail Aktivitas, Progress & Profil + Hapus Double AppBar) — antislop mode during.
  - Profil & Shell (`profile_screen.dart`, `foundation_screen.dart`): AppBar ganda di `ProfileScreen` dihapus, cabang mati `FoundationDestination.activities` dibersihkan, glow blur avatar dihapus (`DESIGN.md` §9.3), state error dibungkus `RwPage`/`RwCard` bebas overflow, 2 baris statis diringkas, dan seluruh string hardcode dipindah ke ARB.
  - Aktivitas (`activities_screen.dart`): filter `RwChip` diganti `RwSegmentedControl`, header bulan kini menampilkan ringkasan jumlah sesi & total km (`_MonthGroupHeader`), teks `'Statistik'` & warna hex pindah ke ARB/`RwColors`.
  - Detail Aktivitas & Progress (`activity_detail_screen.dart`, `progress_screen.dart`): emoji `🟢/🟡/🔴` dan warna Tailwind (`#15803D`, `#B45309`, `#DC2626`) di `_FeelingBadge` diganti ikon Material + `RwColors`; toggle `'Map: ON/OFF'` pindah ke ARB Indonesia (`Peta`/`Jejak rute`); tombol edit ganda dihapus (kartu catatan dapat diketuk); tambah tombol `?` penjelas istilah *Pace & Split*; error mentah di Progress diganti `RwCard` error + *Coba lagi*.
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format` 0 perubahan, 25/25 tes (`activity_detail_test`, `profile_settings_test`, `home_progress_test`, `weekly_goal_celebration_test`) lulus.

- 23 Nov 2026: T5.5 selesai (Poles Ringkasan Sesi & Kartu Bagikan + Simpan Gambar) — antislop mode during.
  - Ringkasan Sesi (`run_summary_screen.dart`): 2 banner piala bertumpuk (PB + Selebrasi) digabung menjadi 1 header selebrasi terpadu + perbaikan format tanggal/jam (`DateFormat`), label slop `'HISTORI RUTE PRESISI'` dihapus, emoji `🟢/🟡/🔴` diganti ikon Material pada pemilih rasa sesi, tombol *Bagikan* & *Simpan Sesi* dipindah ke sticky footer, `catch (_)` kosong diganti `debugPrint`, semua hex/string liar pindah ke `RwColors` & ARB.
  - Kartu Bagikan (`share_card_screen.dart`, `share_card_service.dart`): tambah aksi **Simpan** langsung ke penyimpanan gambar perangkat (via `path_provider` tanpa dependensi native baru) berdampingan rapi dengan **Bagikan gambar** di sticky footer (`RwButton` padding horizontal diset `RwSpace.md` agar tombol sejajar 1 baris).
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format` 0 perubahan, 8/8 tes (`share_card_test`, `personal_best_alert_test`) & 16/16 (`weather_reminder_test`, `release_ui_test`) lulus; golden `share_editor.png` diperbarui & diperiksa visual.

- 23 Nov 2026: T5.4 selesai (Rombak Hero Card Home, Fix Geocoding Kota Terpencil & Detail Cuaca) — antislop mode during + ADR-032.
  - Hero Card Home (`home_dashboard.dart`): dirombak dengan motif outdoor non-interaktif (`_HeroOutdoorBackdrop`: busur lintasan + slash lime samar + siluet bukit), judul tegas 36sp, satu CTA utama, panel cuaca interaktif ber-chevron, dan penghapusan duplikasi `_HeroWeekMetrics`.
  - Geocoding kota (`weather_service.dart`): memakai BigDataCloud Free Client Reverse Geocode API (`localityLanguage=id`, tanpa API key) sebagai sumber utama + fallback Nominatim diperluas (`regency`, `district`, `hamlet`, `state`). Koordinat Lhokseumawe (`5.1801, 97.1507`) terverifikasi live mengembalikan `"Lhokseumawe"`.
  - Detail Cuaca (`weather_detail_screen.dart`): dirombak dengan kartu hero arang `ink950` untuk kondisi saat ini + `RwCard` terstruktur untuk prakiraan 12 jam dan highlight jam basah `lime700`.
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format` 0 perubahan, 25/25 tes (`weather_reminder_test`, `release_ui_test`, `home_progress_test`) lulus termasuk tes parser BigDataCloud Lhokseumawe & skala 200%; 3 golden (`hero_weather_current`, `weather_detail`, `home_next_session`) diperbarui dan diperiksa visual.

- 23 Nov 2026: T5.3 selesai (Animasi Lottie Splash Screen & Poles Onboarding/Setup Profil).
  - Splash Screen (`startup_screen.dart`): latar arang `ink950` dengan animasi Lottie kinetik buatan proyek (`assets/lottie/splash_runner.json`), wordmark `RUNWILD`, tagline lime, durasi minimum 1,4 dtk (`splashMinimumDurationProvider`), dan fallback statis untuk reduced-motion/gagal muat.
  - Onboarding & Setup Profil: bingkai kotak kaku di sekitar `MountainSilhouette` dilepas (Tier-A); `ProfileSetupScreen` dirombak ke `RwCard`, `RwSegmentedControl`, stepper target mingguan atletis, dan `RwFullPageLoading`; token `RwColors.borderCard`/`surfaceMuted` diterapkan di `rw_chip.dart` & `intro_screen.dart`; overflow 200% di divider `GetStartedScreen` diperbaiki.
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format` 0 perubahan, 11/11 tes (`intro_screen_test`, `profile_setup_test`, `auth_screen_test`) lulus termasuk validasi `LottieComposition` aset splash dan skala teks 200%.

- 23 Nov 2026: T5.2 selesai (Auth Google Langsung, Logo Google 4 Warna & Hapus Mode Tamu) — ADR-031 di `docs/DECISIONS.md`.
  - Logo Google resmi 4 warna dibuat via `CustomPainter` (`lib/design/components/google_logo_icon.dart`) dan didukung melalui `RwButton.leading`.
  - Login Google (Android) & Apple (iOS) dipicu langsung dari `GetStartedScreen` dengan loading di tombol dan banner error `RwColors` (halaman konfirmasi perantara `/auth/google` & `/auth/apple` dihapus).
  - Mode tamu (`/auth/guest`, tombol *Lanjut sebagai tamu*, opsi tautan tamu di `AccountActions`) dihapus dari UI & router; warna alert Tailwind di `AuthScreen` & `AccountActions` diganti token `RwColors`.
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format` 0 perubahan, `test/auth_screen_test.dart` 5/5 lulus (termasuk verifikasi langsung Google/Apple & nol tombol tamu). Uji login Google nyata di perangkat/emulator tetap perlu diperiksa pengguna.

- 23 Nov 2026: T5.1 selesai (Lari Aktif, Loading Selesai & Pra-Sesi) — lihat `docs/phases/phase-5-revamp.md`.
  - Bug loading selesai lari diperbaiki (`setState(() => _ending = true)` + `PopScope(canPop: false)` + `RwFullPageLoading` berlabel *"Menyimpan sesi lari…"*).
  - HUD Live diperbarui: label satuan `km`, baris 3 kolom (Durasi · Pace · Kalori perkiraan), banner fase Interval ber-progress bar dengan kontras tinggi (LARI arang+lime, JALAN lime100+ink), dan sticky footer control ber-border rapi.
  - Pra-sesi: 4 quick preset interval tampil langsung di sheet pertama, string hardcode pindah ke ARB (`runSetupSubtitle`, `runFinishing`, `runFinishingHint`, `intervalQuickPresets`), warna hex liar diganti token `RwColors`.
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format` 0 perubahan, 15/15 tes (`run_hold_to_finish`, `run_permissions`, `live_route`) lulus termasuk tes baru loading konfirmasi selesai. Uji lapangan GPS/perangkat nyata tetap di `docs/TESTING.md`.

- 20 Nov 2026: rilis 0.1.5+6 disiapkan untuk push ke main; catatan pengguna docs/releases/0.1.5.md.
  - Isi: cuaca/kota dan detail 12 jam, pengingat bersuara serta jadwal terdekat, badge lime, hero terbaru tanpa rute terakhir.
  - Verifikasi: 82 tes daftar CI lulus; analyze proyek fatal-infos bersih; helper tes terisolasi, sapaan/cuaca golden deterministik; format 134 file sesuai.
  - GitHub Actions akan membuat APK dan release v0.1.5 setelah verify. Run baru tidak dimonitor sesuai preferensi pengguna. Uji perangkat tetap di docs/TESTING.md.

- 20 Nov 2026: panel rute terakhir beserta toggle dihapus dari hero sesuai permintaan. Hero tidak lagi memuat titik rute. Analyze bersih, 11 tes lulus, golden hero diperbarui dan diperiksa.

- 20 Nov 2026: fallback nama kota diperluas untuk state_district/city_district/borough/suburb; reverse geocoding memakai zoom 12. Respons layanan dengan koordinat contoh Jakarta terverifikasi mengembalikan Jakarta Barat.
  - Seluruh kartu rute hero berasio 3:4, termasuk header/toggle. Peta historis mengikuti batas tinggi viewport; mode peta dan jejak tidak mengubah ukuran kartu.
  - Hero menampilkan jadwal mendatang terdekat, terurut waktu, tertaut ke /reminders. Kosong/loading/error tidak menambah panel jadwal.
  - Bukti: analyze bersih, 12 tes weather_reminder/activity_map lulus; rasio dan ukuran sebelum/sesudah toggle teruji; golden hero diperiksa dengan peta pengganti lokal. GPS kota dan tile di HP belum diverifikasi.

- 20 Nov 2026: tautan teks cuaca di hero dihapus; ikon Meteocons membuka detail lewat tombol ber-tooltip. Reduced motion memakai bingkai statis Meteocons, bukan ikon buatan sendiri.
  - Rute terakhir dipindah di bawah homeSessionHint; toggle peta historis ON / jejak rute OFF memakai MapService yang sama dengan detail aktivitas. Tanpa rute valid panel tidak ditampilkan.
  - Bukti: 11 tes weather_reminder lulus (toggle, navigasi ikon, teks 200%); analisis UI bersih, lint import tes diperbaiki. Golden hero diperiksa dengan pengganti peta lokal; tile nyata perlu uji HP.

- 20 Nov 2026: hero hitam menampilkan jarak, menit bergerak, sesi/target minggu ini dan cuaca saat ini. Prakiraan dipindah ke WeatherDetailScreen melalui ketukan area cuaca/link.
  - Kota GPS memakai Nominatim dengan koordinat dibulatkan dan cache memori; pengguna menyetujui egress pada sesi ini. Gagal geocoding tetap menampilkan cuaca dengan nama kota belum tersedia.
  - Detail: suhu, kondisi, 12 jam kondisi/peluang hujan, atribusi dan pesan prakiraan. Ikon beralas arang menjaga keterbacaan lime.
  - Bukti: analyze fitur dan tes bersih; 11 tes weather_reminder lulus (navigasi pergi/kembali, parser kota, teks 200%); golden hero/detail diperiksa. Uji kota live dan perangkat tetap diperlukan.

- 20 Nov 2026 (lanjutan): beranda dirombak, cuaca jadi piktogram, dan pengingat menjadi banyak jadwal.
  - Cuaca: `weather_service.dart` mengambil `weather_code` per jam; strip 12 jam memakai piktogram Meteocons (persen dan mm tidak lagi ditampilkan) plus satu kalimat simpulan waktu hujan, dan suhu didampingi nama kondisi berbahasa Indonesia.
  - Pengingat: `run_reminder.dart` menyimpan daftar jadwal (`RunReminderStore`, diuji tanpa plugin) dan menjadwalkan notifikasi bersuara `Sound_effect.mp3` (`android/app/src/main/res/raw/sound_effect.mp3`, kanal `run_reminders_v2`, tetap terjadwal walau aplikasi tertutup). Halaman baru `/reminders` (`run_reminders_screen.dart`): tambah, ubah lewat ketuk kartu, hapus, kelompok Hari ini/Besok/Berikutnya, plus catatan suara dan keterlambatan jadwal.
  - Beranda: hero dirombak (sapaan per jam + nama depan, satu CTA, kondisi cuaca, rute terakhir), kartu "Minggu ini" digabung (jarak, durasi, sesi, grafik + jawaban satu kalimat, progres target, rentetan minggu), kartu saran memakai tautan teks, pengingat menjadi baris ringkas. Tiga kegagalan senyap diganti keadaan gagal/kosong yang menjelaskan sebab dan bisa dicoba lagi.
  - Kerapian: token baru (`borderCard`, `borderControl`, `surfaceMuted`, `surfaceDisabled`, `chartBar`, `chartBarToday`, `chartTrack`, `chartTrackSoft`), batang grafik 1,42:1 → 6,61:1, emoji dan lima string hardcode pindah ke ARB, aksen lime dibatasi pada judul hero dan tombol utama.
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format` 0 perubahan, daftar tes CI 81 lulus (termasuk tes baru cuaca, jadwal, dan teks sistem 200%), golden `home_next_session`, `home_light/dark`, `catalog_light/dark` diperbarui lalu diperiksa visual (tanpa strip overflow).
  - Belum: notifikasi bersuara saat aplikasi tertutup, pemulihan jadwal setelah reboot, dan animasi Lottie di perangkat belum diuji (langkah di `docs/TESTING.md`); suara khusus iOS perlu berkas ditambahkan ke bundel Xcode.
  - Di luar daftar CI masih ada 30 kegagalan warisan Fase 0 (`app_test`, `auth_screen_test`, `profile_setup_test`, golden `activity_history`/`interval_*`/`components_*`/`run_live`, dan dua asersi `design_test`). Baseline kode sebelum perubahan ini juga 30 kegagalan di berkas yang sama, jadi bukan regresi dan tidak dikerjakan di sesi ini.


- 20 Nov 2026: cuaca Home, pengingat lari, dan badge rekor lime selesai di kode (belum dirilis/commit).
  - Cuaca (`lib/features/foundation/application/weather_service.dart`): memakai izin lokasi yang sudah ada (tidak meminta izin baru), data Open-Meteo (suhu, kode kondisi, 12 jam peluang hujan + mm), state loading/tanpa izin/error+retry, refresh saat resume lewat `WidgetsBindingObserver`. Animasi Meteocons (`fill`, MIT © Bas Milius) untuk enam jenis cuaca lewat `weather_kind.dart`, disimpan di `assets/lottie/meteocons/`; ikon Material statis saat reduced-motion atau aset gagal dimuat.
  - Pengingat (`lib/features/foundation/application/run_reminder.dart`): sekali jalan, waktu lokal pilihan pengguna disimpan sebagai instant (SharedPreferences), bisa ubah/hapus, notifikasi bersuara, jadwal Android dipulihkan setelah reboot (`RECEIVE_BOOT_COMPLETED` + receiver plugin), mode inexact bisa terlambat. Dependensi baru `timezone: 0.11.2` dipin dan dicatat di `docs/DECISIONS.md`.
  - Badge rekor ringkasan: kartu lime rata, ikon piala, judul/detail lewat ARB (`personalBestTitle`, `personalBestDetails`); ekspektasi teks `test/personal_best_alert_test.dart` ikut disesuaikan ke ARB baru.
  - Bukti: `flutter analyze --fatal-infos` bersih, `dart format lib test` 130 berkas 0 perubahan, `flutter gen-l10n` stabil, 18 tes terarah lulus (5 cuaca/pengingat + 4 badge + 9 Home), dan `test/weather_reminder_test.dart` ditambahkan ke daftar tes CI.
  - Belum/blokir: `test/release_ui_test.dart` (masuk daftar tes CI) GAGAL pada golden `goldens/home_next_session.png` (selisih +34%) karena kartu cuaca/pengingat baru di Home — terbukti regresi: tanpa perubahan `home_dashboard.dart` tes itu 4/4 lulus. Golden `test/screens_test.dart` (home sekitar 60%, catalog) juga masih gagal warisan Fase 0. Pemanggilan scheduler/notifikasi, cuaca nyata, dan tampilan animasi Meteocons di layar (baru diuji sebagai komposisi Lottie) belum diperiksa di perangkat — langkah di `docs/TESTING.md`; state loading cuaca hanya teks sementara tanpa state offline khusus.

- 18 Nov 2026: rilis 0.1.4+5 (izin adaptif, kalibrasi GPS, perbaikan drawer interval, lisensi non-komersial).
  - `pubspec.yaml` 0.1.4+5; catatan rilis `docs/releases/0.1.4.md` (3 bagian, 5 bullet, bahasa pengguna).
  - README ditulis ulang: kegunaan, cara pakai, arsitektur, pengembangan, batasan, dan lisensi non-komersial; badge lisensi diperbarui.
  - `LICENSE` baru: RUNWILD Personal & Community License (source-available, hanya pribadi dan komunitas; dilarang komersial). ADR-030 dicatat.
  - Isi kode rilis: kalibrasi GPS + Lottie, sheet izin adaptif (mulai diblokir sampai lokasi & notifikasi aktif), layanan lokasi diperiksa, angka mentah di drawer interval di-clip.
  - Verifikasi sebelum push: 86 tes daftar CI + tes kalibrasi/izin lulus, `flutter analyze --fatal-infos` bersih, format 0 perubahan.
  - Menunggu: GitHub Actions membuat tag v0.1.4 dan APK; uji perangkat fisik (GPS/kalibrasi/notifikasi) masih tertunda.

- 18 Nov 2026: perbaikan kebocoran angka di drawer Atur interval.
  - Field validasi tersembunyi pada durasi dan putaran tingginya hanya 1 px dan dibungkus `ClipRect` + `ExcludeSemantics`, sehingga label/nilai internal (60, 300, 8, 10) tidak lagi bocor sebagai angka mengambang di atas judul kartu.
  - Validasi Form dan input tes tetap bekerja; ditambah tes regresi yang memastikan kelima field tetap 1×1 dan berada di dalam `ClipRect`.
  - Bukti: analyze bersih, format 0 perubahan, `run_permissions_test` (mengetik nilai lewat label) lulus, tes regresi baru lulus.
  - Catatan: golden `interval_*`, `home_*`, `catalog_*`, `run_live` masih usang (latar Fase 0 dan font tes Ahem), bukan akibat perubahan ini; tidak diubah.

- 18 Nov 2026: persiapan lari adaptif dan kalibrasi GPS.
  - Sheet persiapan hanya menampilkan izin yang belum aktif. Peringatan muncul bila lokasi atau notifikasi mati, dengan tombol izin/pengaturan; tombol mulai nonaktif sampai keduanya aktif. Status layanan lokasi perangkat juga diperiksa dan bisa dibuka dari sheet.
  - Kalibrasi GPS: minimal 8 sampel/12 detik, berhenti pada 13 sampel atau 20 detik. Grade baik bila median akurasi ≤8 m dan drift ≤12 m; cukup ≤15 m/≤20 m; selain itu lemah.
  - Kalibrasi diminta hanya bila belum pernah, hasil lemah >1 hari, atau >30 hari. Hasil disimpan lokal (SharedPreferences) dan kartu kalibrasi hanya tampil saat jatuh tempo; sesi tetap bisa dimulai tanpa kalibrasi.
  - Animasi Lottie `assets/lottie/gps_calibration.json` dibuat sendiri (lisensi aman), dengan fallback ikon satelit saat reduced-motion atau aset gagal dimuat. Dependensi `lottie: 3.8.2` dipin.
  - Bukti: `flutter analyze --fatal-infos` bersih, 86 tes (daftar CI + tes kalibrasi baru) lulus, tes memastikan berkas Lottie valid, `run_permissions_test` diperbarui untuk perilaku baru.
  - Belum: uji perangkat fisik (izin notifikasi Android 13+, GPS luar ruang, lokasi perangkat dimatikan) — langkahnya di `docs/TESTING.md`. Golden `screens_test` (home/catalog) ternyata juga usang sejak Fase 0; jangan diperbarui tanpa inspeksi visual.

- 18 Nov 2026: rilis 0.1.3+4 disiapkan dan dipush ke `main`.
  - `pubspec.yaml` 0.1.3+4; catatan rilis `docs/releases/0.1.3.md` (Diperbaiki/Diperbarui, 6 bullet, bahasa pengguna).
  - Isi: badge rekor pribadi, data interval aktual (Drift v6 + sinkron cloud), label pace rata-rata, catatan kalori, format durasi lebih dari satu jam.
  - Verifikasi sebelum push: 74 tes daftar CI + tes baru lulus, `flutter analyze --fatal-infos` bersih, format 0 perubahan.
  - Menunggu: workflow GitHub Actions membangun APK dan membuat tag v0.1.3; belum ada uji perangkat fisik untuk perubahan ini.

- 18 Nov 2026: perbaikan akurasi data tampilan (PB, interval aktual, label pace/kalori, format durasi).
  - Rekor pribadi: perbandingan waktu memakai milidetik (`millisecondsSinceEpoch`), sehingga badge "Rekor Pribadi" muncul untuk sesi normal.
  - Interval: Drift v6 menambah `interval_rounds`, `interval_run_us`, `interval_walk_us` (nullable, hanya `ADD COLUMN`). Nilai aktual ditulis saat checkpoint/finish, disinkronkan sebagai `actualRounds/actualRunSec/actualWalkSec`, dan dipulihkan saat tarik cloud. Sesi lama tanpa angka aktual menampilkan kartu "Rencana Interval" + catatan; tidak ada putaran/waktu karangan.
  - Label: rekor pace kini "Pace Rata-rata Terbaik (≥1 km/≥5 km)"; Progress menambah catatan "Kalori adalah perkiraan..."; label interval detail lewat ARB.
  - Durasi ≥1 jam tampil `1:30:00` di HUD, daftar, detail, ringkasan, dan kartu bagikan (`core/utils/duration_format.dart`).
  - Bukti: `flutter analyze --fatal-infos` bersih, format 0 perubahan, 74 tes daftar CI lulus, `activity_detail_test` 9/9 (termasuk sesi lama → kartu rencana), `duration_format_test` 3/3.
  - Belum: golden `run_live.png` usang (gagal juga pada HEAD, bukan regresi), `app_test`/`auth_screen_test`/`profile_setup_test` masih memakai teks lama, 20 `catch (_)` lain belum diaudit.

- 18 Nov 2026: audit akurasi data yang tampil (temuan; perbaikannya ada di entri di atas).
  - Rekor pribadi praktis tidak terdeteksi pada sesi normal: `summary.startedAt` membawa mikrodetik, SQLite menyimpan milidetik, sehingga `isAtSameMomentAs` gagal. Bukti uji: `...980119` vs `...980000`, `detectPersonalBestsForSession` mengembalikan `[]`. Badge "Rekor Pribadi" hanya bisa muncul pada sesi hasil pemulihan atau bila µs kebetulan 0.
  - Detail riwayat interval menampilkan putaran/waktu yang tidak terjadi: `parseIntervalSummary` membagi `elapsed` dengan siklus lari+jalan tanpa memperhitungkan warmup, cooldown, dan jeda. Bukti uji: 5 menit warmup saja menghasilkan "1 putaran, lari 1 menit, jalan 2 menit".
  - "Pace 1 KM/5 KM Terbaik" adalah pace rata-rata sesi (bukan split tercepat), dan Progress menulis "TOTAL KALORI" tanpa label perkiraan (rumus tetap 65 kg; sesi jalan dihitung seperti lari).
  - Minor: durasi >1 jam tampil "90:00" di daftar/detail, grafik bulanan M4 mencakup 10 hari, dan label interval di detail belum lewat ARB.
  - Uji pembuktian memakai berkas sementara yang sudah dihapus; tidak ada perubahan perilaku.

- 18 Nov 2026: audit gap pasca-Fase 4, tanpa fitur baru.
  - `weekSummaryProvider` dan `FirestoreProfileRepository` tidak lagi menelan error diam-diam; jenis error dicatat via `debugPrint` (tanpa data pribadi) dan target mingguan tetap memakai nilai bawaan saat profil gagal dibaca.
  - `docs/SCREENS.md` disegarkan sesuai rute nyata di `lib/app/router.dart` (S-01–S-92); klaim "shell Fase 0" dan "Fase 4 belum dimulai" dihapus.
  - Bukti: 68 tes daftar CI lulus (termasuk tes fallback baru), `flutter analyze --fatal-infos` bersih, `dart format` tanpa perubahan.
  - Belum: 20 `catch (_)` lain (notifikasi, audio, sync, share) belum diaudit; tercatat di DECISIONS "Ide Nanti".
  - Temuan baru (belum diperbaiki): `test/app_test.dart` masih menguji shell Fase 0 ("Kejar jarakmu.", Profil "belum tersedia", tombol katalog di Profil, tema gelap) sehingga 13 tesnya gagal di lokal; file ini tidak ada dalam daftar tes CI. Perlu sesi terpisah untuk memperbarui atau menghapusnya.

- 18 Nov 2026: perbaikan CI setelah run 44325489061 gagal pada golden kartu bagikan. Lima baseline diselaraskan dengan UI terkini setelah inspeksi; catch yang mengabaikan golden dihapus. Verifikasi lokal sesuai workflow: 67 tes lulus, analyze fatal-infos bersih, format 118 file tanpa perubahan. Run baru tidak dimonitor sesuai permintaan pengguna.

- 18 Nov 2026: patch versi/pembaruan dan UI sesi disiapkan sebagai 0.1.2+3 (belum dipublikasikan).
  - Versi tampilan, pembanding update, dan metadata sync membaca paket terpasang; pubspec sumber versi build/tag.
  - Catatan rilis dirender sebagai heading/bullet; CI memakai docs/releases/<versi>.md dan menunggu verify. Format di AGENTS.md bagian 9.
  - Edit sesi memakai bottom drawer yang mengikuti keyboard. Home fokus pada aksi mulai, tanpa statistik duplikat/rute rekaan.
  - Bukti: 35 tes terarah lulus, analisis bersih setelah perbaikan lint, YAML valid; golden Home/update/drawer diperiksa.
  - Belum diuji: GitHub Actions, build/install APK release 0.1.2 dan unduhan pembaruan di HP.

- 18 Nov 2026 � Pembaruan visual detail aktivitas & kartu bagikan selesai di kode.
  - Detail: peta OSM membingkai seluruh koordinat tersimpan di atas jejak rute; segmen GPS tetap terpisah, tanpa status GPS live pada riwayat.
  - Bagikan: pratinjau di atas, kontrol format/warna/foto, aksi tetap di bawah; ekspor tipografi minimal dengan tiga warna dan dua rasio.
  - Privat: tanpa ikon perisai maupun path GPS; foto tetap terlihat dan dijelaskan pada kontrol privasi. Rute kosong tidak diganti data rekaan.
  - PNG: lebar 1080 px; tes ekspor persegi membuktikan 1080 � 1080. Foto, rekor pribadi, dan pilihan format tetap tersedia.
  - Bukti: 12 tes share_card/activity_detail/activity_map lulus; analisis 6 file bersih; 5 golden diperiksa secara visual (editor serta Story/persegi privat/rute).
  - Uji HP tersisa: tile internet/cache, foto kamera/galeri dan sheet berbagi Android; lihat tambahan docs/TESTING.md.

- Fase 4 selesai 100% (T4.1–T4.7):
  1. T4.6 (Profil & Pengaturan): Model `UserProfile`, layar pengaturan atletis V3 di tab profil (ubah nama, level, target lari, target sesi mingguan, satuan km, auto-pause, panduan suara, getaran haptik, countdown cue, round cue, privasi sembunyikan titik 200m).
  2. T4.7 (Hapus Akun): Dialog konfirmasi ganda (peringatan keras + input verifikasi teks 'HAPUS'), penghapusan tuntas subkoleksi activities dan dokumen user Firestore, pembersihan total data lokal via `RunJournal.purgeUserData`, dan penghapusan akun Firebase Auth.
  3. Rules Firestore diperbarui mendukung update dan delete untuk pemilik akun.
- Bukti T4.6 & T4.7: Analisis bersih (0 issues), 27 tes Fase 4 lulus 100% (5 tes profile_settings, 8 tes home_progress, 7 tes detail, 7 tes sync).
- Font & Tagline Refresh: Font global beralih ke `Google Sans Flex` (weight 100–900 lengkap di assets) dan tagline Hero Card diperbarui menjadi "Run Free, Go Wild.".
- 7 Perbaikan UX & Visual (Polishing Tuntas):
  1. Sinkronisasi Target Mingguan: `FirestoreProfileRepository` dilengkapi in-memory cache dan `weekSummaryProvider` meng-await `userProfileProvider.future` saat update, target di home terupdate instan saat diubah di profil.
  2. Riwayat Aktivitas: Mengganti tombol refresh bawah yang mepet dengan gestur `RefreshIndicator` (pull to refresh) dan menambahkan icon button refresh di pojok kanan atas samping Statistik.
  3. Modal Form Ubah Nama: Rombak dari dialog kecil sempit menjadi bottom sheet atletis modern yang lebar, lega, dan minimalist.
  4. Profil: Tombol katalog komponen dihapus dari tampilan profil pengguna.
  5. Persiapan Lari: Membuang dinding teks penjelasan sensor yang bertumpuk; diganti dengan status sensor chips kompak atletis dan info tip yang rapi.
  6. Profil Rapih: Header avatar atletis berlingkar Prime Lime glow, inisial tebal, pill badge ganda level & target, layout rapi proporsional.
  7. Icon Aplikasi RUNWILD: Mengganti icon default Flutter di seluruh folder mipmap Android (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) dan `assets/icons/` dengan logo siluet pelari atletis Prime Lime & ink950.
- Redesign Kartu Bagikan (S-27) & ShareCardWidget:
  1. Kartu Visual (ShareCardWidget): Mengikuti standar kompetitor lari modern (Strava & Nike Run Club), hero metric jarak masif tebal Google Sans Flex w900, visual rute lari presisi di kanvas tengah, badge Rekor Pribadi melayang atletis, HUD metrik sekunder 3-kolom melayang bergaris pemisah hairline, serta multi-stop sinematik vignette untuk mode foto latar medsos.
  2. Layar Bagikan (ShareCardScreen): Preview interaktif resolusi tinggi dengan realistic soft drop-shadow, card controls rapi minimalis (rasio Story 9:16 vs Persegi 1:1, tema Prime Lime / Clean Paper / Bold Charcoal, opsi foto kamera/galeri, dan privasi rute), serta tombol aksi masif "Bagikan Gambar".
- Bukti Verifikasi: Analisis bersih (0 issues), 24/24 unit & widget tests lulus (share_card_test, personal_best_alert, run_preferences_integration, profile_settings, run_permissions, weekly_goal_celebration).
- Status Fase: Fase 0–4 selesai tuntas beserta seluruh pemolesan UI/UX. Siap untuk Fase 5 (Peta, Uji Fisik/Lapangan, Polishing Rilis).

- Fase 0: APK debug berhasil dibangun dan pengguna mengonfirmasi terpasang di HP Android.
- Fase 0 tersisa: verifikasi iOS dan Firebase prod. Konfigurasi Android dev sudah tersedia.
- Fase 1, T1.1–T1.2 selesai: splash → intro pada pembukaan pertama → Get Started.
- T1.3: daftar/masuk email, tamu, reset, penautan email dan keluar. Pemulihan sesi diuji dengan pengganti layanan.
- T1.4 Android: login Google berhasil di HP dan penautan akun tamu diimplementasikan.
- Konfigurasi debug: pilih RUNWILD Android Dev di VS Code.
- T1.4 iOS: masuk dan tautkan Apple diimplementasikan. Entitlement Runner terpasang.
- T1.5 diimplementasikan: nama, tujuan, pengalaman, target sesi mingguan, profil awal Firestore.
- Dokumen profil hanya dapat dibaca dan dibuat oleh pemilik. File rules ada di `firebase/firestore.rules`.
- Bukti T1.5: analisis bersih, 9 tes widget dan 3 tes Firestore Emulator lulus.
- Uji HP tertunda: buat Cloud Firestore dev, pasang rules, F5, simpan profil, lalu buka ulang.
- Uji iPhone tertunda: siapkan signing Apple dan provider Firebase sesuai `config/README.md`.
- T2.1: izin lokasi/notifikasi berhasil di HP Android (dikonfirmasi pengguna). 17 tes widget lulus.
- Android compileSdk 37 untuk permission_handler_android. Pemeriksaan checkDebugAarMetadata lulus.
- File kunci: `lib/features/run/`. Skenario izin ada di `docs/TESTING.md`.
- T2.2: mesin Dart menghitung jarak, durasi, pace dan jeda. 7 tes lulus, cakupan 98,5%.
- T2.3: uji GPS terhubung ke mesin. Android foreground service dan iOS background mode dikonfigurasi.
- T2.3: uji GPS berhasil di HP Android menurut pengguna. Ketahanan 60 menit dan iOS belum diverifikasi.
- T2.4: countdown, jarak/durasi/pace dan kontrol sesi berhasil di Android menurut pengguna.
- T2.5: checkpoint dan titik GPS tersimpan lokal per akun, serta pilihan lanjut, simpan dan buang saat pemulihan.
- Bukti T2.5: analisis bersih dan 23 tes lulus termasuk membuka ulang file SQLite.
- Perbaikan T2.5: Mulai sesi lari membuka countdown jika akun tidak punya sesi tertunda. Analisis bersih dan 10 tes terarah lulus.
- Cek ulang 16 Nov: pengguna masih kembali ke beranda; 8 tes run_permissions lulus. Menunggu hasil Hot Restart di HP, penyebab perangkat belum terkonfirmasi.
- Fase 2: uji paksa tutup/pulihkan dan uji lapangan masih tertunda. Peta dan estimasi kalori belum tersedia.
- UI Refresh V2 (Prime Lime & Fast Sport): form interval dilengkapi steppers +/- dan chip waktu cepat (tanpa perlu ketik keyboard), layar lari aktif anti-slop HUD atletis dengan angka tabular dan countdown tajam tanpa glow murahan.
- Bukti: analisis bersih (0 issues), 84/84 tes lulus (golden tests diperbarui, skala teks 100–200% bebas overflow).
- T3.3 selesai: audio ducking cues, getar haptik multi-pola (lari 2x, jalan 1x, selesai 3x, jeda 1x) independen dari audio, dan pembaruan notifikasi persisten saat layar mati (flutter_local_notifications 23.0.2). Analisis bersih, 87/87 tes lulus.
- Mode Putaran Bebas (Free Rounds) & Redesign Form Interval: `IntervalConfig.rounds` nullable (`null` = bebas tanpa batas putaran), `IntervalEngine` looping tak terhingga hingga dihentikan manual, form interval rapi atletis dengan toggle pill BEBAS ↔ TERBATAS, stepper +/- dan quick chips. Analisis bersih (0 issues), 88/88 tes lulus (skala teks 100–200% bebas overflow).
- T3.4 selesai: Layar Ringkasan Sesi (S-26) atletis Prime Lime & Sport Minimalist, split per km live di `TrackingEngine`, kartu metrik masif, rincian interval lari vs jalan, rating rasa sesi, catatan sesi, dan opsi Simpan/Buang.
- T3.5 selesai: Kartu Bagikan (S-27) atletis dengan 3 tema visual (Prime Lime, Kertas Bersih, Bold Charcoal) × 2 format rasio (Story 9:16 dan Persegi 1:1), metrik masif, toggle privasi rute, integrasi `share_plus` 13.3.1.
- T3.6 selesai: Sinkronisasi Cloud & Antrean Offline ke Firestore `users/{uid}/activities/{activityId}` secara idempoten tanpa duplikasi (ID doc deterministik klien). SQLite Drift dinaikkan ke v4 dengan tracking `synced` dan query `unsyncedSessions`, polyline encoder standar, dan penanganan fallback saat offline. Rules Firestore diperbarui mengizinkan koleksi `activities`. Analisis bersih (0 issues), 6 tes sinkron lulus.
- UI/UX Rombak Total V3 (Fresh, Minimalist & Speed):
  1. Hapus mode gelap, 100% mode terang atletis segar (`paper50`, `#FFFFFF`, border halus `0xFFE2E6DC`).
  2. Tipografi 1 font murni Archivo dengan angka tabular figures, bebas tracking lebar.
  3. Tombol outline diperhalus (tanpa kontras kaku) dan tombol aksi selalu lebar proporsional (tidak menggantung).
  4. Komponen `RwSegmentedControl` menggantikan chips berserakan pada preset, tema kartu, dan rating RPE.
  5. Form custom interval dirampingkan dan ringan dibuka seketika.
  6. Fitur `RunRouteView` (gambar alur rute presisi start ke finish dengan canvas CustomPainter) diterapkan di Ringkasan Sesi dan Kartu Bagikan.
  7. Kartu bagikan dilengkapi opsi latar foto medsos via kamera/galeri (`image_picker: 1.1.2`) dan alur rute presisi.
  8. Komponen `RwFullPageLoading` (1 layar penuh tanpa teks) diterapkan pada pembukaan awal app (menggantikan teks splash "Menyiapkan RUNWILD") dan transisi penyelesaian sesi lari ke Ringkasan.
  9. Kartu Hero di halaman HOME diubah menjadi Hitam Arang Atletis (`ink950`) dengan preview rute Prime Lime dan tombol aksi menyala, menciptakan kontras dinamis dengan kartu target mingguan putih.
- UI/UX Rombak Onboarding & Auth (Fresh, Minimalist & Speed):
  1. `inputDecorationTheme` terpusat di `RwTheme.light` (border halus, radius konsisten, label Archivo, prefix/suffix icons).
  2. `IntroScreen`: Segmented progress bar atletis, typography display Archivo, layout seimbang bebas overflow teks 200%.
  3. `GetStartedScreen`: Brand hero badge, visual siluet gunung dalam container berbingkai tipis, pemisah opsi bersih, tombol full-width rapi.
  4. `AuthScreen`: Input fields ber-prefix icon modern, toggle visibility kata sandi, banner alert error/sukses elegan, tombol aksi fullWidth.
  5. `AccountActions`: Tombol penautan dan logout profil konsisten dengan icon atletis.
  Bukti: Analisis bersih (0 issues), 100% tes intro (3/3) dan tes auth (5/5) lulus.
- Penyelesaian & Perbaikan Live Map Sesi Lari:
  1. Integrasi `RwSegmentedControl` (Live, Rute, Riwayat) menggantikan chips berserakan di [run_active_screen.dart](file:///d:/RENAL/CODE/runwild-app/lib/features/run/presentation/run_active_screen.dart).
  2. Perbaikan [map_service.dart](file:///d:/RENAL/CODE/runwild-app/lib/core/services/map_service.dart): status strip akurasi/stale GPS atletis, empty state modern, polyline kontras tinggi, tombol recenter fullWidth, dan legal attribution OSM yang rapi.
  3. Pembersihan linter import ordering di `test/support.dart`.
  4. Perbaikan bug `UnsupportedError (Cannot modify unmodifiable map)` pada `tile_layer.dart`: Mengganti headers `const` map menjadi mutable map `<String, String>{'User-Agent': ...}` pada `NetworkTileProvider` di `map_service.dart`.
  5. Perbaikan UI Map: Menghapus teks petunjuk `runMapHint` di atas peta dan memindahkan kredit OpenStreetMap ke pojok kiri bawah peta dengan badge transparan 25% (`opacity: 0.25`).
  6. Penanganan Offline Map & Fix Crash: Menambahkan `silenceExceptions: true` pada `NetworkTileProvider` untuk mencegah unhandled socket error ("aplikasi stop working") saat offline, menghapus baris offline banner yang memicu `OVERFLOWED BY 209 PIXELS`, dan menggantinya dengan floating toast/SnackBar otomatis.
  Bukti: Analisis bersih (0 issues), 6/6 tes map live (`run_live_map_test.dart` & `live_route_test.dart`) lulus 100%.
