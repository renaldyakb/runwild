hot# Data model

Status Fase 0: kontrak perencanaan berikut belum diimplementasikan sebagai penyimpanan.
Rules awal deny-all; perubahan di Fase 1 harus disertai tes Emulator.

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

Implementasi T2.5 memakai database internal `runwild.sqlite`, skema versi 1.
`run_sessions` menyimpan pemilik, waktu mulai, jarak, waktu bergerak/berlalu,
jumlah titik, dan status selesai. Indeks parsial membatasi satu sesi aktif
per akun. `run_points` menyimpan koordinat dan penanda segmen per sesi.
Checkpoint dan batch titik ditulis dalam satu transaksi. Waktu titik adalah
offset sesi dalam mikrodetik. Sesi selesai tetap lokal hingga tahap sinkronisasi.

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
