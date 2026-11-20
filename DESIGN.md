# RUNWILD: arah desain

Sumber: referensi UI lime dari pengguna, 16 November 2026 (menggantikan arah oranye PRD bagian 9). Dials fondasi: ENERGY 2 / RHYTHM 2 / MOTION 1.

Arah terbaru: latar krem kehijauan, hero arang, primary lime #C5FF41, headline tegak,
kartu radius 28, tombol pill dan navigasi arang dengan tab aktif lime. Beranda
menonjolkan aksi Mulai berlari; status GPS, peta dan statistik hanya dari data nyata.
Area rute beranda menampilkan kondisi belum dimulai; ringkasan mingguan belum tersedia.
Primary sebagai teks pada latar terang memakai hijau gelap #486600 agar terbaca.

Lime menandai aksi utama; tinta/krem menjaga fokus dan pilihan terang/gelap.
Archivo tebal tegak membawa karakter atletis; body tegak menjaga keterbacaan.
Spasi 4 pt memisahkan kelompok; kartu hanya membungkus unit informasi terkait.
Motif gunung menunjukkan konteks outdoor dan selalu terpisah dari teks/kontrol.
Ikon Material dipilih menurut arti aksi, bukan sebagai ornamen.
Katalog mengurutkan identitas, tema, aksi, pilihan, metrik, lalu state UI.


Referensi aktif: tangkapan layar lime dari pengguna (16 November 2026). Karakter: **energik, atletis, outdoor, tegas**. Kartu arang pada latar krem kehijauan, aksen lime, tipografi tebal tegak, sudut besar dan navigasi kapsul. `docs/reference/runwild-reference.png` adalah referensi awal yang sudah digantikan.

**Prinsip utama: "Maksimal di tepi, minimal di inti."**

| Tier              | Layar                                                                                              | Perlakuan                                                                                                                     |
| ----------------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **A, Maksimalis** | Splash, Intro, Get Started, header Ringkasan Sesi, Kartu Bagikan, badge terbuka, empty state besar | Tipografi raksasa miring, foto/ilustrasi hitam-putih, bentuk diagonal lime, siluet gunung, halftone, ukuran kontras ekstrem |
| **B, Seimbang**   | Home, Pra-sesi, Detail Aktivitas, Progress, Profil Awal                                            | Satu elemen dekoratif kuat per layar (misal siluet gunung + lingkaran matahari di header Home) dan sisanya bersih             |
| **C, Minimalis**  | Layar Lari Aktif, daftar, form, pengaturan, kustom interval                                        | Permukaan datar, hierarki jelas, hampir tanpa hiasan. Dekorasi hanya di zona non-interaktif (maks 15% tinggi di bawah)        |

**Aturan keras:** dekorasi **tidak boleh** mengurangi keterbacaan angka saat berlari dan tidak boleh berada di bawah teks atau kontrol interaktif.

### 9.3 Token desain (agent menyalin ke `design/tokens/`)

> Nilai warna diperkirakan dari gambar referensi. Jika gambar tersedia di repo, agent boleh mengambil sampel piksel untuk menyempurnakan, lalu mencatat hasilnya di `DESIGN.md`.

**Warna**

| Token        | Hex       | Penggunaan                                 |
| ------------ | --------- | ------------------------------------------ |
| `ink-950`    | `#171A14` | Latar layar gelap, teks pada lime        |
| `ink-900`    | `#20241C` | Permukaan gelap utama                      |
| `ink-800`    | `#282D23` | Kartu pada mode gelap                      |
| `ink-700`    | `#3B4233` | Garis/pemisah gelap                        |
| `ink-500`    | `#6B6B72` | Teks sekunder pada terang                  |
| `paper-50`   | `#F7F9F2` | Latar layar terang (krem hangat)           |
| `paper-100`  | `#FFFFFF` | Kartu/permukaan terang                     |
| `paper-200`  | `#DEE3D6` | Garis/pemisah terang                       |
| `lime-500` | `#C5FF41` | **Warna brand**: tombol utama, rute, aksen |
| `lime-600` | `#B0EB2E` | State ditekan                              |
| `lime-300` | `#D5FF80` | Hover/aksen lembut                         |
| `lime-100` | `#EFFFCC` | Latar chip terpilih (terang)               |
| `lime-700` | `#486600` | **Teks lime di atas latar terang**       |
| `go-500`     | `#2ECC71` | Titik awal rute, GPS bagus                 |
| `warn-500`   | `#FFB020` | Peringatan                                 |
| `danger-500` | `#E5484D` | Error, aksi destruktif                     |

