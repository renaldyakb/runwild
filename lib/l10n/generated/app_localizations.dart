import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'RUNWILD'**
  String get appName;

  /// No description provided for @introTagline.
  ///
  /// In id, this message translates to:
  /// **'RUN. TRACK. IMPROVE. GO WILD.'**
  String get introTagline;

  /// No description provided for @introRunTitle.
  ///
  /// In id, this message translates to:
  /// **'LARI'**
  String get introRunTitle;

  /// No description provided for @introRunBody.
  ///
  /// In id, this message translates to:
  /// **'Mulai dengan jalan kaki atau lari ringan. Pilih ritme yang nyaman untukmu.'**
  String get introRunBody;

  /// No description provided for @introTrackTitle.
  ///
  /// In id, this message translates to:
  /// **'LACAK'**
  String get introTrackTitle;

  /// No description provided for @introTrackBody.
  ///
  /// In id, this message translates to:
  /// **'Ketahui jarak, durasi, dan pace supaya kamu bisa memahami setiap sesi.'**
  String get introTrackBody;

  /// No description provided for @introGrowTitle.
  ///
  /// In id, this message translates to:
  /// **'BERKEMBANG'**
  String get introGrowTitle;

  /// No description provided for @introGrowBody.
  ///
  /// In id, this message translates to:
  /// **'Tetapkan tujuan yang masuk akal dan beri tubuhmu waktu untuk beradaptasi.'**
  String get introGrowBody;

  /// No description provided for @introProgress.
  ///
  /// In id, this message translates to:
  /// **'Langkah {current} dari {total}'**
  String introProgress(int current, int total);

  /// No description provided for @introNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get introNext;

  /// No description provided for @introFinish.
  ///
  /// In id, this message translates to:
  /// **'Lanjut ke layar mulai'**
  String get introFinish;

  /// No description provided for @introSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get introSkip;

  /// No description provided for @splashLoading.
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan RUNWILD…'**
  String get splashLoading;

  /// No description provided for @splashError.
  ///
  /// In id, this message translates to:
  /// **'Status pengenalan belum bisa dibaca.'**
  String get splashError;

  /// No description provided for @introSaveError.
  ///
  /// In id, this message translates to:
  /// **'Progres pengenalan belum tersimpan. Coba lagi.'**
  String get introSaveError;

  /// No description provided for @startTitle.
  ///
  /// In id, this message translates to:
  /// **'SIAP BERGERAK?'**
  String get startTitle;

  /// No description provided for @startBody.
  ///
  /// In id, this message translates to:
  /// **'Mulai dari ritme yang nyaman untukmu.'**
  String get startBody;

  /// No description provided for @startNow.
  ///
  /// In id, this message translates to:
  /// **'Mulai Sekarang'**
  String get startNow;

  /// No description provided for @signIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get signIn;

  /// No description provided for @authRegister.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get authRegister;

  /// No description provided for @authGuest.
  ///
  /// In id, this message translates to:
  /// **'Lanjut sebagai tamu'**
  String get authGuest;

  /// No description provided for @authGoogle.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get authGoogle;

  /// No description provided for @profileSetupTitle.
  ///
  /// In id, this message translates to:
  /// **'Siapkan profil'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupLoading.
  ///
  /// In id, this message translates to:
  /// **'Memeriksa profil…'**
  String get profileSetupLoading;

  /// No description provided for @profileSetupAlreadySaved.
  ///
  /// In id, this message translates to:
  /// **'Profilmu sudah siap.'**
  String get profileSetupAlreadySaved;

  /// No description provided for @profileSetupReadError.
  ///
  /// In id, this message translates to:
  /// **'Profil belum bisa diperiksa. Cek koneksi lalu coba lagi.'**
  String get profileSetupReadError;

  /// No description provided for @profileSetupSaveError.
  ///
  /// In id, this message translates to:
  /// **'Profil belum tersimpan. Cek koneksi lalu coba lagi.'**
  String get profileSetupSaveError;

  /// No description provided for @profileSetupName.
  ///
  /// In id, this message translates to:
  /// **'Nama panggilan'**
  String get profileSetupName;

  /// No description provided for @profileSetupNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama panggilan.'**
  String get profileSetupNameRequired;

  /// No description provided for @profileSetupGoal.
  ///
  /// In id, this message translates to:
  /// **'Tujuan utama'**
  String get profileSetupGoal;

  /// No description provided for @profileSetupLevel.
  ///
  /// In id, this message translates to:
  /// **'Pengalaman lari'**
  String get profileSetupLevel;

  /// No description provided for @profileSetupWeekly.
  ///
  /// In id, this message translates to:
  /// **'Sesi per minggu'**
  String get profileSetupWeekly;

  /// No description provided for @profileSetupFewer.
  ///
  /// In id, this message translates to:
  /// **'Kurangi sesi'**
  String get profileSetupFewer;

  /// No description provided for @profileSetupMore.
  ///
  /// In id, this message translates to:
  /// **'Tambah sesi'**
  String get profileSetupMore;

  /// No description provided for @profileSetupSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan profil'**
  String get profileSetupSave;

  /// No description provided for @profileGoalHealth.
  ///
  /// In id, this message translates to:
  /// **'Lebih sehat'**
  String get profileGoalHealth;

  /// No description provided for @profileGoal5k.
  ///
  /// In id, this message translates to:
  /// **'Lari 5 km'**
  String get profileGoal5k;

  /// No description provided for @profileGoal10k.
  ///
  /// In id, this message translates to:
  /// **'Lari 10 km'**
  String get profileGoal10k;

  /// No description provided for @profileGoalWeight.
  ///
  /// In id, this message translates to:
  /// **'Turunkan berat badan'**
  String get profileGoalWeight;

  /// No description provided for @profileGoalOther.
  ///
  /// In id, this message translates to:
  /// **'Tujuan lain'**
  String get profileGoalOther;

  /// No description provided for @profileLevelBeginner.
  ///
  /// In id, this message translates to:
  /// **'Baru mulai'**
  String get profileLevelBeginner;

  /// No description provided for @profileLevelReturning.
  ///
  /// In id, this message translates to:
  /// **'Mulai lagi'**
  String get profileLevelReturning;

  /// No description provided for @profileLevelRegular.
  ///
  /// In id, this message translates to:
  /// **'Sudah rutin'**
  String get profileLevelRegular;

  /// No description provided for @authGoogleLink.
  ///
  /// In id, this message translates to:
  /// **'Tautkan Google'**
  String get authGoogleLink;

  /// No description provided for @authGoogleUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Google Sign-In belum siap. Periksa konfigurasi Firebase untuk Android.'**
  String get authGoogleUnavailable;

  /// No description provided for @authProviderCanceled.
  ///
  /// In id, this message translates to:
  /// **'Proses masuk dibatalkan.'**
  String get authProviderCanceled;

  /// No description provided for @authApple.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Apple'**
  String get authApple;

  /// No description provided for @authAppleLink.
  ///
  /// In id, this message translates to:
  /// **'Tautkan Apple'**
  String get authAppleLink;

  /// No description provided for @authLink.
  ///
  /// In id, this message translates to:
  /// **'Tautkan email'**
  String get authLink;

  /// No description provided for @authSignOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get authSignOut;

  /// No description provided for @authForgot.
  ///
  /// In id, this message translates to:
  /// **'Lupa kata sandi?'**
  String get authForgot;

  /// No description provided for @authReset.
  ///
  /// In id, this message translates to:
  /// **'Kirim tautan reset'**
  String get authReset;

  /// No description provided for @authResetSent.
  ///
  /// In id, this message translates to:
  /// **'Jika email terdaftar, tautan reset akan dikirim. Periksa kotak masuk dan spam.'**
  String get authResetSent;

  /// No description provided for @authEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi'**
  String get authPassword;

  /// No description provided for @authEmailInvalid.
  ///
  /// In id, this message translates to:
  /// **'Masukkan alamat email yang valid.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kata sandi.'**
  String get authPasswordRequired;

  /// No description provided for @authWeakPassword.
  ///
  /// In id, this message translates to:
  /// **'Gunakan setidaknya 6 karakter.'**
  String get authWeakPassword;

  /// No description provided for @authOffline.
  ///
  /// In id, this message translates to:
  /// **'Koneksi terputus. Sambungkan internet lalu coba lagi.'**
  String get authOffline;

  /// No description provided for @authRejected.
  ///
  /// In id, this message translates to:
  /// **'Periksa email dan kata sandi, lalu coba lagi.'**
  String get authRejected;

  /// No description provided for @authEmailInUse.
  ///
  /// In id, this message translates to:
  /// **'Email ini sudah dipakai. Coba email lain.'**
  String get authEmailInUse;

  /// No description provided for @authUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Akun belum tersedia. Pastikan Firebase dan metode masuk sudah diaktifkan.'**
  String get authUnavailable;

  /// No description provided for @authFailed.
  ///
  /// In id, this message translates to:
  /// **'Aksi belum berhasil. Coba lagi.'**
  String get authFailed;

  /// No description provided for @authLoading.
  ///
  /// In id, this message translates to:
  /// **'Memeriksa sesi…'**
  String get authLoading;

  /// No description provided for @authWorking.
  ///
  /// In id, this message translates to:
  /// **'Memproses…'**
  String get authWorking;

  /// No description provided for @home.
  ///
  /// In id, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @run.
  ///
  /// In id, this message translates to:
  /// **'Lari'**
  String get run;

  /// No description provided for @activities.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas'**
  String get activities;

  /// No description provided for @historyTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat aktivitas'**
  String get historyTitle;

  /// No description provided for @historyAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get historyAll;

  /// No description provided for @historyLocal.
  ///
  /// In id, this message translates to:
  /// **'Sesi di perangkat ini, tetap bisa dibuka offline. Riwayat dari perangkat lain belum tersedia.'**
  String get historyLocal;

  /// No description provided for @historyLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat riwayat…'**
  String get historyLoading;

  /// No description provided for @historyError.
  ///
  /// In id, this message translates to:
  /// **'Riwayat belum bisa dibaca dari perangkat. Coba muat ulang.'**
  String get historyError;

  /// No description provided for @historyEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada aktivitas'**
  String get historyEmpty;

  /// No description provided for @historyFilterEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada sesi untuk filter ini'**
  String get historyFilterEmpty;

  /// No description provided for @historyEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Sesi yang selesai dicatat akan muncul di sini. Masuk ke akun agar sesi tersimpan.'**
  String get historyEmptyBody;

  /// No description provided for @historyMore.
  ///
  /// In id, this message translates to:
  /// **'Muat 20 sesi berikutnya'**
  String get historyMore;

  /// No description provided for @historyMoreError.
  ///
  /// In id, this message translates to:
  /// **'Sesi berikutnya belum bisa dimuat. Riwayat sebelumnya tetap tersedia; coba lagi.'**
  String get historyMoreError;

  /// No description provided for @historyRefresh.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang riwayat'**
  String get historyRefresh;

  /// No description provided for @historyMorning.
  ///
  /// In id, this message translates to:
  /// **'Lari Pagi'**
  String get historyMorning;

  /// No description provided for @historyMidday.
  ///
  /// In id, this message translates to:
  /// **'Lari Siang'**
  String get historyMidday;

  /// No description provided for @historyAfternoon.
  ///
  /// In id, this message translates to:
  /// **'Lari Sore'**
  String get historyAfternoon;

  /// No description provided for @historyNight.
  ///
  /// In id, this message translates to:
  /// **'Lari Malam'**
  String get historyNight;

  /// No description provided for @historySynced.
  ///
  /// In id, this message translates to:
  /// **'Tersinkron ke cloud'**
  String get historySynced;

  /// No description provided for @historyPending.
  ///
  /// In id, this message translates to:
  /// **'Tersimpan di perangkat · belum tersinkron'**
  String get historyPending;

  /// No description provided for @historyRoute.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau rute sesi'**
  String get historyRoute;

  /// No description provided for @historyNoRoute.
  ///
  /// In id, this message translates to:
  /// **'Belum cukup titik GPS untuk menampilkan rute.'**
  String get historyNoRoute;

  /// No description provided for @profile.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @catalog.
  ///
  /// In id, this message translates to:
  /// **'Katalog komponen'**
  String get catalog;

  /// No description provided for @foundation.
  ///
  /// In id, this message translates to:
  /// **'Fondasi aplikasi'**
  String get foundation;

  /// No description provided for @foundationBody.
  ///
  /// In id, this message translates to:
  /// **'Ini versi pengembangan Fase 0. Pelacakan lari dan akun belum tersedia.'**
  String get foundationBody;

  /// No description provided for @homeTitle.
  ///
  /// In id, this message translates to:
  /// **'Run Free,'**
  String get homeTitle;

  /// No description provided for @homeAccent.
  ///
  /// In id, this message translates to:
  /// **'Go Wild.'**
  String get homeAccent;

  /// No description provided for @homeReady.
  ///
  /// In id, this message translates to:
  /// **'SESI BERIKUTNYA'**
  String get homeReady;

  /// No description provided for @homeRouteEmpty.
  ///
  /// In id, this message translates to:
  /// **'Rute dimulai dari langkahmu'**
  String get homeRouteEmpty;

  /// No description provided for @homeRouteHint.
  ///
  /// In id, this message translates to:
  /// **'GPS akan dicatat saat sesi dimulai.'**
  String get homeRouteHint;

  /// No description provided for @homeStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai berlari'**
  String get homeStart;

  /// No description provided for @homeWeekly.
  ///
  /// In id, this message translates to:
  /// **'PERFORMA MINGGUAN'**
  String get homeWeekly;

  /// No description provided for @homeWeeklyEmpty.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan belum tersedia'**
  String get homeWeeklyEmpty;

  /// No description provided for @homeWeeklyHint.
  ///
  /// In id, this message translates to:
  /// **'Pencatatan sesi sudah tersedia. Ringkasan mingguan akan hadir di tahap berikutnya.'**
  String get homeWeeklyHint;

  /// No description provided for @homeDistance.
  ///
  /// In id, this message translates to:
  /// **'JARAK'**
  String get homeDistance;

  /// No description provided for @homePace.
  ///
  /// In id, this message translates to:
  /// **'PACE'**
  String get homePace;

  /// No description provided for @homeDuration.
  ///
  /// In id, this message translates to:
  /// **'DURASI'**
  String get homeDuration;

  /// No description provided for @homeMetricEmpty.
  ///
  /// In id, this message translates to:
  /// **'—'**
  String get homeMetricEmpty;

  /// No description provided for @homeBody.
  ///
  /// In id, this message translates to:
  /// **'Tempat untuk mulai jalan, mencoba lari, dan menemukan ritmemu sendiri.'**
  String get homeBody;

  /// No description provided for @openCatalog.
  ///
  /// In id, this message translates to:
  /// **'Buka katalog komponen'**
  String get openCatalog;

  /// No description provided for @comingActivities.
  ///
  /// In id, this message translates to:
  /// **'Riwayat belum tersedia'**
  String get comingActivities;

  /// No description provided for @comingActivitiesBody.
  ///
  /// In id, this message translates to:
  /// **'Daftar aktivitas akan hadir setelah pelacakan dan penyimpanan sesi siap pada Fase 4.'**
  String get comingActivitiesBody;

  /// No description provided for @comingProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil belum tersedia'**
  String get comingProfile;

  /// No description provided for @comingProfileBody.
  ///
  /// In id, this message translates to:
  /// **'Akun hadir pada Fase 1. Pengaturan lengkap menyusul pada Fase 4.'**
  String get comingProfileBody;

  /// No description provided for @runSetup.
  ///
  /// In id, this message translates to:
  /// **'Persiapan lari'**
  String get runSetup;

  /// No description provided for @comingRun.
  ///
  /// In id, this message translates to:
  /// **'Pelacakan belum tersedia'**
  String get comingRun;

  /// No description provided for @comingRunBody.
  ///
  /// In id, this message translates to:
  /// **'Sesi lari disimpan di perangkat setelah kamu masuk.'**
  String get comingRunBody;

  /// No description provided for @runBeginSession.
  ///
  /// In id, this message translates to:
  /// **'Mulai sesi lari'**
  String get runBeginSession;

  /// No description provided for @intervalMode.
  ///
  /// In id, this message translates to:
  /// **'Interval'**
  String get intervalMode;

  /// No description provided for @intervalFree.
  ///
  /// In id, this message translates to:
  /// **'Bebas'**
  String get intervalFree;

  /// No description provided for @intervalConfigure.
  ///
  /// In id, this message translates to:
  /// **'Atur interval'**
  String get intervalConfigure;

  /// No description provided for @intervalApply.
  ///
  /// In id, this message translates to:
  /// **'Gunakan interval'**
  String get intervalApply;

  /// No description provided for @intervalSaved.
  ///
  /// In id, this message translates to:
  /// **'Preset tersimpan'**
  String get intervalSaved;

  /// No description provided for @intervalLocal.
  ///
  /// In id, this message translates to:
  /// **'Disimpan di perangkat ini, termasuk saat offline. Maksimal 20 preset per akun.'**
  String get intervalLocal;

  /// No description provided for @intervalLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat preset…'**
  String get intervalLoading;

  /// No description provided for @intervalSavedEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada preset tersimpan. Beri nama untuk menyimpan pengaturan ini.'**
  String get intervalSavedEmpty;

  /// No description provided for @intervalName.
  ///
  /// In id, this message translates to:
  /// **'Nama preset'**
  String get intervalName;

  /// No description provided for @intervalSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan preset'**
  String get intervalSave;

  /// No description provided for @intervalUpdate.
  ///
  /// In id, this message translates to:
  /// **'Simpan perubahan preset'**
  String get intervalUpdate;

  /// No description provided for @intervalDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus preset'**
  String get intervalDelete;

  /// No description provided for @intervalDeletePrompt.
  ///
  /// In id, this message translates to:
  /// **'Hapus preset ini? Sesi lari yang sudah tersimpan tidak berubah.'**
  String get intervalDeletePrompt;

  /// No description provided for @intervalSaveError.
  ///
  /// In id, this message translates to:
  /// **'Preset belum bisa disimpan atau dimuat. Coba lagi; jika sudah ada 20 preset, hapus salah satunya.'**
  String get intervalSaveError;

  /// No description provided for @intervalBeginner.
  ///
  /// In id, this message translates to:
  /// **'Pemula Santai'**
  String get intervalBeginner;

  /// No description provided for @intervalClassic.
  ///
  /// In id, this message translates to:
  /// **'Klasik 1:1'**
  String get intervalClassic;

  /// No description provided for @intervalFiveOne.
  ///
  /// In id, this message translates to:
  /// **'5 : 1'**
  String get intervalFiveOne;

  /// No description provided for @intervalLevelUp.
  ///
  /// In id, this message translates to:
  /// **'Naik Level'**
  String get intervalLevelUp;

  /// No description provided for @intervalWarmup.
  ///
  /// In id, this message translates to:
  /// **'Pemanasan'**
  String get intervalWarmup;

  /// No description provided for @intervalRun.
  ///
  /// In id, this message translates to:
  /// **'Lari'**
  String get intervalRun;

  /// No description provided for @intervalWalk.
  ///
  /// In id, this message translates to:
  /// **'Jalan'**
  String get intervalWalk;

  /// No description provided for @intervalCooldown.
  ///
  /// In id, this message translates to:
  /// **'Pendinginan'**
  String get intervalCooldown;

  /// No description provided for @intervalWarmupSeconds.
  ///
  /// In id, this message translates to:
  /// **'Pemanasan (detik)'**
  String get intervalWarmupSeconds;

  /// No description provided for @intervalRunSeconds.
  ///
  /// In id, this message translates to:
  /// **'Lari (detik)'**
  String get intervalRunSeconds;

  /// No description provided for @intervalWalkSeconds.
  ///
  /// In id, this message translates to:
  /// **'Jalan (detik)'**
  String get intervalWalkSeconds;

  /// No description provided for @intervalCooldownSeconds.
  ///
  /// In id, this message translates to:
  /// **'Pendinginan (detik)'**
  String get intervalCooldownSeconds;

  /// No description provided for @intervalRounds.
  ///
  /// In id, this message translates to:
  /// **'Jumlah putaran'**
  String get intervalRounds;

  /// No description provided for @intervalStartWalk.
  ///
  /// In id, this message translates to:
  /// **'Mulai dari jalan'**
  String get intervalStartWalk;

  /// No description provided for @intervalFinished.
  ///
  /// In id, this message translates to:
  /// **'Interval selesai. Tekan Selesai untuk menyimpan sesi.'**
  String get intervalFinished;

  /// No description provided for @intervalNoAudio.
  ///
  /// In id, this message translates to:
  /// **'Panduan suara menandai fase lari/jalan dan sisa 10 detik. Jeda otomatis nonaktif untuk interval.'**
  String get intervalNoAudio;

  /// No description provided for @intervalAudioEnabled.
  ///
  /// In id, this message translates to:
  /// **'Panduan suara'**
  String get intervalAudioEnabled;

  /// No description provided for @intervalAudioError.
  ///
  /// In id, this message translates to:
  /// **'Suara belum bisa diputar. Ikuti fase di layar; matikan lalu aktifkan panduan untuk mencoba lagi pada fase berikutnya.'**
  String get intervalAudioError;

  /// No description provided for @intervalInvalid.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi durasi dan putaran sesuai batas.'**
  String get intervalInvalid;

  /// No description provided for @intervalRange.
  ///
  /// In id, this message translates to:
  /// **'Masukkan bilangan bulat {min}–{max}.'**
  String intervalRange(int min, int max);

  /// No description provided for @intervalRound.
  ///
  /// In id, this message translates to:
  /// **'Putaran {current}/{total}'**
  String intervalRound(int current, int total);

  /// No description provided for @intervalRoundFree.
  ///
  /// In id, this message translates to:
  /// **'Putaran {current}'**
  String intervalRoundFree(int current);

  /// No description provided for @intervalSummary.
  ///
  /// In id, this message translates to:
  /// **'Total {minutes} menit {seconds} detik · {rounds}× lari {run} detik (termasuk pemanasan dan pendinginan)'**
  String intervalSummary(int minutes, int seconds, int rounds, int run);

  /// No description provided for @intervalSummaryFree.
  ///
  /// In id, this message translates to:
  /// **'Bebas · lari {run} detik / jalan {walk} detik per putaran (tanpa batas)'**
  String intervalSummaryFree(int run, int walk);

  /// No description provided for @intervalFreeRounds.
  ///
  /// In id, this message translates to:
  /// **'Bebas'**
  String get intervalFreeRounds;

  /// No description provided for @intervalLimitedRounds.
  ///
  /// In id, this message translates to:
  /// **'Terbatas'**
  String get intervalLimitedRounds;

  /// No description provided for @runActiveTitle.
  ///
  /// In id, this message translates to:
  /// **'Sesi lari'**
  String get runActiveTitle;

  /// No description provided for @runLiveTab.
  ///
  /// In id, this message translates to:
  /// **'Live'**
  String get runLiveTab;

  /// No description provided for @runRouteTab.
  ///
  /// In id, this message translates to:
  /// **'Rute'**
  String get runRouteTab;

  /// No description provided for @runHistoryTab.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get runHistoryTab;

  /// No description provided for @runStartHint.
  ///
  /// In id, this message translates to:
  /// **'Cari ruang terbuka untuk membantu GPS menemukan posisimu.'**
  String get runStartHint;

  /// No description provided for @runMapHint.
  ///
  /// In id, this message translates to:
  /// **'Jejak mengikuti titik GPS sesi ini. Peta dasar dimuat dari OpenStreetMap.'**
  String get runMapHint;

  /// No description provided for @runSessionHistory.
  ///
  /// In id, this message translates to:
  /// **'Rekap sesi berjalan'**
  String get runSessionHistory;

  /// No description provided for @runSessionHistoryHint.
  ///
  /// In id, this message translates to:
  /// **'Putaran interval dan split diperbarui selama sesi. Split terakhir bisa kurang dari 1 km.'**
  String get runSessionHistoryHint;

  /// No description provided for @runRecoveredSplitsHint.
  ///
  /// In id, this message translates to:
  /// **'Split sebelum pemulihan dapat berupa estimasi dari total sesi tersimpan.'**
  String get runRecoveredSplitsHint;

  /// No description provided for @runSplitsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Split muncul setelah ada jarak yang tercatat.'**
  String get runSplitsEmpty;

  /// No description provided for @runSplitMeters.
  ///
  /// In id, this message translates to:
  /// **'{meters} m'**
  String runSplitMeters(int meters);

  /// No description provided for @mapWaiting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu posisi GPS yang cukup akurat. Pastikan lokasi presisi aktif dan coba di ruang terbuka.'**
  String get mapWaiting;

  /// No description provided for @mapAccuracy.
  ///
  /// In id, this message translates to:
  /// **'Akurasi GPS ±{meters} m'**
  String mapAccuracy(int meters);

  /// No description provided for @mapStale.
  ///
  /// In id, this message translates to:
  /// **'Posisi terakhir belum diperbarui. Marker bukan jaminan posisi saat ini.'**
  String get mapStale;

  /// No description provided for @mapCurrent.
  ///
  /// In id, this message translates to:
  /// **'Posisi GPS saat ini'**
  String get mapCurrent;

  /// No description provided for @mapFollowing.
  ///
  /// In id, this message translates to:
  /// **'Mengikuti posisi'**
  String get mapFollowing;

  /// No description provided for @mapRecenter.
  ///
  /// In id, this message translates to:
  /// **'Pusatkan posisi'**
  String get mapRecenter;

  /// No description provided for @mapLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat peta…'**
  String get mapLoading;

  /// No description provided for @mapOffline.
  ///
  /// In id, this message translates to:
  /// **'Sebagian peta belum bisa dimuat. Periksa internet lalu coba lagi; pencatatan GPS tetap berjalan.'**
  String get mapOffline;

  /// No description provided for @mapAttribution.
  ///
  /// In id, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get mapAttribution;

  /// No description provided for @mapLinkError.
  ///
  /// In id, this message translates to:
  /// **'Tautan sumber peta belum bisa dibuka.'**
  String get mapLinkError;

  /// No description provided for @runSessionNotificationText.
  ///
  /// In id, this message translates to:
  /// **'GPS aktif selama sesi lari berlangsung.'**
  String get runSessionNotificationText;

  /// No description provided for @runCountdown.
  ///
  /// In id, this message translates to:
  /// **'Bersiap'**
  String get runCountdown;

  /// No description provided for @runDistance.
  ///
  /// In id, this message translates to:
  /// **'Jarak (km)'**
  String get runDistance;

  /// No description provided for @runMovingTime.
  ///
  /// In id, this message translates to:
  /// **'Durasi bergerak'**
  String get runMovingTime;

  /// No description provided for @runAveragePace.
  ///
  /// In id, this message translates to:
  /// **'Pace rata-rata'**
  String get runAveragePace;

  /// No description provided for @runPaceUnit.
  ///
  /// In id, this message translates to:
  /// **'{pace} /km'**
  String runPaceUnit(String pace);

  /// No description provided for @runPaused.
  ///
  /// In id, this message translates to:
  /// **'Sesi dijeda'**
  String get runPaused;

  /// No description provided for @runAutoPaused.
  ///
  /// In id, this message translates to:
  /// **'Dijeda otomatis'**
  String get runAutoPaused;

  /// No description provided for @runPause.
  ///
  /// In id, this message translates to:
  /// **'Jeda'**
  String get runPause;

  /// No description provided for @runResume.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get runResume;

  /// No description provided for @runFinish.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get runFinish;

  /// No description provided for @runFinishPrompt.
  ///
  /// In id, this message translates to:
  /// **'Akhiri sesi lari ini?'**
  String get runFinishPrompt;

  /// No description provided for @summaryTitle.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Sesi'**
  String get summaryTitle;

  /// No description provided for @summaryCelebration.
  ///
  /// In id, this message translates to:
  /// **'KERJA BAGUS!'**
  String get summaryCelebration;

  /// No description provided for @summaryFeelingQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana rasanya?'**
  String get summaryFeelingQuestion;

  /// No description provided for @summaryFeelingEasy.
  ///
  /// In id, this message translates to:
  /// **'Mudah'**
  String get summaryFeelingEasy;

  /// No description provided for @summaryFeelingNormal.
  ///
  /// In id, this message translates to:
  /// **'Pas'**
  String get summaryFeelingNormal;

  /// No description provided for @summaryFeelingHard.
  ///
  /// In id, this message translates to:
  /// **'Berat'**
  String get summaryFeelingHard;

  /// No description provided for @summarySplits.
  ///
  /// In id, this message translates to:
  /// **'Split per Kilometer'**
  String get summarySplits;

  /// No description provided for @summarySplitKm.
  ///
  /// In id, this message translates to:
  /// **'Km {km}'**
  String summarySplitKm(int km);

  /// No description provided for @summaryIntervalStats.
  ///
  /// In id, this message translates to:
  /// **'Statistik Interval'**
  String get summaryIntervalStats;

  /// No description provided for @summaryIntervalRounds.
  ///
  /// In id, this message translates to:
  /// **'{completed} putaran'**
  String summaryIntervalRounds(int completed);

  /// No description provided for @summaryIntervalRoundsTotal.
  ///
  /// In id, this message translates to:
  /// **'{completed} dari {total} putaran'**
  String summaryIntervalRoundsTotal(int completed, int total);

  /// No description provided for @summaryIntervalRunTime.
  ///
  /// In id, this message translates to:
  /// **'Lari: {time}'**
  String summaryIntervalRunTime(String time);

  /// No description provided for @summaryIntervalWalkTime.
  ///
  /// In id, this message translates to:
  /// **'Jalan: {time}'**
  String summaryIntervalWalkTime(String time);

  /// No description provided for @summaryCalories.
  ///
  /// In id, this message translates to:
  /// **'Kalori (perkiraan)'**
  String get summaryCalories;

  /// No description provided for @summaryCaloriesUnit.
  ///
  /// In id, this message translates to:
  /// **'{cal} kkal'**
  String summaryCaloriesUnit(int cal);

  /// No description provided for @summarySave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Sesi'**
  String get summarySave;

  /// No description provided for @summaryDiscard.
  ///
  /// In id, this message translates to:
  /// **'Buang Sesi'**
  String get summaryDiscard;

  /// No description provided for @summaryDiscardPrompt.
  ///
  /// In id, this message translates to:
  /// **'Buang sesi lari ini? Sesi yang dibuang tidak dapat dipulihkan.'**
  String get summaryDiscardPrompt;

  /// No description provided for @summaryShare.
  ///
  /// In id, this message translates to:
  /// **'Bagikan'**
  String get summaryShare;

  /// No description provided for @summaryNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan sesi'**
  String get summaryNote;

  /// No description provided for @summaryNoteHint.
  ///
  /// In id, this message translates to:
  /// **'Tulis catatan tentang sesi ini…'**
  String get summaryNoteHint;

  /// No description provided for @runStorageFailed.
  ///
  /// In id, this message translates to:
  /// **'Progres belum tersimpan. Coba lagi sebelum menutup aplikasi.'**
  String get runStorageFailed;

  /// No description provided for @runRecoveryTitle.
  ///
  /// In id, this message translates to:
  /// **'Sesi belum selesai'**
  String get runRecoveryTitle;

  /// No description provided for @runRecoveryChecking.
  ///
  /// In id, this message translates to:
  /// **'Memeriksa sesi tersimpan…'**
  String get runRecoveryChecking;

  /// No description provided for @runRecoverySummary.
  ///
  /// In id, this message translates to:
  /// **'Mulai pukul {time} · {meters} m'**
  String runRecoverySummary(String time, int meters);

  /// No description provided for @runRecoveryResume.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan sesi'**
  String get runRecoveryResume;

  /// No description provided for @runRecoverySave.
  ///
  /// In id, this message translates to:
  /// **'Simpan dan akhiri'**
  String get runRecoverySave;

  /// No description provided for @runRecoveryDiscard.
  ///
  /// In id, this message translates to:
  /// **'Buang sesi'**
  String get runRecoveryDiscard;

  /// No description provided for @runRecoveryDiscardPrompt.
  ///
  /// In id, this message translates to:
  /// **'Buang sesi ini? Jarak dan rutenya akan dihapus.'**
  String get runRecoveryDiscardPrompt;

  /// No description provided for @runRecoveryError.
  ///
  /// In id, this message translates to:
  /// **'Sesi tersimpan belum bisa dibuka. Coba lagi.'**
  String get runRecoveryError;

  /// No description provided for @runCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get runCancel;

  /// No description provided for @runLock.
  ///
  /// In id, this message translates to:
  /// **'Kunci kontrol'**
  String get runLock;

  /// No description provided for @runUnlock.
  ///
  /// In id, this message translates to:
  /// **'Tahan 1 detik untuk membuka kunci'**
  String get runUnlock;

  /// No description provided for @runLocked.
  ///
  /// In id, this message translates to:
  /// **'Kontrol terkunci'**
  String get runLocked;

  /// No description provided for @runGpsStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai uji GPS'**
  String get runGpsStart;

  /// No description provided for @runGpsStop.
  ///
  /// In id, this message translates to:
  /// **'Akhiri uji GPS'**
  String get runGpsStop;

  /// No description provided for @runGpsReady.
  ///
  /// In id, this message translates to:
  /// **'Uji GPS mencatat jarak dan titik selama lembar ini terbuka. Hasil uji tidak disimpan.'**
  String get runGpsReady;

  /// No description provided for @runGpsWaiting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu titik GPS yang akurat…'**
  String get runGpsWaiting;

  /// No description provided for @runGpsRecording.
  ///
  /// In id, this message translates to:
  /// **'GPS sedang merekam'**
  String get runGpsRecording;

  /// No description provided for @runGpsStopped.
  ///
  /// In id, this message translates to:
  /// **'Uji GPS selesai.'**
  String get runGpsStopped;

  /// No description provided for @runGpsError.
  ///
  /// In id, this message translates to:
  /// **'GPS terputus. Pastikan layanan lokasi dan izin lokasi presisi aktif, lalu coba lagi.'**
  String get runGpsError;

  /// No description provided for @runGpsNotificationTitle.
  ///
  /// In id, this message translates to:
  /// **'RUNWILD sedang merekam'**
  String get runGpsNotificationTitle;

  /// No description provided for @runGpsNotificationText.
  ///
  /// In id, this message translates to:
  /// **'GPS aktif selama uji rute berlangsung.'**
  String get runGpsNotificationText;

  /// No description provided for @runGpsMetrics.
  ///
  /// In id, this message translates to:
  /// **'{points} titik GPS · {meters} m'**
  String runGpsMetrics(int points, int meters);

  /// No description provided for @runLocationDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi belum diberikan. Izinkan lokasi agar RUNWILD bisa mencatat rute.'**
  String get runLocationDenied;

  /// No description provided for @runLocationBlocked.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan izin lokasi untuk RUNWILD lewat pengaturan perangkat.'**
  String get runLocationBlocked;

  /// No description provided for @runLocationRestricted.
  ///
  /// In id, this message translates to:
  /// **'Perangkat membatasi akses lokasi untuk RUNWILD.'**
  String get runLocationRestricted;

  /// No description provided for @runNotificationsEnable.
  ///
  /// In id, this message translates to:
  /// **'Izinkan notifikasi'**
  String get runNotificationsEnable;

  /// No description provided for @runNotificationsDenied.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi belum diizinkan. Aktifkan agar status sesi tetap terlihat saat layar mati.'**
  String get runNotificationsDenied;

  /// No description provided for @runNotificationsBlocked.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan izin notifikasi RUNWILD lewat pengaturan perangkat.'**
  String get runNotificationsBlocked;

  /// No description provided for @runPermissionError.
  ///
  /// In id, this message translates to:
  /// **'Izin belum bisa diperiksa. Coba lagi.'**
  String get runPermissionError;

  /// No description provided for @runPermissionBusy.
  ///
  /// In id, this message translates to:
  /// **'Memeriksa izin…'**
  String get runPermissionBusy;

  /// No description provided for @runPermissionSettings.
  ///
  /// In id, this message translates to:
  /// **'Buka pengaturan'**
  String get runPermissionSettings;

  /// No description provided for @runPermissionRefresh.
  ///
  /// In id, this message translates to:
  /// **'Periksa izin lagi'**
  String get runPermissionRefresh;

  /// No description provided for @runPermissionSettingsFailed.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan perangkat tidak bisa dibuka. Buka manual dari Pengaturan sistem.'**
  String get runPermissionSettingsFailed;

  /// No description provided for @runPermissionsRequiredTitle.
  ///
  /// In id, this message translates to:
  /// **'Lokasi dan notifikasi perlu aktif'**
  String get runPermissionsRequiredTitle;

  /// No description provided for @runPermissionsRequiredBody.
  ///
  /// In id, this message translates to:
  /// **'Rute hanya terekam saat lokasi aktif. Notifikasi menjaga status sesi tetap terlihat ketika layar mati.'**
  String get runPermissionsRequiredBody;

  /// No description provided for @runLocationEnable.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan lokasi'**
  String get runLocationEnable;

  /// No description provided for @runLocationServiceOff.
  ///
  /// In id, this message translates to:
  /// **'Lokasi perangkat sedang mati. Hidupkan lokasi agar rute bisa direkam.'**
  String get runLocationServiceOff;

  /// No description provided for @runLocationServiceEnable.
  ///
  /// In id, this message translates to:
  /// **'Hidupkan lokasi'**
  String get runLocationServiceEnable;

  /// No description provided for @calibrationTitle.
  ///
  /// In id, this message translates to:
  /// **'Kalibrasi GPS'**
  String get calibrationTitle;

  /// No description provided for @calibrationIntro.
  ///
  /// In id, this message translates to:
  /// **'Berdiri di area terbuka, jauh dari gedung dan pohon tinggi. Diam selama beberapa detik.'**
  String get calibrationIntro;

  /// No description provided for @calibrationStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai kalibrasi'**
  String get calibrationStart;

  /// No description provided for @calibrationMeasuring.
  ///
  /// In id, this message translates to:
  /// **'Mengukur sinyal GPS'**
  String get calibrationMeasuring;

  /// No description provided for @calibrationProgress.
  ///
  /// In id, this message translates to:
  /// **'{seconds} dari {total} detik'**
  String calibrationProgress(int seconds, int total);

  /// No description provided for @calibrationAccuracy.
  ///
  /// In id, this message translates to:
  /// **'Akurasi ±{meters} m'**
  String calibrationAccuracy(int meters);

  /// No description provided for @calibrationGoodTitle.
  ///
  /// In id, this message translates to:
  /// **'Sinyal GPS bagus'**
  String get calibrationGoodTitle;

  /// No description provided for @calibrationGoodBody.
  ///
  /// In id, this message translates to:
  /// **'Akurasi ±{meters} m. Rute sesi ini akan lebih stabil.'**
  String calibrationGoodBody(int meters);

  /// No description provided for @calibrationFairTitle.
  ///
  /// In id, this message translates to:
  /// **'Sinyal GPS cukup'**
  String get calibrationFairTitle;

  /// No description provided for @calibrationFairBody.
  ///
  /// In id, this message translates to:
  /// **'Akurasi ±{meters} m. Tetap di area terbuka saat mulai berlari.'**
  String calibrationFairBody(int meters);

  /// No description provided for @calibrationPoorTitle.
  ///
  /// In id, this message translates to:
  /// **'Sinyal GPS lemah'**
  String get calibrationPoorTitle;

  /// No description provided for @calibrationPoorBody.
  ///
  /// In id, this message translates to:
  /// **'Akurasi ±{meters} m. Coba di area lebih terbuka lalu ulangi kalibrasi.'**
  String calibrationPoorBody(int meters);

  /// No description provided for @calibrationRetry.
  ///
  /// In id, this message translates to:
  /// **'Ulangi kalibrasi'**
  String get calibrationRetry;

  /// No description provided for @calibrationDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get calibrationDone;

  /// No description provided for @calibrationServiceOff.
  ///
  /// In id, this message translates to:
  /// **'Lokasi perangkat mati. Hidupkan lokasi untuk mengukur sinyal.'**
  String get calibrationServiceOff;

  /// No description provided for @calibrationFailed.
  ///
  /// In id, this message translates to:
  /// **'Kalibrasi belum berhasil. Periksa izin lokasi lalu coba lagi.'**
  String get calibrationFailed;

  /// No description provided for @calibrationSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Hasil kalibrasi tidak tersimpan, tetapi sesi tetap bisa dimulai.'**
  String get calibrationSaveFailed;

  /// No description provided for @calibrationDueTitle.
  ///
  /// In id, this message translates to:
  /// **'Kalibrasi GPS'**
  String get calibrationDueTitle;

  /// No description provided for @calibrationDueBody.
  ///
  /// In id, this message translates to:
  /// **'Akurasi lebih stabil bila dikalibrasi di area terbuka.'**
  String get calibrationDueBody;

  /// No description provided for @calibrationCta.
  ///
  /// In id, this message translates to:
  /// **'Kalibrasi'**
  String get calibrationCta;

  /// No description provided for @calibrationCancel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan'**
  String get calibrationCancel;

  /// No description provided for @runSetupSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih mode lari dan pastikan sensor siap.'**
  String get runSetupSubtitle;

  /// No description provided for @runStartBlocked.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan lokasi dan notifikasi untuk mulai.'**
  String get runStartBlocked;

  /// No description provided for @close.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get close;

  /// No description provided for @backHome.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Home'**
  String get backHome;

  /// No description provided for @catalogTitle.
  ///
  /// In id, this message translates to:
  /// **'DIBUAT\nUNTUK GERAK.'**
  String get catalogTitle;

  /// No description provided for @catalogBody.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau komponen RUNWILD. Ubah tema dan kondisi layar untuk memeriksa tampilannya.'**
  String get catalogBody;

  /// No description provided for @appearance.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get darkTheme;

  /// No description provided for @actions.
  ///
  /// In id, this message translates to:
  /// **'Tombol'**
  String get actions;

  /// No description provided for @previewAction.
  ///
  /// In id, this message translates to:
  /// **'Coba tombol utama'**
  String get previewAction;

  /// No description provided for @previewSecondary.
  ///
  /// In id, this message translates to:
  /// **'Buka contoh dialog'**
  String get previewSecondary;

  /// No description provided for @actionFeedback.
  ///
  /// In id, this message translates to:
  /// **'Tombol utama berfungsi.'**
  String get actionFeedback;

  /// No description provided for @dialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Contoh dialog'**
  String get dialogTitle;

  /// No description provided for @dialogBody.
  ///
  /// In id, this message translates to:
  /// **'Dialog dapat ditutup dengan tombol di bawah, tombol kembali, atau Escape.'**
  String get dialogBody;

  /// No description provided for @disabledAction.
  ///
  /// In id, this message translates to:
  /// **'Belum tersedia'**
  String get disabledAction;

  /// No description provided for @loadingAction.
  ///
  /// In id, this message translates to:
  /// **'Memproses…'**
  String get loadingAction;

  /// No description provided for @loadingLabel.
  ///
  /// In id, this message translates to:
  /// **'Contoh tombol saat memproses'**
  String get loadingLabel;

  /// No description provided for @choices.
  ///
  /// In id, this message translates to:
  /// **'Pilihan'**
  String get choices;

  /// No description provided for @freeMode.
  ///
  /// In id, this message translates to:
  /// **'Bebas'**
  String get freeMode;

  /// No description provided for @metrics.
  ///
  /// In id, this message translates to:
  /// **'Angka dan satuan'**
  String get metrics;

  /// No description provided for @metricNote.
  ///
  /// In id, this message translates to:
  /// **'Contoh tampilan tanpa data aktivitas. Angka akan muncul dari sesi yang direkam.'**
  String get metricNote;

  /// No description provided for @distance.
  ///
  /// In id, this message translates to:
  /// **'Jarak'**
  String get distance;

  /// No description provided for @distanceUnit.
  ///
  /// In id, this message translates to:
  /// **'km'**
  String get distanceUnit;

  /// No description provided for @noValue.
  ///
  /// In id, this message translates to:
  /// **'--'**
  String get noValue;

  /// No description provided for @noDistance.
  ///
  /// In id, this message translates to:
  /// **'Jarak belum tersedia'**
  String get noDistance;

  /// No description provided for @states.
  ///
  /// In id, this message translates to:
  /// **'Kondisi layar'**
  String get states;

  /// No description provided for @statePreview.
  ///
  /// In id, this message translates to:
  /// **'Simulasi komponen, bukan status aktivitasmu.'**
  String get statePreview;

  /// No description provided for @stateContent.
  ///
  /// In id, this message translates to:
  /// **'Konten'**
  String get stateContent;

  /// No description provided for @stateLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat'**
  String get stateLoading;

  /// No description provided for @stateEmpty.
  ///
  /// In id, this message translates to:
  /// **'Kosong'**
  String get stateEmpty;

  /// No description provided for @stateError.
  ///
  /// In id, this message translates to:
  /// **'Gagal'**
  String get stateError;

  /// No description provided for @stateOffline.
  ///
  /// In id, this message translates to:
  /// **'Offline'**
  String get stateOffline;

  /// No description provided for @loadingActivities.
  ///
  /// In id, this message translates to:
  /// **'Memuat aktivitas…'**
  String get loadingActivities;

  /// No description provided for @emptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada aktivitas'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In id, this message translates to:
  /// **'Jalan 10 menit saja sudah cukup untuk memulai.'**
  String get emptyBody;

  /// No description provided for @errorTitle.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas belum bisa dimuat'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In id, this message translates to:
  /// **'Periksa koneksi, lalu coba lagi.'**
  String get errorBody;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get retry;

  /// No description provided for @offlineTitle.
  ///
  /// In id, this message translates to:
  /// **'Kamu sedang offline'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada aktivitas tersimpan di perangkat ini. Coba lagi saat terhubung.'**
  String get offlineBody;

  /// No description provided for @contentTitle.
  ///
  /// In id, this message translates to:
  /// **'Komponen siap diperiksa'**
  String get contentTitle;

  /// No description provided for @contentBody.
  ///
  /// In id, this message translates to:
  /// **'Warna, tipografi, dan jarak mengikuti sistem desain RUNWILD.'**
  String get contentBody;

  /// No description provided for @backend.
  ///
  /// In id, this message translates to:
  /// **'Koneksi Firebase'**
  String get backend;

  /// No description provided for @backendLocal.
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi belum dipasang. Katalog berjalan lokal.'**
  String get backendLocal;

  /// No description provided for @backendConnecting.
  ///
  /// In id, this message translates to:
  /// **'Menghubungkan Firebase…'**
  String get backendConnecting;

  /// No description provided for @backendReady.
  ///
  /// In id, this message translates to:
  /// **'Firebase berhasil diinisialisasi.'**
  String get backendReady;

  /// No description provided for @backendError.
  ///
  /// In id, this message translates to:
  /// **'Firebase belum bisa dihubungkan. Periksa konfigurasi proyek lalu coba lagi.'**
  String get backendError;

  /// No description provided for @backendInvalid.
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi Firebase belum lengkap. Lengkapi konfigurasi lokal, lalu jalankan ulang aplikasi.'**
  String get backendInvalid;

  /// No description provided for @pageMissing.
  ///
  /// In id, this message translates to:
  /// **'Layar tidak ditemukan'**
  String get pageMissing;

  /// No description provided for @pageMissingBody.
  ///
  /// In id, this message translates to:
  /// **'Alamat ini belum tersedia. Kembali ke Home untuk melanjutkan.'**
  String get pageMissingBody;

  /// No description provided for @activityDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Aktivitas'**
  String get activityDetailTitle;

  /// No description provided for @activityNotFound.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas tidak ditemukan'**
  String get activityNotFound;

  /// No description provided for @activityNotFoundBody.
  ///
  /// In id, this message translates to:
  /// **'Sesi lari ini mungkin telah dihapus atau tidak tersedia di perangkat ini.'**
  String get activityNotFoundBody;

  /// No description provided for @activityEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Judul & Catatan'**
  String get activityEditTitle;

  /// No description provided for @activityEditTitleDialog.
  ///
  /// In id, this message translates to:
  /// **'Ubah Judul Sesi'**
  String get activityEditTitleDialog;

  /// No description provided for @activityTitleLabel.
  ///
  /// In id, this message translates to:
  /// **'Judul Sesi'**
  String get activityTitleLabel;

  /// No description provided for @activityTitleHint.
  ///
  /// In id, this message translates to:
  /// **'Misal: Lari Pagi Santai'**
  String get activityTitleHint;

  /// No description provided for @activitySaveSuccess.
  ///
  /// In id, this message translates to:
  /// **'Perubahan berhasil disimpan'**
  String get activitySaveSuccess;

  /// No description provided for @activityDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus Aktivitas'**
  String get activityDelete;

  /// No description provided for @activityDeletePrompt.
  ///
  /// In id, this message translates to:
  /// **'Hapus aktivitas ini? Riwayat sesi dan rute akan dihapus permanen.'**
  String get activityDeletePrompt;

  /// No description provided for @activityDeleteSuccess.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas berhasil dihapus'**
  String get activityDeleteSuccess;

  /// No description provided for @activityShareButton.
  ///
  /// In id, this message translates to:
  /// **'Bagikan Sesi'**
  String get activityShareButton;

  /// No description provided for @activitySplitsTitle.
  ///
  /// In id, this message translates to:
  /// **'Split per Kilometer'**
  String get activitySplitsTitle;

  /// No description provided for @activityIntervalActualTitle.
  ///
  /// In id, this message translates to:
  /// **'Statistik Interval'**
  String get activityIntervalActualTitle;

  /// No description provided for @activityIntervalRoundsLabel.
  ///
  /// In id, this message translates to:
  /// **'PUTARAN'**
  String get activityIntervalRoundsLabel;

  /// No description provided for @activityIntervalRunLabel.
  ///
  /// In id, this message translates to:
  /// **'WAKTU LARI'**
  String get activityIntervalRunLabel;

  /// No description provided for @activityIntervalWalkLabel.
  ///
  /// In id, this message translates to:
  /// **'WAKTU JALAN'**
  String get activityIntervalWalkLabel;

  /// No description provided for @activityIntervalPlanTitle.
  ///
  /// In id, this message translates to:
  /// **'Rencana Interval'**
  String get activityIntervalPlanTitle;

  /// No description provided for @activityIntervalPlanRunLabel.
  ///
  /// In id, this message translates to:
  /// **'LARI / PUTARAN'**
  String get activityIntervalPlanRunLabel;

  /// No description provided for @activityIntervalPlanWalkLabel.
  ///
  /// In id, this message translates to:
  /// **'JALAN / PUTARAN'**
  String get activityIntervalPlanWalkLabel;

  /// No description provided for @activityIntervalPlanRoundsLabel.
  ///
  /// In id, this message translates to:
  /// **'PUTARAN RENCANA'**
  String get activityIntervalPlanRoundsLabel;

  /// No description provided for @activityIntervalPlanNote.
  ///
  /// In id, this message translates to:
  /// **'Sesi ini tersimpan sebelum rincian aktual dicatat. Angka di atas adalah rencana interval, bukan hasil aktual.'**
  String get activityIntervalPlanNote;

  /// No description provided for @activityRouteTitle.
  ///
  /// In id, this message translates to:
  /// **'Peta Rute Sesi'**
  String get activityRouteTitle;

  /// No description provided for @activityNoRoute.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada rekaman rute GPS pada sesi ini.'**
  String get activityNoRoute;

  /// No description provided for @homeThisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get homeThisWeek;

  /// No description provided for @homeWeeklyGoal.
  ///
  /// In id, this message translates to:
  /// **'Target Mingguan'**
  String get homeWeeklyGoal;

  /// No description provided for @homeWeeklyGoalProgress.
  ///
  /// In id, this message translates to:
  /// **'{completed} dari {target} sesi ({percent}%)'**
  String homeWeeklyGoalProgress(int completed, int target, int percent);

  /// No description provided for @homeStreak.
  ///
  /// In id, this message translates to:
  /// **'Streak {weeks} minggu berturut-turut'**
  String homeStreak(int weeks);

  /// No description provided for @homeRecommendationTitle.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi Hari Ini'**
  String get homeRecommendationTitle;

  /// No description provided for @homeRecBeginnerTitle.
  ///
  /// In id, this message translates to:
  /// **'Coba Pemula Santai'**
  String get homeRecBeginnerTitle;

  /// No description provided for @homeRecBeginnerDesc.
  ///
  /// In id, this message translates to:
  /// **'20 menit interval ramah sendi: Jalan 2 menit / Lari 1 menit x 8 ronde.'**
  String get homeRecBeginnerDesc;

  /// No description provided for @homeRecClassicTitle.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan Ritme: Interval 1:1'**
  String get homeRecClassicTitle;

  /// No description provided for @homeRecClassicDesc.
  ///
  /// In id, this message translates to:
  /// **'20 menit: Jalan 1 menit / Lari 1 menit x 10 ronde untuk membangun stamina.'**
  String get homeRecClassicDesc;

  /// No description provided for @homeRecFreeTitle.
  ///
  /// In id, this message translates to:
  /// **'Jalan / Lari Bebas'**
  String get homeRecFreeTitle;

  /// No description provided for @homeRecFreeDesc.
  ///
  /// In id, this message translates to:
  /// **'Lari santai tanpa tekanan target atau jeda waktu.'**
  String get homeRecFreeDesc;

  /// No description provided for @homeSeeProgress.
  ///
  /// In id, this message translates to:
  /// **'Lihat Tren & Rekor Pribadi'**
  String get homeSeeProgress;

  /// No description provided for @progressTitle.
  ///
  /// In id, this message translates to:
  /// **'Progress & Rekor'**
  String get progressTitle;

  /// No description provided for @progressPeriodWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get progressPeriodWeek;

  /// No description provided for @progressPeriodMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Ini'**
  String get progressPeriodMonth;

  /// No description provided for @progressPeriodAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get progressPeriodAll;

  /// No description provided for @progressStatsTitle.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Statistik'**
  String get progressStatsTitle;

  /// No description provided for @progressTotalDistance.
  ///
  /// In id, this message translates to:
  /// **'TOTAL JARAK'**
  String get progressTotalDistance;

  /// No description provided for @progressTotalTime.
  ///
  /// In id, this message translates to:
  /// **'TOTAL WAKTU'**
  String get progressTotalTime;

  /// No description provided for @progressTotalSessions.
  ///
  /// In id, this message translates to:
  /// **'TOTAL SESI'**
  String get progressTotalSessions;

  /// No description provided for @progressTotalCalories.
  ///
  /// In id, this message translates to:
  /// **'TOTAL KALORI'**
  String get progressTotalCalories;

  /// No description provided for @progressCaloriesNote.
  ///
  /// In id, this message translates to:
  /// **'Kalori adalah perkiraan, bukan hasil pengukuran medis.'**
  String get progressCaloriesNote;

  /// No description provided for @progressAvgPace.
  ///
  /// In id, this message translates to:
  /// **'PACE RATA-RATA'**
  String get progressAvgPace;

  /// No description provided for @progressRecordsTitle.
  ///
  /// In id, this message translates to:
  /// **'Rekor Pribadi (Personal Best)'**
  String get progressRecordsTitle;

  /// No description provided for @progressRecordLongestDist.
  ///
  /// In id, this message translates to:
  /// **'Jarak Terjauh'**
  String get progressRecordLongestDist;

  /// No description provided for @progressRecordLongestDur.
  ///
  /// In id, this message translates to:
  /// **'Durasi Terlama'**
  String get progressRecordLongestDur;

  /// No description provided for @progressRecordBest1k.
  ///
  /// In id, this message translates to:
  /// **'Pace Rata-rata Terbaik (≥1 km)'**
  String get progressRecordBest1k;

  /// No description provided for @progressRecordBest5k.
  ///
  /// In id, this message translates to:
  /// **'Pace Rata-rata Terbaik (≥5 km)'**
  String get progressRecordBest5k;

  /// No description provided for @progressNoRecords.
  ///
  /// In id, this message translates to:
  /// **'Belum ada rekor pribadi. Mulai sesi lari pertamamu untuk mencatat rekor!'**
  String get progressNoRecords;

  /// No description provided for @progressDistanceChart.
  ///
  /// In id, this message translates to:
  /// **'Grafik Tren Jarak'**
  String get progressDistanceChart;

  /// No description provided for @profileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil & Pengaturan'**
  String get profileTitle;

  /// No description provided for @profileSectionAccount.
  ///
  /// In id, this message translates to:
  /// **'Data Diri & Target'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionRunSettings.
  ///
  /// In id, this message translates to:
  /// **'Preferensi Lari & Suara'**
  String get profileSectionRunSettings;

  /// No description provided for @profileSectionPrivacy.
  ///
  /// In id, this message translates to:
  /// **'Privasi Sesi'**
  String get profileSectionPrivacy;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In id, this message translates to:
  /// **'Akun & Keamanan'**
  String get profileSectionSecurity;

  /// No description provided for @profileEditName.
  ///
  /// In id, this message translates to:
  /// **'Ubah Nama'**
  String get profileEditName;

  /// No description provided for @profileEditNameDialog.
  ///
  /// In id, this message translates to:
  /// **'Ubah Nama Pelari'**
  String get profileEditNameDialog;

  /// No description provided for @profileNameSaved.
  ///
  /// In id, this message translates to:
  /// **'Nama berhasil diperbarui'**
  String get profileNameSaved;

  /// No description provided for @profileUnitsLabel.
  ///
  /// In id, this message translates to:
  /// **'Satuan Jarak'**
  String get profileUnitsLabel;

  /// No description provided for @profileUnitsKm.
  ///
  /// In id, this message translates to:
  /// **'Kilometer (km)'**
  String get profileUnitsKm;

  /// No description provided for @profileAutoPause.
  ///
  /// In id, this message translates to:
  /// **'Jeda Otomatis'**
  String get profileAutoPause;

  /// No description provided for @profileAutoPauseDesc.
  ///
  /// In id, this message translates to:
  /// **'Jeda otomatis saat berhenti bergerak'**
  String get profileAutoPauseDesc;

  /// No description provided for @profileVoiceCues.
  ///
  /// In id, this message translates to:
  /// **'Panduan Suara'**
  String get profileVoiceCues;

  /// No description provided for @profileVoiceCuesDesc.
  ///
  /// In id, this message translates to:
  /// **'Audio progres lari dan interval'**
  String get profileVoiceCuesDesc;

  /// No description provided for @profileHaptics.
  ///
  /// In id, this message translates to:
  /// **'Getaran Haptik'**
  String get profileHaptics;

  /// No description provided for @profileHapticsDesc.
  ///
  /// In id, this message translates to:
  /// **'Getaran saat pergantian interval dan jeda'**
  String get profileHapticsDesc;

  /// No description provided for @profileCountdownCue.
  ///
  /// In id, this message translates to:
  /// **'Hitung Mundur Suara'**
  String get profileCountdownCue;

  /// No description provided for @profileRoundCue.
  ///
  /// In id, this message translates to:
  /// **'Tanda Putaran Interval'**
  String get profileRoundCue;

  /// No description provided for @profilePrivacyHideStartEnd.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan Titik Awal & Akhir'**
  String get profilePrivacyHideStartEnd;

  /// No description provided for @profilePrivacyHideStartEndDesc.
  ///
  /// In id, this message translates to:
  /// **'Radius 200 m di sekitar awal dan akhir rute disamarkan'**
  String get profilePrivacyHideStartEndDesc;

  /// No description provided for @profilePrivacyVisibility.
  ///
  /// In id, this message translates to:
  /// **'Visibilitas Default'**
  String get profilePrivacyVisibility;

  /// No description provided for @profilePrivacyPrivate.
  ///
  /// In id, this message translates to:
  /// **'Hanya Saya (Privat)'**
  String get profilePrivacyPrivate;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan berhasil disimpan'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan perubahan. Cek koneksi internetmu.'**
  String get profileUpdateError;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In id, this message translates to:
  /// **'Hapus Akun'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Akun Permanen?'**
  String get profileDeleteAccountConfirmTitle;

  /// No description provided for @profileDeleteAccountConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Tindakan ini tidak dapat dibatalkan. Seluruh data akun, profil, catatan aktivitas, rute GPS, dan rekor pribadimu akan dihapus selamanya.'**
  String get profileDeleteAccountConfirmBody;

  /// No description provided for @profileDeleteAccountDoubleTitle.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Penghapusan'**
  String get profileDeleteAccountDoubleTitle;

  /// No description provided for @profileDeleteAccountDoubleHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik HAPUS untuk melanjutkan penghapusan akun:'**
  String get profileDeleteAccountDoubleHint;

  /// No description provided for @profileDeleteAccountButton.
  ///
  /// In id, this message translates to:
  /// **'HAPUS AKUN SAYA'**
  String get profileDeleteAccountButton;

  /// No description provided for @profileDeleteAccountSuccess.
  ///
  /// In id, this message translates to:
  /// **'Akun dan semua data berhasil dihapus permanen'**
  String get profileDeleteAccountSuccess;

  /// No description provided for @profileDeleteAccountRecentLogin.
  ///
  /// In id, this message translates to:
  /// **'Demi keamanan, silakan keluar lalu masuk kembali sebelum menghapus akun.'**
  String get profileDeleteAccountRecentLogin;

  /// No description provided for @profileDeleteAccountError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus akun. Coba beberapa saat lagi.'**
  String get profileDeleteAccountError;

  /// No description provided for @shareTitle.
  ///
  /// In id, this message translates to:
  /// **'Kartu bagikan'**
  String get shareTitle;

  /// No description provided for @sharePreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get sharePreview;

  /// No description provided for @shareFormat.
  ///
  /// In id, this message translates to:
  /// **'Format'**
  String get shareFormat;

  /// No description provided for @shareTheme.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get shareTheme;

  /// No description provided for @shareStory.
  ///
  /// In id, this message translates to:
  /// **'Story (9:16)'**
  String get shareStory;

  /// No description provided for @shareSquare.
  ///
  /// In id, this message translates to:
  /// **'Persegi (1:1)'**
  String get shareSquare;

  /// No description provided for @shareLime.
  ///
  /// In id, this message translates to:
  /// **'Lime'**
  String get shareLime;

  /// No description provided for @sharePaper.
  ///
  /// In id, this message translates to:
  /// **'Kertas'**
  String get sharePaper;

  /// No description provided for @shareCharcoal.
  ///
  /// In id, this message translates to:
  /// **'Arang'**
  String get shareCharcoal;

  /// No description provided for @sharePhoto.
  ///
  /// In id, this message translates to:
  /// **'Foto latar'**
  String get sharePhoto;

  /// No description provided for @shareCamera.
  ///
  /// In id, this message translates to:
  /// **'Kamera'**
  String get shareCamera;

  /// No description provided for @shareGallery.
  ///
  /// In id, this message translates to:
  /// **'Galeri'**
  String get shareGallery;

  /// No description provided for @shareRemovePhoto.
  ///
  /// In id, this message translates to:
  /// **'Hapus foto'**
  String get shareRemovePhoto;

  /// No description provided for @sharePrivate.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan rute'**
  String get sharePrivate;

  /// No description provided for @sharePrivateHint.
  ///
  /// In id, this message translates to:
  /// **'Gambar hanya memuat statistik. Foto pilihanmu tetap terlihat.'**
  String get sharePrivateHint;

  /// No description provided for @shareAction.
  ///
  /// In id, this message translates to:
  /// **'Bagikan gambar'**
  String get shareAction;

  /// No description provided for @shareClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get shareClose;

  /// No description provided for @shareRouteHidden.
  ///
  /// In id, this message translates to:
  /// **'Rute disembunyikan'**
  String get shareRouteHidden;

  /// No description provided for @shareNoRoute.
  ///
  /// In id, this message translates to:
  /// **'Rute tidak direkam'**
  String get shareNoRoute;

  /// No description provided for @shareRun.
  ///
  /// In id, this message translates to:
  /// **'SESI LARI'**
  String get shareRun;

  /// No description provided for @shareDistanceUnit.
  ///
  /// In id, this message translates to:
  /// **'km'**
  String get shareDistanceUnit;

  /// No description provided for @shareDuration.
  ///
  /// In id, this message translates to:
  /// **'Durasi'**
  String get shareDuration;

  /// No description provided for @sharePace.
  ///
  /// In id, this message translates to:
  /// **'Pace /km'**
  String get sharePace;

  /// No description provided for @shareRecord.
  ///
  /// In id, this message translates to:
  /// **'Rekor pribadi'**
  String get shareRecord;

  /// No description provided for @shareTagline.
  ///
  /// In id, this message translates to:
  /// **'Run free.\nGo wild.'**
  String get shareTagline;

  /// No description provided for @shareImageError.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat memuat gambar. Coba lagi.'**
  String get shareImageError;

  /// No description provided for @shareError.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa membagikan kartu. Coba lagi.'**
  String get shareError;

  /// No description provided for @shareRouteError.
  ///
  /// In id, this message translates to:
  /// **'Rute belum dapat dimuat. Buka kembali halaman ini untuk mencoba lagi.'**
  String get shareRouteError;

  /// No description provided for @updateTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan tersedia'**
  String get updateTitle;

  /// No description provided for @updateInstalled.
  ///
  /// In id, this message translates to:
  /// **'Terpasang: v{version}'**
  String updateInstalled(String version);

  /// No description provided for @updateChanges.
  ///
  /// In id, this message translates to:
  /// **'Yang baru'**
  String get updateChanges;

  /// No description provided for @updateEmpty.
  ///
  /// In id, this message translates to:
  /// **'Catatan perubahan belum tersedia untuk versi ini.'**
  String get updateEmpty;

  /// No description provided for @updateDownload.
  ///
  /// In id, this message translates to:
  /// **'Unduh pembaruan'**
  String get updateDownload;

  /// No description provided for @updateLater.
  ///
  /// In id, this message translates to:
  /// **'Nanti saja'**
  String get updateLater;

  /// No description provided for @updateDownloadError.
  ///
  /// In id, this message translates to:
  /// **'Tautan unduhan belum dapat dibuka. Coba lagi.'**
  String get updateDownloadError;

  /// No description provided for @activityEditSheetTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul & catatan'**
  String get activityEditSheetTitle;

  /// No description provided for @activitySave.
  ///
  /// In id, this message translates to:
  /// **'Simpan perubahan'**
  String get activitySave;

  /// No description provided for @homeSessionHint.
  ///
  /// In id, this message translates to:
  /// **'Mulai dari langkahmu hari ini.'**
  String get homeSessionHint;

  /// No description provided for @homeLastRoute.
  ///
  /// In id, this message translates to:
  /// **'Rute terakhir'**
  String get homeLastRoute;

  /// No description provided for @homeWeekLabel.
  ///
  /// In id, this message translates to:
  /// **'Minggu ini'**
  String get homeWeekLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
