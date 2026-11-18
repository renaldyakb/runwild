# RUNWILD

> **RUN. TRACK. IMPROVE. GO WILD.**
> Pelacak jalan dan lari ramah pemula untuk Android dan iOS. Antarmuka Bahasa Indonesia, data jujur, dan bisa dipakai tanpa internet.

[![Build & Checks](https://github.com/renaldyakb/runwild/actions/workflows/ci.yml/badge.svg)](https://github.com/renaldyakb/runwild/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.50.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.14.0-0175C2?logo=dart)](https://dart.dev)
[![License: Non-Commercial](https://img.shields.io/badge/License-Non--Commercial-orange.svg)](LICENSE)

**Lisensi: hanya untuk pemakaian pribadi dan pengembangan komunitas. Dilarang
diperjualbelikan atau dikomersialkan.** Lihat [LICENSE](LICENSE).

---

## 1. Kegunaan aplikasi

RUNWILD membantu orang yang baru mulai berjalan atau berlari untuk mencatat
sesi, memahami ritme latihan, dan melihat kemajuan tanpa merasa dihakimi.

Aplikasi ini dipakai untuk:

- Merekam rute dan metrik sesi jalan/lari: jarak, durasi bergerak, pace,
  split per kilometer, dan estimasi kalori.
- Menjalani latihan interval jalan-lari dengan panduan fase, suara, getar, dan
  notifikasi.
- Menyimpan riwayat sesi secara lokal, lalu menyinkronkannya ke Firestore saat
  akun tersedia dan jaringan kembali.
- Membagikan ringkasan sesi sebagai gambar tanpa membocorkan titik awal/akhir
  rumah.
- Mengatur target mingguan, melihat grafik, streak, dan rekor pribadi.

### Untuk siapa

- Pelari pemula yang butuh panduan interval dan progres sederhana.
- Pejalan cepat yang ingin mencatat jarak dan durasi.
- Pengguna yang peduli privasi: rute tidak wajib dibagikan dan bisa disamarkan.

### Prinsip produk

1. **Data jujur.** Tidak ada angka latihan rekaan atau statistik palsu. Nilai
   estimasi selalu diberi label perkiraan.
2. **Offline dulu.** Sesi disimpan di perangkat sejak awal; sinkron cloud
   bersifat tambahan, bukan syarat.
3. **Privasi default aman.** Titik awal dan akhir rute disamarkan 200 m saat
   dibagikan; visibilitas sesi default privat.
4. **Ramah pemula.** Target mingguan berbasis jumlah sesi, streak mingguan,
   dan panduan suara berbahasa Indonesia.

### Status rilis

- Versi saat ini: **0.1.4+5** (sumber versi: `pubspec.yaml`; APK rilis dibuat
  oleh GitHub Actions).
- Fase 0–4 sudah berjalan di kode: fondasi, onboarding/auth, tracking,
  interval, ringkasan/bagikan, riwayat, home/progress, dan profil.
- Belum termasuk: program 0→5K, badge, pengingat latihan, tantangan, ekspor
  GPX, mode indoor, integrasi kesehatan, dan fitur sosial.
- Uji lapangan GPS 60 menit, force-kill/recover, dan iOS masih perlu
  diverifikasi di perangkat nyata. Lihat `docs/TESTING.md`.

---

## 2. Fitur yang tersedia

### Pelacakan dan sesi

- Filter sampel GPS: akurasi, usia titik, jarak minimum, dan pemisahan segmen
  setelah jeda; jarak memakai formula haversine.
- **Auto-pause** untuk mode bebas (bukan interval) memakai ambang kecepatan dan
  waktu dari `core/constants/tracking_limits.dart`.
- Waktu sesi memakai jam monoton, bukan hitungan timer, agar tetap akurat saat
  layar mati atau aplikasi dipulihkan.
- HUD lari: jarak, durasi bergerak, pace, panel fase interval, kontrol jeda,
  kunci layar, dan peta OSM (flutter_map) dengan atribusi.
- Pemulihan sesi setelah aplikasi ditutup paksa: lanjutkan, simpan, atau buang.
- Split per kilometer (split terakhir boleh kurang dari 1 km; split sebelum
  pemulihan dapat berupa estimasi dan diberi keterangan).

### Interval

- Mode bebas dan interval; preset Pemula Santai, Klasik 1:1, 5:1, Naik Level.
- Form kustom: pemanasan, lari, jalan, jumlah putaran (atau bebas), pendinginan,
  mulai dari jalan.
- Preset bisa disimpan, diganti nama, dan dihapus.
- Panduan suara (audio lokal), getar, hitung mundur 3-2-1, dan tanda pergantian
  putaran; preferensi suara/getar diatur di Profil.
- Statistik interval di ringkasan memakai angka aktual. Sesi lama yang belum
  menyimpan angka aktual menampilkan kartu "Rencana Interval" dengan catatan,
  bukan angka karangan.

### Ringkasan dan kartu bagikan

- Ringkasan sesi: jarak, durasi, pace rata-rata, kalori (perkiraan), split,
  statistik interval, dan deteksi rekor pribadi.
- Kartu bagikan: dua format (Story 9:16 dan Persegi 1:1), tiga tema warna,
  opsi foto dari kamera/galeri, dan tombol menyembunyikan rute.
- Ekspor PNG 1080 px; tanpa data rute, kartu tetap dirender jujur tanpa rute
  rekaan.

### Riwayat, progres, dan profil

- Daftar aktivitas per bulan dengan filter bebas/interval, 20 per halaman,
  pratinjau rute, dan pull-to-refresh.
- Detail aktivitas: peta, split, interval, catatan, perasaan sesi, ubah judul,
  dan hapus.
- Sinkronisasi Firestore idempoten (`users/{uid}/activities/{activityId}`)
  dengan antrean offline; unduhan riwayat dari perangkat lain.
- Home: target mingguan, streak, grafik 7 hari, dan rekomendasi sesi berikutnya.
- Progress: total minggu/bulan/semua, grafik, dan rekor pribadi (jarak terjauh,
  durasi terlama, pace rata-rata terbaik sesi ≥1 km dan ≥5 km).
- Profil: nama, level, target lari, target sesi mingguan, satuan km, auto-pause,
  suara/getar, hitung mundur, tanda putaran, dan privasi rute.
- Hapus akun dengan konfirmasi ganda: menghapus data lokal, subkoleksi
  aktivitas, dokumen pengguna, dan akun Firebase Auth.

### Persiapan lari dan kalibrasi GPS

- Lembar persiapan **hanya menampilkan izin yang belum aktif**. Jika lokasi atau
  notifikasi mati, muncul peringatan berisi tombol izin/pengaturan dan tombol
  mulai nonaktif sampai keduanya aktif.
- Status layanan lokasi perangkat (GPS mati) diperiksa terpisah dan bisa dibuka
  langsung dari lembar persiapan.
- **Kalibrasi GPS** memakai 8 sampel/12 detik minimum, berhenti pada 13 sampel
  atau 20 detik. Hasil dinilai bagus/cukup/lemah dari median akurasi dan drift.
  Kalibrasi hanya diminta bila belum pernah, hasil lemah lebih dari 1 hari, atau
  lebih dari 30 hari; sesi tetap bisa dimulai tanpa kalibrasi.
- Animasi Lottie ring sinyal (aset milik proyek) dengan fallback ikon saat
  reduced-motion aktif atau aset gagal dimuat.

### Pembaruan aplikasi

- Pemeriksa versi membaca GitHub Releases (`AppVersion` dari
  `package_info_plus`, bukan angka hardcode).
- Catatan rilis dirender sebagai heading, paragraf, dan bullet — bukan Markdown
  mentah.
- Tautan unduhan membuka halaman rilis resmi.

### Batasan yang diketahui

- Estimasi kalori memakai asumsi berat 65 kg dan rumus jarak; nilainya
  perkiraan, bukan pengukuran medis.
- Rekor pace adalah **pace rata-rata sesi** (≥1 km / ≥5 km), bukan split
  tercepat di dalam sesi.
- Golden test (`home_*`, `catalog_*`, `interval_*`, `run_live`) dan
  `test/app_test.dart` masih usang; tidak dipakai sebagai gerbang CI.
- Tanpa Firebase, aplikasi tetap berjalan lokal (auth tamu, riwayat lokal,
  tanpa sinkron cloud).

---

## 3. Cara pakai

### Memasang aplikasi

1. Buka [Releases](https://github.com/renaldyakb/runwild/releases) dan unduh APK
   dari rilis terbaru.
2. Pasang APK (izinkan pemasangan dari sumber tidak dikenal bila diminta).
3. Untuk iOS, build sendiri dari Xcode (lihat bagian pengembangan); belum ada
   distribusi App Store.

### Sesi pertama

1. Splash → Intro (3 slide, bisa Lewati) → Get Started.
2. Daftar/masuk dengan email, Google (Android), Apple (iOS), atau lanjut sebagai
   tamu.
3. Isi profil awal: nama, tujuan, level, target sesi mingguan.
4. Beri izin lokasi dan notifikasi. Izin yang sudah aktif tidak ditampilkan
   lagi pada kunjungan berikutnya.

### Menjalankan sesi

1. Tab **Lari** membuka lembar persiapan. Pilih **Bebas** atau **Interval**.
2. Untuk interval, pilih preset atau **Atur interval** (pemanasan, lari, jalan,
   putaran, pendinginan).
3. Jika kartu **Kalibrasi GPS** muncul (belum pernah / hasil lemah / sudah 30
   hari), berdiri di area terbuka lalu mulai kalibrasi. Kartu ini tidak muncul
   setiap sesi.
4. Tekan **Mulai sesi lari** → countdown → HUD. Layar bisa dikunci agar tidak
   tersentuh saat berlari.
5. Jeda/lanjut kapan saja; akhiri dengan tahan tombol selesai.
6. Ringkasan sesi menampilkan metrik, split, interval, dan rekor pribadi bila
   ada. Dari sini sesi bisa dibagikan atau disimpan.

### Melihat dan mengelola data

- **Aktivitas**: daftar per bulan, filter, buka detail, ubah judul/catatan,
  atau hapus.
- **Home**: target mingguan, grafik 7 hari, rekomendasi sesi.
- **Progress**: statistik minggu/bulan/semua dan rekor pribadi.
- **Profil**: pengaturan latihan, suara, privasi, serta hapus akun permanen.

### Offline dan pembaruan

- Sesi tetap terekam tanpa internet; sinkron berjalan otomatis saat jaringan
  kembali.
- Bila ada rilis baru, aplikasi menampilkan dialog pembaruan dengan catatan
  rilis dan tautan unduhan resmi.

---

## 4. Desain dan arsitektur

### Arah desain

- Karakter: energik, atletis, outdoor, tegas; prinsip "maksimal di tepi, minimal
  di inti".
- Palet: latar krem kehijauan, kartu putih, tinta arang, aksen **Prime Lime**
  `#C5FF41`; teks aksen di latar terang memakai hijau gelap `#486600`.
- Tipografi: **Google Sans Flex** (100–900) dengan angka tabular untuk metrik.
- Radius kartu besar, tombol pill, navigasi kapsul; dekorasi hanya di zona
  non-interaktif.
- Motion singkat dan bertujuan (hitung mundur, ganti fase, selesai); menghormati
  "kurangi gerakan" (`MediaQuery.disableAnimations`).
- Copy Bahasa Indonesia, tanpa klaim berlebihan; estimasi diberi label.

Panduan lengkap: `DESIGN.md`.

### Struktur proyek

```
lib/
├── app/                 # bootstrap UI, router go_router, shell navigasi
├── core/
│   ├── constants/       # ambang tracking, interval, kalibrasi, versi, peta
│   ├── services/        # peta, audio interval, notifikasi, wakelock, share card
│   └── utils/           # formatter durasi dan utilitas kecil
├── design/
│   ├── tokens/          # warna, spasi, radius, tipografi, motion
│   ├── components/      # RwButton, RwCard, RwPage, RwBarChart, RwRouteView, dll.
│   ├── theme/           # tema terang
│   └── decor/           # siluet gunung
├── domain/              # Dart murni tanpa Flutter/Firebase
│   ├── interval/        # IntervalEngine, preset, cue
│   ├── stats/           # mingguan, streak, rekor pribadi
│   └── tracking/        # TrackingEngine, split, detail aktivitas, kalibrasi GPS
├── features/<fitur>/{application,presentation}
│   ├── activities/      # riwayat, detail, progress
│   ├── auth/            # sesi, login email/Google/Apple/tamu
│   ├── catalog/         # katalog komponen (debug)
│   ├── foundation/      # Home, dialog update, panel backend
│   ├── onboarding/      # splash, intro, get started
│   ├── profile/         # profil, pengaturan, hapus akun
│   └── run/             # sesi aktif, izin, interval, kalibrasi, ringkasan
├── l10n/                # ARB (id) + hasil generate
├── bootstrap.dart
└── main.dart
```

`lib/data/*` masih berupa placeholder; repository nyata saat ini berada di
`features/*/application` (mis. `run_journal.dart`, `activity_sync.dart`,
`profile_service.dart`). `domain/` tetap bebas dari Flutter dan Firebase.

### Alur data

1. UI hanya membaca/menulis lewat provider Riverpod (`application/`).
2. `application/` memanggil `domain/` untuk perhitungan murni dan repository
   untuk penyimpanan.
3. Penyimpanan lokal memakai **Drift/SQLite** (skema v6: sesi, titik rute,
   preset interval, progress interval aktual, judul/catatan, status sinkron).
4. Sinkron Firestore memakai ID dokumen dari klien sehingga idempoten, dengan
   antrean offline dan penggabungan konflik sederhana.
5. Error dicatat tanpa data pribadi; tidak ada `catch` kosong.

### Teknologi (versi dipin di `pubspec.yaml`)

| Area | Paket |
| --- | --- |
| Framework | Flutter 3.50.0, Dart 3.14.0, material_ui 1.1.0 |
| State & routing | flutter_riverpod 3.5.0, go_router 18.1.4 |
| Lokal | drift 2.35.4, path_provider 2.1.6, shared_preferences 2.5.5 |
| Firebase (opsional) | firebase_core 5.1.0, firebase_auth 7.0.1, cloud_firestore 7.1.0, google_sign_in 7.2.0 |
| Lokasi | geolocator 14.1.2, permission_handler 13.0.0 |
| Peta | flutter_map 8.3.1, latlong2 0.9.1, url_launcher 6.3.2 |
| Audio & notifikasi | just_audio 0.10.5, audio_session 0.2.2, flutter_local_notifications 23.0.2, wakelock_plus 1.8.0 |
| Media & grafik | share_plus 13.3.1, image_picker 1.1.2, fl_chart 1.3.1, lottie 3.8.2 |
| Lainnya | intl 0.20.3, package_info_plus 10.2.2 |

Peta memakai OSM Standard dengan User-Agent RUNWILD dan atribusi terlihat;
tidak ada tile berbayar atau bulk download. Ikuti kebijakan tile OSM.

---

## 5. Pengembangan

### Prasyarat

- **Flutter 3.50.0** (channel stable) dan **Dart 3.14.0+**.
- **JDK 17** dan Android SDK untuk build Android.
- **Xcode + CocoaPods** (macOS) untuk build iOS.
- Git; Node.js 20+ hanya bila ingin menjalankan tes aturan Firestore.
- Perangkat/emulator untuk uji GPS, notifikasi, dan audio.

### Menyiapkan proyek

```bash
git clone https://github.com/renaldyakb/runwild.git
cd runwild
flutter pub get --enforce-lockfile
flutter gen-l10n
```

Di Windows, repo ini menyediakan pembungkus SDK lokal:

```powershell
./tool/flutter.ps1 pub get --enforce-lockfile
./tool/flutter.ps1 gen-l10n
./tool/flutter.ps1 run
```

### Menjalankan dan menguji

```bash
flutter run                       # perangkat/emulator
flutter test                      # seluruh tes (beberapa golden usang)
flutter analyze --fatal-infos     # gerbang CI
dart format --output=none --set-exit-if-changed lib test
```

Daftar tes yang menjadi gerbang CI ada di `.github/workflows/ci.yml` (release
notes, UI pembaruan, share card, personal best, preferensi, profil, izin,
weekly goal, detail aktivitas, sync, home/progress, tracking engine, durasi,
kalibrasi GPS). Tes yang butuh perangkat nyata tidak dijalankan di CI.

### Firebase (opsional)

Aplikasi berjalan tanpa Firebase (auth tamu, riwayat lokal). Untuk sinkron
cloud:

1. Buat proyek Firebase, aktifkan Auth (email/Google/Apple), Firestore, dan
   Storage bila diperlukan.
2. Salin konfigurasi ke `config/dev.android.json` atau `config/prod.android.json`
   (diabaikan Git), lalu jalankan dengan
   `--dart-define-from-file=config/dev.android.json`.
3. Letakkan `google-services.json` di `android/app/` dan
   `GoogleService-Info.plist` untuk iOS.
4. Deploy aturan dari root repo:

```bash
firebase deploy --only firestore:rules,storage
```

Jangan menyimpan kunci, keystore, atau berkas konfigurasi rahasia di repo.
Signing rilis Android diambil dari secret CI.

### Menambah fitur

1. Baca `AGENTS.md` (aturan kerja), `DESIGN.md` (UI), dan `docs/STATUS.md`.
2. Logika murni wajib di `domain/` dan punya unit test.
3. String UI lewat ARB (`lib/l10n/app_id.arb`), bukan hardcode.
4. Tidak ada angka ajaib: taruh ambang di `core/constants/`.
5. Tidak ada data palsu di UI; estimasi diberi label.
6. Setiap layar punya state loading, empty, error, offline, dan content.
7. Satu sesi kerja = satu tugas; perbarui `docs/STATUS.md` setelah selesai.

### Versi dan rilis

- Sumber versi hanya `pubspec.yaml` (`major.minor.patch+build`).
- Naikkan patch **dan** build setiap rilis (contoh `0.1.4+5`).
- Tulis catatan rilis pengguna di `docs/releases/<versi>.md` dengan heading
  `## Diperbaiki`, `## Diperbarui`, atau `## Ditambahkan` dan 3–6 bullet singkat.
  Jangan memakai HTML, tabel, gambar, emoji hias, atau klaim tanpa bukti.
- Alur CI: push ke `main` → job **Code Analysis & Tests** → build APK →
  publikasi GitHub Release dengan tag `v<versi>` dan APK terlampir. Publikasi
  menunggu job verifikasi berhasil.
- Jangan mengganti aset rilis lama dengan kode berbeda pada versi yang sama.

Build lokal:

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

### Gaya kontribusi kode

- Branch: `main` (stabil) dan `feat/...`, `fix/...`, `docs/...`.
- Commit mengikuti Conventional Commits, contoh
  `fix(run): hentikan angka mentah di pengaturan interval`.
- Sertakan bukti verifikasi di PR (perintah dan hasil singkat).
- Jangan menambah dependensi tanpa mencatat alasan dan versi di
  `docs/DECISIONS.md`.

---

## 6. Lisensi (Non-Komersial)

RUNWILD dilisensikan di bawah **RUNWILD Personal & Community License** —
lisensi *source-available* yang **bukan** lisensi open-source komersial.
Teks lengkap dan mengikat ada di [LICENSE](LICENSE).

**Ringkasan:**

| Diizinkan | Dilarang |
| --- | --- |
| Pakai pribadi untuk jalan/lari | Menjual aplikasi atau versi modifikasinya |
| Mempelajari dan memodifikasi kode | Distribusi berbayar di toko aplikasi |
| Fork untuk pengembangan komunitas | Iklan, sponsor, langganan, atau donasi bisnis |
| Membagikan versi modifikasi **gratis** dengan lisensi yang sama | Memakai kode dalam produk/layanan komersial |
| Berkontribusi balik ke proyek | Mengganti lisensi menjadi komersial/permissive |
| Menyalin potongan kode dengan atribusi | Menghapus notice lisensi dan atribusi |

Ketentuan penting:

1. **Hanya pemakaian pribadi dan pengembangan komunitas.** Dilarang
   diperjualbelikan atau dikomersialkan dalam bentuk apa pun.
2. Versi modifikasi wajib memakai lisensi yang sama, tetap gratis, memberi
   atribusi, dan menyatakan bahwa itu bukan versi resmi.
3. Nama, wordmark, logo, dan identitas visual RUNWILD tidak boleh dipakai untuk
   mempromosikan produk lain atau menyiratkan endorsement.
4. Lisensi pihak ketiga (Flutter, paket Dart, font, OpenStreetMap) tetap
   berlaku dan harus diikuti.
5. Perangkat lunak disediakan "sebagaimana adanya", tanpa jaminan; bukan alat
   medis. Estimasi jarak/pace/kalori bukan pengukuran medis.
6. Untuk kebutuhan komersial, hubungi pemilik repositori melalui issue tracker
   GitHub untuk pembicaraan lisensi terpisah.

---

## 7. Berkontribusi

Kontribusi komunitas sangat diterima: perbaikan bug, penerjemahan, dokumentasi,
pengujian di perangkat, atau penyempurnaan UI yang tetap sesuai `DESIGN.md`.

1. Fork repositori dan buat branch: `git checkout -b fix/nama-perbaikan`.
2. Baca `AGENTS.md` dan `DESIGN.md`; jangan menambah fitur di luar lingkup.
3. Tulis tes untuk logika murni dan jalankan gerbang lokal:

   ```bash
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze --fatal-infos
   flutter test
   ```

4. Commit dengan pesan jelas (Conventional Commits), lalu buka Pull Request.
5. Dengan mengirim kontribusi, Anda menyetujui kontribusi tersebut dilisensikan
   di bawah lisensi proyek ini dan tidak boleh dikomersialkan.

Jangan melaporkan masalah keamanan atau data pribadi di issue publik; gunakan
kanal privat ke pemilik repositori.

---

## 8. Dokumen penting

| Dokumen | Isi |
| --- | --- |
| `AGENTS.md` | Aturan kerja agen/developer, batas token, alur sesi |
| `DESIGN.md` | Arah visual, token, tipografi, aksesibilitas |
| `docs/PRD.md` | Spesifikasi produk, fitur F-01–F-27, roadmap |
| `docs/STATUS.md` | Status terkini, bukti verifikasi, langkah berikutnya |
| `docs/DECISIONS.md` | ADR dan daftar "Ide Nanti" |
| `docs/TESTING.md` | Langkah uji perangkat nyata dan riwayat pengujian |
| `docs/SCREENS.md` | Inventaris layar dan rute aktual |
| `docs/releases/` | Catatan rilis yang dipakai CI |
| `docs/specs/` | Spesifikasi interval dan catatan teknis lain |

---

## 9. Kredit

- Peta: © OpenStreetMap contributors.
- Font: Google Sans Flex (dipakai sesuai lisensi font).
- Paket Flutter/Dart: lihat `pubspec.yaml` dan lisensi masing-masing paket.
- Animasi kalibrasi GPS: aset milik proyek ini.

---

<p align="center">
  Dibuat untuk komunitas pelari di Indonesia.<br>
  <b>RUNWILD — RUN. TRACK. IMPROVE. GO WILD.</b><br>
  Pemakaian pribadi dan pengembangan komunitas. Bukan untuk dijual.
</p>