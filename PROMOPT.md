# PROMPTS — salin, ganti <...>, tempel. Satu sesi = satu tugas.

## Cara pakai (untuk kamu)

1. Taruh seluruh folder ini di root repo (AGENTS.md, DESIGN.md, docs/).
2. Simpan gambar referensi di `docs/reference/runwild-reference.png`.
3. Tiap sesi baru: tempel **Prompt Tugas** di bawah. Selesai → minta agent update STATUS.md → tutup sesi.
4. Jalankan build/tes berat sendiri di terminal; tempel ke agent hanya baris error pertama.
5. Gagal 2× di masalah yang sama → tutup sesi, mulai baru dengan deskripsi lebih jelas.
6. Model besar untuk logika sulit (T2.2, T3.1, T3.6). Model kecil untuk UI rutin & teks.

## A. Prompt Tugas (paling sering dipakai)

```text
Kerjakan <T2.2> untuk RUNWILD.
Baca HANYA: AGENTS.md, docs/STATUS.md, tugas <T2.2> di docs/phases/phase-<2>.md, dan <docs/specs/tracking.md>.
Sentuh HANYA: <lib/domain/tracking/ dan test/>. Jangan baca/ubah file lain kecuali terpaksa (sebutkan alasannya).
Verifikasi terarah (format + analyze folder + tes terkait). Jangan build penuh.
Akhir: update docs/STATUS.md (≤20 baris), lalu laporan ≤15 baris: selesai / bukti / belum bisa diuji / keputusan baru.
```

## B. Sesi pertama (Fase 0, sekali saja)

```text
Kamu engineer Flutter senior untuk aplikasi RUNWILD. Baca AGENTS.md dan docs/phases/phase-0.md. Kerjakan T0.1 saja.
Ringkas pemahamanmu ≤8 baris dulu. Jangan membaca dokumen lain. Laporan ≤15 baris, update docs/STATUS.md.
```

## C. Tugas UI (tambahkan ke Prompt A)

```text
Tambahan UI: baca DESIGN.md. antislop aktif (mode during; muat antislop + antislop-ui). Tier layar: <A/B/C>.
Wajib 5 state (loading/empty/error/offline/content), token saja, tanpa data palsu. Akhiri dengan Delivery Gate 1 baris per blok.
```

## D. Perbaikan bug

```text
Bug: <gejala + langkah reproduksi + perangkat/OS>. Error pertama: <tempel ≤10 baris>.
Baca HANYA AGENTS.md dan file yang terkait stack trace. Beri hipotesis + bukti dari kode, tulis tes gagal bila bisa, perbaiki seminimal mungkin, tanpa refactor lain. Laporan ≤10 baris.
```

## E. Penutup sesi / serah-terima

```text
Update docs/STATUS.md: selesai, terblokir, file kunci (path + 1 baris), uji lapangan yang perlu saya lakukan, catatan ≤5 baris, tugas berikutnya. Maks 40 baris total. Jangan ulangi isi lama yang sudah tidak relevan.
```

## F. Rincikan fase berikutnya (Fase 5+)

```text
Mulai Fase <5>. Baca HANYA AGENTS.md, docs/STATUS.md, docs/phases/phase-5-plus.md. Pecah jadi tugas T-xx kecil (1 sesi/tugas) dengan kolom Sentuh dan "Selesai bila", simpan sebagai docs/phases/phase-5.md. Tulis spec yang dibutuhkan di docs/specs/. Jangan mengimplementasikan apa pun di sesi ini.
```

## G. Audit sebelum beta (sekali)

```text
Jalankan antislop mode "after" pada UI dan teks. Hasilkan daftar temuan bernomor (aturan, lokasi, keparahan), maks 30 baris. Jangan memperbaiki sebelum saya setujui nomornya.
```
