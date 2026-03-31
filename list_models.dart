import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  // List available models
  const String apiKey = 'AIzaSyAi4lvjgfHe6N_lk_5JP4xWJTHxQt004Zk';

  print('🔑 Listing available Gemini models...');

  const String url =
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';

  try {
    print('📤 Sending request to: $url');

    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));

    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();

    print('📥 Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(responseBody);

      print('✅ Available models:');
      if (data['models'] != null) {
        for (var model in data['models']) {
          if (model['supportedGenerationMethods']?.contains(
                'generateContent',
              ) ==
              true) {
            print(
              '  📌 ${model['name']} - ${model['displayName'] ?? 'No display name'}',
            );
          }
        }
      }
    } else {
      print('❌ API Error: ${response.statusCode} - $responseBody');
    }

    client.close();
  } catch (e) {
    print('❌ Exception: $e');
  }
}
