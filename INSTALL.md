# 📦 Panduan Instalasi PhoneAsWatch

Panduan ini mencakup dua skenario:

1. **Instal APK di HP Android** (tanpa perlu Flutter).
2. **Menjalankan project dari source code** untuk development di Android, iOS, atau web.

> **Catatan hardware:** fitur PPG (detak jantung) membutuhkan **kamera belakang + flash**, sedangkan step/sleep membutuhkan **akselerometer dan mikrofon**. Barometer hanya tersedia di sebagian HP. Karena itu, aplikasi sebaiknya dijalankan di **HP fisik**, bukan emulator.

---

## Kompatibilitas Android

APK PhoneAsWatch saat ini memakai `minSdk 24` dan `targetSdk 36`, sehingga **Android 11 ke atas sudah didukung** — bahkan Android 7.0+ juga masih bisa memasangnya.

| Versi Android | Status | Catatan |
|---|---|---|
| Android 11 (API 30) | ✅ Didukung | Runtime permission kamera, mikrofon, activity recognition |
| Android 12 / 12L (API 31–32) | ✅ Didukung | Permission model & sensor high-sampling |
| Android 13 (API 33) | ✅ Didukung | Tidak membutuhkan notifikasi/media permission |
| Android 14 (API 34) | ✅ Didukung | — |
| Android 15 (API 35) | ✅ Didukung | UI sudah edge-to-edge + SafeArea |
| Android 16 (API 36) | ✅ Didukung | Target SDK aplikasi |
| Android 7–10 (API 24–29) | ✅ Masih bisa | Di luar target minimum yang kamu minta |

Arsitektur native yang dibundel: **arm64-v8a**, **armeabi-v7a**, dan **x86_64**. Hampir semua HP Android 11+ memakai arm64-v8a.

> Ingin APK **hanya** bisa dipasang di Android 11+? Ubah `minSdk = flutter.minSdkVersion` menjadi `minSdk = 30` di [`android/app/build.gradle.kts`](android/app/build.gradle.kts), lalu build ulang. Saat ini `minSdk 24` sengaja dipakai agar kompatibilitas lebih luas; Android 11+ tetap aman.

---

## 1. Instal APK di HP Android (paling cepat)

APK release tersedia di folder [`dist/`](dist/):

```text
dist/phone_as_watch-1.0.0.apk
```

| Info APK | Nilai |
|---|---|
| Ukuran | ± 46 MB |
| Package | `com.example.phone_as_watch` |
| Versi | 1.0.0 (versionCode 1) |
| Minimum Android | 7.0 / API 24 |
| Target SDK | Android 16 / API 36 |
| SHA-256 | `4479e6f88563cd8ecc516f8bc8a234fa88706100e8382198c053707477f755a7` |
| Signing | Debug key (untuk sideload, bukan Play Store) |

### Langkah instalasi

1. Pindahkan file APK ke HP melalui kabel USB, Google Drive, atau kirim ke diri sendiri.
2. Di HP, buka **Pengaturan → Tentang ponsel → Info versi**.
3. Ketuk **Nomor build** 7 kali sampai muncul pesan *"Anda sekarang menjadi developer"*.
4. Buka **Pengaturan → Sistem → Opsi developer**, aktifkan **USB debugging** (opsional untuk instal manual).
5. Buka file APK lewat **File Manager**, lalu pilih **Install**.
6. Jika muncul peringatan, izinkan **Install unknown apps** untuk aplikasi File Manager yang digunakan.
7. Buka **PhoneAsWatch**, lalu izinkan:
   - **Kamera** → untuk sensor PPG.
   - **Mikrofon** → untuk deteksi dengkuran saat tidur.
   - **Aktivitas fisik / Motion** → untuk langkah dan actigraphy.
8. Selesai. Coba ukur detak jantung dengan menutup kamera belakang + flash menggunakan ujung jari.

### Instal lewat ADB (opsional)

```bash
# cek HP terdeteksi
adb devices

# instal / update APK
adb install -r dist/phone_as_watch-1.0.0.apk
```

### Catatan keamanan

