import 'package:flutter_test/flutter_test.dart';
import 'package:aksi/features/email_checker/domain/services/email_repository.dart';

void main() {
  final repo = EmailRepository();

  group('EmailRepository.checkEmailReputationAPI (fallback)', () {
    // Tanpa API key emailrep.io -> HTTP 429 -> selalu jatuh ke jalur fallback.
    test('email bernada judol -> suspicious', () async {
      final r = await repo.checkEmailReputationAPI('hrdslotjudi@gmail.com');
      expect(r, isNotNull);
      expect(r!.suspicious, isTrue);
    });

    test('email gmail menyamar resmi (bca) -> suspicious', () async {
      final r = await repo.checkEmailReputationAPI('admin.bca@gmail.com');
      expect(r, isNotNull);
      expect(r!.suspicious, isTrue);
    });

    test('email biasa -> tidak suspicious', () async {
      final r = await repo.checkEmailReputationAPI('budi@gmail.com');
      expect(r, isNotNull);
      expect(r!.suspicious, isFalse);
    });
  });
}