**Aturan kontras (hasil hitung, wajib dipatuhi):**

- Teks di atas `lime-500` **selalu `ink-950`**. Dilarang teks putih di atas lime. Pasangan normal, ditekan dan hover diverifikasi lewat tes kontras.
- `lime-500` sebagai **teks** hanya di atas latar gelap. Di atas latar terang gunakan `lime-700` atau jadikan lime sebagai isian, bukan teks.
- Semua kombinasi teks/latar harus ≥ 4,5:1 (teks normal) dan ≥ 3:1 (teks besar/ikon). Agent menambahkan tes otomatis untuk pasangan token.

**Tipografi**

| Peran                                       | Font        | Gaya                                                                                                                |
| ------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------- |
| Display / headline / wordmark / angka besar | **Archivo** | ExtraBold–Black, **tegak**, sentence case untuk headline beranda, tracking rapat                            |
| UI / body / label                           | **Archivo** | Regular–SemiBold, tegak                                                                                             |
| Angka metrik                                | Archivo     | `FontFeature.tabularFigures()`; agent memverifikasi dukungan tabular. Jika tidak ada, ganti ke **Barlow** dan catat |

- Font dibundel sebagai aset (bukan diunduh runtime) agar tetap bekerja offline.
- Skala (sp): Display-XL 72 · Display-L 48 · Display-M 32 · Title 22 · Body 16 · Body-S 14 · Label 12. Angka jarak di layar lari ≥ 72 sp.
- Mendukung pembesaran teks sistem hingga 200% tanpa terpotong (layar lari boleh membatasi pada 130% untuk angka utama, dengan alasan tercatat).

**Spasi, bentuk, elevasi**

- Spasi skala 4 pt: 4, 8, 12, 16, 20, 24, 32, 40, 56, 72.
- Radius: `sm 12` · `md 20` · `lg 28` · `pill 999`. Kartu memakai `md`–`lg`, tombol dan chip `pill`.
- Elevasi minimal: pilih **tonal + garis tipis**, bukan bayangan tebal. Satu tingkat bayangan lembut hanya untuk sheet dan dialog.
- Margin layar 20; tap target ≥ 48×48 dp, kontrol layar lari ≥ 56 dp (tombol jeda 88 dp).

**Motion**

- Durasi: 120 ms (mikro) · 200 ms (transisi) · 320 ms (sheet/halaman). Kurva `easeOutCubic` untuk masuk, `easeInCubic` untuk keluar.
- Momen "bernyawa" yang disengaja: hitung mundur, perubahan fase interval, penyelesaian lari, buka badge. Di luar itu, tenang.
- Hormati "Kurangi gerakan" sistem: ganti animasi dengan fade singkat.
- Haptic selaras dengan momen penting (mulai, ganti fase, selesai), bukan di setiap ketukan.

### 9.4 Pustaka dekorasi (aset buatan sendiri)

| Motif                                     | Deskripsi                                           | Penggunaan                            | Batas                  |
| ----------------------------------------- | --------------------------------------------------- | ------------------------------------- | ---------------------- |
| **Siluet gunung**                         | Poligon bergerigi hitam-putih dengan bayangan salju | Header Home, dasar layar lari, Splash | 1 per layar            |
| **Garis diagonal (slash)**                | Pita lime bersudut tajam menyerupai sambaran      | Latar Intro/Get Started, dasar Splash | Maks 2 per layar       |
| **Lingkaran matahari + busur konsentris** | Lingkaran lime dengan garis lengkung tipis        | Header Home                           | 1 per layar            |
| **Halftone**                              | Titik gradasi kecil                                 | Sudut kartu tier A                    | Tidak di belakang teks |
| **Bendera kotak-kotak**                   | Penanda finis di peta                               | Peta rute                             | Hanya di peta          |
| **Titik awal hijau**                      | Lingkaran hijau bergaris putih                      | Peta rute                             | Hanya di peta          |

Semua motif adalah SVG/`CustomPainter` buatan sendiri (tanpa aset berhak cipta pihak lain).

### 9.5 Foto dan ilustrasi

