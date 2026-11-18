# RUNWILD 🏃‍♂️⚡

> **RUN. TRACK. IMPROVE. GO WILD.**  
> Aplikasi pelacak jalan dan lari ramah pemula (Android & iOS) yang fokus pada kemudahan penggunaan, estetika atletis modern, dan privasi penuh.

[![Build & Checks](https://github.com/renaldyakb/runwild/actions/workflows/ci.yml/badge.svg)](https://github.com/renaldyakb/runwild/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.50.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.14.0-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🌟 Fitur Utama

### 📍 1. Pelacakan GPS Presisi & Auto-Pause Monotonik
- Perekaman rute akurat dengan penyaringan loncatan sinyal GPS (*kalman/distance filter*).
- **Jeda Otomatis Pintar**: Terhenti saat lampu merah atau istirahat, dan otomatis lanjut saat mulai bergerak lagi.
- Penghitungan metrik esensial: Jarak tempuh, durasi total, pace rata-rata (menit/km), dan estimasi kalori terbakar.

### ⏱️ 2. Mode Lari Bebas & Lari Interval Kustom
- **Lari Bebas**: Mulai lari tanpa tekanan target, cocok untuk santai (*recovery run*).
- **Lari Interval (Couch-to-5K Friendly)**:
  - Preset pemula yang dirancang khusus untuk transisi dari jalan santai ke lari teratur.
  - Kustomisasi fase jalan, fase lari, dan jumlah putaran (*rounds*).
  - Tampilan fase aktif visual yang jelas dan kontras saat sesi berlangsung.

### 🎧 3. Panduan Suara & Haptik (Audio Coach)
- Umpan balik suara dalam Bahasa Indonesia yang jernih (*text-to-speech*).
- Pengumuman progres berkala setiap kilometer (waktu, pace, sisa jarak).
- Hitung mundur suara 3-2-1 dan tanda pergantian fase interval dengan getaran haptik.

### 📊 4. Dasbor Progres & Rekor Pribadi (Personal Best)
- Grafik performa jarak 7 hari terakhir secara visual.
- Pelacak *Weekly Goal* dan *Streak* mingguan untuk menjaga konsistensi latihan.
- Deteksi otomatis rekor terbaik (*Personal Best*): 1 KM tercepat, 5 KM tercepat, 10 KM tercepat, dan jarak terjauh.

### 🎨 5. Kartu Bagikan Estetik (Social Share Card)
- Hasilkan kartu ringkasan sesi beresolusi tinggi untuk dibagikan ke Instagram Stories, WhatsApp, atau media sosial lainnya.
- Pilihan format tampilan: *Story (9:16)*, *Square (1:1)*, atau *Banner (16:9)*.
- **Privasi Terjaga**: Tombol instan untuk menyamarkan titik awal dan akhir rute rumah demi keamanan Anda.

### 🚀 6. Pembaruan Otomatis Terintegrasi (In-App Updates)
- Terhubung langsung dengan GitHub Releases.
- Menampilkan notifikasi di ponsel saat versi baru rilis.
- Dialog pembaruan interaktif di dalam aplikasi untuk mengunduh APK terbaru hanya dalam satu ketukan.

---

## 🎨 Desain & Antarmuka

- **Tipografi**: Menggunakan **Google Sans Flex** berbobot variabel (*dynamic weights*) untuk keterbacaan optimal saat bergerak.
- **Palet Warna**: Sentuhan atletis berenergi tinggi dengan warna aksen **Prime Lime** (`#C5FF41`) berpadu dengan **Hitam Arang Atletis** (`#171A14`).
- **Bahasa**: Antarmuka 100% Bahasa Indonesia yang ramah, hangat, dan mudah dipahami oleh pelari pemula hingga mahir.

---

## 🏗️ Arsitektur & Teknologi

RUNWILD dibangun dengan arsitektur bersih (*Clean Architecture* berbasis fitur):

```
lib/
├── app/               # Inisialisasi aplikasi, router (go_router), & tema
├── core/              # Layanan inti, utilitas, konstanta, & error handling
│   ├── constants/     # Ambang batas metrik, batas GPS, versi app
│   └── services/      # GPS probe, notifikasi lokal, audio, app update
├── data/              # Model data, DAO Drift SQLite, sinkronisasi remote
├── design/            # Sistem desain (tokens warna, tipografi, komponen Rw)
├── domain/            # Logika murni (mesin interval, pelacakan rute, kalkulasi pace)
├── features/          # Modul fitur:
│   ├── activities/    # Riwayat sesi, detail aktivitas, grafik rute
│   ├── auth/          # Masuk anonim & akun Firebase
│   ├── foundation/    # Beranda (dashboard), progres mingguan, dialog update
│   ├── profile/       # Pengaturan profil, preferensi suara, target lari
│   └── run/           # Sesi lari aktif, kontrol jeda/selesai, izin sensor
└── l10n/              # Lokalisasi bahasa (ARB format)
```

- **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- **Local Storage**: [drift](https://pub.dev/packages/drift) (SQLite terindeks dengan antrean sinkronisasi offline)
- **Peta Rute**: [flutter_map](https://pub.dev/packages/flutter_map) + OpenStreetMap (ringan tanpa lisensi komersial)
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio) & [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

---

## 💻 Memulai untuk Pengembang Komunitas

Kami sangat menyambut kontribusi dari komunitas! Berikut langkah-langkah untuk menyiapkan proyek di komputer lokal Anda:

### Prasyarat
- **Flutter SDK**: `v3.50.0` atau versi stabil terbaru ([Panduan Instalasi Flutter](https://docs.flutter.dev/get-started/install)).
- **Dart SDK**: `v3.14.0+`.
- **Java**: JDK 17.
- **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart.

### Langkah Instalasi

1. **Clone repositori**:
   ```bash
   git clone https://github.com/renaldyakb/runwild.git
   cd runwild
   ```

2. **Pasang dependensi**:
   ```bash
   flutter pub get
   ```

3. **Generate file lokalisasi**:
   ```bash
   flutter gen-l10n
   ```

4. **Jalankan tes otomatis**:
   ```bash
   flutter test
   ```

5. **Jalankan aplikasi di perangkat atau emulator**:
   ```bash
   flutter run
   ```

---

## 📦 Membangun Versi Rilis (Release APK)

### 1. Build Lokal
Untuk menghasilkan APK rilis yang optimal dan siap dipasang langsung di perangkat Android:
```bash
flutter build apk --release
```
File APK akan berada di:  
`build/app/outputs/flutter-apk/app-release.apk`

### 2. Unduh dari GitHub Actions
Setiap kali ada commit atau Pull Request ke branch `main`, GitHub Actions secara otomatis memvalidasi kode dan mem-build APK Release:
1. Buka tab **[Actions](https://github.com/renaldyakb/runwild/actions)** di repositori GitHub.
2. Pilih workflow run terbaru.
3. Unduh berkas dari bagian **Artifacts**: `runwild-release-apk`.

---

## 🤝 Panduan Berkontribusi (Contributing)

Ingin menambahkan fitur baru, memperbaiki bug, atau menyempurnakan desain?

1. **Fork repositori** ini ke akun GitHub Anda.
2. Buat branch baru untuk fitur Anda:
   ```bash
   git checkout -b fitur/nama-fitur-baru
   ```
3. Pastikan kode mengikuti standar linting dan format:
   ```bash
   dart format lib test
   flutter analyze
   flutter test
   ```
4. Commit perubahan Anda dengan pesan yang jelas:
   ```bash
   git commit -m "feat: tambahkan ringkasan mingguan pada smartwatch"
   ```
5. Push ke branch Anda dan buat **Pull Request (PR)**.

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah lisensi open-source [MIT](LICENSE).

---

<p align="center">
  Dibuat dengan ❤️ untuk komunitas pelari di Indonesia.<br>
  <b>RUNWILD — RUN. TRACK. IMPROVE. GO WILD.</b>
</p>
