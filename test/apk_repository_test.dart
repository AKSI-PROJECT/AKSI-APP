import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aksi/features/apk_scanner/domain/services/apk_repository.dart';

void main() {
  late Directory tempDir;
  final repo = ApkRepository();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('apk_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<ApkReputation> scanDummyApk(String name) async {
    // File APK dummy: cukup nama + ukuran, scanApk tidak membaca isi file.
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(List.filled(1024 * 1024, 0)); // 1 MB
    return repo.scanApk(file);
  }

  group('ApkRepository.scanApk', () {
    test('modus undangan -> dangerous', () async {
      final r = await scanDummyApk('undangan.apk');
      expect(r.status, ApkStatus.dangerous);
    });

    test('aplikasi judol slot -> dangerous', () async {
      final r = await scanDummyApk('slotgacor.apk');
      expect(r.status, ApkStatus.dangerous);
    });

    test('mod whatsapp / update -> dangerous', () async {
      final r = await scanDummyApk('whatsapp_update.apk');
      expect(r.status, ApkStatus.dangerous);
    });

    test('ekstensi ganda .jpg.apk -> dangerous', () async {
      final r = await scanDummyApk('foto.jpg.apk');
      expect(r.status, ApkStatus.dangerous);
    });

    test('apk normal -> safe', () async {
      final r = await scanDummyApk('aplikasi_normal.apk');
      expect(r.status, ApkStatus.safe);
    });
  });
}
