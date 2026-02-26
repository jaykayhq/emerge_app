#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Full-Character Avatar Generator for Emerge App
//
// Generates complete character images via Pollinations.ai gptimage model.
// Each image = one full character (archetype × skinTone × hairStyle)
// with transparent background. No separate body parts needed.
//
// Usage:
//   dart run tools/generate_complete_avatars.dart --target=all
//   dart run tools/generate_complete_avatars.dart --target=bodies --archetype=athlete
//   dart run tools/generate_complete_avatars.dart --dry-run
//
// Requires POLLINATIONS_API_KEY environment variable.

import 'dart:io';

// API Configuration
const String apiKey = String.fromEnvironment('POLLINATIONS_API_KEY');
const String baseUrl = 'https://gen.pollinations.ai/image';

// Archetype descriptors for consistent character generation
const Map<String, Map<String, String>> archetypes = {
  'athlete': {
    'build': 'athletic sporty dynamic build, confident powerful stance',
    'outfit': 'modern athletic sportswear tracksuit, running shoes',
    'colors': '#ff6b6b',
  },
  'creator': {
    'build': 'artistic creative slender build, expressive pose',
    'outfit': 'casual bohemian artist apron, paint-stained clothes',
    'colors': '#ffd93d',
  },
  'scholar': {
    'build': 'lean intellectual studious build, poised stance',
    'outfit': 'smart tweed jacket with glasses, leather shoes',
    'colors': '#6bcb77',
  },
  'stoic': {
    'build': 'balanced strong meditative build, calm steady pose',
    'outfit': 'simple minimalist linen tunic, zen sandals',
    'colors': '#4dd4ac',
  },
  'mystic': {
    'build': 'ethereal flowing celestial build, serene floating pose',
    'outfit': 'flowing celestial robes with star patterns',
    'colors': '#bb6bd9',
  },
};

const List<String> skinTones = ['lightOlive', 'mediumBrown', 'darkEbony'];

const Map<String, String> skinToneDescriptors = {
  'lightOlive': 'light olive warm skin tone',
  'mediumBrown': 'medium brown warm skin tone',
  'darkEbony': 'dark ebony rich skin tone',
};

const Map<String, List<String>> hairstyles = {
  'athlete': ['buzz_cut', 'short_spiky', 'swept_back', 'pompadour', 'undercut'],
  'creator': [
    'messy_shag',
    'man_bun',
    'side_swept',
    'curly_afro',
    'dreadlocks',
  ],
  'scholar': [
    'neat_part',
    'slicked_back',
    'bob_cut',
    'wispy_bangs',
    'gray_academic',
  ],
  'stoic': [
    'monk_shave',
    'simple_crop',
    'center_part',
    'low_bun',
    'bald_with_beard',
  ],
  'mystic': [
    'flowing_long',
    'space_buns',
    'ethereal_wisps',
    'silver_vibrant',
    'cosmic_halos',
  ],
};

// Fixed seeds per archetype for style consistency
const Map<String, int> archetypeSeeds = {
  'athlete': 42,
  'creator': 84,
  'scholar': 126,
  'stoic': 168,
  'mystic': 210,
};

// Generation queue
List<GenerationTask> generationQueue = [];

class GenerationTask {
  final String prompt;
  final String negativePrompt;
  final String outputPath;
  final int width;
  final int height;
  final int seed;
  final String model;

  GenerationTask({
    required this.prompt,
    required this.negativePrompt,
    required this.outputPath,
    this.width = 512,
    this.height = 768,
    required this.seed,
    this.model = 'gptimage',
  });
}

// Main execution
Future<void> main(List<String> args) async {
  if (apiKey.isEmpty) {
    print('ERROR: POLLINATIONS_API_KEY not set.');
    print(
      'Run with: dart run --define=POLLINATIONS_API_KEY=sk_xxx tools/generate_complete_avatars.dart',
    );
    exit(1);
  }

  // Parse arguments
  String target = 'all';
  String? archetypeFilter;
  bool dryRun = false;

  for (final arg in args) {
    if (arg.startsWith('--target=')) {
      target = arg.substring('--target='.length);
    } else if (arg.startsWith('--archetype=')) {
      archetypeFilter = arg.substring('--archetype='.length);
    } else if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--help') {
      printUsage();
      exit(0);
    }
  }

  print('╔══════════════════════════════════════════╗');
  print('║  Emerge Avatar Generator v2.0            ║');
  print('║  Full-Character Variants (gptimage)      ║');
  print('╚══════════════════════════════════════════╝');
  print('');
  print('Target: $target');
  print('Archetype filter: ${archetypeFilter ?? "all"}');
  print('Dry run: $dryRun');
  print('');

  // Build generation queue
  buildGenerationQueue(target, archetypeFilter);

  print('Total tasks: ${generationQueue.length}');
  print('Estimated cost: ~${generationQueue.length * 2} pollen');
  print('');

  if (dryRun) {
    print('--- DRY RUN: Prompts Preview ---');
    for (final task in generationQueue) {
      print('');
      print('📁 ${task.outputPath}');
      print('🖼 Model: ${task.model} | Seed: ${task.seed}');
      print('📝 ${task.prompt.trim()}');
      print('🚫 ${task.negativePrompt}');
    }
    print('');
    print('Dry run complete. Remove --dry-run to generate.');
    return;
  }

  // Execute generation
  int completed = 0;
  int failed = 0;

  int skipped = 0;

  for (final task in generationQueue) {
    // Skip already-existing files
    final existingFile = File(task.outputPath);
    if (existingFile.existsSync() && existingFile.lengthSync() > 0) {
      skipped++;
      print(
        '[${completed + failed + skipped}/${generationQueue.length}] ⏭ Skipped (exists): ${task.outputPath}',
      );
      continue;
    }

    print(
      '[${completed + failed + skipped + 1}/${generationQueue.length}] Generating: ${task.outputPath}',
    );

    final success = await generateAsset(task);
    if (success) {
      completed++;
      print('  ✅ Done');
    } else {
      failed++;
      print('  ❌ Failed');
    }

    // Rate limiting: 2 second delay between calls
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  print('');
  print('═══════════════════════════════════════');
  print('Completed: $completed | Failed: $failed | Skipped: $skipped');
  print('═══════════════════════════════════════');
}

