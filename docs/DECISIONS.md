# Keputusan teknis

## ADR-001 | 2026-11-14 | Mulai Fase 0

Workspace awal hanya berisi PRD.md. Ikuti kickoff PRD 13.2 dan larangan
melompati fase. Fase 1 dan seterusnya belum dimulai. Tidak membangun web app.
Salin PRD ke docs/PRD.md tanpa mengubah sumber asli. Package: id.runwild.app.

## ADR-002 | Toolchain lokal

Flutter/Dart tidak ada di PATH. SDK stable dari repositori resmi dipasang
di .tooling/flutter; cache pub di .tooling/pub-cache. Keduanya diabaikan Git.
Tidak mengubah PATH global. Platform mobile tetap perlu SDK Android dan macOS
dengan Xcode untuk iOS. Ketiadaan perangkat bukan hasil uji lulus.

## ADR-003 | Dependensi Fase 0

Hanya flutter_riverpod (DI/state), go_router (routing), firebase_core
(bootstrap opsional), flutter_lints (analisis), flutter_localizations dan intl
(ARB) yang dipasang. Versi exact di pubspec.yaml dan lockfile.
intl/flutter_localizations diperlukan oleh R-DEV-06; alternatif string manual
ditolak karena tidak siap i18n. Tidak menambah state generator, database, maps,
auth, analytics, atau plugin tracking sebelum fasenya. ThemeMode tidak
dipersistenkan pada fondasi; pengaturan persisten termasuk F-14.

## ADR-004 | Firebase tanpa akun proyek

Tidak ada ID proyek dev/prod atau akun Firebase yang disediakan. Bootstrap
mendukung --dart-define-from-file melalui konfigurasi lokal yang diabaikan Git.
Tanpa konfigurasi, katalog tetap berjalan lokal dengan status yang jujur.
Konfigurasi parsial/gagal tidak menjatuhkan aplikasi; ditampilkan dan dapat
dicoba ulang. Belum membuat resource cloud, login, atau mengirim analytics.
Rules deny-all melindungi konfigurasi awal hingga rules model Fase 1 diuji.

## ADR-005 | Anti-slop dan aset

Core anti-slop disalin dari repo yang disebut PRD (lisensi disertakan).
Mode during dan setup sudah diotorisasi PRD 9.1/13.2; tidak perlu wizard ulang.
Panduan terbaru berisi R-01 sampai R-40 (PRD menyebut 38). Terapkan semua yang
relevan. Aturan HTML/CSS diterjemahkan ke Semantics, fokus, Material controls,
MediaQuery.disableAnimations dan asset bundling Flutter. Web vitals N/A.
PRD asli dipertahankan verbatim termasuk tanda baca milik penulis.
Referensi gambar belum diberikan; tidak mengunduh foto internet.
Gunung buatan sendiri dan wordmark teks telah diarahkan eksplisit oleh PRD.

## ADR-006 | Ruang lingkup UI

Tab Home, Aktivitas, Profil adalah shell dengan label tahap pengembangan,
bukan fitur MVP yang dianggap selesai. Lari membuka sheet informasi Fase 2.
Tidak ada tombol mulai tracking yang pura-pura bekerja. Katalog hanya tersedia
di debug; kontrolnya benar-benar mengganti tema, state, dan pilihan chip.
Nilai metrik katalog menggunakan placeholder, bukan data aktivitas karangan.

## ADR-007 | Flutter 3.50 dan Material

SDK stable terverifikasi: Flutter 3.50.0, Dart 3.14.0, revision ab2912035e.
Scaffold resmi memindahkan Material ke material_ui; flutter/material.dart
deprecated. Tambahkan material_ui 1.1.0 (versi minimum scaffold, exact pin)
agar tidak memakai API deprecated. Alternatif SDK lama bertentangan dengan
stable terbaru pada PRD. Dampak: satu paket UI resmi dan dependensi transitif,
tanpa layanan tambahan. firebase_core mensyaratkan iOS 15 atau lebih baru.

## ADR-008 | Izin platform sesuai fase

