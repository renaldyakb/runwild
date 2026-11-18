# RUNWILD — Aturan Agent (BACA INI DULU)

Aplikasi pelacak jalan/lari ramah pemula (Android + iOS). Flutter + Firebase. UI Indonesia.
Tagline: RUN. TRACK. IMPROVE. GO WILD. Referensi visual: `docs/reference/runwild-reference.png`.

## 1. Aturan hemat token (WAJIB)

1. **Jangan baca semua dokumen.** Baca hanya: file ini, `docs/STATUS.md`, tugas aktif di `docs/phases/phase-N.md`, dan spec yang disebut tugas itu.
2. Jangan menjelajah repo. Pakai `ls`/`grep` terarah. Jangan baca `*.g.dart`, `*.freezed.dart`, `build/`, `.dart_tool/`.
3. Jangan baca ulang file yang baru kamu tulis di sesi ini.
4. Edit dengan diff/str_replace. Jangan menulis ulang file utuh untuk perubahan kecil.
5. Potong output perintah: `| tail -30`, `--reporter compact`, `2>&1 | grep -E "error|Error" | head`.
6. Verifikasi default = `dart format` + `flutter analyze <folder>` + tes terarah. **Build penuh hanya jika diminta.**
7. Satu sesi = satu tugas (T-xx). Selesai → update `docs/STATUS.md` → berhenti.
8. Laporan akhir maks 15 baris. Tanpa penjelasan panjang.
9. Jangan menambah fitur di luar tugas. Ide baru → tulis 1 baris di `docs/DECISIONS.md` bagian "Ide Nanti".

## 2. Peta dokumen (baca HANYA yang dibutuhkan)

| File                       | Isi                                   | Kapan dibaca             |
| -------------------------- | ------------------------------------- | ------------------------ |
| `docs/STATUS.md`           | Status, file kunci, langkah berikut   | Selalu                   |
| `docs/phases/phase-N.md`   | Daftar tugas T-xx + DoD fase          | Hanya fase aktif         |
| `DESIGN.md`                | Token, tier, copy, a11y               | Saat mengerjakan UI/teks |
| `docs/specs/tracking.md`   | GPS, filter, auto-pause, pace, kalori | Tugas tracking           |
| `docs/specs/interval.md`   | Mesin interval, preset, suara         | Tugas interval           |
| `docs/specs/share-card.md` | Ringkasan sesi + kartu bagikan        | Tugas ringkasan/bagikan  |
| `docs/specs/data-model.md` | Skema Firestore, Drift, rules         | Tugas data/sync          |
| `docs/DECISIONS.md`        | Keputusan + Ide Nanti                 | Hanya untuk menulis      |

## 3. Stack (jangan tambah dependensi tanpa catat di DECISIONS.md; pin versi)

Flutter stable · flutter_riverpod · go_router · freezed + json_serializable · drift · Firebase (Auth, Firestore, Storage, Messaging, Crashlytics, Analytics, App Check, Remote Config) · google_maps_flutter (via `MapService`) · geolocator · permission_handler · flutter_tts + just_audio · flutter_local_notifications · wakelock_plus · share_plus + gal · very_good_analysis.

## 4. Arsitektur

```
lib/ app/ · design/{tokens,components,decor} · core/{constants,services,utils,error}
     data/{models,local,remote,repositories} · domain/ (Dart murni) · features/<fitur>/{presentation,application}
```

UI → application (Riverpod) → domain + repositories. UI tidak memanggil Firebase/plugin langsung. `domain/` tanpa Flutter/Firebase.

## 5. Aturan kode inti

- Null safety penuh; hindari `dynamic` dan `!`. Model imutabel (freezed).
- Tidak ada angka ajaib: ambang di `core/constants/`. Tidak ada hex/ukuran liar: pakai token desain.
- String UI lewat lokalisasi (ARB), bukan hardcode.
- Waktu sesi pakai jam monoton/timestamp, bukan hitungan `Timer`.
- Tulis Firestore idempoten (ID dari klien), dukung antrean offline.
- Tidak ada `catch (_) {}` kosong. Error → pesan manusiawi + Crashlytics tanpa koordinat.
- Satuan internal: meter, detik, m/s, detik/km. Konversi hanya di tampilan.
- Tidak ada kunci/rahasia di repo. Tidak ada data palsu di UI. Tidak ada foto dari internet (pakai `TODO(asset)`).
- Logika murni wajib punya unit test.

## 6. Setiap layar wajib punya state

loading (skeleton) · empty (pesan jujur + 1 aksi) · error (apa terjadi + apa dilakukan) · offline · content.

## 7. Anti-slop (UI/teks/kode)

Skill: https://github.com/miqdadbadjuber/anti-slop. Pasang SEKALI: `npx antislop-ai`; pilih `antislop`, `antislop-ui`, `antislop-copywriting`, `antislop-human`, `antislop-layoutmobile`, `antislop-code`. Mode **during**.

- Tugas UI: muat `antislop` + `antislop-ui` (+ `antislop-human`/`layoutmobile` jika relevan). Tugas logika: `antislop-code` saja.
- Laporan **Delivery Gate** hanya untuk perubahan UI/teks, ringkas: 1 baris PASS/FAIL per blok.
- Audit mode **after** hanya sekali sebelum beta.
- Arah visual ditentukan `DESIGN.md`; anti-slop = filter.

## 8. Alur sesi

1. Baca AGENTS.md + STATUS.md + tugas T-xx. 2. Rencana ≤5 baris. 3. Implementasi kecil. 4. Verifikasi terarah.
2. Update STATUS.md (≤20 baris). 6. Laporan ≤15 baris: selesai / bukti / belum bisa diuji (perangkat nyata) / keputusan baru.
   Jangan klaim selesai tanpa bukti. Hal yang butuh perangkat fisik (GPS, background, audio) → katakan jujur + tambahkan langkah uji ke `docs/TESTING.md`.


## 9. Versi dan catatan rilis GitHub Actions

- Sumber versi hanya `pubspec.yaml` (`major.minor.patch+build`). Naikkan patch dan build untuk setiap APK pembaruan; jangan mengganti aset rilis lama dengan kode berbeda pada versi yang sama.
- UI/pemeriksa update membaca versi paket terpasang lewat `AppVersion.initialize()` / `package_info_plus`. Jangan hardcode versi tampilan atau pembanding.
- Sebelum rilis, tulis `docs/releases/<versi>.md`, misalnya `docs/releases/0.1.2.md`. CI memakai file ini sebagai `body_path`; tag `v<versi>` berasal dari pubspec.
- Format yang didukung aplikasi: heading `## Diperbaiki` / `## Diperbarui` / `## Ditambahkan`, paragraf pendek, dan bullet `- Satu perubahan nyata per baris.` Gunakan hanya bagian yang ada isinya, idealnya 3-6 bullet singkat.
- Tulis perubahan untuk pengguna dalam bahasa Indonesia. Jangan isi catatan dengan tagline, nama branch, daftar APK, perintah instalasi, HTML, tabel, gambar, emoji hias, atau code block.
- Penebalan, backtick, dan tautan Markdown lama dinormalisasi menjadi teks; heading/bullet dirender sebagai komponen. Jangan menampilkan body GitHub mentah lewat `Text(releaseNotes)`.
- Jangan mengarang klaim perbaikan/performa. Catatan kosong harus tampil jujur. Jalankan tes versi, parser catatan rilis dan UI pembaruan sebelum publikasi; publish harus menunggu job verify berhasil.
