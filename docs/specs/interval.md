# Interval · PRD §6.2

- Pemanasan/pendinginan masing-masing 0–15 menit; default 5 menit.
- Lari/jalan masing-masing 10 detik–60 menit; default 1/2 menit.
- Putaran 1–50; default 8, mulai dari jalan.
- Countdown 3 detik mengikuti alur sesi aktif. Fase berdurasi nol dilewati.
- Satu putaran selalu memuat satu lari dan satu jalan, sesuai urutan awal.
- Durasi latihan tidak termasuk countdown; elapsed mesin termasuk countdown,
  tidak termasuk jeda. runTime/walkTime hanya menjumlahkan fase interval terkait.
- Jam monoton diinjeksi; pembacaan terlambat langsung mencerminkan fase kini.
- Jeda mempertahankan sisa fase termasuk countdown; start/pause/resume berulang aman.
- T3.2: pilihan Bebas/Interval di lembar persiapan, empat preset bawaan,
  editor detik/putaran dan total durasi langsung. Pemula, Klasik dan Naik Level
  mulai lari; 5:1 mulai jalan. Semua preset memiliki pemanasan/pendinginan 5 menit.
- Preset kustom lokal per akun: maksimal 20, simpan/ubah nama/hapus.
  Belum sinkron antarperangkat; sinkron masuk T3.6.
- SQLite versi 2 menambah interval_json/interval_us pada run_sessions dan
  interval_presets. Migrasi mempertahankan sesi mode bebas versi 1.
- Countdown layar selesai sebelum GPS dan interval dimulai. Mesin disetel ke
  elapsed 3 detik agar tidak ada countdown ganda. Checkpoint interval atomik
  bersama metrik/titik GPS; pemulihan memakai konfigurasi tersimpan, bukan pilihan baru.
- Auto-pause GPS nonaktif dalam mode interval; Jeda manual membekukan keduanya.
  Interval selesai menghentikan GPS; pengguna menekan Selesai untuk menyimpan sesi.
- T3.3 berikutnya: cue audio/getar/notifikasi; saat ini panduan fase hanya di layar.
