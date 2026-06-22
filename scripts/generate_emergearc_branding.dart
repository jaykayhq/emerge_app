// ignore_for_file: avoid_print
// ---------------------------------------------------------------------------
// EmergeArc Brand Image Generator
// Uses Pollinations.ai API with Flux model to generate branding concepts.
//
// Usage:
//   dart run scripts/generate_emergearc_branding.dart
//
// Each variant generates a unique logo concept and saves it to
// scripts/output/ as a JPG.
// ---------------------------------------------------------------------------
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const String apiKey =
    'sk_OGhhzmGVPhl6FFdSSHKiyAnHEx48dHlj';
const String baseUrl = 'https://gen.pollinations.ai';

/// Logo concept prompts for EmergeArc branding.
const List<LogoConcept> concepts = [
  LogoConcept(
    name: 'logo_rising_arc',
    prompt:
        'A sleek, minimal app icon for "EmergeArc" — a dark cosmic background '
        'with a single luminous arc rising from bottom-left to top-right, '
        'with a bright star or dot at the apex. The arc glows with a gradient '
        'from deep violet to neon green (#2BEE79). Clean, premium, no text. '
        'Square 1:1, minimalist logo design, dark mode.',
  ),
  LogoConcept(
    name: 'logo_letter_e_with_arc',
    prompt:
        'A minimalist app icon featuring a lowercase "e" that extends into a '
        'sweeping arc above it. The "e" is drawn with a neon teal line '
        '(color #2BEE79) on a deep cosmic purple-black background (#0A0A1A). '
        'The arc glows subtly. Modern, clean tech logo, no text, square 1:1.',
  ),
  LogoConcept(
    name: 'logo_archway_keystone',
    prompt:
        'A simple stone archway icon representing "arc" — two pillars with an '
        'arched top and a glowing keystone at the center. The keystone glows '
        'neon green (#2BEE79). Dark cosmic background (#0A0A1A). '
        'Minimalist, architectural logo, square 1:1, no text.',
  ),
  LogoConcept(
    name: 'logo_golden_arc_path',
    prompt:
        'A dark circular background with a golden arc path sweeping from '
        'left to right, dotted with small bright nodes along the curve. '
        'The arc transitions from deep violet to warm gold to neon green. '
        'Abstract path of progress. Minimalist app icon, square 1:1, no text, '
        'dark background #0A0A1A.',
  ),
  LogoConcept(
    name: 'logo_eclipse_rising',
    prompt:
        'A minimalist app icon showing a partial eclipse — a dark circle '
        'with a thin glowing neon green (#2BEE79) crescent edge on the '
        'top-right. The glow casts a soft light on the cosmic purple-black '
        'background. Clean, geometric, premium feel. Square 1:1, no text.',
  ),
];

void main(List<String> args) async {
  // Parse flags
  final onlyIndex = args.contains('--only')
      ? args.indexOf('--only') + 1 < args.length
          ? int.tryParse(args[args.indexOf('--only') + 1])
          : null
      : null;

  final outputDir = Directory('scripts/output');

  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  print('╔══════════════════════════════════════════════╗');
  print('║      EmergeArc Brand Image Generator        ║');
  print('║      Flux via Pollinations.ai               ║');
  print('╚══════════════════════════════════════════════╝');
  print('');

  final toGenerate = onlyIndex != null
      ? [concepts[onlyIndex]]
      : concepts;

  for (var i = 0; i < toGenerate.length; i++) {
    final concept = toGenerate[i];
    final outputPath = '${outputDir.path}/${concept.name}.jpg';

    print('─── [${i + 1}/${toGenerate.length}] ${concept.name} ───');
    print('   Prompt: ${concept.prompt.substring(0, 80)}...');
    print('   Output: $outputPath');
    print('');

    try {
      final stopwatch = Stopwatch()..start();
      await generateImage(concept.prompt, outputPath);
      stopwatch.stop();
      print('   ✅ Done in ${stopwatch.elapsed.inSeconds}s');
      print('');
    } catch (e) {
      print('   ❌ Error: $e');
      print('');
    }
  }

  print('✨ All done! Files saved to ${outputDir.path}/');
  print('');
  print('   Tip: open scripts/output/ in your file browser to view results.');
}

/// Generates an image using Pollinations.ai Flux model and saves to [outputPath].
Future<void> generateImage(String prompt, String outputPath) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 60)
    ..autoUncompress = true;

  try {
    final encodedPrompt = Uri.encodeComponent(prompt);
    final url = Uri.parse(
      '$baseUrl/image/$encodedPrompt?model=flux&width=1024&height=1024&seed=${Random().nextInt(99999)}',
    );

    final request = await client.getUrl(url);
    request.headers.set('Authorization', 'Bearer $apiKey');

    final response = await request.close();

    if (response.statusCode != 200) {
      final body = await response.transform(utf8.decoder).join();
      throw HttpException(
        'API returned ${response.statusCode}: $body',
        uri: url,
      );
    }

    // Stream response bytes to file
    final file = File(outputPath);
    final sink = file.openWrite();
    await response.pipe(sink);
    await sink.flush();
    await sink.close();

    final size = file.lengthSync();
    final sizeKb = (size / 1024).toStringAsFixed(1);
    print('   📦 File size: ${sizeKb}KB');
  } finally {
    client.close();
  }
}

/// A logo concept with a name and image prompt.
class LogoConcept {
  final String name;
  final String prompt;

  const LogoConcept({required this.name, required this.prompt});
}