void printUsage() {
  print('Usage: dart run tools/generate_complete_avatars.dart [options]');
  print('');
  print('Options:');
  print('  --target=all|bodies    What to generate (default: all)');
  print('  --archetype=NAME       Filter to specific archetype');
  print('  --dry-run              Preview prompts without generating');
  print('  --help                 Show this help');
}

void buildGenerationQueue(String target, String? archetypeFilter) {
  final targetArchetypes = archetypeFilter != null
      ? [archetypeFilter]
      : archetypes.keys.toList();

  for (final archetype in targetArchetypes) {
    if (!archetypes.containsKey(archetype)) {
      print('WARNING: Unknown archetype "$archetype", skipping.');
      continue;
    }

    switch (target) {
      case 'all':
      case 'bodies':
        queueCharacters(archetype);
        break;
      default:
        print('Unknown target: $target. Use "all" or "bodies".');
        exit(1);
    }
  }
}

void queueCharacters(String archetype) {
  final info = archetypes[archetype]!;
  final seed = archetypeSeeds[archetype]!;
  final styles = hairstyles[archetype]!;

  for (final skinTone in skinTones) {
    final skinDesc = skinToneDescriptors[skinTone]!;

    for (final hairStyle in styles) {
      final hairDesc = hairStyle.replaceAll('_', ' ');

      final prompt =
          '''
2D flat vector character, full body front-facing standing pose,
${info['build']}, $skinDesc, $hairDesc hairstyle,
wearing ${info['outfit']},
thick clean black outlines, cell-shaded coloring, no gradients,
pastel color palette, minimalist design, character sheet style,
centered in frame, professional game character art,
no text, no watermark, no other objects
''';

      final negativePrompt =
          'background, scenery, environment, text, watermark, '
          'border, frame, multiple characters, realistic, 3D, '
          'photorealistic, blurry, low quality, gradient shading';

      final outputPath =
          'assets/images/avatars/base/$archetype/${skinTone}_$hairStyle.png';

      generationQueue.add(
        GenerationTask(
          prompt: prompt,
          negativePrompt: negativePrompt,
          outputPath: outputPath,
          seed: seed,
          model: 'gptimage',
        ),
      );
    }
  }
}

Future<bool> generateAsset(GenerationTask task) async {
  const maxRetries = 3;

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // Ensure output directory exists
      final outputFile = File(task.outputPath);
      await outputFile.parent.create(recursive: true);

      // Build URL with parameters
      final params = {
        'model': task.model,
        'width': task.width.toString(),
        'height': task.height.toString(),
        'seed': task.seed.toString(),
        'negative_prompt': task.negativePrompt,
        'transparent': 'true',
        'quality': 'high',
      };

      final url = Uri.parse(
        '$baseUrl/${Uri.encodeComponent(task.prompt.trim())}',
      ).replace(queryParameters: params);

      final client = HttpClient();
      client.connectionTimeout = const Duration(minutes: 3);

      final request = await client.getUrl(url);
      request.headers.set('Authorization', 'Bearer $apiKey');
      request.headers.set('Accept', 'image/*');

      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        await outputFile.writeAsBytes(bytes);
        client.close();
        return true;
      } else {
        final body = await response
            .transform(const SystemEncoding().decoder)
            .join();
        print('  ⚠️  Attempt $attempt: HTTP ${response.statusCode} - $body');
        client.close();

        if (attempt < maxRetries) {
          print('  ↻ Retrying in 3 seconds...');
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }
    } catch (e) {
      print('  ⚠️  Attempt $attempt: Error - $e');
      if (attempt < maxRetries) {
        print('  ↻ Retrying in 3 seconds...');
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
  }

  return false;
}