APK ini ditandatangani dengan **debug key** bawaan project agar bisa di-sideload. Untuk distribusi ke Play Store, buat keystore release sendiri dan ubah konfigurasi `signingConfig` di [`android/app/build.gradle.kts`](android/app/build.gradle.kts). Lihat bagian [Build APK release dengan keystore sendiri](#8-build-apk-release-dengan-keystore-sendiri).

---

## 2. Prasyarat development

| Kebutuhan | Versi / keterangan |
|---|---|
| Flutter SDK | **≥ 3.19** (disarankan stable terbaru; project dites di 3.47) |
| Dart SDK | ≥ 3.3 (sudah termasuk di Flutter) |
| Android Studio | Untuk Android SDK + emulator (opsional) |
| JDK | **17** (disarankan yang dibundel Android Studio / Homebrew OpenJDK 17) |
| Xcode | **15+** untuk iOS/macOS (hanya di macOS) |
| CocoaPods | Untuk dependency iOS |
| HP Android | **Android 7.0+ (API 24)**, kamera belakang + flash, akselerometer |
| Network | Koneksi internet untuk `flutter pub get` dan Gradle pertama kali |

---

## 3. Instal Flutter SDK

### macOS (Homebrew)

```bash
brew install --cask flutter
flutter --version
```

### macOS / Windows / Linux (manual)

1. Unduh Flutter SDK: <https://docs.flutter.dev/get-started/install>
2. Ekstrak ke folder permanen, misalnya `~/development/flutter`.
3. Tambahkan `flutter/bin` ke `PATH`:

```bash
# macOS/Linux (zsh)
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Windows (PowerShell)
$env:Path += ";C:\development\flutter\bin"
```

4. Verifikasi:

```bash
flutter --version
flutter doctor
```

### Siapkan Android

1. Instal **Android Studio**.
2. Di Android Studio: **Settings → Languages & Frameworks → Android SDK**.
3. Instal **Android SDK Platform**, **Android SDK Build-Tools**, dan **Android SDK Command-line Tools**.
4. Setujui lisensi:

```bash
flutter doctor --android-licenses
```

5. Pastikan `flutter doctor` menampilkan:

```text
[✓] Android toolchain - develop for Android devices
```

Jika JDK tidak terdeteksi:

```bash
flutter config --jdk-dir="/path/to/jdk-17"
```

### Siapkan iOS (khusus macOS)

1. Instal **Xcode** dari App Store.
2. Set Xcode sebagai toolchain aktif:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

3. Instal CocoaPods:

```bash
brew install cocoapods
# atau
sudo gem install cocoapods
```

4. Cek lagi:

```bash
flutter doctor -v
```

---

## 4. Ambil project dan dependency

Jika project sudah ada di komputer:

```bash
cd /path/ke/phone-as-watch
flutter pub get
```

Jika mengambil dari repository:

```bash
git clone <URL_REPOSITORY> phone-as-watch
cd phone-as-watch
flutter pub get
```

Jika dependency bermasalah:

```bash
flutter clean
flutter pub get
```

---

## 5. Siapkan HP fisik

### Android

1. Aktifkan **Opsi developer** (ketuk *Nomor build* 7 kali).
2. Aktifkan **USB debugging**.
3. Sambungkan HP dengan kabel USB, pilih mode **File Transfer / MTP**.
4. Saat muncul dialog **Allow USB debugging?**, pilih **Allow**.
5. Cek dari terminal:

```bash
flutter devices
adb devices
```

### iOS

1. Sambungkan iPhone, lalu percayai komputer (*Trust This Computer*).
2. Buka workspace Xcode:

```bash
open ios/Runner.xcworkspace
```

3. Pilih target **Runner → Signing & Capabilities**.
4. Pilih **Team** (Apple ID) dan ganti **Bundle Identifier** menjadi unik, misalnya `com.namamu.phoneaswatch`.
5. Di iPhone: **Settings → General → VPN & Device Management → Developer App** → **Trust**.
6. Cek:

```bash
flutter devices
```

> Simulator iOS **tidak memiliki kamera**, jadi fitur PPG tidak akan berfungsi di simulator.

---

## 6. Jalankan aplikasi

Jalankan pada perangkat yang terhubung:

```bash
flutter run
```

Pilih device tertentu:

```bash
flutter devices
flutter run -d <DEVICE_ID>
```

Contoh:

```bash
flutter run -d 192.168.1.10:5555   # Android via Wi-Fi debugging
flutter run -d 00008110-001A2C3E   # iPhone
```

### Izin saat pertama kali dibuka

| Izin | Digunakan untuk |
|---|---|
| Kamera | Membaca sinyal PPG dari ujung jari lewat kamera + flash |
| Mikrofon | Mendeteksi dengkuran / pola napas saat sleep tracking |
| Motion & Fitness / Sensors | Langkah, lantai, dan actigraphy tidur |
| Physical Activity / Activity Recognition | Klasifikasi aktivitas dan pedometer |

Jika izin ditolak:

- **Android:** Settings → Apps → PhoneAsWatch → Permissions.
- **iOS:** Settings → PhoneAsWatch → aktifkan Camera, Microphone, Motion & Fitness.

---

## 7. Build dan instal versi release

### Android APK

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Instal ke HP:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Atau salin APK ke HP dan buka lewat File Manager.

### APK per arsitektur (ukuran lebih kecil)

```bash
flutter build apk --split-per-abi
```

Output:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

Gunakan **arm64-v8a** untuk hampir semua HP Android modern.

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ios --release
flutter build ipa --release
```

Output IPA:

```text
build/ios/ipa/*.ipa
```

Untuk memasang ke iPhone tanpa App Store, gunakan Xcode:

1. Buka `ios/Runner.xcworkspace`.
2. Pilih device iPhone.
3. **Product → Archive**.
4. **Distribute App → Development / Ad Hoc**.

### Web (hanya untuk preview UI)

```bash
flutter build web --release
cd build/web
python3 -m http.server 8000
```

Buka <http://localhost:8000>.

> Di web, sebagian sensor dan kamera tidak tersedia atau berbeda perilakunya. Gunakan HP fisik untuk menguji PPG, pedometer, barometer, dan sleep tracking.

---

## 8. Build APK release dengan keystore sendiri

Secara default, `build.gradle.kts` memakai **debug key** untuk release. Untuk distribusi serius:

1. Buat keystore:

```bash
keytool -genkey -v -keystore ~/phoneaswatch-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias phoneaswatch
```

2. Buat `android/key.properties`:

```properties
storePassword=passwordKamu
keyPassword=passwordKamu
keyAlias=phoneaswatch
storeFile=/Users/namamu/phoneaswatch-release.jks
```

3. Load di `android/app/build.gradle.kts`, lalu ganti konfigurasi `signingConfigs` dan `buildTypes.release` agar memakai keystore tersebut.

Contoh sketsa:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

Jangan commit `key.properties` atau file `.jks` ke repository.

---

## 9. Verifikasi setelah instalasi

```bash
flutter analyze
flutter test
```

Hasil yang diharapkan:

```text
No issues found!
All tests passed!
```

Uji cepat di HP:

1. **Activity** → berjalan beberapa langkah, angka steps bertambah.
2. **Heart rate** → tekan *Measure heart rate*, tutup kamera belakang + flash dengan ujung jari selama ±15 detik.
3. **Sleep** → tekan *Start sleep tracking*, letakkan HP di kasur, lalu tekan *End sleep session*.
4. **Barometer/Floors** → hanya berfungsi jika HP memiliki sensor barometer.

---

## 10. Troubleshooting

| Masalah | Solusi |
|---|---|
| `flutter: command not found` | Tambahkan `flutter/bin` ke `PATH`, buka terminal baru. |
| `flutter doctor` error lisensi Android | `flutter doctor --android-licenses`, jawab `y`. |
| Gradle error / versi Java | Gunakan JDK 17 dan set `flutter config --jdk-dir=...`. |
| `pub get` gagal | Cek internet, lalu `flutter clean && flutter pub get`. |
| CocoaPods error | `cd ios && pod install --repo-update`. |
| Build pertama lama | Gradle mengunduh dependency; tunggu dan pastikan internet stabil. |
| Kamera hitam / flash tidak menyala | Gunakan HP fisik, izinkan kamera, tutup aplikasi kamera lain, lepas casing yang menutupi flash. |
| Ujung jari tidak terdeteksi | Tutup penuh lensa + flash, tekan lembut, jangan bergerak selama 15 detik. |
| Steps tidak bertambah | Aktifkan izin Physical Activity; coba berjalan beberapa langkah dengan HP di tangan/saku. |
| Floors selalu 0 | HP tidak memiliki barometer; ini normal. |
| Sleep tidak merekam | Aktifkan mikrofon, biarkan aplikasi tetap berjalan, matikan optimasi baterai untuk aplikasi ini. |
| Android 11+ meminta izin ulang | Android dapat mencabut izin aplikasi yang lama tidak dipakai; izinkan lagi lewat dialog atau Settings → Apps → PhoneAsWatch. |
| Kamera/mic mati setelah app di-background | Android 11+ memakai one-time permission untuk mic/kamera; buka lagi aplikasi dan izinkan saat diminta. |
| `MissingPluginException` di web/emulator | Plugin hardware tidak tersedia di platform tersebut; jalankan di HP fisik. |
| APK tidak bisa diinstal | Hapus versi lama dengan package ID sama, izinkan *Install unknown apps*, cek arsitektur APK. |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Ada aplikasi lama dengan package sama tetapi tanda tangan berbeda; uninstall dulu, lalu instal ulang. |
| Play Protect memblokir APK | Pilih **More details → Install anyway** (APK di-sideload, bukan dari Play Store). |
| Xiaomi/Redmi tidak bisa install via USB | Aktifkan **Install via USB** di Opsi developer; izinkan instalasi dari sumber tidak dikenal. |
| iPhone: *Untrusted Developer* | Settings → General → VPN & Device Management → Trust aplikasi. |
| Aplikasi iOS berhenti setelah beberapa hari | Provisioning Apple ID gratis berlaku ±7 hari; build ulang lewat Xcode atau gunakan akun developer berbayar. |
| iPhone: build signing gagal | Pilih Team di Xcode, ganti bundle identifier unik, lalu `flutter clean`. |

---

## 11. Catatan penggunaan

- **PPG / heart rate** memakai kamera belakang dan flash; hasil bisa terpengaruh gerakan, tekanan jari, dan cahaya sekitar.
- **Sleep tracking** sebaiknya dilakukan sambil HP di-charge dan diletakkan di kasur; `wakelock_plus` menjaga layar/proses tetap aktif.
- **Barometer** tidak tersedia di semua HP; fitur floors akan tetap 0 jika sensor tidak ada.
- Semua pemrosesan sinyal dilakukan **on-device** di Dart. Tidak ada data yang dikirim ke cloud.
- Aplikasi ini bukan alat medis; gunakan sebagai eksperimen/edukasi, bukan diagnosis.

---

## 12. Quick start (sudah punya Flutter)

```bash
cd phone-as-watch
flutter pub get
flutter devices
flutter run
```

Build APK:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
