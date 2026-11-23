# Fase 5 · Perombakan UI/UX, Auth, Cuaca & Animasi

Dokumen ini merangkum seluruh tugas perombakan hasil audit seluruh halaman + kebutuhan tambahan pengguna. Dikerjakan berurutan berdasarkan prioritas (P1 → P5), satu tugas per sesi kerja.

---

## Ringkasan Prioritas

| Prioritas | Kode | Judul Tugas | Area File Utama |
| --- | --- | --- | --- |
| **P1 · Kritis (Alur Inti & Bug Visual)** | **T5.1** | **Perombakan Alur Lari Aktif, Loading Selesai & Pra-Sesi** *(selesai)* | `run_active_screen.dart`, `run_permission_sheet.dart`, `interval_options.dart` |
| **P1 · Kritis (Alur Inti & Bug Visual)** | **T5.2** | **Auth Langsung Google, Logo Google Baru & Hapus Mode Tamu** *(selesai)* | `startup_screen.dart`, `auth_screen.dart`, `account_actions.dart`, `router.dart` |
| **P2 · Tampilan Utama & Brand** | **T5.3** | **Animasi Lottie Splash Screen & Poles Onboarding/Setup Profil** *(selesai)* | `assets/lottie/`, `startup_screen.dart`, `intro_screen.dart`, `profile_setup_screen.dart` |
| **P2 · Tampilan Utama & Brand** | **T5.4** | **Rombak Hero Card Home, Fix Geocoding Kota (Lhokseumawe) & Detail Cuaca** *(selesai)* | `home_dashboard.dart`, `weather_service.dart`, `weather_detail_screen.dart` |
| **P3 · Anti-Slop & Konsistensi Layar** | **T5.5** | **Poles Ringkasan Sesi & Kartu Bagikan (Anti-Slop + Simpan Galeri)** *(selesai)* | `run_summary_screen.dart`, `share_card_screen.dart` |
| **P3 · Anti-Slop & Konsistensi Layar** | **T5.6** | **Poles Aktivitas, Detail Aktivitas, Progress & Profil (Hapus Double AppBar)** *(selesai)* | `router.dart`, `foundation_screen.dart`, `activities_screen.dart`, `activity_detail_screen.dart`, `progress_screen.dart`, `profile_screen.dart` |
| **P4 · Animasi & Micro-Interactions** | **T5.7** | **Sistem Motion & Transisi Atletis di Seluruh Layar Utama** *(selesai)* | `design/components/`, `home_dashboard.dart`, `run_active_screen.dart`, `run_summary_screen.dart` |

---

## Detail Tugas Per Prioritas

### P1 — Alur Kritis & Ergonomi Inti

#### T5.1 · Lari Aktif, Loading Selesai & Pra-Sesi
- **Loading Selesai Lari:** Saat pengguna menekan tombol *Selesai* dan mengonfirmasi dialog, tampilkan layar/overlay loading penuh yang jelas (*"Menyimpan sesi lari..."*) sejak konfirmasi ditekan hingga checkpoint/ringkasan siap berpindah ke `/run/summary` (tanpa jeda beku atau layar kosong).
- **Sticky Bottom Controls (`run_active_screen.dart`):** Pindahkan kontrol **Kunci · Jeda/Lanjut · Selesai** keluar dari `RwPage` scrollable ke footer tetap (`bottomNavigationBar`), sehingga tetap terjangkau saat tab *Rute* atau *Riwayat Split* dibuka.
- **HUD Outdoor & Banner Interval:** Tambah label satuan `km` tegas, kolom ke-3 **Kalori (perkiraan)** live, serta **linear progress bar sisa waktu fase** di banner interval dengan kontras tegas (**LARI**: arang `ink950` + aksen `lime500`; **JALAN**: `lime100` + `ink950`).
- **Quick Preset Pra-Sesi (`interval_options.dart`):** Tampilkan 4 pilihan cepat preset (*Pemula · 1:1 · 5:1 · Naik Level*) langsung di sheet persiapan tanpa harus membuka sheet kedua; pindahkan teks hardcode `'Pilih mode lari...'` ke ARB.
- **Selesai bila:** Kontrol tetap sticky di 3 tab, loading tampil saat konfirmasi selesai, analisis bersih, tes terarah lulus.

