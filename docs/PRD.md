# RUNWILD — Product Requirements Document (PRD)

> **Versi dokumen:** 1.0 · **Status:** Siap dieksekusi oleh AI agent · **Bahasa UI default:** Indonesia (siap i18n, Inggris menyusul)
> **Tagline brand:** RUN. TRACK. IMPROVE. GO WILD.
> **Platform:** Android + iOS (satu codebase Flutter) · **Backend:** Firebase

---

## 0. Cara Memakai Dokumen Ini

### 0.1 Untuk manusia (pemilik produk)

1. Buat repo baru bernama `runwild`.
2. Simpan dokumen ini di `docs/PRD.md`.
3. Simpan gambar referensi desain di `docs/reference/runwild-reference.png` (tiga layar: onboarding, home, active run).
4. Pasang skill anti-slop (lihat bagian 9.1), lalu buka sesi agent dan tempel **Kickoff Prompt** dari bagian 13.2.

### 0.2 Untuk AI agent

- Dokumen ini adalah **sumber kebenaran tunggal**. Jika ada konflik antara dokumen ini dan asumsi kamu, ikuti dokumen ini.
- Jika ada hal yang tidak tercakup, buat keputusan terkecil yang aman, catat di `docs/DECISIONS.md`, lalu lanjut. Jangan berhenti untuk bertanya hal yang bisa diputuskan sendiri. Bertanya hanya untuk hal yang memblokir (misalnya kredensial, keputusan bisnis).
- Kerjakan **per fase** (bagian 11). Jangan mengerjakan fase berikutnya sebelum Definition of Done fase sekarang terpenuhi.
- Setiap ID (F-xx, S-xx, R-xx) di dokumen ini boleh dipakai sebagai referensi di commit, PR, dan laporan.

### 0.3 Struktur file dokumentasi yang harus dibuat dan dirawat agent

```text
runwild/
├── AGENTS.md                  # ringkas: aturan inti + pointer ke docs/PRD.md (maks 80 baris)
├── DESIGN.md                  # arah desain (diturunkan dari bagian 9), dibaca anti-slop
├── docs/
│   ├── PRD.md                 # dokumen ini
│   ├── DECISIONS.md           # log keputusan teknis (ADR singkat)
│   ├── CHANGELOG.md           # per fase / rilis
│   ├── DATA_MODEL.md          # salinan terawat dari bagian 7
│   ├── SCREENS.md             # inventaris layar + status implementasi
│   ├── TESTING.md             # strategi dan hasil uji lapangan
│   └── reference/
│       └── runwild-reference.png
└── (kode Flutter)
```

---

## 1. Ringkasan Produk

### 1.1 Visi

RUNWILD adalah aplikasi pelacak jalan dan lari yang **ramah pemula**. Pengguna yang belum pernah lari bisa mulai dalam 3 ketukan, tidak dibuat bingung oleh istilah teknis, dan tetap mendapat rute di peta, pace, waktu, serta kartu yang bisa dibagikan, seperti Strava tetapi lebih sederhana dan lebih memandu.

### 1.2 Masalah yang diselesaikan

| Masalah pemula                                                       | Cara RUNWILD menjawab                                         |
| -------------------------------------------------------------------- | ------------------------------------------------------------- |
| Aplikasi lari terlalu rumit dan penuh istilah (VO2max, cadence, TSS) | Bahasa sederhana, 3 angka utama saja saat berlari             |
| Tidak tahu harus mulai dari mana                                     | Preset interval jalan/lari dan program terpandu (0 ke 5K)     |
| Langsung lari terus-menerus lalu cedera atau kapok                   | Mode interval jalan/lari dengan panduan suara                 |
| Harus melihat layar terus saat berlari                               | Panduan suara bahasa Indonesia dan getar                      |
| Takut lokasi rumah terlihat saat berbagi                             | Pengaturan privasi titik awal/akhir yang aktif secara default |
| Data terkunci di satu aplikasi                                       | Ekspor GPX (Fase 5)                                           |

### 1.3 Target pengguna

| Persona                         | Deskripsi                                             | Kebutuhan utama                                    |
| ------------------------------- | ----------------------------------------------------- | -------------------------------------------------- |
| **Rani, 27, pemula total**      | Belum pernah lari rutin, ingin sehat dan bisa lari 5K | Panduan, tidak malu/tidak bingung, motivasi ringan |
| **Dimas, 35, kembali berlari**  | Dulu aktif, berhenti beberapa tahun                   | Interval, target mingguan, riwayat jelas           |
| **Pemilik produk (dogfooding)** | Memakai app untuk jalan dan jogging sendiri           | Akurat, hemat baterai, mudah dibagikan             |

### 1.4 Prinsip produk (dipakai untuk memutuskan konflik prioritas)

1. **Satu aksi utama per layar.** Tombol terbesar selalu jawaban atas "apa yang harus saya lakukan sekarang?".
2. **Mulai lari maksimal 3 ketukan** dari layar Home.
3. **Saat berlari: glanceable.** Maksimal 3 angka + 1 panel fase interval. Terbaca dalam 1 detik dari jarak lengan.
4. **Data jujur.** Tidak ada angka palsu, tidak ada statistik karangan, tidak ada "10.000+ pelari". Estimasi diberi label "perkiraan".
5. **Pemula tidak dihukum.** Hari istirahat dihargai, streak bersifat mingguan, bukan harian.
6. **Offline dulu.** Sesi tidak boleh hilang karena sinyal atau aplikasi tertutup.
7. **Privasi default aman.** Semua aktivitas privat; titik awal/akhir disamarkan saat dibagikan.

### 1.5 Non-goals (tidak dikerjakan sebelum PMF terbukti)

- Bukan jam tangan/pelatihan elit: tanpa VO2max, training load, segmen, leaderboard publik.
- Tidak ada feed sosial publik di MVP.
- Tidak ada AI coach / chatbot di MVP.
- Tidak ada dukungan wearable/BLE heart-rate di MVP (Fase 5).
- Tidak ada web app dan tidak ada tablet-optimized layout di MVP.

---

## 2. Tujuan dan Goals

### 2.1 Business goals

| ID   | Goal                                       | Ukuran                                                            |
| ---- | ------------------------------------------ | ----------------------------------------------------------------- |
| BG-1 | Aplikasi layak dipakai sendiri setiap hari | Pemilik memakai ≥ 3 sesi/minggu selama 4 minggu berturut-turut    |
| BG-2 | Validasi pasar pemula                      | 10 penguji pemula; ≥ 6 menyelesaikan ≥ 3 sesi dalam 2 minggu      |
| BG-3 | Siap rilis publik                          | Lolos review Google Play dan App Store, crash-free sessions ≥ 99% |
| BG-4 | Dasar monetisasi                           | Program berbayar/tema share siap diuji setelah BG-2 tercapai      |

### 2.2 Product goals

| ID   | Goal                  | Target terukur (awal, divalidasi saat beta)                                   |
| ---- | --------------------- | ----------------------------------------------------------------------------- |
| PG-1 | Onboarding cepat      | Dari buka aplikasi pertama kali sampai di Home ≤ 90 detik                     |
| PG-2 | Mulai lari cepat      | Home ke countdown ≤ 3 ketukan (sudah login, izin sudah diberikan)             |
| PG-3 | Pelacakan akurat      | Jarak dalam ±3% dari jarak referensi (rute terukur atau jam lari pembanding)  |
| PG-4 | Hemat baterai         | ≤ 8% per jam dengan layar mati, GPS aktif (target; diukur di perangkat nyata) |
| PG-5 | Tidak kehilangan data | 0 sesi hilang pada uji: aplikasi di-kill, HP restart, sinyal putus            |
| PG-6 | Mudah dibagikan       | Selesai lari ke kartu siap bagi ≤ 2 ketukan                                   |
| PG-7 | Interval andal        | Panduan fase tepat waktu (selisih ≤ 1 detik) saat layar mati selama 60 menit  |

### 2.3 Metrik keberhasilan (analytics)

`first_run_completion_rate`, `d1/d7/d28_retention`, `sessions_per_user_per_week`, `interval_mode_share`, `share_card_rate`, `crash_free_sessions`, `program_week_completion`. Tidak ada koordinat lokasi yang boleh dikirim ke analytics.

---

## 3. Scope: MVP dan Setelahnya

Prioritas: **P0** wajib MVP · **P1** segera setelah MVP · **P2** nanti.

