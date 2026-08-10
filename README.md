# Aksi

Aplikasi **Aksi** merupakan solusi cerdas berbasis mobile yang dikembangkan menggunakan Flutter. Aplikasi ini memanfaatkan keunggulan integrasi **Google ML Kit** untuk kecerdasan pemrosesan gambar dan teks, serta menggunakan **Supabase** sebagai fondasi backend.

---

## 🛠 Teknologi yang Digunakan

Aplikasi ini dibangun menggunakan *stack* teknologi modern untuk menjamin performa, keamanan, dan skalabilitas:

- **Framework:** Flutter (Mobile App)
- **Bahasa Pemrograman:** Dart
- **Backend as a Service (BaaS):** Supabase (Authentication & Database)
- **Machine Learning / AI Vision:** Google ML Kit 
  - *Document Scanner*
  - *Text Recognition (OCR)*
  - *Face Detection*
  - *Barcode Scanning*
- **Utilitas Utama:**
  - `flutter_dotenv`: Untuk manajemen environment variables (*security*)
  - `image_picker` & `file_picker`: Manajemen input file
  - `pdf`: Untuk manipulasi dokumen/PDF

---

## 📂 Struktur Project

Proyek ini mengimplementasikan pemisahan struktur direktori (*Clean Architecture* / *Feature-Driven*) yang terorganisir rapi di dalam folder `lib/`, yang memudahkan proses kolaborasi dan pemeliharaan jangka panjang:

```text
lib/
├── core/         # Berisi kode inti aplikasi (konstanta, konfigurasi, tema, helper, exception).
├── data/         # Lapisan data, berisi koneksi backend (contoh: supabase_service.dart), model data, dan repositori.
├── features/     # Modul-modul UI/fitur aplikasi (misal: fitur 'home'). Dipisah ke dalam presentation (UI) dan logic.
└── main.dart     # Entry point, titik awal eksekusi aplikasi Flutter.
```

Selain `lib/`, berikut beberapa struktur krusial lainnya:
- `assets/` : Menyimpan aset statis seperti gambar (contoh: `logo_icon.png`).
- `.env` : File kredensial (disembunyikan dari repository via `.gitignore` demi keamanan).

---

## ⚙️ Cara Instalasi

Untuk menyiapkan environment pengembangan aplikasi di mesin lokal, silakan ikuti panduan berikut:

1. **Clone Repository**
   Buka terminal, lalu jalankan:
   ```bash
   git clone <URL_REPOSITORY_ANDA>
   cd aksi
   ```

2. **Cek Persyaratan Sistem (Flutter SDK)**
   Pastikan Anda sudah menginstal **Flutter SDK (versi 3.10.8 ke atas)**. Verifikasi dengan menjalankan:
   ```bash
   flutter doctor
   ```

3. **Unduh Dependencies**
   Instal semua paket (library) yang tercatat pada `pubspec.yaml`:
   ```bash
   flutter pub get
   ```

4. **Konfigurasi Environment Variables (.env)**
   Aplikasi ini membutuhkan akses ke Supabase. Karena alasan keamanan, file rahasia tidak kami unggah ke repositori. 
   Buatlah sebuah file baru bernama `.env` di direktori paling luar (sejajar dengan `pubspec.yaml`), lalu tambahkan kunci rahasia berikut:
   ```env
   SUPABASE_URL=url_project_supabase_anda
   SUPABASE_ANON_KEY=anon_key_project_supabase_anda
   ```
   *(Catatan untuk Juri: Kunci API rahasia dapat diminta langsung kepada panitia atau perwakilan tim jika diperlukan untuk pengujian).*

---

## 🚀 Cara Menjalankan Aplikasi

Setelah proses instalasi berhasil, Anda bisa mencoba menjalankan aplikasi dengan langkah-langkah di bawah ini. Pastikan *emulator* (Android/iOS) sudah berjalan, atau *smartphone* asli Anda sudah terhubung (USB Debugging aktif).

**Menjalankan Aplikasi (Debug Mode):**
```bash
flutter run
```

*(Opsional)* **Membangun Aplikasi (Build APK Release):**
Jika ingin mencoba versi rilis (performa lebih cepat/asli), lakukan build ke format APK untuk Android:
```bash
flutter build apk --release
```
*Hasil APK dapat Anda temukan pada direktori: `build/app/outputs/flutter-apk/app-release.apk`*