Fase 0 hanya meminta INTERNET untuk bootstrap Firebase. Izin lokasi,
notifikasi, foreground service, wake lock, getar, dan background iOS akan
ditambahkan bersama penjelasan pengguna dan implementasi F-03/F-05 pada
Fase 2. Belum ada izin lokasi berlebihan pada shell. Signing release Android
tidak memakai debug key; distribusi ditangani Fase 8.

## ADR-009 | Kontras berbukti

Tes WCAG menunjukkan orange-700 pada paper-100 hanya 4,3273:1 dan pada
orange-100 hanya 4,2440:1. Pertahankan palet PRD; tambahkan token semantik
orangeTextOnLight #B83A0A untuk teks aksen pada permukaan terang. Chip terpilih
memakai teks ink-950. Isian tombol tetap orange-500 sesuai PRD. Tes menguji
semua pasangan teks yang dipakai, bukan mengasumsikan rasio dari dokumen.
ink-500 pada paper-100 juga hanya 4,4189:1; gunakan token mutedTextOnLight
#65656C untuk teks sekunder di tema terang. Token asli tetap tersedia.

## ADR-010 | Font dan lokalisasi

Font Archivo dari google/fonts (OFL di assets/fonts/OFL.txt) dibundel offline.
Tabel GSUB berisi fitur tnum, diverifikasi langsung dari berkas font.
Material 3.50 memakai GlobalMaterialLocalizations.delegates dari material_ui;
delegate ARB tetap dari gen-l10n. Tidak mencampur tipe delegate Material lama.

## ADR-011 | Status Firebase dikonfirmasi

Pemilik menyatakan proyek Firebase dev/prod belum ada pada 2026-11-14.
Setup cloud tetap terbuka. Fase 0 belum ditutup atau ditag sampai proyek cloud
dan verifikasi Android/iOS terpenuhi. Fase 1 tidak dimulai.

## ADR-012: Penanda intro lokal

`shared_preferences` 2.5.5 menyimpan satu penanda intro per instalasi.
Adapter memakai API asinkron dan diuji lewat pengganti penyimpanan.

## ADR-013: Firebase Auth

Firebase Auth 7.0.1 kompatibel dengan Firebase Core 5.1.0.
Tamu memakai akun anonim Firebase. Pendaftaran dari akun tamu menautkan
kredensial agar UID tetap sama. Tes lokal memakai pengganti layanan.

## ADR-014: Google Sign-In Android

Google Sign-In 7.2.0 memakai ID OAuth web dari konfigurasi Firebase lokal
melalui dart-define. Kredensial Google ditautkan jika sesi masih tamu.
Konfigurasi Apple ditangani terpisah.

## ADR-015: Profil awal Firestore

Cloud Firestore 7.1.0 kompatibel dengan Firebase Core 5.1.0.
Profil awal disimpan di users/{uid} dengan timestamp server. Tugas ini
membuka baca dan buat profil untuk pemilik. Edit profil menyusul di Fase 4.

## ADR-016: Permintaan izin aktivitas

Permission Handler 13.0.0 menangani lokasi saat digunakan dan notifikasi.
Notifikasi opsional. Izin latar, foreground service dan perekaman GPS
ditambahkan bersama integrasi tracking.

## ADR-017: Sumber GPS perangkat

Geolocator 14.1.2 mengirim fix ke TrackingEngine dengan waktu capture
yang dipetakan ke Stopwatch sesi. Fix cache lebih tua dari lima detik
dibuang. Akuisisi tanpa filter jarak dibutuhkan untuk mendeteksi diam.
Android memakai foreground service lokasi, iOS memakai background mode.

## ADR-018: Jurnal sesi lokal

Drift 2.35.4 memakai SQLite dalam isolate. Path Provider 2.1.6
menempatkan database di direktori internal aplikasi. Jurnal versi 1
menyimpan satu sesi aktif per akun dan mengarsipkan sesi selesai lokal.
Waktu selama aplikasi tertutup tidak masuk durasi bergerak.