| ID   | Fitur                                                   | Prioritas | Fase |
| ---- | ------------------------------------------------------- | --------- | ---- |
| F-01 | Onboarding 3 slide + pilihan tujuan/level               | P0        | 1    |
| F-02 | Auth: email+password, Google, Apple (iOS)               | P0        | 1    |
| F-03 | Perizinan lokasi/notifikasi dengan penjelasan manusiawi | P0        | 2    |
| F-04 | Pelacakan GPS: rute, jarak, waktu, pace, kecepatan      | P0        | 2    |
| F-05 | Tracking background (layar mati) + pemulihan sesi       | P0        | 2    |
| F-06 | Jeda manual + auto-pause + kunci layar                  | P0        | 2    |
| F-07 | Mode **Interval Jalan/Lari** (preset + kustom)          | P0        | 3    |
| F-08 | Panduan suara Indonesia + getar + notifikasi            | P0        | 3    |
| F-09 | Ringkasan sesi (peta, split per km, perasaan)           | P0        | 3    |
| F-10 | Kartu bagikan (9:16 dan 1:1, 3 tema)                    | P0        | 3    |
| F-11 | Riwayat aktivitas (daftar, filter, detail)              | P0        | 4    |
| F-12 | Home: ringkasan minggu ini + target mingguan            | P0        | 4    |
| F-13 | Progress: grafik mingguan/bulanan, rekor pribadi        | P0        | 4    |
| F-14 | Profil + pengaturan (satuan, suara, privasi, akun)      | P0        | 4    |
| F-15 | Hapus akun dan data (wajib toko aplikasi)               | P0        | 4    |
| F-16 | Program terpandu "0 ke 5K" 8 minggu                     | P1        | 5    |
| F-17 | Streak mingguan + badge                                 | P1        | 5    |
| F-18 | Pengingat latihan + hari istirahat                      | P1        | 5    |
| F-19 | Pemanasan dan pendinginan terpandu                      | P1        | 5    |
| F-20 | Tantangan bawaan (misal "10K sekali jalan")             | P1        | 5    |
| F-21 | Ekspor GPX, mode indoor/treadmill                       | P1        | 5    |
| F-22 | Health Connect / Apple Health                           | P1        | 6    |
| F-23 | Live location sharing + kontak darurat                  | P1        | 6    |
| F-24 | Kontrol musik (Spotify/pemutar sistem)                  | P2        | 6    |
| F-25 | Teman, grup kecil, tantangan bersama                    | P2        | 7    |
| F-26 | Monetisasi (program premium, tema kartu)                | P2        | 7    |
| F-27 | Heart rate via sensor/wearable                          | P2        | 7    |

**Aturan scope:** apa pun yang tidak ada di tabel ini **tidak boleh** ditambahkan tanpa mencatat keputusan di `docs/DECISIONS.md`.

### Catatan terhadap gambar referensi

Gambar referensi menampilkan elemen yang **sengaja ditunda atau diubah**:

| Elemen di referensi                      | Keputusan                                                                                                                        |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Tab "Community"                          | Tidak ada di MVP. Diganti tab **Profil**. Tab Community muncul di Fase 7                                                         |
| Kartu "Challenge 10K Runner" di Home     | Fase 5 (F-20). Di MVP slot itu diisi kartu "Program/Preset interval rekomendasi"                                                 |
| Heart rate (162 bpm) di layar lari       | Tidak ditampilkan di MVP karena belum ada sensor. Slot ketiga diisi **Kalori (perkiraan)**. Dilarang menampilkan angka bpm palsu |
| Angka contoh (24.8 km, 1,420 kcal, dst.) | Hanya contoh visual. Aplikasi hanya menampilkan data nyata pengguna                                                              |
| Teks Inggris "Ready for your next run?"  | Dilokalkan ke Indonesia, brand tagline tetap Inggris                                                                             |

---

## 4. User Flows

### 4.1 Flow pengguna baru

```text
Splash → Intro (3 slide, bisa Lewati) → Get Started
  → Daftar/Masuk (email / Google / Apple)
  → Profil awal: nama → tujuan → level pengalaman → target mingguan
  → Home (tanpa meminta izin lokasi dulu)
```

Izin lokasi diminta **saat pertama kali menekan Mulai Lari**, dengan layar penjelasan sendiri sebelum dialog sistem muncul.

### 4.2 Flow inti: sesi lari/jalan

```text
Home → [Mulai Lari]
  → Pra-sesi (bottom sheet): pilih mode [Bebas | Interval | Program] + status GPS
  → (Interval) pilih preset atau kustom → [Mulai]
  → Countdown 3-2-1
  → Layar Aktif (rekam, panduan suara)
      ├─ Jeda / Lanjut
      ├─ Kunci layar
      └─ Selesai (tekan-tahan 1,5 detik atau konfirmasi dialog)
  → Ringkasan Sesi: peta, statistik, split, "Bagaimana rasanya?" [Mudah | Pas | Berat]
      ├─ Simpan (default)
      ├─ Buang (konfirmasi)
      └─ Bagikan → Pilih kartu → Bagikan ke aplikasi lain / simpan ke galeri
  → Kembali ke Home dengan statistik terbarui
```

### 4.3 Flow pemulihan

Jika aplikasi tertutup/crash saat sesi aktif, saat dibuka lagi tampilkan dialog: **"Ada sesi yang belum selesai (dimulai 06.12, 3,4 km). Lanjutkan, simpan, atau buang?"**

### 4.4 Flow edge case

| Kondisi                      | Perilaku                                                                                          |
| ---------------------------- | ------------------------------------------------------------------------------------------------- |
| GPS lemah saat mulai         | Tampilkan "Mencari sinyal GPS…", izinkan mulai setelah 10 detik atau tekan "Mulai tanpa menunggu" |
| Izin lokasi ditolak          | Layar penjelasan + tombol buka Pengaturan. Tawarkan mode manual/indoor (Fase 5)                   |
| Baterai ≤ 10%                | Peringatan satu kali; tawarkan mode hemat baterai                                                 |
| Sesi < 100 m atau < 60 detik | Saat selesai tanya "Sesi sangat pendek, tetap simpan?"                                            |
| Tanpa internet               | Semua berjalan; sinkron otomatis saat online                                                      |

---

## 5. Struktur Aplikasi: Sitemap dan Inventaris Layar

### 5.1 Navigasi

Bottom navigation (4 tab, label selalu terlihat): **Home · Lari · Aktivitas · Profil**. Tab "Lari" membuka sheet pra-sesi; sesi aktif adalah rute layar penuh tanpa bottom nav.

### 5.2 Sitemap

```text
RUNWILD
├── Onboarding
│   ├── S-01 Splash
│   ├── S-02 Intro (3 slide)
│   ├── S-03 Get Started / Masuk
│   ├── S-04 Daftar
│   ├── S-05 Masuk
│   ├── S-06 Lupa Kata Sandi
│   └── S-07 Profil Awal (nama · tujuan · level · target mingguan)
├── Tab: Home
│   ├── S-10 Home
│   └── S-11 Ringkasan Minggu (detail)
├── Tab: Lari
│   ├── S-20 Pra-sesi (bottom sheet pilih mode)
│   ├── S-21 Pilih Preset Interval
│   ├── S-22 Kustom Interval
│   ├── S-23 Penjelasan Izin Lokasi
│   ├── S-24 Countdown
│   ├── S-25 Layar Lari Aktif (+ varian interval, + varian dikunci, + varian jeda)
│   ├── S-26 Ringkasan Sesi
│   └── S-27 Kartu Bagikan (pilih tema/format)
├── Tab: Aktivitas
│   ├── S-30 Daftar Aktivitas (filter: semua / lari / jalan / interval; kelompok per bulan)
│   ├── S-31 Detail Aktivitas (peta, statistik, split, interval, catatan)
│   └── S-32 Edit Aktivitas (judul, catatan, hapus)
├── Progress (dibuka dari Home → kartu "Progress")
│   ├── S-40 Progress (mingguan/bulanan, grafik)
│   └── S-41 Rekor Pribadi
├── Tab: Profil
│   ├── S-50 Profil
│   ├── S-51 Pengaturan
│   │   ├── S-52 Satuan & Tampilan
│   │   ├── S-53 Suara & Getar
│   │   ├── S-54 Privasi (zona samar, visibilitas default)
│   │   ├── S-55 Target Mingguan
│   │   └── S-56 Akun (ubah email/sandi, hapus akun & data)
│   └── S-57 Tentang (versi, lisensi, kebijakan privasi)
├── Fase 5+: S-60 Program, S-61 Detail Program, S-62 Tantangan, S-63 Badge, S-64 Pengingat
└── Sistem: S-90 Pemulihan Sesi, S-91 Offline/Error, S-92 Update Wajib
```

### 5.3 Inventaris layar (MVP)

`Tier` mengacu pada intensitas desain (bagian 9.4). A = maksimalis, B = seimbang, C = minimalis.

| ID      | Layar               | Tujuan                                         | Komponen kunci                                                                                     | Data                           | Tier |
| ------- | ------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------ | ---- |
| S-01    | Splash              | Identitas brand sambil inisialisasi            | Logo RUNWILD, siluet gunung, garis diagonal                                                        | –                              | A    |
| S-02    | Intro               | Menjelaskan 3 nilai: Lari · Lacak · Berkembang | Foto/ilustrasi hitam-putih + aksen oranye, headline besar miring, indikator halaman, "Lewati"      | –                              | A    |
| S-03    | Get Started         | Gerbang masuk                                  | Tombol utama "Mulai Sekarang", tombol sekunder "Masuk"                                             | –                              | A    |
| S-04/05 | Daftar/Masuk        | Autentikasi                                    | Field, tombol Google/Apple, error inline                                                           | `users`                        | C    |
| S-07    | Profil Awal         | Personalisasi ringan                           | Chip pilihan tujuan, level, stepper target mingguan                                                | `users`                        | B    |
| S-10    | Home                | Pintu utama                                    | Salam, tombol **Mulai Lari** besar, 4 tile aksi, kartu "Minggu Ini", kartu rekomendasi             | `stats`, `activities` (7 hari) | B    |
| S-20    | Pra-sesi            | Memilih mode                                   | 3 kartu mode, indikator GPS, tombol Mulai                                                          | `presets`                      | B    |
| S-22    | Kustom Interval     | Mengatur interval                              | Stepper durasi, jumlah putaran, mulai dari, **total durasi live**, simpan sebagai preset           | `presets`                      | C    |
| S-23    | Penjelasan Izin     | Konteks sebelum dialog sistem                  | Ilustrasi, 3 alasan singkat, tombol lanjut                                                         | –                              | B    |
| S-25    | Lari Aktif          | Merekam dan memandu                            | Peta gelap + rute oranye, angka jarak besar, 3 stat, panel fase, kontrol (kunci · jeda · pusatkan) | sesi lokal                     | C    |
| S-26    | Ringkasan           | Merayakan dan menyimpan                        | Header besar, peta rute, statistik, split, pilihan perasaan, Simpan/Bagikan                        | sesi lokal                     | A/B  |
| S-27    | Kartu Bagikan       | Membuat gambar                                 | Pratinjau, pemilih tema, pemilih format, tombol Bagikan/Simpan                                     | aktivitas                      | A    |
| S-30    | Aktivitas           | Riwayat                                        | Daftar kartu ringkas, filter chip, header bulan                                                    | `activities`                   | C    |
| S-31    | Detail              | Melihat satu sesi                              | Peta interaktif, grid statistik, tabel split, ringkasan interval, tombol Bagikan                   | `activities` + track           | B    |
| S-40    | Progress            | Melihat tren                                   | Grafik batang mingguan, pemilih periode, total                                                     | `stats`                        | B    |
| S-50–57 | Profil & Pengaturan | Konfigurasi                                    | Daftar bergrup, toggle, dialog konfirmasi                                                          | `users`                        | C    |

