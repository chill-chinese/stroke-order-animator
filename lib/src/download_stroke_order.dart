import 'package:http/http.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

/// Downloads stroke order data for a single character.
///
/// Returns a JSON string that can be passed to the [StrokeOrder] constructor
/// or saved for offline usage.
Future<String> downloadStrokeOrder(String character, Client client) async {
  const baseUrl = 'https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1/';

  final url = Uri.parse('$baseUrl$character.json');

  final response = await client.get(url);

  if (response.statusCode != 200) {
    throw Exception("Failed to get stroke order for '$character'");
  }

  return response.body;
}
