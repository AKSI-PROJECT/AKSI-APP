import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aksi/features/link_checker/domain/services/link_repository.dart';

void main() async {
  // Muat .env nyata dari disk; test di-skip bila key tidak tersedia.
  var skipLive = true;
  if (File('.env').existsSync()) {
    dotenv.testLoad(fileInput: File('.env').readAsStringSync());
    skipLive =
        (dotenv.env['SAFE_BROWSING_API_KEY'] ?? '').trim().isEmpty;
  }

  final repo = LinkRepository();

  group('LinkRepository.checkLink (live GSB, .env)', () {
    test('situs judol -> dangerous (heuristik)', () async {
      final r = await repo.checkLink('judibola.org');
      expect(r.status, LinkStatus.dangerous);
    }, skip: skipLive);

    test('situs pornografi -> dangerous (heuristik)', () async {
      final r = await repo.checkLink('xnxx.com');
      expect(r.status, LinkStatus.dangerous);
    }, skip: skipLive);

    test('domain whitelist -> safe (tanpa GSB)', () async {
      final r = await repo.checkLink('google.com');
      expect(r.status, LinkStatus.safe);
    }, skip: skipLive);

    test('domain bersih tak dikenal -> GSB live (safe/unknown, bukan dangerous)',
        () async {
      final r = await repo.checkLink('example.com');
      expect(
        r.status,
        isNot(LinkStatus.dangerous),
        reason: 'GSB tidak menandai example.com',
      );
    }, skip: skipLive);
  });
}