### 5.4 Standar state setiap layar (wajib)

Setiap layar harus mengimplementasikan: **loading** (skeleton, bukan spinner kosong), **empty** (pesan jujur + satu aksi), **error** (pesan manusiawi + coba lagi), **offline**, dan **content**. Dilarang ada layar yang hanya bagus pada kondisi "data penuh".

---

## 6. Spesifikasi Fitur Detail

### 6.1 Pelacakan GPS (F-04, F-05, F-06)

**Akuisisi lokasi**

| Parameter | Nilai awal                                                                                                           |
| --------- | -------------------------------------------------------------------------------------------------------------------- |
| Akurasi   | High / best-for-navigation                                                                                           |
| Android   | Foreground service bertipe `location` dengan notifikasi persisten "RUNWILD sedang merekam"                           |
| iOS       | Background mode `location` + `showsBackgroundLocationIndicator = true`, `pausesLocationUpdatesAutomatically = false` |
| Interval  | ≈ 1 detik, `distanceFilter` ≈ 3–5 m                                                                                  |
| Wakelock  | Aktif hanya saat layar lari terlihat                                                                                 |

**Penyaringan titik (wajib, bisa disetel di satu file konstanta):**

| Aturan                        | Nilai                                           |
| ----------------------------- | ----------------------------------------------- |
| Buang jika akurasi horizontal | > 30 m                                          |
| Buang jika kecepatan tersirat | > 12 m/s (43 km/j)                              |
| Abaikan pergeseran            | < 3 m dari titik terakhir saat bergerak lambat  |
| Jarak                         | Jumlah haversine antar titik valid              |
| Waktu bergerak (`movingTime`) | Total waktu dikurangi waktu jeda dan auto-pause |

**Auto-pause:** kecepatan < 0,5 m/s selama 8 detik → jeda otomatis; kecepatan > 1,0 m/s selama 2 detik → lanjut. Bisa dimatikan di pengaturan. Tampilkan banner "Dijeda otomatis".

**Pace:**

- _Pace saat ini_: rata-rata bergulir 15 detik. Jika data < 15 detik atau jarak < 20 m, tampilkan `--'--"`.
- _Pace rata-rata_: `movingTime / distance`.
- Format tampilan: `5'50"/km` (satuan mengikuti pengaturan).

**Indikator GPS (pill di kanan atas):** ≤ 10 m = 3 batang "Bagus"; ≤ 20 m = 2; ≤ 35 m = 1; selain itu = "Mencari". Jangan mengandalkan warna saja; sertakan jumlah batang dan label.

**Kalori (perkiraan):** `kcal = MET × beratKg × jam`. Jika berat belum diisi pakai 60 kg dan beri label "perkiraan" serta ajakan mengisi berat. Tabel MET berdasarkan kecepatan (nilai perkiraan dari Compendium of Physical Activities; agent wajib memverifikasi dan mencatat sumber di `DECISIONS.md`):

| Kecepatan (km/j) | MET     |
| ---------------- | ------- |
| < 3,2            | 2,8     |
| 3,2–4,8          | 3,5     |
| 4,8–6,4          | 4,3–5,0 |
| 6,4–8,0          | 7,0     |
| 8,0–9,7          | 8,3     |
| 9,7–11,3         | 9,8     |
| 11,3–12,9        | 11,0    |
| > 12,9           | 11,8    |

**Persistensi sesi (wajib untuk PG-5):**

- Tulis setiap titik valid ke SQLite lokal (Drift) dalam batch ≤ 5 detik.
- Simpan snapshot status sesi (fase interval, waktu aktif, jeda) tiap 5 detik.
- Saat sesi selesai: bangun ringkasan → simpan lokal → antre sinkron ke Firebase.
- **Waktu selalu dihitung dari jam monoton / timestamp, bukan penghitung `Timer` per detik**, agar tidak melenceng saat layar mati.

### 6.2 Mode Interval Jalan/Lari (F-07, F-08)

**Konfigurasi:**

| Field                      | Rentang         | Default |
| -------------------------- | --------------- | ------- |
| Pemanasan (jalan santai)   | 0–15 mnt        | 5 mnt   |
| Durasi **Lari**            | 10 dtk – 60 mnt | 1 mnt   |
| Durasi **Jalan**           | 10 dtk – 60 mnt | 2 mnt   |
| Jumlah putaran             | 1–50            | 8       |
| Mulai dari                 | Jalan / Lari    | Jalan   |
| Pendinginan (jalan santai) | 0–15 mnt        | 5 mnt   |

UI kustom wajib menampilkan **total durasi dan perkiraan jumlah lari** secara langsung saat nilai diubah (contoh: "Total 41 menit · 8× lari 1 menit").

**Preset bawaan:**

| Nama          | Susunan                       | Untuk                                        |
| ------------- | ----------------------------- | -------------------------------------------- |
| Pemula Santai | Lari 1 mnt / Jalan 2 mnt × 8  | Baru mulai                                   |
| Klasik 1:1    | Lari 1 mnt / Jalan 1 mnt × 10 | Sudah terbiasa jalan cepat                   |
| 5 : 1         | Jalan 5 mnt / Lari 1 mnt × 6  | Contoh dari pemilik produk, mulai dari Jalan |
| Naik Level    | Lari 2 mnt / Jalan 1 mnt × 8  | Siap menambah lari                           |

Pengguna dapat menyimpan preset sendiri (maks 20) dan mengganti nama/hapus.

**State machine (satu mesin, diuji unit penuh):**

```text
idle → countdown → warmup → [ run ⇄ walk ] × N → cooldown → finished
                      ↑ semua state aktif dapat → paused → kembali ke state sebelumnya
```

- Batas fase dihitung dari **waktu aktif kumulatif** (tidak termasuk jeda), dari satu sumber waktu monoton.
- Mesin interval adalah kelas Dart murni tanpa dependensi UI/plugin, sehingga bisa diuji dengan jam palsu.
- Jika pengguna menjeda saat fase berjalan, sisa waktu fase dipertahankan.

**Panduan suara (TTS bahasa Indonesia; fallback nada pendek bila TTS tidak tersedia):**

| Momen                 | Teks                                             | Getar     |
| --------------------- | ------------------------------------------------ | --------- |
| Mulai sesi            | "Mulai. Pemanasan jalan santai."                 | 1 pendek  |
| 10 dtk sebelum pindah | "Sepuluh detik lagi." (opsional)                 | –         |
| Pindah ke Lari        | "Sekarang mulai lari."                           | 2 pendek  |
| Pindah ke Jalan       | "Sekarang jalan."                                | 1 panjang |
| Putaran selesai       | "Bagus. Satu putaran selesai." (dapat dimatikan) | –         |
| Pendinginan           | "Pendinginan. Jalan santai."                     | 1 panjang |
| Selesai               | "Selesai. Kerja bagus."                          | 3 pendek  |
| Jeda / lanjut         | "Dijeda." / "Lanjut."                            | 1 pendek  |

- Audio **menurunkan volume** musik lain (audio ducking), tidak menghentikannya.
- Volume suara dan bahasa dapat diatur; suara bisa dimatikan sementara getar tetap aktif.
- Notifikasi persisten menampilkan fase dan sisa waktu.

**Panel fase di layar aktif:** label besar **JALAN** atau **LARI** + ikon, sisa waktu fase, bilah progres fase, dan "Putaran 3/8". Perbedaan fase tidak boleh hanya warna: gunakan label, ikon, dan pola getar berbeda. Warna: LARI = oranye solid, JALAN = permukaan netral dengan garis oranye.

### 6.3 Ringkasan Sesi (F-09)

Menampilkan: peta rute dengan titik awal (hijau) dan finis (bendera kotak-kotak), jarak, waktu bergerak, pace rata-rata, kalori (perkiraan), split per km (tabel; split terakhir parsial), ringkasan interval (putaran selesai, total waktu lari vs jalan), dan pertanyaan **"Bagaimana rasanya?"** dengan tiga pilihan (Mudah / Pas / Berat). Pilihan ini membantu program dan rekomendasi kelak.

### 6.4 Kartu Bagikan (F-10)