- Gaya: foto pelari **hitam-putih kontras tinggi** dengan satu aksen lime (siluet pelari + pita lime).
- Agent **dilarang** mengambil foto dari internet atau memakai stok yang lisensinya tidak jelas. Gunakan **placeholder bergaya** (blok siluet) yang ditandai `TODO(asset)` dan catat di checklist aset (bagian 14.3). Pemilik produk menyuplai foto berlisensi atau ilustrasi.
- Tidak ada ikon "sparkle/bintang AI", gradien ungu-biru, atau avatar generik buatan AI.

### 9.6 Spesifikasi komponen kunci

| Komponen                   | Spesifikasi                                                                                                                        |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **RwButton.primary**       | Pill, isian `lime-500`, teks `ink-950` SemiBold, tinggi 56, ikon opsional di kiri, state: default / pressed / disabled / loading |
| **RwButton.secondary**     | Pill, kontur 1,5 dp, isian transparan                                                                                              |
| **RwStatTile**             | Label kecil atas, angka besar tabular, satuan kecil, ikon garis lime                                                             |
| **RwWeekBars**             | 7 batang, hari ini lime solid, lainnya netral, label hari di bawah                                                               |
| **RwMetricRow (lari)**     | Kartu pill gelap dengan 3 kolom (Durasi · Pace · Kalori) dan pembatas tipis                                                        |
| **PhaseBanner (interval)** | Label LARI/JALAN besar, sisa waktu, bilah progres, "Putaran n/N"                                                                   |
| **RwBottomNav**            | 4 item, ikon garis + label, kapsul arang, tab aktif berisi lime dengan teks gelap, safe area dan ruang konten terpisah |
| **GpsPill**                | Batang sinyal + label, pojok kanan atas                                                                                            |
| **RouteMap**               | Peta gelap, garis rute lime 5 dp dengan tepi halus, titik hijau awal, bendera finis                                              |
| **LockSlider/LockButton**  | Tombol kunci; saat terkunci, buka dengan geser/tekan-tahan                                                                         |

### 9.7 Detail layar Lari Aktif (acuan referensi, layar paling penting)

```text
┌──────────────────────────────┐
│ [←]     RUNWILD     [GPS ▮▮▮] │  bar atas, kontras tinggi
│                                │
│     PETA GELAP + RUTE ORANYE   │  ± 45% tinggi layar
│  ●(awal hijau)        🏁(finis) │
│                                │
│        5.21   km               │  angka jarak 72sp+ miring tebal
│ ┌────────────────────────────┐ │
│ │ 30:24    5'50"/km   312 kkal│ │  durasi · pace · kalori (perkiraan)
│ └────────────────────────────┘ │
│ [ PHASE BANNER (mode interval)]│  hanya di mode interval
│ [🔒]      ( ❚❚ JEDA )     [◎]  │  kunci · jeda (lime, besar) · pusatkan
│  ▲ siluet gunung samar di dasar│  non-interaktif, ≤ 15% tinggi
└──────────────────────────────┘
```

- Mode jeda: tombol berubah menjadi **Lanjut** (lime) + **Selesai** (sekunder); statistik tidak berubah.
- Mode terkunci: sentuhan diabaikan, ikon gembok jelas, buka dengan tekan-tahan 1 detik.
- Kontras dan ukuran harus terbaca di bawah sinar matahari (angka putih di atas `ink-950`).

### 9.8 Aturan copy (anti-slop copywriting)

- Bahasa Indonesia sehari-hari, ringkas, hangat, tidak menggurui. Gunakan "kamu".
- Tidak ada hype kosong ("revolusioner", "tingkatkan performa 10×"), tidak ada emoji sebagai bullet, tidak ada statistik/testimoni karangan.
- Jelaskan istilah dengan kalimat: tampilkan "Rata-rata 7'10" per km" dan sediakan tombol "?" yang membuka penjelasan "Pace = waktu yang kamu butuhkan untuk menempuh 1 km".
- Pesan error: apa yang terjadi + apa yang bisa dilakukan. Contoh: "GPS belum menemukan sinyal. Pindah ke area terbuka lalu coba lagi."
- Empty state jujur: "Belum ada aktivitas. Jalan 10 menit saja sudah cukup untuk memulai."
- Brand tagline "RUN. TRACK. IMPROVE. GO WILD." tetap bahasa Inggris dan hanya dipakai di Splash/Intro/Share card.
- Salam Home bergantung jam: "Selamat pagi" / "siang" / "sore" / "malam" + nama.

### 9.9 Aksesibilitas (anti-slop-human)

