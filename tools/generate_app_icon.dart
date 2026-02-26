import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> main() async {
  final apiKey = String.fromEnvironment('POLLINATIONS_API_KEY');
  if (apiKey.isEmpty) {
    debugPrint('Please provide the POLLINATIONS_API_KEY via --dart-define');
    exit(1);
  }

  final prompt = '''
    A premium minimalist app icon representing an inner fire. 
    A stylized dynamic flame burning with a vibrant mixture of emerald green and royal purple glows. 
    The flame is centered on a deep obsidian or black background. 
    Sleek modern design with subtle glassmorphism effects and soft internal lighting. 
    High-end digital art style. No text.
  ''';

  final tasks = [
    {
      'model': 'flux',
      'filename': 'assets/images/app_icon_flame_flux_1.png',
      'seed': '42',
    },
    {
      'model': 'flux',
      'filename': 'assets/images/app_icon_flame_flux_2.png',
      'seed': '100',
    },
    {
      'model': 'gptimage',
      'filename': 'assets/images/app_icon_flame_gptimage.png',
      'seed': '42',
    },
  ];

  for (final task in tasks) {
    debugPrint('Generating \${task["filename"]} using \${task["model"]}...');
    await generateImage(
      apiKey: apiKey,
      prompt: prompt,
      model: task['model']!,
      outputPath: task['filename']!,
      seed: task['seed']!,
    );
    // Be nice to the API
    await Future.delayed(const Duration(seconds: 2));
  }
}

Future<void> generateImage({
  required String apiKey,
  required String prompt,
  required String model,
  required String outputPath,
  required String seed,
}) async {
  final baseUrl = 'https://gen.pollinations.ai/image';

  final params = {
    'model': model,
    'width': '1024',
    'height': '1024',
    'seed': seed,
    'enhance': 'true',
    'negative_prompt': 'text, watermark, words, letters, blurry, low quality',
  };

  final url = Uri.parse(
    '$baseUrl/${Uri.encodeComponent(prompt.trim())}',
  ).replace(queryParameters: params);

  try {
    final response = await http
        .get(
          url,
          headers: {'Authorization': 'Bearer $apiKey', 'Accept': 'image/*'},
        )
        .timeout(const Duration(minutes: 2));

    if (response.statusCode == 200) {
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
      debugPrint('✅ Saved to $outputPath');
    } else {
      debugPrint('❌ Failed: HTTP ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    debugPrint('❌ Error: $e');
  }
}