| Properti | Spesifikasi                                                                                                                             |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Format   | Story 1080×1920 (9:16) dan Kotak 1080×1080 (1:1)                                                                                        |
| Tema     | **Gelap Peta** (mirip layar lari), **Kertas** (terang, tipografis), **Bold** (maksimalis: tanpa peta, rute sebagai bentuk grafis besar) |
| Isi      | Rute, jarak (angka terbesar), waktu, pace, tanggal, wordmark RUNWILD                                                                    |
| Rute     | Digambar sebagai vektor (CustomPainter) dari polyline: cepat, offline, tanpa lisensi tile                                               |
| Privasi  | Default memotong 200 m pertama dan terakhir rute dan menyembunyikan titik awal; toggle di layar kartu                                   |
| Output   | PNG via `RepaintBoundary.toImage`, dibagikan lewat `share_plus` dan bisa disimpan ke galeri                                             |

### 6.5 Riwayat dan Detail (F-11)

- Daftar dikelompokkan per bulan, paginasi (20 per halaman) dari cache lokal, disinkronkan dengan Firestore.
- Kartu daftar: ikon tipe, judul (default "Lari Pagi/Siang/Sore/Malam" berdasar jam), tanggal, jarak, waktu, pace, thumbnail rute vektor.
- Detail: peta (Google Maps gaya gelap) dengan rute penuh dari file track, grid statistik, tabel split, ringkasan interval, catatan, ubah judul, hapus (konfirmasi).

### 6.6 Home dan Progress (F-12, F-13)

- **Kartu "Minggu Ini"**: jarak, durasi, kalori (perkiraan), 7 batang Senin–Minggu (hari ini disorot oranye). Rentang tanggal tampil sebagai "20–26 Jan" sesuai lokal.
- **Target mingguan** (pilih satu): jarak, jumlah sesi, atau durasi. Default: 3 sesi.
- **Kartu rekomendasi**: jika belum pernah berlari → "Coba Pemula Santai"; jika ada sesi → sesi berikutnya dari program (Fase 5) atau "Lanjutkan ritme".
- **Progress**: total per minggu/bulan, grafik batang, rekor pribadi (jarak terjauh, durasi terlama, pace 1 km terbaik, pace 5 km terbaik).
- Streak: **mingguan** = jumlah minggu beruntun mencapai target mingguan (F-17).

### 6.7 Auth, Onboarding, Profil (F-01, F-02, F-14, F-15)

- Firebase Auth: email+password, Google, Apple (wajib di iOS karena ada login pihak ketiga).
- Pengguna dapat memakai aplikasi sebagai tamu (anonymous auth) sebelum mendaftar, lalu menautkan akun tanpa kehilangan data.
- Hapus akun: konfirmasi ganda, menghapus dokumen Firestore, file Storage, dan akun Auth.
- Kolom opsional berat/tinggi/tahun lahir hanya untuk estimasi kalori; jelaskan kegunaannya.

---

## 7. Data: Kategori, Model, dan Aturan

### 7.1 Kategori data

| Kategori                     | Isi                                                  | Penyimpanan                                       | Sensitivitas     |
| ---------------------------- | ---------------------------------------------------- | ------------------------------------------------- | ---------------- |
| Akun & profil                | Nama, email, tujuan, level, satuan, berat (opsional) | Firestore `users/{uid}`                           | Pribadi          |
| Aktivitas (ringkasan)        | Jarak, waktu, pace, polyline sederhana, split        | Firestore `users/{uid}/activities`                | Pribadi + lokasi |
| Aktivitas (rute penuh)       | Titik GPS resolusi penuh                             | Cloud Storage `tracks/{uid}/{activityId}.json.gz` | Lokasi presisi   |
| Preset interval              | Konfigurasi interval kustom                          | Firestore `users/{uid}/presets`                   | Rendah           |
| Statistik agregat            | Total, rekor, streak                                 | Firestore `users/{uid}/stats/summary`             | Pribadi          |
| Progres program              | Minggu/sesi selesai                                  | Firestore `users/{uid}/programProgress`           | Rendah           |
| Badge                        | Badge yang sudah dibuka                              | Firestore `users/{uid}/badges`                    | Rendah           |
| Sesi aktif & antrean sinkron | Titik mentah, status                                 | SQLite lokal (Drift)                              | Lokasi presisi   |
| Konten statis                | Definisi program, badge, preset bawaan, string suara | Aset JSON di aplikasi (+ Remote Config nanti)     | Publik           |

> **Mengapa rute penuh tidak di Firestore:** dokumen Firestore dibatasi 1 MiB dan satu lari 1 jam bisa 3.600+ titik. Ringkasan + polyline sederhana (±300 titik) di Firestore untuk daftar cepat; rute penuh sebagai file terkompresi di Storage, diambil saat membuka Detail.

### 7.2 Skema Firestore

Semua ID dokumen aktivitas dibuat di klien (UUID v4) agar sinkron bersifat idempoten (aman diulang). Semua waktu disimpan UTC sebagai `Timestamp`. Semua jarak dalam **meter**, durasi dalam **detik**, kecepatan dalam **m/s**, pace dalam **detik per km** (konversi hanya di lapisan tampilan).

**`users/{uid}`**

| Field                         | Tipe      | Catatan                                                                           |
| ----------------------------- | --------- | --------------------------------------------------------------------------------- |
| displayName                   | string    |                                                                                   |
| email                         | string    |                                                                                   |
| photoUrl                      | string?   |                                                                                   |
| level                         | enum      | `pemula` \| `kembali` \| `rutin`                                                  |
| goal                          | enum      | `sehat` \| `lari_5k` \| `lari_10k` \| `turun_bb` \| `lainnya`                     |
| units                         | enum      | `km` \| `mi` (default `km`)                                                       |
| weightKg, heightCm, birthYear | number?   | opsional, untuk estimasi                                                          |
| weeklyGoal                    | map       | `{type: 'sessions'\|'distance'\|'duration', target: number}`                      |
| privacy                       | map       | `{hideStartEnd: true, trimMeters: 200, defaultVisibility: 'private'}`             |
| voice                         | map       | `{enabled: true, volume: 0.8, haptics: true, countdownCue: true, roundCue: true}` |
| autoPause                     | bool      | default true                                                                      |
| createdAt, updatedAt          | Timestamp |                                                                                   |
| schemaVersion                 | int       | mulai 1                                                                           |

**`users/{uid}/activities/{activityId}`**

| Field                              | Tipe       | Catatan                                                                                                                              |
| ---------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| type                               | enum       | `run` \| `walk` \| `run_walk`                                                                                                        |
| mode                               | enum       | `free` \| `interval` \| `program`                                                                                                    |
| title, note                        | string     |                                                                                                                                      |
| startedAt, endedAt                 | Timestamp  |                                                                                                                                      |
| movingTimeSec, elapsedTimeSec      | int        |                                                                                                                                      |
| distanceM                          | number     |                                                                                                                                      |
| avgSpeedMps                        | number     |                                                                                                                                      |
| avgPaceSecPerKm                    | number?    | null jika jarak sangat kecil                                                                                                         |
| bestPaceSecPerKm                   | number?    |                                                                                                                                      |
| elevationGainM                     | number?    | opsional (P1)                                                                                                                        |
| caloriesEst                        | number     | perkiraan                                                                                                                            |
| splits                             | array      | `[{index, distanceM, durationSec, paceSecPerKm}]`                                                                                    |
| polyline                           | string     | polyline ter-encode, disederhanakan                                                                                                  |
| bbox                               | map        | `{minLat, minLng, maxLat, maxLng}`                                                                                                   |
| startLat, startLng, endLat, endLng | number     | presisi penuh; samarkan **saat render/bagikan**, bukan saat simpan                                                                   |
| trackPath                          | string     | path file di Storage                                                                                                                 |
| trackPointCount                    | int        |                                                                                                                                      |
| interval                           | map?       | snapshot konfigurasi `{warmupSec, runSec, walkSec, rounds, startWith, cooldownSec}` + `{completedRounds, totalRunSec, totalWalkSec}` |
| programRef                         | map?       | `{programId, week, session}`                                                                                                         |
| feeling                            | enum?      | `mudah` \| `pas` \| `berat`                                                                                                          |
| visibility                         | enum       | `private` (default)                                                                                                                  |
| source                             | enum       | `gps` \| `manual` \| `health_import`                                                                                                 |
| deviceInfo                         | map        | `{platform, appVersion}`                                                                                                             |
| createdAt, updatedAt               | Timestamp  |                                                                                                                                      |
| deletedAt                          | Timestamp? | soft-delete untuk sinkron                                                                                                            |

**`users/{uid}/presets/{presetId}`:** `name, warmupSec, runSec, walkSec, rounds, startWith, cooldownSec, createdAt, updatedAt`.

**`users/{uid}/stats/summary`:** `totals {distanceM, movingTimeSec, count, calories}`, `weeklyStreak {current, longest, lastQualifiedWeek}`, `records {longestDistance {value, activityId}, longestDuration {...}, best1k {...}, best5k {...}}`, `updatedAt`.

**`users/{uid}/programProgress/{programId}`:** `startedAt, status ('active'|'paused'|'completed'), completedSessions [{week, session, activityId, completedAt}], reminderDays [1..7], reminderTime`.

**`users/{uid}/badges/{badgeId}`:** `unlockedAt, activityId?`.

> Agregat (`stats/summary`) dihitung di klien dan ditulis dalam **transaksi** saat aktivitas disimpan/dihapus. Cloud Functions tidak dipakai di MVP (paket Spark gratis tidak mendukungnya). Fungsi `recomputeStats()` harus ada untuk memperbaiki agregat dari seluruh aktivitas bila terjadi ketidakcocokan.

