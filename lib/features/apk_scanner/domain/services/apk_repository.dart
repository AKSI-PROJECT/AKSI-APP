import 'dart:io';
import 'package:path/path.dart' as path;

enum ApkStatus { safe, dangerous, unknown }

class ApkReputation {
  final ApkStatus status;
  final String message;
  final String fileName;
  final double fileSizeMB;
  final List<String> detectedThreats;

  ApkReputation({
    required this.status,
    required this.message,
    required this.fileName,
    required this.fileSizeMB,
    this.detectedThreats = const [],
  });
}

class ApkRepository {
  Future<ApkReputation> scanApk(File file) async {
    await Future.delayed(const Duration(seconds: 2));

    final fileName = path.basename(file.path);
    final fileNameLower = fileName.toLowerCase();

    int sizeInBytes = 0;
    try {
      sizeInBytes = await file.length();
    } catch (e) {
      sizeInBytes = 0;
    }

    final fileSizeMB = sizeInBytes / (1024 * 1024);

    final suspiciousKeywords = [
      'undangan', 'pernikahan', 'resi', 'kurir', 'paket', 'tilang', 'surat',
      'bukti', 'transfer', 'tagihan', 'pajak', 'struk', 'pln', 'bpjs',
      'bansos', 'hadiah', 'undian', 'pemilu', 'kpu', 'panggilan', 'polri'
    ];

    List<String> threats = [];
    bool isDangerous = false;

    for (var keyword in suspiciousKeywords) {
      if (fileNameLower.contains(keyword)) {
        isDangerous = true;
        threats.add('Pola nama file mencurigakan (Modus $keyword)');
        break;
      }
    }

    final judolKeywords = [
      'slot', 'judi', 'togel', 'maxwin', 'gacor', 'sbobet', '1xbet', 'm88', 'bet365', 'poker', 'casino', 'rtp'
    ];

    for (var keyword in judolKeywords) {
      if (fileNameLower.contains(keyword)) {
        isDangerous = true;
        threats.add('Terindikasi aplikasi judi online (Judol)');
        break;
      }
    }

    if (fileNameLower.contains('.pdf.apk') ||
        fileNameLower.contains('.jpg.apk') ||
        fileNameLower.contains('.png.apk') ||
        fileNameLower.contains('.doc.apk') ||
        fileNameLower.contains('.docx.apk')) {
      isDangerous = true;
      threats.add('File menyamarkan diri sebagai dokumen (Ekstensi ganda)');
    }

    if (fileNameLower.contains('whatsapp') ||
        fileNameLower.contains('facebook') ||
        fileNameLower.contains('instagram')) {
      if (fileNameLower.contains('update') ||
          fileNameLower.contains('mod') ||
          fileNameLower.contains('premium')) {
        isDangerous = true;
        threats.add('Terindikasi aplikasi modifikasi/palsu dari pihak ketiga');
      }
    }

    if (isDangerous && fileSizeMB < 5.0) {
      threats.add(
        'Ukuran file sangat kecil, umum ditemui pada malware pencuri data (SMS Forwarder)',
      );
    }

    if (isDangerous) {
      return ApkReputation(
        status: ApkStatus.dangerous,
        message:
            'File APK ini terindikasi sebagai malware atau alat penipuan. JANGAN DIINSTAL!\n\n'
            'Peringatan: Mengunduh aplikasi sembarangan berisiko mencuri data pribadi, menginfeksi perangkat dengan virus, membobol akun bank, hingga mengambil alih kendali ponsel.',
        fileName: fileName,
        fileSizeMB: fileSizeMB,
        detectedThreats: threats,
      );
    } else {
      return ApkReputation(
        status: ApkStatus.safe,
        message:
            'Tidak ditemukan pola berbahaya pada file APK ini. Namun, tetaplah berhati-hati saat menginstal dari luar Play Store.',
        fileName: fileName,
        fileSizeMB: fileSizeMB,
      );
    }
  }
}
