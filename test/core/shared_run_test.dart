import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/shared_run.dart';

void main() {
  test('share link reports expiry and preserves public URL', () {
    final link = ShareLink.fromJson({
      'shareId': 'abc',
      'token': 'secret',
      'expiresAtUtc': '2026-09-04T00:00:00Z',
      'shareUrl': 'https://example.test/share-run?shareId=abc&token=secret',
    });

    expect(link.shareUrl, contains('shareId=abc'));
    expect(link.isExpiredAt(DateTime.utc(2026, 9, 3)), isFalse);
    expect(link.isExpiredAt(DateTime.utc(2026, 9, 4)), isTrue);
  });
}