### 7.3 Database lokal (Drift/SQLite)

| Tabel              | Kolom penting                                                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| `active_session`   | id, mode, status, startedAt, activeSeconds, pausedSeconds, intervalConfigJson, phaseIndex, phaseElapsedSeconds, updatedAt |
| `track_points`     | sessionId, seq, ts, lat, lng, accuracy, altitude, speed                                                                   |
| `activities_cache` | salinan ringkasan aktivitas untuk daftar offline                                                                          |
| `pending_sync`     | id, entityType, entityId, operation, payloadJson, attempts, lastError                                                     |
| `settings_cache`   | key, value                                                                                                                |

### 7.4 Aturan keamanan (Firestore dan Storage)

- **Deny by default.** Hanya pemilik (`request.auth.uid == uid`) yang dapat membaca/menulis subtree `users/{uid}/**` dan `tracks/{uid}/**`.
- Validasi tipe, rentang, dan ukuran field di rules (misal `distanceM >= 0`, `title.size() <= 80`, file Storage ≤ 2 MB, `contentType` sesuai).
- Aktifkan **Firebase App Check** (Play Integrity / App Attest) sebelum rilis publik.
- Wajib ada tes rules memakai Firebase Emulator Suite (`@firebase/rules-unit-testing`).
- Indeks komposit yang dibutuhkan: `activities` pada `(deletedAt asc, startedAt desc)` dan `(type asc, startedAt desc)`. Catat setiap indeks di `docs/DATA_MODEL.md`.

---

## 8. Tech Stack dan Arsitektur

### 8.1 Stack

| Lapisan          | Pilihan                                                                                             | Alasan                                                                                                                                      |
| ---------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Framework        | **Flutter** (stable terbaru) + Dart                                                                 | Satu codebase, performa baik, ekosistem GPS/peta kuat                                                                                       |
| State            | `flutter_riverpod`                                                                                  | Testable, eksplisit                                                                                                                         |
| Routing          | `go_router`                                                                                         | Deklaratif, deep link                                                                                                                       |
| Model            | `freezed` + `json_serializable`                                                                     | Imutabel, aman tipe                                                                                                                         |
| Lokal DB         | `drift`                                                                                             | Query tipe-aman, migrasi, cocok untuk titik GPS                                                                                             |
| Backend          | **Firebase**: Auth, Firestore, Storage, Messaging, Crashlytics, Analytics, App Check, Remote Config | Sesuai keputusan pemilik                                                                                                                    |
| Peta             | `google_maps_flutter` dengan style JSON gelap                                                       | Maps SDK mobile tanpa biaya per-load; mudah digayakan agar cocok dengan referensi. Bungkus dalam `MapService` agar bisa diganti ke MapLibre |
| Lokasi           | `geolocator` (+ konfigurasi foreground service Android)                                             | Mature, mendukung background                                                                                                                |
| Suara            | `flutter_tts` (+ nada cadangan via `just_audio`), `HapticFeedback`/`vibration`                      |                                                                                                                                             |
| Notifikasi       | `flutter_local_notifications`, `firebase_messaging`                                                 |                                                                                                                                             |
| Wakelock         | `wakelock_plus`                                                                                     |                                                                                                                                             |
| Bagikan          | `share_plus`, `gal` (simpan ke galeri)                                                              |                                                                                                                                             |
| Izin             | `permission_handler`                                                                                |                                                                                                                                             |
| Kesehatan (F-22) | paket `health`                                                                                      | Health Connect + HealthKit                                                                                                                  |
| Lint/Format      | `very_good_analysis` atau `flutter_lints` ketat + `dart format`                                     |                                                                                                                                             |
| CI               | GitHub Actions: analyze, test, build                                                                |                                                                                                                                             |

> Agent **dilarang** menambah dependensi di luar tabel ini tanpa mencatat alasan, alternatif, dan ukuran dampak di `DECISIONS.md`. Semua versi paket dipin di `pubspec.yaml` (tanpa `any`).

### 8.2 Arsitektur: feature-first, berlapis

```text
lib/
├── main.dart · bootstrap.dart
├── app/                 # MaterialApp, router, tema, DI (provider root)
├── design/              # tokens, theme, komponen dasar (lihat bagian 9)
│   ├── tokens/          # warna, tipografi, spasi, radius, motion
│   ├── components/      # RwButton, RwCard, RwStatTile, RwChip, RwBottomNav, ...
│   └── decor/           # MountainSilhouette, DiagonalSlash, Halftone, SunArcs
├── core/
│   ├── constants/       # tuning GPS, ambang, batas
│   ├── services/        # location, audio_cue, haptics, notifications, share, map
│   ├── utils/           # format pace/jarak/durasi, haversine, polyline
│   └── error/           # tipe error, mapper pesan manusiawi
├── data/
│   ├── models/          # freezed models
│   ├── local/           # drift database + DAO
│   ├── remote/          # firestore/storage data source
│   └── repositories/    # ActivityRepository, UserRepository, PresetRepository, StatsRepository
├── domain/              # logika murni: TrackingEngine, IntervalEngine, StatsCalculator, BadgeRules
└── features/
    ├── onboarding/ · auth/ · home/ · run/ (setup, active, summary) · share/
    ├── activities/ · progress/ · profile/ · settings/ · plans/ (Fase 5)
    └── <feature>/ {presentation, application, (domain khusus fitur bila perlu)}
```

**Aturan lapisan:** `presentation` → `application` (controller/notifier) → `domain` + `data/repositories`. UI tidak memanggil Firebase atau plugin langsung. `domain/` tidak boleh mengimpor Flutter atau Firebase.

### 8.3 Konfigurasi platform yang wajib

**Android:** `minSdk` sesuai syarat plugin (≥ 24); izin `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `VIBRATE`. Mulai foreground service saat aplikasi terlihat sehingga **tidak perlu** meminta `ACCESS_BACKGROUND_LOCATION` (mengurangi hambatan review Play). Siapkan disclosure yang jelas untuk formulir Data Safety.

**iOS:** `UIBackgroundModes` → `location`; string `NSLocationWhenInUseUsageDescription` dan (jika dibutuhkan) `NSLocationAlwaysAndWhenInUseUsageDescription` dalam bahasa manusia dan jujur; `NSMotionUsageDescription` bila memakai pedometer; Sign in with Apple capability. Pengujian iOS wajib di perangkat fisik.

**Rahasia:** kunci Maps dan file konfigurasi Firebase tidak boleh ada di riwayat git yang bersifat rahasia; gunakan `--dart-define`/file lokal yang di-`.gitignore`, batasi kunci API per bundle ID/package + SHA-1.

---

## 9. Sistem Desain

> Bagian ini adalah **bahan baku `DESIGN.md`**. Agent harus membuat `DESIGN.md` di root dari bagian ini pada Fase 0. Arah desain ditentukan di sini; anti-slop bertugas menyaring hal yang generik.

### 9.1 Skill desain: anti-slop (WAJIB)

Repo: `https://github.com/miqdadbadjuber/anti-slop`. Anti-slop adalah **filter, bukan panduan gaya**: ia menolak desain, teks, dan kode yang terkesan generik buatan AI, tetapi **arah visual harus datang dari `DESIGN.md`**. Hasil yang hambar berarti arah desain kurang, bukan filternya gagal.

**Langkah untuk agent (Fase 0, sebelum menulis UI apa pun):**

1. Pasang: `npx antislop-ai`. Pilih skill: `antislop` (inti), `antislop-ui`, `antislop-copywriting`, `antislop-human`, `antislop-layoutmobile`, `antislop-code`. Jika installer tidak tersedia di lingkungan agent, unduh `antislop.md` dari repo (`raw.githubusercontent.com/miqdadbadjuber/anti-slop/main/antislop.md`) dan gunakan sebagai filter.
2. **Baca penuh** `antislop.md`/`SKILL.md` terpasang, termasuk 38 aturan (R-01–R-38), Liveliness Toolkit (ENERGY / RHYTHM / MOTION), dan Delivery Gate. Jangan mengandalkan ringkasan.
3. Gunakan mode **during** (aturan berlaku selama membangun; sesi ditutup dengan laporan **Delivery Gate PASS/FAIL**). Gunakan mode **after** untuk mengaudit hasil sebelum rilis.
4. Buat `DESIGN.md` dari bagian 9 ini.
5. Anti-slop awalnya berorientasi UI web. Terapkan **prinsipnya** (hierarki, kontras, tidak ada hiasan tanpa tujuan, teks jujur, state lengkap, tap target, aksesibilitas) ke Flutter. Jika sebuah aturan tidak berlaku untuk Flutter, catat pengecualiannya di `DECISIONS.md`, jangan diam-diam diabaikan.
6. **Tiap sesi kerja yang menyentuh UI/teks/kode ditutup dengan laporan Delivery Gate** yang ditempel di deskripsi PR.

### 9.2 Karakter visual: "Semi-Minimalis & Maksimalis"

Referensi: `docs/reference/runwild-reference.png`. Karakter yang harus ditangkap: **energik, atletis, outdoor, tegas**. Kombinasi foto hitam-putih bergaya editorial, aksen oranye menyala, siluet pegunungan, bentuk diagonal seperti sambaran, tipografi tebal miring, dan kartu berpermukaan lembut dengan sudut besar.

**Prinsip utama: "Maksimal di tepi, minimal di inti."**

