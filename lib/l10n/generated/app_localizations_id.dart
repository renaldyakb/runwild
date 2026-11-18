// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'RUNWILD';

  @override
  String get introTagline => 'RUN. TRACK. IMPROVE. GO WILD.';

  @override
  String get introRunTitle => 'LARI';

  @override
  String get introRunBody =>
      'Mulai dengan jalan kaki atau lari ringan. Pilih ritme yang nyaman untukmu.';

  @override
  String get introTrackTitle => 'LACAK';

  @override
  String get introTrackBody =>
      'Ketahui jarak, durasi, dan pace supaya kamu bisa memahami setiap sesi.';

  @override
  String get introGrowTitle => 'BERKEMBANG';

  @override
  String get introGrowBody =>
      'Tetapkan tujuan yang masuk akal dan beri tubuhmu waktu untuk beradaptasi.';

  @override
  String introProgress(int current, int total) {
    return 'Langkah $current dari $total';
  }

  @override
  String get introNext => 'Lanjut';

  @override
  String get introFinish => 'Lanjut ke layar mulai';

  @override
  String get introSkip => 'Lewati';

  @override
  String get splashLoading => 'Menyiapkan RUNWILD…';

  @override
  String get splashError => 'Status pengenalan belum bisa dibaca.';

  @override
  String get introSaveError => 'Progres pengenalan belum tersimpan. Coba lagi.';

  @override
  String get startTitle => 'SIAP BERGERAK?';

  @override
  String get startBody => 'Mulai dari ritme yang nyaman untukmu.';

  @override
  String get startNow => 'Mulai Sekarang';

  @override
  String get signIn => 'Masuk';

  @override
  String get authRegister => 'Daftar';

  @override
  String get authGuest => 'Lanjut sebagai tamu';

  @override
  String get authGoogle => 'Masuk dengan Google';

  @override
  String get profileSetupTitle => 'Siapkan profil';

  @override
  String get profileSetupLoading => 'Memeriksa profil…';

  @override
  String get profileSetupAlreadySaved => 'Profilmu sudah siap.';

  @override
  String get profileSetupReadError =>
      'Profil belum bisa diperiksa. Cek koneksi lalu coba lagi.';

  @override
  String get profileSetupSaveError =>
      'Profil belum tersimpan. Cek koneksi lalu coba lagi.';

  @override
  String get profileSetupName => 'Nama panggilan';

  @override
  String get profileSetupNameRequired => 'Masukkan nama panggilan.';

  @override
  String get profileSetupGoal => 'Tujuan utama';

  @override
  String get profileSetupLevel => 'Pengalaman lari';

  @override
  String get profileSetupWeekly => 'Sesi per minggu';

  @override
  String get profileSetupFewer => 'Kurangi sesi';

  @override
  String get profileSetupMore => 'Tambah sesi';

  @override
  String get profileSetupSave => 'Simpan profil';

  @override
  String get profileGoalHealth => 'Lebih sehat';

  @override
  String get profileGoal5k => 'Lari 5 km';

  @override
  String get profileGoal10k => 'Lari 10 km';

  @override
  String get profileGoalWeight => 'Turunkan berat badan';

  @override
  String get profileGoalOther => 'Tujuan lain';

  @override
  String get profileLevelBeginner => 'Baru mulai';

  @override
  String get profileLevelReturning => 'Mulai lagi';

  @override
  String get profileLevelRegular => 'Sudah rutin';

  @override
  String get authGoogleLink => 'Tautkan Google';

  @override
  String get authGoogleUnavailable =>
      'Google Sign-In belum siap. Periksa konfigurasi Firebase untuk Android.';

  @override
  String get authProviderCanceled => 'Proses masuk dibatalkan.';

  @override
  String get authApple => 'Masuk dengan Apple';

  @override
  String get authAppleLink => 'Tautkan Apple';

  @override
  String get authLink => 'Tautkan email';

  @override
  String get authSignOut => 'Keluar';

  @override
  String get authForgot => 'Lupa kata sandi?';

  @override
  String get authReset => 'Kirim tautan reset';

  @override
  String get authResetSent =>
      'Jika email terdaftar, tautan reset akan dikirim. Periksa kotak masuk dan spam.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Kata sandi';

  @override
  String get authEmailInvalid => 'Masukkan alamat email yang valid.';

  @override
  String get authPasswordRequired => 'Masukkan kata sandi.';

  @override
  String get authWeakPassword => 'Gunakan setidaknya 6 karakter.';

  @override
  String get authOffline =>
      'Koneksi terputus. Sambungkan internet lalu coba lagi.';

  @override
  String get authRejected => 'Periksa email dan kata sandi, lalu coba lagi.';

  @override
  String get authEmailInUse => 'Email ini sudah dipakai. Coba email lain.';

  @override
  String get authUnavailable =>
      'Akun belum tersedia. Pastikan Firebase dan metode masuk sudah diaktifkan.';

  @override
  String get authFailed => 'Aksi belum berhasil. Coba lagi.';

  @override
  String get authLoading => 'Memeriksa sesi…';

  @override
  String get authWorking => 'Memproses…';

  @override
  String get home => 'Home';

  @override
  String get run => 'Lari';

  @override
  String get activities => 'Aktivitas';

  @override
  String get historyTitle => 'Riwayat aktivitas';

  @override
  String get historyAll => 'Semua';

  @override
  String get historyLocal =>
      'Sesi di perangkat ini, tetap bisa dibuka offline. Riwayat dari perangkat lain belum tersedia.';

  @override
  String get historyLoading => 'Memuat riwayat…';

  @override
  String get historyError =>
      'Riwayat belum bisa dibaca dari perangkat. Coba muat ulang.';

  @override
  String get historyEmpty => 'Belum ada aktivitas';

  @override
  String get historyFilterEmpty => 'Belum ada sesi untuk filter ini';

  @override
  String get historyEmptyBody =>
      'Sesi yang selesai dicatat akan muncul di sini. Masuk ke akun agar sesi tersimpan.';

  @override
  String get historyMore => 'Muat 20 sesi berikutnya';

  @override
  String get historyMoreError =>
      'Sesi berikutnya belum bisa dimuat. Riwayat sebelumnya tetap tersedia; coba lagi.';

  @override
  String get historyRefresh => 'Muat ulang riwayat';

  @override
  String get historyMorning => 'Lari Pagi';

  @override
  String get historyMidday => 'Lari Siang';

  @override
  String get historyAfternoon => 'Lari Sore';

  @override
  String get historyNight => 'Lari Malam';

  @override
  String get historySynced => 'Tersinkron ke cloud';

  @override
  String get historyPending => 'Tersimpan di perangkat · belum tersinkron';

  @override
  String get historyRoute => 'Pratinjau rute sesi';

  @override
  String get historyNoRoute => 'Belum cukup titik GPS untuk menampilkan rute.';

  @override
  String get profile => 'Profil';

  @override
  String get catalog => 'Katalog komponen';

  @override
  String get foundation => 'Fondasi aplikasi';

  @override
  String get foundationBody =>
      'Ini versi pengembangan Fase 0. Pelacakan lari dan akun belum tersedia.';

  @override
  String get homeTitle => 'Run Free,';

  @override
  String get homeAccent => 'Go Wild.';

  @override
  String get homeReady => 'SESI BERIKUTNYA';

  @override
  String get homeRouteEmpty => 'Rute dimulai dari langkahmu';

  @override
  String get homeRouteHint => 'GPS akan dicatat saat sesi dimulai.';

  @override
  String get homeStart => 'Mulai berlari';

  @override
  String get homeWeekly => 'PERFORMA MINGGUAN';

  @override
  String get homeWeeklyEmpty => 'Ringkasan belum tersedia';

  @override
  String get homeWeeklyHint =>
      'Pencatatan sesi sudah tersedia. Ringkasan mingguan akan hadir di tahap berikutnya.';

  @override
  String get homeDistance => 'JARAK';

  @override
  String get homePace => 'PACE';

  @override
  String get homeDuration => 'DURASI';

  @override
  String get homeMetricEmpty => '—';

  @override
  String get homeBody =>
      'Tempat untuk mulai jalan, mencoba lari, dan menemukan ritmemu sendiri.';

  @override
  String get openCatalog => 'Buka katalog komponen';

  @override
  String get comingActivities => 'Riwayat belum tersedia';

  @override
  String get comingActivitiesBody =>
      'Daftar aktivitas akan hadir setelah pelacakan dan penyimpanan sesi siap pada Fase 4.';

  @override
  String get comingProfile => 'Profil belum tersedia';

  @override
  String get comingProfileBody =>
      'Akun hadir pada Fase 1. Pengaturan lengkap menyusul pada Fase 4.';

  @override
  String get runSetup => 'Persiapan lari';

  @override
  String get comingRun => 'Pelacakan belum tersedia';

  @override
  String get comingRunBody =>
      'Sesi lari disimpan di perangkat setelah kamu masuk.';

  @override
  String get runBeginSession => 'Mulai sesi lari';

  @override
  String get intervalMode => 'Interval';

  @override
  String get intervalFree => 'Bebas';

  @override
  String get intervalConfigure => 'Atur interval';

  @override
  String get intervalApply => 'Gunakan interval';

  @override
  String get intervalSaved => 'Preset tersimpan';

  @override
  String get intervalLocal =>
      'Disimpan di perangkat ini, termasuk saat offline. Maksimal 20 preset per akun.';

  @override
  String get intervalLoading => 'Memuat preset…';

  @override
  String get intervalSavedEmpty =>
      'Belum ada preset tersimpan. Beri nama untuk menyimpan pengaturan ini.';

  @override
  String get intervalName => 'Nama preset';

  @override
  String get intervalSave => 'Simpan preset';

  @override
  String get intervalUpdate => 'Simpan perubahan preset';

  @override
  String get intervalDelete => 'Hapus preset';

  @override
  String get intervalDeletePrompt =>
      'Hapus preset ini? Sesi lari yang sudah tersimpan tidak berubah.';

  @override
  String get intervalSaveError =>
      'Preset belum bisa disimpan atau dimuat. Coba lagi; jika sudah ada 20 preset, hapus salah satunya.';

  @override
  String get intervalBeginner => 'Pemula Santai';

  @override
  String get intervalClassic => 'Klasik 1:1';

  @override
  String get intervalFiveOne => '5 : 1';

  @override
  String get intervalLevelUp => 'Naik Level';

  @override
  String get intervalWarmup => 'Pemanasan';

  @override
  String get intervalRun => 'Lari';

  @override
  String get intervalWalk => 'Jalan';

  @override
  String get intervalCooldown => 'Pendinginan';

  @override
  String get intervalWarmupSeconds => 'Pemanasan (detik)';

  @override
  String get intervalRunSeconds => 'Lari (detik)';

  @override
  String get intervalWalkSeconds => 'Jalan (detik)';

  @override
  String get intervalCooldownSeconds => 'Pendinginan (detik)';

  @override
  String get intervalRounds => 'Jumlah putaran';

  @override
  String get intervalStartWalk => 'Mulai dari jalan';

  @override
  String get intervalFinished =>
      'Interval selesai. Tekan Selesai untuk menyimpan sesi.';

  @override
  String get intervalNoAudio =>
      'Panduan suara menandai fase lari/jalan dan sisa 10 detik. Jeda otomatis nonaktif untuk interval.';

  @override
  String get intervalAudioEnabled => 'Panduan suara';

  @override
  String get intervalAudioError =>
      'Suara belum bisa diputar. Ikuti fase di layar; matikan lalu aktifkan panduan untuk mencoba lagi pada fase berikutnya.';

  @override
  String get intervalInvalid => 'Lengkapi durasi dan putaran sesuai batas.';

  @override
  String intervalRange(int min, int max) {
    return 'Masukkan bilangan bulat $min–$max.';
  }

  @override
  String intervalRound(int current, int total) {
    return 'Putaran $current/$total';
  }

  @override
  String intervalRoundFree(int current) {
    return 'Putaran $current';
  }

  @override
  String intervalSummary(int minutes, int seconds, int rounds, int run) {
    return 'Total $minutes menit $seconds detik · $rounds× lari $run detik (termasuk pemanasan dan pendinginan)';
  }

  @override
  String intervalSummaryFree(int run, int walk) {
    return 'Bebas · lari $run detik / jalan $walk detik per putaran (tanpa batas)';
  }

  @override
  String get intervalFreeRounds => 'Bebas';

  @override
  String get intervalLimitedRounds => 'Terbatas';

  @override
  String get runActiveTitle => 'Sesi lari';

  @override
  String get runLiveTab => 'Live';

  @override
  String get runRouteTab => 'Rute';

  @override
  String get runHistoryTab => 'Riwayat';

  @override
  String get runStartHint =>
      'Cari ruang terbuka untuk membantu GPS menemukan posisimu.';

  @override
  String get runMapHint =>
      'Jejak mengikuti titik GPS sesi ini. Peta dasar dimuat dari OpenStreetMap.';

  @override
  String get runSessionHistory => 'Rekap sesi berjalan';

  @override
  String get runSessionHistoryHint =>
      'Putaran interval dan split diperbarui selama sesi. Split terakhir bisa kurang dari 1 km.';

  @override
  String get runRecoveredSplitsHint =>
      'Split sebelum pemulihan dapat berupa estimasi dari total sesi tersimpan.';

  @override
  String get runSplitsEmpty => 'Split muncul setelah ada jarak yang tercatat.';

  @override
  String runSplitMeters(int meters) {
    return '$meters m';
  }

  @override
  String get mapWaiting =>
      'Menunggu posisi GPS yang cukup akurat. Pastikan lokasi presisi aktif dan coba di ruang terbuka.';

  @override
  String mapAccuracy(int meters) {
    return 'Akurasi GPS ±$meters m';
  }

  @override
  String get mapStale =>
      'Posisi terakhir belum diperbarui. Marker bukan jaminan posisi saat ini.';

  @override
  String get mapCurrent => 'Posisi GPS saat ini';

  @override
  String get mapFollowing => 'Mengikuti posisi';

  @override
  String get mapRecenter => 'Pusatkan posisi';

  @override
  String get mapLoading => 'Memuat peta…';

  @override
  String get mapOffline =>
      'Sebagian peta belum bisa dimuat. Periksa internet lalu coba lagi; pencatatan GPS tetap berjalan.';

  @override
  String get mapAttribution => '© OpenStreetMap contributors';

  @override
  String get mapLinkError => 'Tautan sumber peta belum bisa dibuka.';

  @override
  String get runSessionNotificationText =>
      'GPS aktif selama sesi lari berlangsung.';

  @override
  String get runCountdown => 'Bersiap';

  @override
  String get runDistance => 'Jarak (km)';

  @override
  String get runMovingTime => 'Durasi bergerak';

  @override
  String get runAveragePace => 'Pace rata-rata';

  @override
  String runPaceUnit(String pace) {
    return '$pace /km';
  }

  @override
  String get runPaused => 'Sesi dijeda';

  @override
  String get runAutoPaused => 'Dijeda otomatis';

  @override
  String get runPause => 'Jeda';

  @override
  String get runResume => 'Lanjut';

  @override
  String get runFinish => 'Selesai';

  @override
  String get runFinishPrompt => 'Akhiri sesi lari ini?';

  @override
  String get summaryTitle => 'Ringkasan Sesi';

  @override
  String get summaryCelebration => 'KERJA BAGUS!';

  @override
  String get summaryFeelingQuestion => 'Bagaimana rasanya?';

  @override
  String get summaryFeelingEasy => 'Mudah';

  @override
  String get summaryFeelingNormal => 'Pas';

  @override
  String get summaryFeelingHard => 'Berat';

  @override
  String get summarySplits => 'Split per Kilometer';

  @override
  String summarySplitKm(int km) {
    return 'Km $km';
  }

  @override
  String get summaryIntervalStats => 'Statistik Interval';

  @override
  String summaryIntervalRounds(int completed) {
    return '$completed putaran';
  }

  @override
  String summaryIntervalRoundsTotal(int completed, int total) {
    return '$completed dari $total putaran';
  }

  @override
  String summaryIntervalRunTime(String time) {
    return 'Lari: $time';
  }

  @override
  String summaryIntervalWalkTime(String time) {
    return 'Jalan: $time';
  }

  @override
  String get summaryCalories => 'Kalori (perkiraan)';

  @override
  String summaryCaloriesUnit(int cal) {
    return '$cal kkal';
  }

  @override
  String get summarySave => 'Simpan Sesi';

  @override
  String get summaryDiscard => 'Buang Sesi';

  @override
  String get summaryDiscardPrompt =>
      'Buang sesi lari ini? Sesi yang dibuang tidak dapat dipulihkan.';

  @override
  String get summaryShare => 'Bagikan';

  @override
  String get summaryNote => 'Catatan sesi';

  @override
  String get summaryNoteHint => 'Tulis catatan tentang sesi ini…';

  @override
  String get runStorageFailed =>
      'Progres belum tersimpan. Coba lagi sebelum menutup aplikasi.';

  @override
  String get runRecoveryTitle => 'Sesi belum selesai';

  @override
  String get runRecoveryChecking => 'Memeriksa sesi tersimpan…';

  @override
  String runRecoverySummary(String time, int meters) {
    return 'Mulai pukul $time · $meters m';
  }

  @override
  String get runRecoveryResume => 'Lanjutkan sesi';

  @override
  String get runRecoverySave => 'Simpan dan akhiri';

  @override
  String get runRecoveryDiscard => 'Buang sesi';

  @override
  String get runRecoveryDiscardPrompt =>
      'Buang sesi ini? Jarak dan rutenya akan dihapus.';

  @override
  String get runRecoveryError => 'Sesi tersimpan belum bisa dibuka. Coba lagi.';

  @override
  String get runCancel => 'Batal';

  @override
  String get runLock => 'Kunci kontrol';

  @override
  String get runUnlock => 'Tahan 1 detik untuk membuka kunci';

  @override
  String get runLocked => 'Kontrol terkunci';

  @override
  String get runGpsStart => 'Mulai uji GPS';

  @override
  String get runGpsStop => 'Akhiri uji GPS';

  @override
  String get runGpsReady =>
      'Uji GPS mencatat jarak dan titik selama lembar ini terbuka. Hasil uji tidak disimpan.';

  @override
  String get runGpsWaiting => 'Menunggu titik GPS yang akurat…';

  @override
  String get runGpsRecording => 'GPS sedang merekam';

  @override
  String get runGpsStopped => 'Uji GPS selesai.';

  @override
  String get runGpsError =>
      'GPS terputus. Pastikan layanan lokasi dan izin lokasi presisi aktif, lalu coba lagi.';

  @override
  String get runGpsNotificationTitle => 'RUNWILD sedang merekam';

  @override
  String get runGpsNotificationText => 'GPS aktif selama uji rute berlangsung.';

  @override
  String runGpsMetrics(int points, int meters) {
    return '$points titik GPS · $meters m';
  }

  @override
  String get runStart => 'Mulai Lari';

  @override
  String get runLocationExplanation =>
      'Lokasi digunakan untuk mencatat rute dan menghitung jarak saat kamu berlari.';

  @override
  String get runLocationDenied =>
      'Izin lokasi belum diberikan. Izinkan lokasi agar RUNWILD bisa mencatat rute.';

  @override
  String get runLocationBlocked =>
      'Aktifkan izin lokasi untuk RUNWILD lewat pengaturan perangkat.';

  @override
  String get runLocationRestricted =>
      'Perangkat membatasi akses lokasi untuk RUNWILD.';

  @override
  String get runLocationReady => 'Izin lokasi sudah diberikan.';

  @override
  String get runNotificationsExplanation =>
      'Notifikasi opsional untuk melihat status sesi saat berlari.';

  @override
  String get runNotificationsEnable => 'Izinkan notifikasi';

  @override
  String get runNotificationsDenied =>
      'Notifikasi belum diizinkan. Kamu tetap bisa lanjut tanpa notifikasi.';

  @override
  String get runNotificationsBlocked =>
      'Jika ingin notifikasi sesi, aktifkan lewat pengaturan perangkat.';

  @override
  String get runNotificationsReady => 'Notifikasi sudah diizinkan.';

  @override
  String get runPermissionError => 'Izin belum bisa diperiksa. Coba lagi.';

  @override
  String get runPermissionBusy => 'Memeriksa izin…';

  @override
  String get runPermissionSettings => 'Buka pengaturan';

  @override
  String get runPermissionRefresh => 'Periksa izin lagi';

  @override
  String get close => 'Tutup';

  @override
  String get backHome => 'Kembali ke Home';

  @override
  String get catalogTitle => 'DIBUAT\nUNTUK GERAK.';

  @override
  String get catalogBody =>
      'Pratinjau komponen RUNWILD. Ubah tema dan kondisi layar untuk memeriksa tampilannya.';

  @override
  String get appearance => 'Tampilan';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get lightTheme => 'Terang';

  @override
  String get darkTheme => 'Gelap';

  @override
  String get actions => 'Tombol';

  @override
  String get previewAction => 'Coba tombol utama';

  @override
  String get previewSecondary => 'Buka contoh dialog';

  @override
  String get actionFeedback => 'Tombol utama berfungsi.';

  @override
  String get dialogTitle => 'Contoh dialog';

  @override
  String get dialogBody =>
      'Dialog dapat ditutup dengan tombol di bawah, tombol kembali, atau Escape.';

  @override
  String get disabledAction => 'Belum tersedia';

  @override
  String get loadingAction => 'Memproses…';

  @override
  String get loadingLabel => 'Contoh tombol saat memproses';

  @override
  String get choices => 'Pilihan';

  @override
  String get freeMode => 'Bebas';

  @override
  String get metrics => 'Angka dan satuan';

  @override
  String get metricNote =>
      'Contoh tampilan tanpa data aktivitas. Angka akan muncul dari sesi yang direkam.';

  @override
  String get distance => 'Jarak';

  @override
  String get distanceUnit => 'km';

  @override
  String get noValue => '--';

  @override
  String get noDistance => 'Jarak belum tersedia';

  @override
  String get states => 'Kondisi layar';

  @override
  String get statePreview => 'Simulasi komponen, bukan status aktivitasmu.';

  @override
  String get stateContent => 'Konten';

  @override
  String get stateLoading => 'Memuat';

  @override
  String get stateEmpty => 'Kosong';

  @override
  String get stateError => 'Gagal';

  @override
  String get stateOffline => 'Offline';

  @override
  String get loadingActivities => 'Memuat aktivitas…';

  @override
  String get emptyTitle => 'Belum ada aktivitas';

  @override
  String get emptyBody => 'Jalan 10 menit saja sudah cukup untuk memulai.';

  @override
  String get errorTitle => 'Aktivitas belum bisa dimuat';

  @override
  String get errorBody => 'Periksa koneksi, lalu coba lagi.';

  @override
  String get retry => 'Coba lagi';

  @override
  String get offlineTitle => 'Kamu sedang offline';

  @override
  String get offlineBody =>
      'Belum ada aktivitas tersimpan di perangkat ini. Coba lagi saat terhubung.';

  @override
  String get contentTitle => 'Komponen siap diperiksa';

  @override
  String get contentBody =>
      'Warna, tipografi, dan jarak mengikuti sistem desain RUNWILD.';

  @override
  String get backend => 'Koneksi Firebase';

  @override
  String get backendLocal =>
      'Konfigurasi belum dipasang. Katalog berjalan lokal.';

  @override
  String get backendConnecting => 'Menghubungkan Firebase…';

  @override
  String get backendReady => 'Firebase berhasil diinisialisasi.';

  @override
  String get backendError =>
      'Firebase belum bisa dihubungkan. Periksa konfigurasi proyek lalu coba lagi.';

  @override
  String get backendInvalid =>
      'Konfigurasi Firebase belum lengkap. Lengkapi konfigurasi lokal, lalu jalankan ulang aplikasi.';

  @override
  String get pageMissing => 'Layar tidak ditemukan';

  @override
  String get pageMissingBody =>
      'Alamat ini belum tersedia. Kembali ke Home untuk melanjutkan.';

  @override
  String get activityDetailTitle => 'Detail Aktivitas';

  @override
  String get activityNotFound => 'Aktivitas tidak ditemukan';

  @override
  String get activityNotFoundBody =>
      'Sesi lari ini mungkin telah dihapus atau tidak tersedia di perangkat ini.';

  @override
  String get activityEditTitle => 'Ubah Judul & Catatan';

  @override
  String get activityEditTitleDialog => 'Ubah Judul Sesi';

  @override
  String get activityTitleLabel => 'Judul Sesi';

  @override
  String get activityTitleHint => 'Misal: Lari Pagi Santai';

  @override
  String get activitySaveSuccess => 'Perubahan berhasil disimpan';

  @override
  String get activityDelete => 'Hapus Aktivitas';

  @override
  String get activityDeletePrompt =>
      'Hapus aktivitas ini? Riwayat sesi dan rute akan dihapus permanen.';

  @override
  String get activityDeleteSuccess => 'Aktivitas berhasil dihapus';

  @override
  String get activityShareButton => 'Bagikan Sesi';

  @override
  String get activitySplitsTitle => 'Split per Kilometer';

  @override
  String get activityRouteTitle => 'Peta Rute Sesi';

  @override
  String get activityNoRoute => 'Tidak ada rekaman rute GPS pada sesi ini.';

  @override
  String get homeThisWeek => 'Minggu Ini';

  @override
  String get homeWeeklyGoal => 'Target Mingguan';

  @override
  String homeWeeklyGoalProgress(int completed, int target, int percent) {
    return '$completed dari $target sesi ($percent%)';
  }

  @override
  String homeStreak(int weeks) {
    return 'Streak $weeks minggu berturut-turut';
  }

  @override
  String get homeRecommendationTitle => 'Rekomendasi Hari Ini';

  @override
  String get homeRecBeginnerTitle => 'Coba Pemula Santai';

  @override
  String get homeRecBeginnerDesc =>
      '20 menit interval ramah sendi: Jalan 2 menit / Lari 1 menit x 8 ronde.';

  @override
  String get homeRecClassicTitle => 'Lanjutkan Ritme: Interval 1:1';

  @override
  String get homeRecClassicDesc =>
      '20 menit: Jalan 1 menit / Lari 1 menit x 10 ronde untuk membangun stamina.';

  @override
  String get homeRecFreeTitle => 'Jalan / Lari Bebas';

  @override
  String get homeRecFreeDesc =>
      'Lari santai tanpa tekanan target atau jeda waktu.';

  @override
  String get homeSeeProgress => 'Lihat Tren & Rekor Pribadi';

  @override
  String get progressTitle => 'Progress & Rekor';

  @override
  String get progressPeriodWeek => 'Minggu Ini';

  @override
  String get progressPeriodMonth => 'Bulan Ini';

  @override
  String get progressPeriodAll => 'Semua';

  @override
  String get progressStatsTitle => 'Ringkasan Statistik';

  @override
  String get progressTotalDistance => 'TOTAL JARAK';

  @override
  String get progressTotalTime => 'TOTAL WAKTU';

  @override
  String get progressTotalSessions => 'TOTAL SESI';

  @override
  String get progressTotalCalories => 'TOTAL KALORI';

  @override
  String get progressAvgPace => 'PACE RATA-RATA';

  @override
  String get progressRecordsTitle => 'Rekor Pribadi (Personal Best)';

  @override
  String get progressRecordLongestDist => 'Jarak Terjauh';

  @override
  String get progressRecordLongestDur => 'Durasi Terlama';

  @override
  String get progressRecordBest1k => 'Pace 1 KM Terbaik';

  @override
  String get progressRecordBest5k => 'Pace 5 KM Terbaik';

  @override
  String get progressNoRecords =>
      'Belum ada rekor pribadi. Mulai sesi lari pertamamu untuk mencatat rekor!';

  @override
  String get progressDistanceChart => 'Grafik Tren Jarak';

  @override
  String get profileTitle => 'Profil & Pengaturan';

  @override
  String get profileSectionAccount => 'Data Diri & Target';

  @override
  String get profileSectionRunSettings => 'Preferensi Lari & Suara';

  @override
  String get profileSectionPrivacy => 'Privasi Sesi';

  @override
  String get profileSectionSecurity => 'Akun & Keamanan';

  @override
  String get profileEditName => 'Ubah Nama';

  @override
  String get profileEditNameDialog => 'Ubah Nama Pelari';

  @override
  String get profileNameSaved => 'Nama berhasil diperbarui';

  @override
  String get profileUnitsLabel => 'Satuan Jarak';

  @override
  String get profileUnitsKm => 'Kilometer (km)';

  @override
  String get profileAutoPause => 'Jeda Otomatis';

  @override
  String get profileAutoPauseDesc => 'Jeda otomatis saat berhenti bergerak';

  @override
  String get profileVoiceCues => 'Panduan Suara';

  @override
  String get profileVoiceCuesDesc => 'Audio progres lari dan interval';

  @override
  String get profileHaptics => 'Getaran Haptik';

  @override
  String get profileHapticsDesc => 'Getaran saat pergantian interval dan jeda';

  @override
  String get profileCountdownCue => 'Hitung Mundur Suara';

  @override
  String get profileRoundCue => 'Tanda Putaran Interval';

  @override
  String get profilePrivacyHideStartEnd => 'Sembunyikan Titik Awal & Akhir';

  @override
  String get profilePrivacyHideStartEndDesc =>
      'Radius 200 m di sekitar awal dan akhir rute disamarkan';

  @override
  String get profilePrivacyVisibility => 'Visibilitas Default';

  @override
  String get profilePrivacyPrivate => 'Hanya Saya (Privat)';

  @override
  String get profileUpdateSuccess => 'Pengaturan berhasil disimpan';

  @override
  String get profileUpdateError =>
      'Gagal menyimpan perubahan. Cek koneksi internetmu.';

  @override
  String get profileDeleteAccount => 'Hapus Akun';

  @override
  String get profileDeleteAccountConfirmTitle => 'Hapus Akun Permanen?';

  @override
  String get profileDeleteAccountConfirmBody =>
      'Tindakan ini tidak dapat dibatalkan. Seluruh data akun, profil, catatan aktivitas, rute GPS, dan rekor pribadimu akan dihapus selamanya.';

  @override
  String get profileDeleteAccountDoubleTitle => 'Konfirmasi Penghapusan';

  @override
  String get profileDeleteAccountDoubleHint =>
      'Ketik HAPUS untuk melanjutkan penghapusan akun:';

  @override
  String get profileDeleteAccountButton => 'HAPUS AKUN SAYA';

  @override
  String get profileDeleteAccountSuccess =>
      'Akun dan semua data berhasil dihapus permanen';

  @override
  String get profileDeleteAccountRecentLogin =>
      'Demi keamanan, silakan keluar lalu masuk kembali sebelum menghapus akun.';

  @override
  String get profileDeleteAccountError =>
      'Gagal menghapus akun. Coba beberapa saat lagi.';

  @override
  String get shareTitle => 'Kartu bagikan';

  @override
  String get sharePreview => 'Pratinjau';

  @override
  String get shareFormat => 'Format';

  @override
  String get shareTheme => 'Warna';

  @override
  String get shareStory => 'Story (9:16)';

  @override
  String get shareSquare => 'Persegi (1:1)';

  @override
  String get shareLime => 'Lime';

  @override
  String get sharePaper => 'Kertas';

  @override
  String get shareCharcoal => 'Arang';

  @override
  String get sharePhoto => 'Foto latar';

  @override
  String get shareCamera => 'Kamera';

  @override
  String get shareGallery => 'Galeri';

  @override
  String get shareRemovePhoto => 'Hapus foto';

  @override
  String get sharePrivate => 'Sembunyikan rute';

  @override
  String get sharePrivateHint =>
      'Gambar hanya memuat statistik. Foto pilihanmu tetap terlihat.';

  @override
  String get shareAction => 'Bagikan gambar';

  @override
  String get shareClose => 'Tutup';

  @override
  String get shareRouteHidden => 'Rute disembunyikan';

  @override
  String get shareNoRoute => 'Rute tidak direkam';

  @override
  String get shareRun => 'SESI LARI';

  @override
  String get shareDistanceUnit => 'km';

  @override
  String get shareDuration => 'Durasi';

  @override
  String get sharePace => 'Pace /km';

  @override
  String get shareRecord => 'Rekor pribadi';

  @override
  String get shareTagline => 'Run free.\nGo wild.';

  @override
  String get shareImageError => 'Tidak dapat memuat gambar. Coba lagi.';

  @override
  String get shareError => 'Belum bisa membagikan kartu. Coba lagi.';

  @override
  String get shareRouteError =>
      'Rute belum dapat dimuat. Buka kembali halaman ini untuk mencoba lagi.';

  @override
  String get updateTitle => 'Pembaruan tersedia';

  @override
  String updateInstalled(String version) {
    return 'Terpasang: v$version';
  }

  @override
  String get updateChanges => 'Yang baru';

  @override
  String get updateEmpty => 'Catatan perubahan belum tersedia untuk versi ini.';

  @override
  String get updateDownload => 'Unduh pembaruan';

  @override
  String get updateLater => 'Nanti saja';

  @override
  String get updateDownloadError =>
      'Tautan unduhan belum dapat dibuka. Coba lagi.';

  @override
  String get activityEditSheetTitle => 'Judul & catatan';

  @override
  String get activitySave => 'Simpan perubahan';

  @override
  String get homeSessionHint => 'Mulai dari langkahmu hari ini.';

  @override
  String get homeLastRoute => 'Rute terakhir';

  @override
  String get homeWeekLabel => 'Minggu ini';
}
