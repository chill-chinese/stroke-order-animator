import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

import '../test_strokes.dart';
import 'download_stroke_order_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  test('Test existing stroke order retrieval', () async {
    final client = MockClient();

    when(client.get(any)).thenAnswer((_) async {
      return http.Response(strokeOrderJsons['永']!, 200);
    });
    await downloadStrokeOrder('永', client);

    verify(
      client.get(
        Uri.parse('https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1/'
            '永.json'),
      ),
    );
  });

  test('Test non-existing stroke order retrieval', () {
    final client = MockClient();
    when(client.get(any)).thenAnswer((_) async => http.Response('', 404));
    expect(
      () async => await downloadStrokeOrder('a', client),
      throwsA(
        predicate(
          (e) =>
              e is Exception &&
              e.toString() == "Exception: Failed to get stroke order for 'a'",
        ),
      ),
    );
  });
}