| Tier              | Layar                                                                                              | Perlakuan                                                                                                                     |
| ----------------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **A, Maksimalis** | Splash, Intro, Get Started, header Ringkasan Sesi, Kartu Bagikan, badge terbuka, empty state besar | Tipografi raksasa miring, foto/ilustrasi hitam-putih, bentuk diagonal oranye, siluet gunung, halftone, ukuran kontras ekstrem |
| **B, Seimbang**   | Home, Pra-sesi, Detail Aktivitas, Progress, Profil Awal                                            | Satu elemen dekoratif kuat per layar (misal siluet gunung + lingkaran matahari di header Home) dan sisanya bersih             |
| **C, Minimalis**  | Layar Lari Aktif, daftar, form, pengaturan, kustom interval                                        | Permukaan datar, hierarki jelas, hampir tanpa hiasan. Dekorasi hanya di zona non-interaktif (maks 15% tinggi di bawah)        |

**Aturan keras:** dekorasi **tidak boleh** mengurangi keterbacaan angka saat berlari dan tidak boleh berada di bawah teks atau kontrol interaktif.

### 9.3 Token desain (agent menyalin ke `design/tokens/`)

> Nilai warna diperkirakan dari gambar referensi. Jika gambar tersedia di repo, agent boleh mengambil sampel piksel untuk menyempurnakan, lalu mencatat hasilnya di `DESIGN.md`.

**Warna**

| Token        | Hex       | Penggunaan                                 |
| ------------ | --------- | ------------------------------------------ |
| `ink-950`    | `#0B0B0C` | Latar layar gelap, teks pada oranye        |
| `ink-900`    | `#131315` | Permukaan gelap utama                      |
| `ink-800`    | `#1C1C1F` | Kartu pada mode gelap                      |
| `ink-700`    | `#2A2A2E` | Garis/pemisah gelap                        |
| `ink-500`    | `#6B6B72` | Teks sekunder pada terang                  |
| `paper-50`   | `#F7F3EE` | Latar layar terang (krem hangat)           |
| `paper-100`  | `#EFEAE3` | Kartu/permukaan terang                     |
| `paper-200`  | `#E3DDD4` | Garis/pemisah terang                       |
| `orange-500` | `#FF5A1F` | **Warna brand**: tombol utama, rute, aksen |
| `orange-600` | `#E8440C` | State ditekan                              |
| `orange-300` | `#FF8A5C` | Hover/aksen lembut                         |
| `orange-100` | `#FFE3D6` | Latar chip terpilih (terang)               |
| `orange-700` | `#C2410C` | **Teks oranye di atas latar terang**       |
| `go-500`     | `#2ECC71` | Titik awal rute, GPS bagus                 |
| `warn-500`   | `#FFB020` | Peringatan                                 |
| `danger-500` | `#E5484D` | Error, aksi destruktif                     |

**Aturan kontras (hasil hitung, wajib dipatuhi):**

- Teks di atas `orange-500` **selalu `ink-950`** (≈ 6,4:1). **Dilarang teks putih di atas oranye** (≈ 3,1:1, gagal untuk teks normal).
- `orange-500` sebagai **teks** hanya di atas latar gelap. Di atas latar terang gunakan `orange-700` (≈ 4,7:1) atau jadikan oranye sebagai isian, bukan teks.
- Semua kombinasi teks/latar harus ≥ 4,5:1 (teks normal) dan ≥ 3:1 (teks besar/ikon). Agent menambahkan tes otomatis untuk pasangan token.

**Tipografi**

| Peran                                       | Font        | Gaya                                                                                                                |
| ------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------- |
| Display / headline / wordmark / angka besar | **Archivo** | ExtraBold–Black, **miring (italic)**, huruf kapital untuk headline brand, tracking rapat                            |
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
| **Garis diagonal (slash)**                | Pita oranye bersudut tajam menyerupai sambaran      | Latar Intro/Get Started, dasar Splash | Maks 2 per layar       |
| **Lingkaran matahari + busur konsentris** | Lingkaran oranye dengan garis lengkung tipis        | Header Home                           | 1 per layar            |
| **Halftone**                              | Titik gradasi kecil                                 | Sudut kartu tier A                    | Tidak di belakang teks |
| **Bendera kotak-kotak**                   | Penanda finis di peta                               | Peta rute                             | Hanya di peta          |
| **Titik awal hijau**                      | Lingkaran hijau bergaris putih                      | Peta rute                             | Hanya di peta          |

Semua motif adalah SVG/`CustomPainter` buatan sendiri (tanpa aset berhak cipta pihak lain).

### 9.5 Foto dan ilustrasi

- Gaya: foto pelari **hitam-putih kontras tinggi** dengan satu aksen oranye (siluet pelari + pita oranye).
- Agent **dilarang** mengambil foto dari internet atau memakai stok yang lisensinya tidak jelas. Gunakan **placeholder bergaya** (blok siluet) yang ditandai `TODO(asset)` dan catat di checklist aset (bagian 14.3). Pemilik produk menyuplai foto berlisensi atau ilustrasi.
- Tidak ada ikon "sparkle/bintang AI", gradien ungu-biru, atau avatar generik buatan AI.

### 9.6 Spesifikasi komponen kunci

