import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<String>> openAiQualityChecks({
  required String apiKey,
  required String model,
  required String field,
  required String value,
  required List<String> checks,
}) async {
  final List<String> failedChecks = [];

  if (apiKey.isEmpty) {
    print("OpenAI API key is not set");
    return ["OpenAI API key is not set"];
  }

  for (final check in checks) {
    final prompt = """
    Your only job is to ascertain if the user's input meets this criterion '${check}' and output a boolean true or false, as JSON in this format {"evaluation": "true"}.
    """;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': value},
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to validate with OpenAI');
      }

      final data = jsonDecode(response.body);
      final aiResult = data['choices'][0]['message']['content'];
      final evaluation = jsonDecode(aiResult)['evaluation'];

      if (evaluation != "true") {
        failedChecks.add("$field does not meet the criterion: $check");
      }
    } catch (error) {
      print('Error during OpenAI API call: $error');
      failedChecks.add("Error evaluating $check: $error");
    }
  }

  return failedChecks;
}

