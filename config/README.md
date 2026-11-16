# Firebase lokal

Buat proyek Firebase dev dan prod terpisah; daftarkan aplikasi Android dan iOS
dengan ID `id.runwild.app`. Ambil nilai konfigurasi dari konsol untuk setiap
platform. File JSON di direktori ini diabaikan Git.

Untuk Android, simpan file unduhan Firebase sebagai `config/google-services.json`.
Jalankan `./tool/configure-firebase-android.ps1` dari PowerShell untuk membuat
`config/dev.android.json`. Pilih **RUNWILD Android Dev** di Run and Debug VS Code.

Google Sign-In memerlukan metode Google aktif dan SHA-1 sertifikat aplikasi
terdaftar pada aplikasi Android di Firebase. Unduh ulang file konfigurasi
setelah menambahkan SHA-1, lalu jalankan skrip di atas lagi. Skrip mengambil
ID klien OAuth web untuk `GOOGLE_SERVER_CLIENT_ID`.

Contoh bentuk `dev.android.json`:

```json
{
  "FIREBASE_API_KEY": "<dari Firebase>",
  "FIREBASE_APP_ID": "<app Android dev>",
  "FIREBASE_MESSAGING_SENDER_ID": "<sender ID>",
  "FIREBASE_PROJECT_ID": "<project dev>",
  "FIREBASE_STORAGE_BUCKET": "<bucket proyek>"
}
```

Untuk iOS gunakan App ID iOS dan tambahkan `FIREBASE_IOS_BUNDLE_ID`.
Untuk masuk dengan Apple, daftarkan bundle `id.runwild.app` di Apple Developer,
aktifkan **Sign in with Apple** di App ID dan pilih team signing di Xcode.
Di Firebase, daftarkan aplikasi iOS dengan bundle ID yang sama, aktifkan metode
**Apple**, dan masukkan konfigurasi iOS ke `config/dev.ios.json`.
Jalankan pada iPhone dari macOS dengan
`flutter run --dart-define-from-file=config/dev.ios.json`.
Uji masuk, pembatalan, buka ulang, serta penautan akun tamu dengan persetujuan pengguna.
Simpan masing-masing konfigurasi dev/prod terpisah, jalankan:

```sh
flutter run --dart-define-from-file=config/dev.android.json
```

Aktifkan metode **Email/Password** dan **Anonymous** pada Firebase Authentication.
Tanpa konfigurasi, layar autentikasi menampilkan pesan bahwa layanan belum tersedia.
Koneksi Firebase belum diuji hingga konfigurasi nyata diberikan. Jangan
menambahkan service-account private key ke aplikasi klien.

Untuk menguji profil awal, buat database Cloud Firestore di proyek dev.
Di tab **Rules**, salin isi `firebase/firestore.rules` lalu klik **Publish**.
Rules ini mengizinkan pemilik membaca dan membuat profilnya sendiri.

Tes rules lokal memerlukan Java 21 dan Node.js yang didukung Firebase CLI.
Jalankan `npm --prefix firebase ci`, lalu `npm --prefix firebase run test:emulator`.