## ADR-019: Refresh UI/UX Prime Lime dan Penataan Komponen

Penyegaran tampilan visual dan interaksi sesuai arahan pengguna:
1. Warna aksen Prime Lime (#C5FF41) dipadukan dengan permukaan arang (#171A14/#20241C)
   dan kertas krem (#F7F9F2). Kontras teks pada lime wajib ink-950 (WCAG AAA).
2. Penataan ulang (declutter): menghilangkan tombol profil ganda di AppBar (cukup
   di bottom nav), memindahkan panel backend fondasi ke modal debug terpisah,
   dan memperkuat empty state aktivitas serta kartu profil.
3. Komponen diperkaya: RwCard mendukung padding/border kustom, RwStatTile
   menggunakan badge ikon dan angka tabular, RwBottomNav mengapung dengan sudut 28dp
   dan FittedBox untuk dukungan teks 200%. Layar lari aktif didesain menjadi HUD
   atletis dengan angka jarak masif dan kontrol thumb-friendly.
4. Form interval dilengkapi komponen khusus stepper +/- dan quick jump chips waktu
   (tanpa perlu mengetik keyboard); countdown lari menggunakan kontur lingkaran tegas
   tanpa glow blur dekoratif (anti-slop).

## ADR-020: Panduan Fase Haptik dan Notifikasi Persisten (T3.3)

1. `flutter_local_notifications` 23.0.2 dipasang (versi exact) untuk memperbarui
   notifikasi persisten di background saat layar mati (fase interval, sisa waktu,
   putaran, jarak dan durasi bergerak) tanpa chime/alert mengganggu.
2. `IntervalHaptics` mengimplementasikan pola getar sesuai PRD §6.2: lari (2x pendek),
   jalan (1x panjang), selesai (3x pendek), jeda/lanjut/umum (1x pendek), menggunakan
   `HapticFeedback` bawaan Flutter. Getar berjalan independen dari toggle suara.
3. AndroidManifest menambahkan izin `android.permission.VIBRATE`.

## ADR-021: Mode Putaran Bebas (Free Rounds) & Redesign Form Interval

1. `IntervalConfig.rounds` diubah menjadi nullable (`int?`). Nilai `null` menandakan
   mode putaran bebas tanpa batas.
2. `IntervalEngine` dalam mode bebas (`rounds == null`) tidak memiliki `trainingDuration`
   tetap (`null`) dan melakukan iterasi putaran (fase lari/jalan berulang) secara tak terhingga
   sampai pengguna menghentikan sesi lari secara manual.
3. Form `IntervalEditor` didesain ulang rapi:
   - Header putaran dilengkapi toggle pill `BEBAS` ↔ `TERBATAS`.
   - Mode Bebas menampilkan simbol atletis `∞ putaran bebas`.
   - Mode Terbatas menyediakan stepper +/- (min 1, max 50), quick chips (`4×`, `6×`, `8×`, `10×`, `12×`, `16×`), dan input langsung.
   - Layar lari aktif dan notifikasi latar menampilkan format `Putaran X` (tanpa batas total).
   - Seluruh kartu form dirancang responsif dan lulus uji text scale 200% tanpa RenderFlex overflow.

## ADR-022: Ringkasan Sesi Lari, Split per Km, dan Penilaian Rasa Sesi (T3.4)

1. `TrackingEngine` menghitung milestone kilometer secara inkremental dan menghasilkan
   `List<KmSplit>` (durasi, jarak, pace) secara akurat tanpa drift atau artifak jeda.
2. Skema SQLite `run_sessions` dinaikkan ke versi 3 dengan penambahan kolom `feeling` dan `note`.
   Metode `updateSummary` dan `discardSession` ditambahkan pada `RunJournal`.
3. Layar S-26 `RunSummaryScreen` dibangun dengan arsitektur sport minimalist:
   - Banner selebrasi atletis Prime Lime.
   - Metrik utama: Jarak (km), Durasi bergerak, Pace rata-rata, dan Estimasi Kalori MET.
   - Kartu statistik interval (bila sesi interval) menampilkan rasio waktu lari vs jalan.
   - Tabel split per km dengan penanda visual (highlight kilat) pada kilometer tercepat.
   - Pemilih rasa sesi RPE (Mudah / Pas / Berat) dan input catatan opsional.
   - Tombol Simpan Sesi (simpan ke database lokal dan kembali ke Home) serta opsi Buang Sesi.

## ADR-023: Kartu Bagikan Sesi Lari (T3.5)

1. `share_plus` versi 13.3.1 (pinned exact) dipasang untuk ekspor file gambar dan pemanggilan share sheet sistem operasi perangkat.
2. `ShareCardService` membungkus `SharePlus.instance.share(ShareParams(...))` dengan fallback aman saat runtime/desktop.
3. Komponen `ShareCardWidget` dan Layar `ShareCardScreen` (S-27):
   - 3 tema visual: `primeLime` (latar hijau limau energik), `cleanPaper` (latar kertas krem bersih), dan `boldCharcoal` (latar arang atletis gelap).
   - 2 format rasio: `story` (9:16 untuk Instagram/WhatsApp Stories) dan `square` (1:1 untuk feed).
   - Tipografi masif jarak (km), durasi bergerak, pace rata-rata, estimasi kalori MET, tanggal sesi, dan branding RUNWILD (`RUN. TRACK. IMPROVE. GO WILD.`).
   - Opsi privasi rute: toggle untuk menyembunyikan rute/lokasi dengan badge privasi.
   - Ekspor PNG menggunakan `RepaintBoundary` rendering raster bytes pada 3.0 pixel ratio untuk ketajaman visual saat dibagikan.

## ADR-024: Sinkronisasi Cloud Idempoten dan Antrean Offline Sesi Lari (T3.6)

1. Skema SQLite `run_sessions` dinaikkan ke versi 4 dengan penambahan kolom `synced` (0/1) dan `activity_id` (string), serta query `unsyncedSessions` dan update `markSynced`. Migrasi defensif memeriksa metadata tabel SQLite (`PRAGMA table_info`).
2. Model domain murni `ActivityRecord` dan implementasi algoritma enkripsi polyline standar (`encodePolyline`, presisi 1e5) dengan fungsi kompresi downsampling `simplifyPoints` agar ukuran dokumen Firestore tetap efisien (<1MB).
3. `FirestoreActivitySyncRepository` mengimplementasikan sinkronisasi idempoten via `users/{uid}/activities/{activityId}.set(..., SetOptions(merge: true))`:
   - ID dokumen klien deterministik berbasis `act_{sessionId}_{startedAtMs}` mencegah duplikasi data jika sinkronisasi dicoba ulang.
   - Penanganan offline: jika koneksi internet terputus atau timeout, loop berhenti dengan aman dan membiarkan status sesi `synced = 0` di lokal untuk disinkronkan kembali pada panggilan berikutnya.
4. `RunSummaryScreen` memicu antrean `syncPending(owner)` di latar belakang secara asinkron saat pengguna menekan tombol "Simpan Sesi", menjaga alur navigasi UI tetap instan tanpa terhambat latensi jaringan.
5. Aturan keamanan `firestore.rules` diperbarui mengizinkan pemilik akun (`isOwner(uid)`) melakukan operasi read/write pada subkoleksi `users/{uid}/activities/{activityId}`.

## ADR-025: Rombak UI/UX V3 (Fresh, Minimalist & Speed) & Penghapusan Tema Gelap

1. **Penghapusan Tema Gelap:** Seluruh aplikasi beralih ke 100% tema terang atletis (`ThemeMode.light`), menggunakan basis warna kertas segar (`paper50`), kontainer kartu putih bersih (`#FFFFFF`), border halus elegan (`0xFFE2E6DC`), serta aksen Prime Lime (`#C5FF41`) dan deep ink (`#171A14`).
2. **Tipografi Bersih & 1 Font Konsisten:** Diterapkan 1 font tunggal `Archivo` secara global via `RwTheme`, membersihkan semua `letterSpacing` lebar buatan (anti-slop), dan mempertahankan angka tabular figures untuk metrik performa.
3. **Penyempurnaan Komponen Tombol & Navigasi:**
   - Tombol outline diperhalus dengan background putih dan border `0xFFE2E6DC` tanpa kontras hitam kaku.
   - Tombol aksi utama selalu lebar penuh (`fullWidth`) dan tidak menggantung nanggung.
   - `RwSegmentedControl` ditambahkan untuk menggantikan chip pilihan yang berserakan/tidak simetris.
4. **Form Custom Interval Ringan & Rapi:** Struktur dioptimalkan, memangkas bobot rendering, menggunakan pemilih preset simetris, stepper bulat modern, dan baris quick values yang teratur.
5. **Visualisasi Alur Rute Presisi (`RunRouteView`):** Proyeksi koordinat GPS lokal via canvas CustomPainter menggambar jalur rute mulus dari titik START (lingkaran hijau) ke FINISH (pin) secara presisi, diterapkan di Ringkasan Sesi dan Kartu Bagikan.
6. **Kartu Bagikan Latar Foto Medsos:** `image_picker: 1.1.2` (pinned exact) dipasang untuk memungkinkan pelari memilih foto dari kamera/galeri sebagai latar belakang kartu dengan overlay kontras gradient gelap (gaya Strava/Nike), dipadukan dengan visual rute lari presisi.
7. **Komponen Loading Full Screen Bersih:** `RwFullPageLoading` diterapkan pada inisialisasi awal aplikasi (menghilangkan teks "Menyiapkan RUNWILD") dan proses transisi penutupan sesi GPS ke Ringkasan Sesi agar pergantian layar instan dan mulus.
8. **Kartu Hero Hitam Atletis di Home:** Mengubah kartu hero di Home Dashboard menjadi hitam arang atletis (`ink950`) dengan preview rute Prime Lime menyala, menciptakan kontras yang kuat dan fungsional terhadap kartu target mingguan.

## ADR-026: Visualisasi Grafik Komunitas fl_chart untuk Home & Progress (T4.4 & T4.5)

Sesuai permintaan pengguna untuk memakai grafik dari komunitas yang tersedia di internet, ditambahkan library grafik Flutter standar `fl_chart: 1.3.1` (pinned exact). Digunakan untuk grafik batang 7 hari ("Minggu Ini") di Home Dashboard dan visualisasi tren mingguan/bulanan serta distribusi performa di tab Progress.

## ADR-027: Penggunaan Font Google Sans Flex dan Tagline Baru (Run Free, Go Wild.)

1. Sesuai permintaan pengguna, font global aplikasi diganti dari `Archivo` ke `Google Sans Flex` dengan varian bobot lengkap (weight 100–900: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold, ExtraBold, Black) yang dibundel di `assets/fonts/` agar rendering offline tetap stabil dan tajam.
2. Tagline pada Hero Card di Home Dashboard diperbarui menjadi: "Run Free, Go Wild.".

## ADR-028: Akurasi angka tampilan (PB, interval aktual, label pace/kalori)

1. Perbandingan rekor memakai `millisecondsSinceEpoch` karena sesi disimpan sebagai `started_ms`; mikrodetik dibuang dan sebelumnya membuat badge Rekor Pribadi tidak pernah cocok.
2. Drift naik ke v6 dengan tiga kolom nullable (`interval_rounds`, `interval_run_us`, `interval_walk_us`). Migrasi hanya `ALTER TABLE ... ADD COLUMN`, jadi data lama utuh. Rincian interval aktual ditulis saat checkpoint/finish dan ikut disinkronkan (`actualRounds`, `actualRunSec`, `actualWalkSec`). Sesi lama tanpa nilai itu menampilkan rencana interval dengan catatan jujur, bukan angka hasil `elapsed ÷ siklus`.
3. Rekor pace diberi label "Pace Rata-rata Terbaik (≥1 km/≥5 km)" karena memang dihitung dari pace rata-rata sesi, bukan split tercepat. Perhitungan berbasis split ditunda sampai split disimpan untuk seluruh sesi.
4. Estimasi kalori tetap memakai 65 kg: ringkasan/detail berlabel "perkiraan", Progress menambah catatan. Berat badan opsional menyusul.

## ADR-029: Izin adaptif dan kalibrasi GPS

1. Sheet persiapan hanya menampilkan izin yang belum aktif. Lokasi dan notifikasi sama-sama wajib sebelum sesi dimulai karena foreground service membutuhkan notifikasi; status layanan lokasi (GPS perangkat) diperiksa terpisah dan bisa dibuka dari sheet.
2. Kalibrasi memakai 8 sampel/12 detik minimum dan berhenti pada 13 sampel atau 20 detik. Grade baik bila median akurasi ≤8 m dan drift ≤12 m, cukup ≤15 m/≤20 m, selain itu lemah. Kalibrasi diminta ulang hanya bila belum pernah, hasil lemah lebih dari 1 hari, atau lebih dari 30 hari, agar tidak menjadi langkah rutin.
3. `lottie: 3.8.2` (MIT) ditambahkan untuk animasi ring sinyal. Aset dibuat sendiri (`assets/lottie/gps_calibration.json`), bukan unduhan pihak ketiga, supaya lisensi jelas dan warna mengikuti Prime Lime. Saat reduced-motion atau aset gagal dimuat, tampil ikon satelit statis.
4. Hasil kalibrasi disimpan lokal (SharedPreferences) dan tidak disinkronkan: menjaga privasi dan menghindari biaya cloud.

## ADR-030: Lisensi non-komersial

1. MIT tidak lagi dipakai sesuai permintaan pemilik proyek: aplikasi hanya untuk pemakaian pribadi dan pengembangan komunitas.
2. `LICENSE` diganti dengan **RUNWILD Personal & Community License** (source-available): boleh dipakai, dipelajari, dimodifikasi, dan di-fork secara non-komersial dengan lisensi yang sama dan atribusi; dilarang dijual, dipasang iklan, dilanggankan, dipakai dalam produk/jasa komersial, atau di-relicense.
3. README memuat ringkasan izin/larangan, batasan merek, serta catatan bahwa lisensi pihak ketiga (Flutter, paket Dart, font, OpenStreetMap) tetap berlaku.
4. Permintaan komersial harus lewat pemilik repositori; tidak ada izin komersial otomatis.

## ADR-031: Sumber cuaca Open-Meteo dan animasi Meteocons

1. Cuaca beranda memakai Open-Meteo (`api.open-meteo.com`) tanpa kunci dan tanpa akun; yang dipakai hanya izin lokasi yang sudah ada dan aplikasi tidak meminta izin lokasi sendiri. Data yang diambil: suhu, kode kondisi WMO, dan 12 jam peluang hujan + jumlah mm. Tidak ada cache maupun antrean offline; bila gagal tampil pesan singkat dan tombol coba lagi.
2. Animasi cuaca memakai Meteocons (MIT, © Bas Milius, https://github.com/basmilius/meteocons). Repositori itu tidak menyimpan berkas Lottie di Git; berkas dihasilkan lalu diterbitkan sebagai paket npm `@meteocons/lottie`. Aset diambil dari paket versi 0.1.0 gaya `fill` dan disimpan di `assets/lottie/meteocons/`; salinan lisensi MIT ikut dibundel di folder yang sama. Aset matahari buatan sendiri sebelumnya dihapus.
3. Enam tampilan cuaca dipetakan dari kode WMO di `weather_kind.dart`: cerah, berawan sebagian, mendung, hujan, salju, badai guntur. Saat reduced-motion aktif atau aset gagal dimuat, tampil ikon Material statis supaya ruang cuaca tidak pernah kosong.


## ADR-032: Cuaca piktogram, jadwal lari bersuara, dan kerapian beranda

1. Prakiraan 12 jam tidak lagi menampilkan peluang hujan dalam persen atau jumlah mm. Pengguna membaca piktogram cuaca per jam (Meteocons, MIT) ditambah satu kalimat simpulan "Hujan diperkirakan pukul HH.mm" atau "Tidak ada hujan diperkirakan dalam 12 jam ini". Ambang jam basah: kode WMO hujan/salju/badai guntur, atau peluang hujan ≥ 50% (`rainLikelyThreshold` di `weather_kind.dart`).
2. Pengingat lari berubah dari satu jadwal menjadi banyak jadwal dengan halaman khusus `/reminders`. Penyimpanan di `SharedPreferences` (JSON, kunci `run_reminders_v1`) dengan ID notifikasi berurutan yang stabil; jadwal yang sudah lewat dipangkas saat dibaca. `RunReminderStore` sengaja tidak menyentuh plugin notifikasi supaya aturan jadwal (urutan, pemangkasan, ID unik) dapat diuji tanpa perangkat.
3. Notifikasi memakai suara khusus `assets/audio/Sound_effect.mp3`, disalin ke `android/app/src/main/res/raw/sound_effect.mp3` karena Android hanya menerima suara notifikasi dari resource mentah. Kanal baru `run_reminders_v2` dipakai karena Android tidak mengubah suara kanal yang sudah pernah dibuat. Penjadwalan tetap `inexactAllowWhileIdle` (tanpa izin alarm tepat waktu), sehingga notifikasi dapat terlambat beberapa menit; jadwal dipulihkan sistem setelah reboot lewat `ScheduledNotificationBootReceiver`. iOS memakai berkas suara dari bundel app; penambahan berkas ke target Xcode belum dikerjakan sehingga iOS masih memakai suara bawaan.
4. Beranda dirapikan: satu aksi utama (tombol di hero), kartu minggu digabung (jarak, durasi, sesi, grafik, target, rentetan minggu), kartu saran memakai tautan teks, pengingat menjadi baris ringkas di bawah informasi minggu, dan tiga kegagalan senyap (`SizedBox.shrink`) diganti keadaan gagal/kosong yang menjelaskan sebab serta menyediakan aksi. Grafik mendapat jawaban satu kalimat dan label semantik karena kanvas tidak terbaca pembaca layar.
5. Warna dan aksen dirapikan: hex liar di widget diganti token (`borderCard`, `borderControl`, `surfaceMuted`, `surfaceDisabled`, `chartBar`, `chartBarToday`, `chartTrack`, `chartTrackSoft`), batang grafik dinaikkan dari 1,42:1 menjadi 6,61:1 di atas putih, dan aksen lime dibatasi pada judul hero dan tombol utama. Emoji dekoratif dan lima string hardcode diganti kunci ARB.


## Ide nanti

Tidak ada penambahan di luar roadmap PRD.

- 2026-11-16: Sesuai permintaan pengguna, peta live memakai flutter_map 8.3.1 + latlong2 0.9.1 + url_launcher 6.3.2 melalui MapService, menggantikan rencana Google Maps untuk layar sesi. OSM Standard tanpa key; User-Agent RUNWILD, atribusi selalu terlihat, cache HTTP bawaan 128 MiB, tanpa bulk download. Tidak ada SLA tile publik; GPS tetap merekam jika tile gagal. Sumber: https://operations.osmfoundation.org/policies/tiles/ dan https://pub.dev/packages/flutter_map .

- 18 Nov 2026: package_info_plus 10.2.2 dipin untuk membaca versi/build APK terpasang; pubspec menjadi sumber versi rilis. Patch perbaikan disiapkan sebagai 0.1.2+3 agar terdeteksi oleh pengguna 0.1.1.

- 18 Nov 2026: audit sisa `catch (_)` di layanan notifikasi, audio, sync, dan share card agar setiap kegagalan tercatat (tanpa koordinat); belum dikerjakan karena butuh verifikasi perangkat.

- 20 Nov 2026: timezone 0.11.2 dipin untuk penjadwalan notifikasi satu kali dalam UTC; waktu lokal dipilih pengguna dan disimpan sebagai instant.
