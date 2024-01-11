import 'package:http/http.dart';

Future<String> getStrokeOrder(String character, Client client) async {
  const baseUrl = "https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1/";

  final url = Uri.parse(baseUrl + character + ".json");

  final response = await client.get(url);

  if (response.statusCode != 200) {
    throw Exception("Failed to get stroke order for '$character'");
  }

  return response.body;
}