Kontras sesuai 9.3, tap target ≥ 48 dp, label semantik untuk semua ikon/tombol, urutan fokus logis, dukungan TalkBack/VoiceOver untuk layar lari (angka dibacakan dengan satuan), tidak mengandalkan warna saja, mendukung teks besar dan "Kurangi gerakan".

### 9.10 Checklist QA desain (dijalankan agent tiap fitur UI)

- [ ] Sesuai tier (A/B/C) dan batas dekorasi
- [ ] Semua warna berasal dari token (tidak ada hex liar di widget)
- [ ] Semua state ada: loading, empty, error, offline, content
- [ ] Kontras lolos; tidak ada teks putih di atas lime
- [ ] Tes di layar kecil (360×640 dp) dan besar (430×932 dp) tanpa overflow
- [ ] Tes dengan teks sistem 130% dan 200%
- [ ] Teks sesuai aturan copy; tidak ada data palsu
- [ ] Laporan Delivery Gate anti-slop: **PASS**

---

## 10. Rules & Guidelines UI/UX V2 (Prime Lime Refresh & Declutter)

### 10.1 Filosofi Desain
1. **Athletic & Energizing (Prime Lime Accent)**:
   - Warna aksen utama adalah Electric Prime Lime (`#C5FF41`), memberikan aura outdoor, segar, dan sporty.
   - Dipadukan dengan permukaan kontras tinggi: Charcoal/Dark Ink (`#171A14`, `#20241C`) untuk kartu hero dan layar lari aktif, serta Cream Warm Paper (`#F7F9F2`) untuk latar utama mode terang.
   - **Aturan Mutlak Kontras**: Teks di atas isian `lime-500` Wajib `ink-950` SemiBold/Bold (rasio ≥ 9:1, lolos WCAG AAA). Dilarang keras teks putih di atas lime. Pada latar terang, teks aksen lime memakai `lime-700` (`#486600`).
2. **Minimalis & Anti-Clutter**:
   - Hilangkan redundansi navigasi: jangan letakkan tombol Profil di AppBar jika Bottom Nav sudah menyediakan tab Profil.
   - Pisahkan kontrol developer/debug (seperti panel backend / katalog komponen) ke lembar utilitas tersembunyi, jangan kotori alur utama pengguna.
   - Setiap layar memiliki **Satu Aksi Utama Terjelas (Single Primary CTA)**.
3. **Ramah Pemula & Mudah Digunakan**:
   - Di Beranda: Hero card langsung menyapa pengguna, menampilkan status GPS/koneksi saat ini, metrik ringkas, dan tombol besar "Mulai berlari".
   - Di Lembar Persiapan: Pemilihan mode (Bebas vs Interval) dibuat dengan tab toggle pill yang jelas, visualisasi izin lokasi yang transparan, dan satu tombol start.
   - Saat Berlari: Tampilan HUD atletis dengan angka jarak masif (72sp), metrik durasi & pace terpisah rapi dengan ikon aksen, tombol jeda besar (thumb-friendly min 88dp), dan kunci layar anti-salah-sentuh.
4. **Tipografi Berkarakter & Skalabel**:
   - Display & Headline: Archivo ExtraBold/Black tegak (`w800`–`w900`), tracking rapat atletis.
   - Angka Metrik: Archivo dengan `FontFeature.tabularFigures()` agar digit tidak bergeser saat nilai berubah.
   - Aksesibilitas: Wajib mendukung text scale hingga 200% tanpa RenderFlex overflow. Gunakan `LayoutBuilder`, `FittedBox` pada label navigasi pendek, dan `Expanded` pada teks berdampingan.
