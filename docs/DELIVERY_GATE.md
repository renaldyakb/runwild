# Delivery Gate Fase 0

Mode during, sumber PRD 9.1. Direction dari DESIGN.md.
Reading: fondasi mobile pelari pemula, bahasa visual atletis/outdoor,
ENERGY 2 / RHYTHM 2 / MOTION 1.

Status implementasi lokal: PASS pada ruang lingkup shell/katalog yang diuji.
Status penutupan Fase 0: FAIL / belum memenuhi DoD platform dan Firebase.
Ini bukan persetujuan rilis aplikasi atau klaim seluruh PRD sudah selesai.
PRD meminta laporan PASS/FAIL yang jujur; bagian yang belum diuji ditulis
eksplisit, bukan diberi PASS untuk memenuhi format.

## Hard Gate

| Aturan | Status lokal | Bukti |
| --- | --- | --- |
| R-02 copy | PASS | ARB Indonesia tidak memakai em dash; sumber PRD/vendor tetap verbatim |
| R-03 layout | PASS | 12 kombinasi ukuran/skala/tema dan 10 kombinasi state, tanpa overflow |
| R-17 angka | PASS | Tidak ada statistik pengguna; metric placeholder -- dengan penjelasan |
| R-18 testimoni | PASS | Tidak ada testimoni/avatar/rekaan |
| R-23 aset | PASS | PRD mengarahkan gunung/wordmark; font OFL; launcher ditandai placeholder |
| R-24 navigasi | PASS | Semua tab mempunyai halaman/sheet yang menjelaskan status fase |
| R-25 kontras | PASS | Tes WCAG untuk pasangan aktual; token koreksi dicatat ADR-009 |
| R-26 kontrol | PASS | Daftar interaksi di bawah; loading/disabled memblokir aksi |
| R-27 state | PASS | Lima state RwStateView dan loading/error/retry BackendPanel diuji |
| R-28 FAQ | PASS | Tidak ada FAQ pengisi |
| R-32 keyboard | PASS | Tab/Enter/Space, Escape dialog, fokus Material + outline tombol/nav |
| R-33 source | PASS | Fitur ditulis dalam Dart; tidak ada patch script runtime |
| R-34 tema | PASS | Golden dan interaksi pada dua tema; pilihan Sistem/Terang/Gelap berfungsi |
| R-35 verifikasi | PASS lokal | App dipompa/dirender Flutter engine; 38 tes dan 6 golden; native belum diverifikasi |
| R-36 klaim | PASS | UI mengatakan fase fondasi dan Firebase belum dikonfigurasi |
| R-37 direction | PASS | PRD bagian 9 diturunkan ke DESIGN.md sebelum UI |
| R-38 konten | PASS | Shell dan simulasi state berlabel eksplisit; tidak ada data palsu |
| R-39 semantik | PASS lokal | Semantics, label, touch guidelines, kontrol Material; reduced motion dari MediaQuery |
| R-40 performa | PASS adaptasi | Font bundled, motif berdimensi tetap; web media/CWV N/A, performa nyata belum diukur |

## Purpose Gate

PASS: R-01/R-06 palet dan Archivo mengikuti brand; R-04 ikon menggambarkan
rumah/lari/rute/profil/aksi; R-07 tanpa background grid; R-08 tanpa panah
dekoratif; R-09 tanpa badge klaim; R-10/R-13 tanpa blur/glow; R-12 permukaan
datar; R-14 kartu hanya untuk informasi terkait; R-19 transisi tema/kontrol
untuk feedback; R-22 gunung memberi konteks outdoor. Alasan ada di DESIGN.md.

## Liveliness

PASS lokal: dials dinyatakan; headline/CTA menjadi fokus; spasi 4 pt membedakan
kelompok; satu aksen oranye; motif gunung dan Archivo miring menjaga identitas.
Katalog berurutan menurut tugas memeriksa tema, kontrol, metrik, dan state.
Tidak ada loop animasi dekoratif. Lihat golden Home/katalog untuk bukti visual.

## Craftsmanship dan quality locks

PASS lokal: C-1/R-31 keputusan tercatat; C-2 kontrol teruji; C-3 bagian sesuai
kebutuhan fondasi; C-4 layout dan state diuji; C-5 tanpa klaim/data rekaan.
R-05 komposisi mengikuti isi; R-11 radius kartu 20, kontrol pill; R-15/R-16
CTA spesifik dan copy sederhana; R-20/R-30 identitas mengikuti PRD sendiri;
R-21 tema dapat dipilih; R-29 satu aksen dengan permukaan netral.

## Bukti interaksi

| Kontrol | Aksi yang diverifikasi |
| --- | --- |
| Home, Aktivitas, Profil | Berpindah ke route yang benar |
| Lari | Membuka sheet pelacakan belum tersedia |
| Tutup sheet | Kembali ke halaman sebelumnya |
| Buka katalog | Membuka /catalog; tombol kembali kembali ke Home |
| Sistem/Terang/Gelap | ThemeMode berubah dan brightness sesuai |
| Coba tombol utama | Menampilkan snackbar feedback |
| Buka contoh dialog | Menampilkan dialog; Escape menutupnya |
| Tombol loading/disabled | Callback tidak dipanggil |
| Bebas/Interval | Status terpilih berubah |
| Memuat/Kosong/Gagal/Offline/Konten | State yang sesuai tampil |
| Coba lagi simulasi | State kembali ke konten, bukan koneksi palsu |
| Persiapan lari pada empty | Sheet informasi terbuka |
| Retry Firebase | Service dipanggil ulang, status berubah dari failed ke ready melalui fake test |
| Rute tidak dikenal | Tombol kembali menuju Home |
| Keyboard tombol/chip | Tab memindah fokus, Enter/Space mengaktifkan |

Bukti: test/app_test.dart, accessibility_test.dart, backend_test.dart,
design_test.dart, screens_test.dart, docs/evidence/test.log.

## DoD global yang tertahan

FAIL: proyek Firebase dev/prod belum dibuat. FAIL: Android/iOS belum dibuild
dan dijalankan di perangkat target. CI baru disiapkan, belum dieksekusi di
GitHub. Aset referensi dari pemilik masih kosong. Lihat TESTING.md untuk
langkah penyelesaian. Fase berikutnya tidak dimulai sesuai PRD 0.2/11.
