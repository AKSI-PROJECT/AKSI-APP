import 'package:flutter_test/flutter_test.dart';
import 'package:aksi/features/link_checker/domain/services/link_heuristics.dart';
import 'package:aksi/features/link_checker/domain/services/link_repository.dart';

void main() {
  group('LinkHeuristics.isJudolLink', () {
    final judol = [
      'judibola.org',
      'situs-judi-slot.com',
      'qqpulsa88.net',
      'rajabandarqiu.com',
      'bandarqq.top',
      'link-alternatif-188bet.xyz',
      'rajaslot888.site',
      'paus4d.online',
      'hokibet.top',
      'toto4d.net',
      'slotgacor88.com',
      'sbobet.com',
      '1xbet.com',
      'pragmaticplay88.net',
      'w88.com',
    ];

    for (final url in judol) {
      test('$url terdeteksi judol', () {
        expect(LinkHeuristics.isJudolLink(url), isTrue, reason: url);
      });
    }

    final notJudol = [
      'google.com',
      'github.com',
      'gratis.com',
      'rating.com',
      'pragmatic.com',
      'toto.com',
      'paus4d.com',
    ];

    for (final url in notJudol) {
      test('$url bukan judol (no false positive)', () {
        expect(LinkHeuristics.isJudolLink(url), isFalse, reason: url);
      });
    }
  });

  group('LinkHeuristics.isPornLink', () {
    final porn = ['pornhub.com', 'xnxx.com', 'bokep.tv', 'xhamster.com'];
    for (final url in porn) {
      test('$url terdeteksi pornografi', () {
        expect(LinkHeuristics.isPornLink(url), isTrue, reason: url);
      });
    }

    final notPorn = ['java.com', 'javascript.com', 'android.com'];
    for (final url in notPorn) {
      test('$url bukan pornografi', () {
        expect(LinkHeuristics.isPornLink(url), isFalse, reason: url);
      });
    }
  });

  group('LinkHeuristics.isMalwareOrScamLink', () {
    final malware = [
      'modapk.com',
      'keygen.com',
      'coinhive.com',
      'free-robux.com',
      'ngrok.io',
      'crack-software.com',
    ];
    for (final url in malware) {
      test('$url terdeteksi malware/scam', () {
        expect(LinkHeuristics.isMalwareOrScamLink(url), isTrue, reason: url);
      });
    }

    // 'rat' harus dihapus dari keyword agar 'gratis'/'rating' tidak false positive
    final notMalware = ['gratis.com', 'rating.com', 'ornament.com'];
    for (final url in notMalware) {
      test('$url bukan malware (fix false positive rat)', () {
        expect(LinkHeuristics.isMalwareOrScamLink(url), isFalse, reason: url);
      });
    }
  });

  group('LinkHeuristics.isSafeDomain', () {
    test('domain aman dengan boundary yang benar', () {
      expect(LinkHeuristics.isSafeDomain('www.google.com'), isTrue);
      expect(LinkHeuristics.isSafeDomain('google.com'), isTrue);
      expect(LinkHeuristics.isSafeDomain('evil-bri.co.id'), isFalse);
      expect(LinkHeuristics.isSafeDomain('bri.co.id.evil.com'), isFalse);
    });
  });

  group('LinkRepository.checkLink (fail-closed, tanpa API key)', () {
    final repo = LinkRepository();

    test('link judol -> dangerous', () async {
      final r = await repo.checkLink('judibola.org');
      expect(r.status, LinkStatus.dangerous);
    });

    test('link pornografi -> dangerous', () async {
      final r = await repo.checkLink('https://xnxx.com');
      expect(r.status, LinkStatus.dangerous);
    });

    test('domain whitelist -> safe', () async {
      final r = await repo.checkLink('https://google.com');
      expect(r.status, LinkStatus.safe);
    });

    test('tanpa sinyal & tanpa API key -> unknown (bukan safe)', () async {
      final r = await repo.checkLink('https://gratis.com');
      expect(r.status, LinkStatus.unknown);
    });
  });
}