5. **Modern Elevation & Borders**:
   - Hindari bayangan pekat murahan (slop). Gunakan permukaan flat dengan border halus 1–1.5dp (`ink-700` pada gelap, `paper-200` pada terang) dan sudut melengkung modern (`RwRadius.md` 20dp, `RwRadius.lg` 28dp, `RwRadius.pill` 999dp).
   - Batas kartu wajib benar-benar terlihat di atas `paper-50`: `RwColors.borderCard` (#DEE3D6) untuk kartu, `RwColors.borderControl` (#E2E6DC) untuk kontrol/tombol sekunder, dan `RwColors.surfaceMuted` (#F0F3EB) untuk permukaan pendamping. Kartu putih di atas `paper-50` hanya berbeda 1,06:1, jadi garisnya yang menandai bentuk kartu.
   - Warna data grafik memakai token khusus: `chartBar` (#486600) untuk batang, `chartBarToday` (#171A14) untuk penanda hari ini, `chartTrack`/`chartTrackSoft` untuk jalur kosong. Batang data wajib ≥ 3:1 terhadap permukaannya.
6. **Gerak & Animasi Cuaca**: animasi cuaca Meteocons (MIT) dimuat dari `assets/lottie/meteocons/`. Kondisi saat ini boleh beranimasi satu kali lalu diam; strip 12 jam memakai bingkai pertama sebagai piktogram statis supaya tidak ada belasan gerak berulang di layar. Saat "Kurangi gerakan" aktif atau aset gagal dimuat, tampil ikon Material statis.

### 10.2 Dokumentasi Perubahan Komponen & Layar
| Komponen / Layar | Perubahan UI/UX | Manfaat Pengguna |
| :--- | :--- | :--- |
| `RwCard` | Penambahan parameter `borderColor`, `radius`, `color`, `padding`. Default radius kini dinamis & responsif. | Tampilan lebih ramping, border halus anti-flat-monoton. |
| `RwStatTile` | Badge ikon rounded accent (`RwRadius.sm`), angka tabular tebal `w800`, suffix satuan terpisah rapi. | Metrik jarak, durasi, pace terbaca instan sekilas pandang. |
| `RwBottomNav` | Kapsul dock mengambang dengan radius 28dp, border halus, tab aktif lime dengan teks kontras tinggi, dan `FittedBox` pada label. | Navigasi nyaman digapai jempol, tidak meluap pada text scale 200%. |
| `_AppShell` | Menghilangkan tombol profil redundan di AppBar atas; AppBar hanya menampilkan Wordmark tebal dan status konektivitas. | Area atas bersih, tidak ada duplikasi fungsi dengan BottomNav. |
| `HomeDashboard` | Kartu hero `ink-950` rata (tanpa gradient) berisi sapaan sesuai jam + nama depan, tagline, satu tombol CTA "Mulai berlari", cuaca saat ini (piktogram + suhu + nama kondisi + satu kalimat waktu hujan), strip piktogram 12 jam, dan pratinjau rute terakhir. Di bawahnya satu kartu "Minggu ini" (jarak, durasi, sesi, grafik dengan jawaban satu kalimat, progres target, rentetan minggu), kartu saran sesi dengan tautan (bukan CTA kedua), baris jadwal, dan tautan Progress. Setiap keadaan (memuat, kosong, gagal) punya kalimatnya sendiri. | Pengguna paham kondisi sekarang dan bisa mulai lari dalam satu ketukan tanpa aksi yang bersaing. |
| `RunRemindersScreen` | Halaman `/reminders`: satu tombol "Tambah jadwal", daftar bergaya kalender (chip tanggal + nama hari + jam), kelompok Hari ini/Besok/Berikutnya, hapus via ikon, ubah via ketuk kartu, plus catatan suara notifikasi dan keterlambatan penjadwalan. | Pengguna dapat menyiapkan banyak jadwal lari dan tahu bahwa notifikasinya bersuara walau aplikasi tertutup. |
| `FoundationScreen` | Mengganti teks debug "Fondasi Fase 0" dengan empty state atletis yang ramah & edukatif pada tab Aktivitas dan kartu profil modern pada tab Profil. | Tampilan profesional, ramah pemula, menyembunyikan detail teknis internal. |
| `RunPermissionSheet` | Redesain menjadi lembar persiapan elegan: mode toggle pill (Bebas/Interval), status izin lokasi yang transparan, dan 1 tombol mulai. | Alur persiapan lari terasa mulus tanpa kebingungan teknis. |
| `RunActiveScreen` | HUD lari atletis: GPS pill status rapi, interval phase banner prime lime, angka jarak raksasa (72sp), metrik split responsive, countdown lingkaran tajam tanpa glow murahan, dan tombol jeda 88dp. | Sangat mudah dibaca saat berlari di bawah sinar matahari langsung; aman dari salah sentuh. |
| `IntervalEditor` | Komponen khusus `_SportIntervalField`: stepper +/- (48×48dp) dan quick-jump chips waktu (`30d`, `1m`, `2m`, `4x`, dll.) dengan tampilan menit:detik tabular tebal. | Mengatur interval super cepat (fast/quick sport UX) tanpa perlu mengetik angka di software keyboard. |

