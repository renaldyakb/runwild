# Status RUNWILD

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
