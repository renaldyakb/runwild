# Pengujian

## Hasil lokal, 2026-11-14

Lingkungan: Windows, Flutter 3.50.0, Dart 3.14.0. Tes berjalan pada Flutter
test engine, bukan emulator Android atau simulator iOS.

| Pemeriksaan | Hasil | Bukti |
| --- | --- | --- |
| dart format lib test | PASS, 28 file, 0 perubahan terakhir | evidence/format.log |
| flutter analyze --fatal-infos | PASS, no issues found | evidence/analyze.log |
| flutter test --coverage | PASS, 38 tes | evidence/test.log |
| Golden regression | PASS, 6 gambar terang/gelap | test/goldens di root proyek |
| Kontras token yang dipakai | PASS, ambang teks 4,5:1, batas kontrol 3:1 | test/design_test.dart |
| Keyboard | PASS, Tab/Enter/Space; Escape menutup dialog | test/accessibility_test.dart, app_test.dart |
| Touch target/nama semantik | PASS, guideline Android dan labeled target | test/accessibility_test.dart |
| Font offline/tabular | PASS, Archivo GSUB berisi tnum | assets/fonts/README.md |
| Bundle Flutter ARM64 debug | PASS, kernel dan assets terkompilasi; bukan APK | evidence/build-bundle.log |
| Android APK | BELUM DIUJI, SDK Android tidak tersedia | evidence/doctor.log |
| iOS build/run | BELUM DIUJI, host Windows | perlu macOS/Xcode dan perangkat |
| Firebase dev/prod | BELUM DIUJI, proyek belum ada | konfirmasi pemilik, ADR-011 |
| GitHub Actions | BELUM DIJALANKAN | .github/workflows/ci.yml siap |

LCOV mencatat 532/547 baris tercakup (97,26%). Ini cakupan kode yang tercatat
oleh tes saat ini, bukan cakupan MVP atau engine domain yang belum dibuat.
Laporan mentah ada di coverage/lcov.info (hasil build, diabaikan Git).

## Matriks layout

12 kombinasi shell/katalog: 360×640 dan 430×932 dp × teks 100%, 130%, 200%
× terang/gelap. Semua navigasi tab, sheet, buka katalog, scroll sampai state,
dan kembali ke Home berhasil tanpa exception layout.

10 kombinasi state: content/loading/empty/error/offline × terang/gelap pada
360×640 dp dengan teks 200%, tanpa overflow. Label tetap tersedia dan konten
dapat discroll; tidak ada pemotongan skala teks.

## Catatan visual

Enam golden diperiksa langsung: components_light/dark, home_light/dark,
catalog_light/dark. Font Archivo dan Material Icons dimuat pada engine tes.
Rute dan status tidak memakai data latihan contoh yang menyamar sebagai data
nyata. Gunung tidak berada di belakang teks/kontrol. Baseline Windows dijaga
dengan CI Windows; rasterisasi lintas OS tidak dianggap identik.

## Catatan perbaikan selama verifikasi

- Delegate Material lama tidak kompatibel dengan material_ui; memakai delegate
  paket baru dan ARB aplikasi.
- Tiga pasangan warna di palet awal gagal AA; token semantik diperbaiki,
  dengan angka rasio dan alasan di ADR-009.
- Helper tester.pageBack mencari tipe Material lama; tes menekan BackButton
  material_ui langsung dan membuktikan navigasi kembali, bukan melewati UI.
- SemanticsHandle pada tes dilepas sebelum verifikasi akhir framework.