#### T5.2 · Auth Langsung Google, Logo Google Baru & Hapus Mode Tamu
- **Logo Google Autentik:** Ganti `Icons.g_mobiledata_rounded` dengan komponen vektor `GoogleLogoIcon` (4 warna resmi Google via `CustomPainter`).
- **Login Google Langsung:** Hapus halaman konfirmasi perantara `/auth/google` (kartu "Sinkronisasi riwayat lari..."). Menekan tombol **Masuk dengan Google** di `GetStartedScreen` langsung menjalankan `signInWithGoogle()` dengan indikator loading langsung pada tombol dan banner error bila gagal/dibatalkan.
- **Hapus Login Sebagai Tamu:** Hilangkan opsi *"Lanjutkan sebagai tamu"*, rute `/auth/guest`, serta tombol penautan akun tamu di UI (`GetStartedScreen`, `AuthScreen`, `AccountActions`, `router.dart`). Catat keputusan penghapusan mode tamu di `docs/DECISIONS.md`.
- **Bersihkan Warna Slop Auth:** Ganti warna Tailwind (`#FEE2E2`, `#FCA5A5`, `#B91C1C`, `#DCFCE7`, `#86EFAC`, `#15803D`) di banner error/sukses ke token `RwColors`.
- **Selesai bila:** Tidak ada pintu login tamu di UI, tombol Google berlogo resmi dan langsung membuka picker akun Google, analisis + tes auth diperbarui dan lulus.

---

### P2 — Identitas Visual, Hero Home & Cuaca

#### T5.3 · Animasi Lottie Splash Screen & Poles Onboarding
- **Splash Screen Lottie:** Buat/pasangkan aset animasi Lottie atletis baru di `assets/lottie/splash_runner.json` (siluet pelari / denyut lintasan Prime Lime di latar `ink950`) di `SplashScreen` dengan fallback statis bila `MediaQuery.disableAnimations` aktif.
- **Get Started & Intro (`startup_screen.dart`, `intro_screen.dart`):** Lepas bingkai kotak kaku di sekitar `MountainSilhouette` agar terasa lapang (Tier-A); pindahkan `'OPSI LAIN'` ke ARB; ganti semua `Color(0xFFE2E6DC)` ke `RwColors.borderCard`.
- **Rombak `ProfileSetupScreen`:** Ganti pilihan Level dari `Wrap` chip lama ke `RwSegmentedControl`, bungkus stepper target mingguan dalam `RwCard` modern, tombol aksi `fullWidth: true`.
- **Selesai bila:** Splash menampilkan animasi Lottie halus, aset JSON tervalidasi di unit test, onboarding bebas warna/teks hardcode.

#### T5.4 · Rombak Hero Card Home, Fix Geocoding Kota & Detail Cuaca
- **Rombak Hero Card (`home_dashboard.dart`):**
  - Desain ulang kartu Hero arang (`ink950`) dengan komposisi visual yang lebih berkarakter: latar siluet gunung/garis lintasan samar di sisi bawah/kanan (non-interaktif, sesuai `DESIGN.md` §9.4), chip cuaca interaktif di pojok atas, sapaan personal + headline tegas, dan CTA **Mulai berlari** `lime500` yang menonjol.
  - **Hapus Duplikasi:** Hilangkan `_HeroWeekMetrics` (karena statistik mingguan sudah lengkap di kartu *Minggu Ini* tepat di bawahnya) dan satukan pintu jadwal pengingat agar tidak tampil ganda.
- **Fix Deteksi Nama Kota Terpencil (cth. Lhokseumawe):**
  - Upgrade reverse geocoding di `weather_service.dart` dengan rantai sumber gratis tanpa API key:
    1. **Primary:** BigDataCloud Free Reverse Geocode API (`api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=id`) — membaca `city`, `locality`, dan `principalSubdivision` hingga tingkat kota/kabupaten/kecamatan Indonesia (termasuk Lhokseumawe, Aceh).
    2. **Fallback:** OpenStreetMap Nominatim (perluas fallback ke `regency`, `county`, `state_district`, `village`, `name`, `state`).
  - Catat penggunaan endpoint gratis tambahan di `docs/DECISIONS.md` + tambahkan unit test khusus koordinat Lhokseumawe (`5.1801, 97.1507`).
- **Poles `WeatherDetailScreen`:** Bungkus suhu utama dalam kartu Hero `ink950` dan daftar prakiraan 12 jam di dalam `RwCard` rapi (bukan teks + `Divider` telanjang).
- **Selesai bila:** Koordinat Lhokseumawe teruji mengembalikan `"Lhokseumawe"`, Hero Card baru bebas duplikasi & lolos tes skala teks 200%.

---