| Komponen                   | Spesifikasi                                                                                                                        |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **RwButton.primary**       | Pill, isian `orange-500`, teks `ink-950` SemiBold, tinggi 56, ikon opsional di kiri, state: default / pressed / disabled / loading |
| **RwButton.secondary**     | Pill, kontur 1,5 dp, isian transparan                                                                                              |
| **RwStatTile**             | Label kecil atas, angka besar tabular, satuan kecil, ikon garis oranye                                                             |
| **RwWeekBars**             | 7 batang, hari ini oranye solid, lainnya netral, label hari di bawah                                                               |
| **RwMetricRow (lari)**     | Kartu pill gelap dengan 3 kolom (Durasi · Pace · Kalori) dan pembatas tipis                                                        |
| **PhaseBanner (interval)** | Label LARI/JALAN besar, sisa waktu, bilah progres, "Putaran n/N"                                                                   |
| **RwBottomNav**            | 4 item, ikon garis + label, aktif oranye dengan indikator atas                                                                     |
| **GpsPill**                | Batang sinyal + label, pojok kanan atas                                                                                            |
| **RouteMap**               | Peta gelap, garis rute oranye 5 dp dengan tepi halus, titik hijau awal, bendera finis                                              |
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
│ [🔒]      ( ❚❚ JEDA )     [◎]  │  kunci · jeda (oranye, besar) · pusatkan
│  ▲ siluet gunung samar di dasar│  non-interaktif, ≤ 15% tinggi
└──────────────────────────────┘
```

- Mode jeda: tombol berubah menjadi **Lanjut** (oranye) + **Selesai** (sekunder); statistik tidak berubah.
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
- [ ] Kontras lolos; tidak ada teks putih di atas oranye
- [ ] Tes di layar kecil (360×640 dp) dan besar (430×932 dp) tanpa overflow
- [ ] Tes dengan teks sistem 130% dan 200%
- [ ] Teks sesuai aturan copy; tidak ada data palsu
- [ ] Laporan Delivery Gate anti-slop: **PASS**

---

## 10. Aturan Pengembangan (Engineering Rules)

### 10.1 Proses kerja agent

1. **Baca dulu**: PRD, `DESIGN.md`, `DECISIONS.md`, dan kode terkait sebelum mengubah.
2. **Rencana singkat** (5–10 baris): apa yang diubah, file yang disentuh, risiko, cara verifikasi.
3. **Implementasi kecil dan bertahap**; satu PR/commit = satu hal yang koheren.
4. **Verifikasi**: `dart format`, `flutter analyze` (0 warning), tes relevan lulus, jalankan aplikasi bila UI berubah.
5. **Laporan**: ringkas apa yang selesai, apa yang tidak, keputusan baru, langkah berikutnya, dan Delivery Gate untuk perubahan UI/teks.
6. **Jangan mengklaim selesai tanpa bukti** (hasil tes, tangkapan layar, log). Jika sesuatu tidak bisa diuji (misal GPS nyata), katakan terus terang dan tambahkan ke daftar uji lapangan di `TESTING.md`.

### 10.2 Aturan kode (R-DEV)

| ID       | Aturan                                                                                                                                |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| R-DEV-01 | Null safety penuh; dilarang `dynamic` dan `!` tanpa alasan tercatat                                                                   |
| R-DEV-02 | Model imutabel (`freezed`); tidak ada map mentah menyebar di UI                                                                       |
| R-DEV-03 | UI tidak memanggil Firebase/plugin langsung; lewat repository/service                                                                 |
| R-DEV-04 | `domain/` bebas Flutter & Firebase, ditest unit                                                                                       |
| R-DEV-05 | Tidak ada angka ajaib: semua ambang GPS/interval di `core/constants/`                                                                 |
| R-DEV-06 | Semua string tampilan lewat sistem lokalisasi (`intl`/ARB), bukan hardcode di widget                                                  |
| R-DEV-07 | Semua warna/ukuran/radius dari token desain                                                                                           |
| R-DEV-08 | Penanganan error eksplisit; tidak ada `catch (_) {}` kosong; error ditampilkan manusiawi dan dicatat ke Crashlytics tanpa data lokasi |
| R-DEV-09 | Semua operasi async dibatalkan dengan benar saat layar ditutup; tidak ada kebocoran stream/subscription                               |
| R-DEV-10 | Waktu sesi memakai jam monoton/timestamp, bukan hitungan `Timer`                                                                      |
| R-DEV-11 | Penulisan Firestore idempoten (ID dari klien) dan mendukung antrean offline                                                           |
| R-DEV-12 | Tidak ada kode mati, `TODO` tanpa tiket/ID PRD, atau komentar yang hanya mengulang kode (anti-slop-code)                              |
| R-DEV-13 | Dependensi baru memerlukan entri di `DECISIONS.md`                                                                                    |
| R-DEV-14 | Tidak ada kredensial, kunci, atau data pribadi di repo atau log                                                                       |
| R-DEV-15 | Migrasi Drift dan `schemaVersion` Firestore dikelola eksplisit; perubahan skema memperbarui `DATA_MODEL.md`                           |
| R-DEV-16 | Fungsi publik di `domain/` dan `core/utils/` memiliki dokumentasi singkat dan tes                                                     |

### 10.3 Standar pengujian

| Jenis                        | Cakupan wajib                                                                                                                   |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Unit                         | Haversine, filter titik, pace, split, kalori, `IntervalEngine` (semua transisi, jeda, batas), `StatsCalculator`, streak, format |
| Widget                       | Komponen design system, layar kunci dengan semua state                                                                          |
| Golden                       | Komponen kunci (tombol, stat tile, phase banner, kartu bagikan) pada tema gelap dan terang                                      |
| Integrasi                    | Alur: daftar → profil → mulai sesi (lokasi disimulasikan) → selesai → simpan → muncul di riwayat                                |
| Rules                        | Firestore/Storage rules via Emulator (akses silang pengguna ditolak)                                                            |
| Uji lapangan (manual, wajib) | Jalan/lari rute nyata: bandingkan jarak, layar mati 60 menit, app di-kill, mode pesawat, baterai, Android & iOS fisik           |

Target awal: cakupan `domain/` ≥ 90%, keseluruhan ≥ 70%.

### 10.4 Git dan CI

- Branch: `main` (stabil), `feat/F-07-interval-engine`, `fix/...`. Commit mengikuti Conventional Commits (`feat(run): ...`, `fix(sync): ...`) dan menyebut ID PRD.
- CI wajib hijau sebelum merge: format, analyze, test, build debug Android.
- Setiap fase ditutup dengan tag (`v0.1.0` dst.) dan entri `CHANGELOG.md`.

### 10.5 Keamanan, privasi, kepatuhan

- Minimisasi data: hanya kumpulkan yang dibutuhkan; berat/tinggi/tahun lahir opsional.
- Persetujuan analytics eksplisit; tidak ada koordinat di analytics/Crashlytics.
- Siapkan: Kebijakan Privasi, penjelasan penggunaan lokasi latar (untuk Play dan App Store), formulir Data Safety / App Privacy, fitur hapus akun dan data.
- Disclaimer kesehatan: "RUNWILD bukan alat medis. Konsultasikan dengan dokter sebelum memulai program olahraga baru jika ada kondisi kesehatan tertentu."

---

## 11. Roadmap dan Milestone

Estimasi bersifat perkiraan untuk satu pengembang dengan bantuan agent AI, dan harus dikoreksi setelah Fase 1.

### Fase 0 — Fondasi (±3–5 hari)

**Output:** proyek Flutter, struktur folder, CI, Firebase (proyek dev + prod), anti-slop terpasang, `DESIGN.md`, token + tema + komponen dasar (`RwButton`, `RwCard`, `RwChip`, `RwStatTile`), router + bottom nav kosong, katalog komponen (layar debug).
**DoD:** `flutter analyze` bersih; aplikasi berjalan di Android dan iOS; katalog komponen tema gelap dan terang tampil sesuai bagian 9; laporan Delivery Gate PASS; semua dokumen di 0.3 ada.

### Fase 1 — Onboarding dan Auth (±4–6 hari) — F-01, F-02

**Output:** S-01–S-07 lengkap; Firebase Auth (email, Google, Apple, tamu); profil awal tersimpan; rules + tes rules dasar.
**DoD:** pengguna baru mencapai Home ≤ 90 detik; error auth manusiawi; sesi login bertahan setelah restart; tes rules lulus.

### Fase 2 — Tracking Inti (±8–12 hari) — F-03, F-04, F-05, F-06

**Output:** layar penjelasan izin, `TrackingEngine`, foreground service/background iOS, penyaringan titik, auto-pause, kunci layar, persistensi Drift, pemulihan sesi, layar Lari Aktif (mode bebas) sesuai 9.7.
**DoD:** uji lapangan jalan 30 menit, jarak dalam ±3% dari referensi; layar mati 60 menit tetap merekam di Android dan iOS; app di-kill lalu dipulihkan tanpa kehilangan data; unit test engine ≥ 90%.

### Fase 3 — Interval, Ringkasan, Bagikan (±8–12 hari) — F-07, F-08, F-09, F-10

**Output:** `IntervalEngine`, preset + kustom, panduan suara/getar/notifikasi, ringkasan sesi, kartu bagikan (3 tema × 2 format), sinkron ke Firestore/Storage.
**DoD:** panduan fase tepat (≤ 1 dtk) selama 60 menit layar mati; audio menurunkan volume musik, tidak menghentikannya; kartu bagikan terbuka benar di Instagram Story dan WhatsApp; sinkron offline → online berhasil tanpa duplikasi.

### Fase 4 — Riwayat, Home, Progress, Profil (±7–10 hari) — F-11–F-15

**Output:** S-10, S-11, S-30–S-32, S-40, S-41, S-50–S-57; agregat statistik; hapus akun dan data.
**DoD:** semua state layar (loading/empty/error/offline) ada; angka Home cocok dengan data; hapus akun benar-benar menghapus data; **siap beta tertutup**.

### ★ Milestone MVP: akhir Fase 4

Rilis **TestFlight / Internal Testing**. Pemilik memakai sendiri minimal 4 minggu; rekrut 5–10 penguji pemula. Kumpulkan: layar mana yang membuat bingung, titik GPS gagal, baterai.

### Fase 5 — Pembeda Pemula (±10–14 hari) — F-16–F-21

Program 0→5K, streak mingguan + badge, pengingat, pemanasan/pendinginan, tantangan bawaan, ekspor GPX, mode indoor.
**DoD:** program 8 minggu dapat diselesaikan end-to-end; pengingat muncul tepat waktu; badge terbuka benar.

### Fase 6 — Integrasi dan Keselamatan (±7–10 hari) — F-22–F-24

Health Connect/Apple Health, live location sharing + kontak darurat, kontrol musik.

### Fase 7 — Sosial ringan dan Monetisasi (±10–15 hari) — F-25–F-27

Teman, grup kecil, tantangan bersama (tab Community), program premium/tema kartu, heart rate sensor. Mulai **hanya jika** BG-2 tercapai.

### Fase 8 — Persiapan rilis publik

App Check, performa, aksesibilitas penuh, aset toko, kebijakan privasi, review Play/App Store, rencana dukungan.

---

## 12. Analytics, Observability, QA

| Event                   | Parameter (tanpa lokasi)                                          |
| ----------------------- | ----------------------------------------------------------------- |
| `onboarding_completed`  | `goal`, `level`                                                   |
| `run_started`           | `mode`, `preset_id?`                                              |
| `run_finished`          | `mode`, `duration_bucket`, `distance_bucket`, `completed_rounds?` |
| `run_discarded`         | `reason?`                                                         |
| `session_recovered`     | `action`                                                          |
| `share_card_created`    | `theme`, `format`                                                 |
| `interval_preset_saved` | –                                                                 |
| `permission_result`     | `type`, `granted`                                                 |

- Crashlytics: aktif; ganti pengenal pengguna dengan UID hash; tanpa koordinat.
- Log lokal (debug) untuk kualitas GPS: persentase titik dibuang, akurasi rata-rata. Dipakai saat uji lapangan, tidak dikirim.
- Matriks uji perangkat minimum: 2 Android (satu merek dengan manajemen baterai agresif, misal Xiaomi/Oppo/Vivo) dan 1 iPhone fisik. Dokumentasikan langkah "izinkan app berjalan di latar" untuk merek Android tersebut di dalam aplikasi (halaman bantuan singkat).

---

## 13. Prompting untuk AI Agent

### 13.1 Prinsip prompting

- Satu sesi = satu fase atau satu fitur. Sertakan ID PRD.
- Selalu minta **rencana dulu, lalu implementasi, lalu bukti verifikasi**.
- Minta agent melaporkan keputusan dan hal yang tidak bisa diuji.
- Untuk UI: selalu minta laporan Delivery Gate anti-slop.

### 13.2 Kickoff Prompt (tempel di sesi pertama)

```text
Kamu adalah engineer Flutter senior sekaligus desainer produk yang membangun aplikasi mobile "RUNWILD".

Sumber kebenaran: docs/PRD.md. Baca SELURUH dokumen itu sebelum bertindak, lalu baca juga docs/reference/runwild-reference.png untuk arah visual.

Tugasmu sekarang: kerjakan FASE 0 (Fondasi) dari PRD bagian 11.