## Menjalankan ulang

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --debug
```

Di workspace Windows, pakai `./tool/flutter.ps1` sebagai pengganti `flutter`.
Flutter SDK lokal tidak dimasukkan Git. Periksa gambar terlebih dahulu sebelum
`flutter test --update-goldens`; jangan memperbarui baseline untuk menutupi bug.

## Uji yang masih wajib untuk menutup Fase 0

1. Pasang Android SDK/JDK 17, hubungkan Android, jalankan doctor dan build debug.
2. Buka app di Android kecil dan besar, cek seluruh kontrol serta tema.
3. Pada Mac, resolve paket iOS, build tanpa signing untuk pemeriksaan awal,
   lalu signing dan jalankan di iPhone.
4. Ulangi skala teks 130%/200%, TalkBack/VoiceOver, fokus keyboard bila tersedia,
   mode Kurangi gerakan, rotasi, dan safe area pada perangkat fisik.
5. Buat proyek Firebase dev/prod, isi config lokal per platform, pastikan Core
   terhubung; restart aplikasi dan coba konfigurasi salah/koneksi terputus.
6. Jalankan CI di GitHub. Baru tutup Fase 0 setelah semua hasil dicatat.

## Uji lapangan fase berikutnya (belum dilakukan)

T2.5: hentikan debug dan F5 agar SQLite dan Path Provider masuk ke build.
Masuk dengan akun, mulai sesi sampai ada jarak, tunggu setidaknya lima detik
setelah titik diterima, lalu paksa tutup aplikasi. Buka ulang dengan akun sama
dan cek ringkasan pemulihan. Coba Lanjutkan sesi. Jarak harus mulai dari
checkpoint terakhir dan waktu saat aplikasi tertutup tidak dihitung sebagai
waktu bergerak. Ulangi untuk Simpan dan akhiri serta Buang sesi. Akun lain
tidak boleh melihat sesi tersebut. Ulangi pada iPhone.

T2.4: buka Lari, lanjutkan pemeriksaan izin lokasi, lalu tekan Mulai sesi lari.
Pastikan GPS mulai setelah hitung mundur, durasi berhenti saat Jeda dan tombol
sesi tersembunyi saat terkunci. Tahan satu detik untuk membuka kontrol. Akhiri
sesi dengan konfirmasi dan pastikan aplikasi kembali ke Home serta GPS berhenti.

T2.3: hentikan sesi debug dan F5 untuk memasang plugin Geolocator. Di area
terbuka, pilih Lari → Mulai Lari → Mulai uji GPS. Setelah titik pertama
diterima, catat jumlah titik dan jarak. Kunci layar, berjalan, lalu buka kunci
dan bandingkan keduanya. Android menampilkan notifikasi foreground jika izin
notifikasi aktif. Uji selama 60 menit di Android dan iPhone untuk DoD fase.
Tekan Akhiri uji GPS atau tutup lembar Lari. Perekaman harus berhenti.
Jika tidak ada titik, cek layanan lokasi dan izin presisi di pengaturan.

T2.1 pada HP: buka RUNWILD dan pastikan tidak ada dialog izin di Home. Buka
menu Lari, baca penjelasan, lalu tekan Mulai Lari. Coba tolak dan izinkan ulang,
serta buka pengaturan bila izin diblokir. Setelah kembali, status harus sesuai
izin sistem. Tolak notifikasi secara terpisah dan pastikan status lokasi
tetap berlaku. Ulangi skenario pada iPhone.

Fase 2: rute terukur 30 menit (deviasi jarak ≤3%), layar mati 60 menit,
app di-kill/restart HP, mode pesawat, baterai per jam; minimal dua Android
(termasuk merek dengan penghemat agresif) dan satu iPhone.
Fase 3: interval ≤1 detik drift, TTS/getar, audio ducking, sinkron offline
tanpa duplikasi, kartu share Instagram/WhatsApp dengan trim lokasi 200 m.
Fase 4: statistik cocok dengan aktivitas dan penghapusan seluruh data akun.

Jangan menganggap hasil widget test sebagai bukti GPS/background/persistensi.

T4.1: buka tab Aktivitas setelah menyimpan sesi Bebas dan Interval. Cek kelompok
bulan, tanggal/jam lokal, jarak/durasi/pace, pratinjau rute serta status sinkron.
Coba filter, Muat ulang dan (jika >20 sesi) Muat 20 sesi berikutnya: tanpa duplikasi.
Matikan internet dan buka ulang: sesi lokal tetap terlihat. Ganti akun: sesi akun
sebelumnya tidak boleh muncul. Coba font sistem 200%. Detail belum dapat dibuka;
riwayat dari perangkat lain belum diunduh (T4.2/T4.3).

T3.2 pada HP: Hot Restart, Lari → Interval → Atur interval. Coba 5:1 dan
kustom pemanasan/pendinginan 0, lari/jalan 10 detik, 2 putaran. Jeda 10 detik
dan lanjutkan; sisa fase harus tetap. Saat interval selesai GPS harus berhenti.
Simpan/ubah nama/hapus preset, coba offline dan buka ulang. Saat sesi berlangsung,
paksa tutup setelah checkpoint (≥5 detik), tunggu 30 detik, lalu pulihkan:
fase dan sisa waktu melanjutkan checkpoint, bukan melompat 30 detik.
Sesi bebas lama harus tetap bisa dipulihkan setelah migrasi. Audio belum tersedia.

T3.1: simulasi jam palsu 60 menit menguji mesin saja. Setelah T3.2/T3.3,
uji interval di HP selama 60 menit dengan layar mati; cocokkan pergantian fase,
jeda/lanjut, pemulihan dan cue audio terhadap stopwatch (galat ≤1 detik).

UI lime (16 Nov): Hot Restart, periksa beranda dan menu Home/Lari/Aktivitas/Profil
di HP. Tombol Mulai berlari harus membuka izin lalu countdown/pemulihan.
Periksa tema terang/gelap, font sistem besar, scroll sampai kartu mingguan,
dan pastikan navigasi tidak menutupi konten. Peta dan statistik belum tersedia;
beranda tidak boleh mengklaim GPS terkunci atau menampilkan jarak rekaan.