### P3 — Anti-Slop & Konsistensi Seluruh Layar

#### T5.5 · Poles Ringkasan Sesi & Kartu Bagikan
- **Ringkasan Sesi (`run_summary_screen.dart`):**
  - Gabungkan **Personal Best Banner** + **Celebration Banner** agar tidak ada 2 banner piala bertumpuk.
  - Hapus label slop `'HISTORI RUTE PRESISI'` di atas kanvas rute.
  - Ganti emoji `🟢 / 🟡 / 🔴` pada pemilih rasa sesi dengan ikon Material yang bersih.
  - Rapikan tombol bawah (*Simpan*, *Bagikan*, *Buang*) dan bersihkan `Color(0xFFE2E6DC)`.
- **Kartu Bagikan (`share_card_screen.dart`):** Tambah aksi **Simpan ke Galeri** langsung di samping tombol *Bagikan Gambar* (menggunakan `gal` yang sudah terdaftar di stack) + pesan umpan balik SnackBar.
- **Selesai bila:** Bebas emoji/slop, simpan ke galeri bekerja, tes `run_summary` & `share_card` lulus.

#### T5.6 · Poles Aktivitas, Detail, Progress & Profil
- **Hapus Double AppBar (`profile_screen.dart`, `router.dart`):** Hapus `Scaffold`/`AppBar` bersarang di dalam `ProfileScreen` agar tidak bertumpuk dengan AppBar `_AppShell`; hapus cabang mati `FoundationDestination.activities` di `foundation_screen.dart`.
- **Aktivitas (`activities_screen.dart`):** Ganti filter `RwChip` ke `RwSegmentedControl` (*Semua · Bebas · Interval*); pindahkan `'Statistik'` ke ARB; tampilkan total sesi & km ringkas di header bulan.
- **Detail Aktivitas (`activity_detail_screen.dart`):** Ganti emoji `🟢/🟡/🔴` & warna Tailwind pada `_FeelingBadge` ke ikon + token `RwColors`; ganti toggle hardcode `'Map: ON' / 'Map: OFF'` ke ARB Indonesia; hapus salah satu dari 2 tombol edit kembar; tambah ikon `?` penjelas singkat istilah *Pace* & *Split*.
- **Progress (`progress_screen.dart`):** Ganti teks error mentah `'Gagal memuat data statistik: $err'` dengan `RwCard` error + tombol *Coba Lagi*.
- **Profil (`profile_screen.dart`):** Hapus `boxShadow` glow lime di avatar (sesuai `DESIGN.md`); rapikan 2 baris statis tanpa aksi (*Satuan KM*, *Visibilitas Privat*) menjadi info ringkas; pindahkan seluruh teks hardcode (*Versi & Pembaruan*, *Periksa Pembaruan*, dll.) ke ARB.
- **Selesai bila:** Tidak ada double AppBar, nol warna Tailwind/emoji slop di seluruh layar, semua string melalui ARB.

---

### P4 — Animasi & Micro-Interactions

#### T5.7 · Animasi Halus & Terukur (`DESIGN.md` §9.3)
- Buat helper animasi ringan di `lib/design/components/rw_motion.dart` yang otomatis menghormati `MediaQuery.disableAnimationsOf(context)` (kurva `easeOutCubic`, durasi 120–320 ms):
  - **Staggered Entrance:** Kemunculan halus kartu-kartu Home, Progress, dan Ringkasan Sesi.
  - **Countdown & Phase Switch:** Animasi skala + fade saat hitung mundur `3-2-1` dan pergantian fase interval *LARI ↔ JALAN*.
  - **Animated Number Counter:** Angka jarak/kalori di Ringkasan Sesi dan Kartu Minggu Ini berhitung naik halus saat layar dibuka.
  - **Micro Press Feedback:** Efek tekan halus pada kartu interaktif (`RwCard` dengan `onTap`) dan tombol aksi utama.
- **Selesai bila:** Animasi berjalan mulus 60fps di emulator/perangkat, otomatis nonaktif saat *Kurangi Gerakan* aktif, seluruh tes CI lulus.

---

## DoD Fase 5
1. Seluruh layar mematuhi token `DESIGN.md` (nol warna Tailwind liar, nol emoji slop, nol double AppBar, nol string UI hardcode).
2. `dart format`, `flutter analyze --fatal-infos`, dan seluruh tes CI lulus di setiap selesai tugas.
3. Perubahan visual diverifikasi langsung via *hot reload* di MuMu Emulator (`127.0.0.1:16384`).