Langkah:
1. Ringkas pemahamanmu tentang produk, MVP, dan aturan (maks 15 baris) dan sebutkan asumsi yang kamu ambil.
2. Pasang skill anti-slop (https://github.com/miqdadbadjuber/anti-slop) sesuai PRD bagian 9.1: jalankan `npx antislop-ai`, pilih skill antislop, antislop-ui, antislop-copywriting, antislop-human, antislop-layoutmobile, antislop-code. Baca penuh aturannya. Gunakan mode "during". Umumkan "antislop active" di awal.
3. Buat struktur dokumen (PRD bagian 0.3) dan DESIGN.md dari PRD bagian 9.
4. Inisialisasi proyek Flutter dengan struktur folder PRD bagian 8.2, dependensi hanya dari tabel PRD 8.1 (pin versi).
5. Implementasikan token desain, tema gelap/terang, komponen dasar, router + bottom nav, dan layar katalog komponen.
6. Siapkan CI (format, analyze, test).
7. Verifikasi: format, analyze, test, jalankan aplikasi. Tampilkan bukti.
8. Tutup dengan laporan: yang selesai, keputusan baru (catat di DECISIONS.md), yang belum bisa diverifikasi, dan laporan Delivery Gate (PASS/FAIL per blok).

Aturan keras: ikuti PRD bagian 10 (aturan pengembangan) dan bagian 9 (aturan desain). Jangan menambah fitur di luar PRD. Jangan memakai data palsu di UI. Jangan mengambil foto dari internet. Jangan berhenti untuk bertanya hal yang bisa kamu putuskan sendiri; catat keputusannya. Bertanya hanya jika terblokir.
```

### 13.3 Template prompt per fase/fitur

```text
Konteks: RUNWILD, docs/PRD.md adalah sumber kebenaran. antislop aktif (mode during).

Kerjakan: FASE <n> — <nama fase> (fitur <F-xx, F-yy>).

Sebelum menulis kode:
- Baca PRD bagian <bagian relevan>, DESIGN.md, DECISIONS.md, dan kode yang sudah ada.
- Berikan rencana 5–10 baris: file yang disentuh, risiko, cara verifikasi.

Saat mengerjakan:
- Ikuti R-DEV-01 s.d. R-DEV-16 dan aturan desain PRD bagian 9.
- Tiap layar wajib punya state loading/empty/error/offline/content.
- Tulis tes sesuai PRD 10.3. Logika murni wajib punya unit test.

Selesai bila Definition of Done fase <n> di PRD bagian 11 terpenuhi.

Laporan akhir: (1) apa yang selesai per ID PRD, (2) bukti verifikasi (hasil tes, tangkapan layar), (3) yang tidak bisa diuji di sini + langkah uji lapangan untuk saya, (4) keputusan baru, (5) Delivery Gate anti-slop.
```

### 13.4 Prompt khusus yang sering dipakai

**Mesin interval (Fase 3):**

```text
Implementasikan IntervalEngine sebagai kelas Dart murni di lib/domain/ sesuai PRD 6.2. Tanpa dependensi Flutter/plugin. Terima sumber waktu (Clock) lewat injeksi agar bisa diuji dengan jam palsu. Tulis tes untuk: urutan fase, mulai dari Jalan/Lari, pemanasan/pendinginan 0 menit, jeda di tengah fase, jeda berulang, putaran terakhir, batas minimum/maksimum, dan tidak ada drift pada simulasi 60 menit. Setelah engine lulus, sambungkan ke AudioCueService dan layar aktif.
```

**Tracking background (Fase 2):**

```text
Implementasikan TrackingEngine dan layanan lokasi sesuai PRD 6.1 dan 8.3. Prioritas: tidak boleh ada sesi yang hilang. Simpan titik ke Drift tiap ≤5 detik, snapshot status tiap 5 detik, dan pulihkan sesi saat app dibuka ulang. Beri tahu saya dengan jelas apa yang tidak bisa kamu verifikasi tanpa perangkat fisik, lalu tulis skrip/instruksi uji lapangan di docs/TESTING.md.
```

**Audit desain (sebelum rilis beta):**

```text
Jalankan antislop dalam mode "after" pada seluruh UI dan teks aplikasi. Hasilkan daftar temuan bernomor (aturan yang dilanggar, lokasi file/layar, tingkat keparahan). Jangan memperbaiki apa pun sebelum saya setujui nomor mana yang diperbaiki. Setelah disetujui, perbaiki dan berikan laporan Delivery Gate lanjutan. Periksa juga checklist PRD 9.10 dan kontras token PRD 9.3.
```

**Perbaikan bug:**

```text
Bug: <deskripsi + langkah reproduksi + perangkat/OS>. Pertama, reproduksi atau jelaskan hipotesis penyebab beserta bukti dari kode/log. Tulis tes yang gagal untuk bug ini jika memungkinkan. Lalu perbaiki dengan perubahan sekecil mungkin. Jangan refactor di luar bug ini. Laporkan akar masalah, perbaikan, dan tes yang membuktikan.
```

### 13.5 Pedoman "jika ragu" untuk agent

| Situasi                                  | Tindakan                                                                                           |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Spesifikasi ambigu                       | Pilih opsi paling sederhana yang sesuai prinsip produk 1.4, catat di DECISIONS.md                  |
| Fitur menggoda tapi tidak ada di PRD     | Jangan dikerjakan; tulis di bagian "Ide Nanti" di DECISIONS.md                                     |
| Aturan anti-slop bertentangan dengan PRD | PRD bagian 9 menang untuk arah visual; anti-slop menang untuk kualitas/kejujuran. Catat konfliknya |
| Tidak bisa menguji di perangkat          | Katakan terus terang, sediakan langkah uji lapangan                                                |
| Butuh aset (foto, font)                  | Gunakan placeholder bertanda `TODO(asset)` dan tambahkan ke checklist aset                         |

---

## 14. Risiko, Pertanyaan Terbuka, Lampiran

### 14.1 Risiko

| Risiko                                                            | Dampak         | Mitigasi                                                                                  |
| ----------------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------- |
| Tracking background dimatikan OS/penghemat baterai merek tertentu | Sesi terputus  | Foreground service, snapshot berkala, halaman bantuan per merek, uji di perangkat agresif |
| Aturan background iOS lebih ketat                                 | Rute bolong    | Uji di iPhone fisik sejak Fase 2; indikator latar aktif                                   |
| Penolakan review karena lokasi latar                              | Rilis tertunda | Hindari `ACCESS_BACKGROUND_LOCATION`, disclosure jelas, video demo                        |
| Biaya Firestore/Storage membengkak                                | Biaya          | Polyline disederhanakan, rute penuh terkompresi, paginasi, cache lokal                    |
| Akurasi GPS buruk di area tertutup                                | Jarak salah    | Filter titik, indikator GPS, pelaporan kualitas di ringkasan                              |
| Scope creep                                                       | MVP molor      | Aturan scope bagian 3, DECISIONS.md "Ide Nanti"                                           |
| Agent menghasilkan UI generik                                     | Desain hambar  | anti-slop + `DESIGN.md` + checklist 9.10 + audit "after"                                  |
| Kalori tidak akurat                                               | Kepercayaan    | Label "perkiraan", sumber MET tercatat                                                    |

### 14.2 Pertanyaan terbuka (diputuskan pemilik produk, tidak memblokir agent)

1. Apakah subscription/tema berbayar dijual lewat IAP langsung atau RevenueCat? (Fase 7)
2. Apakah perlu bahasa Inggris saat rilis publik pertama?
3. Sumber foto/ilustrasi final: kreator sendiri, lisensi stok, atau ilustrator?
4. Nama bundle/package final (usulan: `id.runwild.app`).
5. Apakah target pasar awal Indonesia saja (menentukan prioritas bahasa, suara TTS, kebijakan privasi)?

### 14.3 Checklist aset yang harus disiapkan pemilik produk

- [ ] Gambar referensi di `docs/reference/runwild-reference.png`
- [ ] Logo RUNWILD (SVG), ikon aplikasi 1024×1024
- [ ] Foto/ilustrasi pelari hitam-putih berlisensi (untuk Intro & Get Started)
- [ ] File font Archivo (OFL) dan Barlow (cadangan) untuk dibundel
- [ ] Akun Firebase (proyek dev dan prod), akun Google Play Console, Apple Developer
- [ ] Kunci Google Maps (Android & iOS) dengan pembatasan
- [ ] Domain/halaman Kebijakan Privasi

### 14.4 Definition of Done global (setiap fitur)

- [ ] Kriteria fitur di PRD terpenuhi
- [ ] Semua state layar lengkap
- [ ] Tes relevan ditulis dan lulus; analyze 0 warning
- [ ] Mengikuti aturan desain dan lolos checklist 9.10
- [ ] Laporan Delivery Gate anti-slop: PASS
- [ ] Dokumen terkait diperbarui (`DATA_MODEL.md`, `SCREENS.md`, `CHANGELOG.md`, `DECISIONS.md`)
- [ ] Diuji di perangkat nyata bila menyangkut GPS, audio, atau background
- [ ] Tidak ada rahasia/data pribadi di repo

### 14.5 Glosarium

| Istilah             | Arti dalam aplikasi                                              |
| ------------------- | ---------------------------------------------------------------- |
| Pace                | Waktu untuk menempuh 1 km (menit'detik"/km)                      |
| Moving time         | Waktu bergerak, tidak termasuk jeda dan auto-pause               |
| Split               | Catatan waktu dan pace per kilometer                             |
| Run-walk / Interval | Bergantian antara lari dan jalan dalam putaran terukur           |
| Putaran (round)     | Satu pasang fase lari + jalan                                    |
| Preset              | Konfigurasi interval tersimpan                                   |
| Delivery Gate       | Laporan PASS/FAIL anti-slop yang wajib sebelum menyerahkan hasil |

---

_Akhir dokumen. Perubahan pada PRD dicatat di `docs/CHANGELOG.md` dengan nomor versi dokumen._
