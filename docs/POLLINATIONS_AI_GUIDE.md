# Pollinations.ai Image Generation Guide

## Overview

This guide explains how to integrate Pollinations.ai image generation into the Emerge app for creating archetype avatars, milestone celebrations, and other AI-generated imagery.

## API Endpoint

The correct API endpoint for authenticated image generation is:

```
https://gen.pollinations.ai/image/{prompt}
```

**Note:** Do NOT use `image.pollinations.ai` - this is the public/free endpoint which is often unreliable and returns HTTP 530 errors.

## Authentication

### Getting Your API Key

1. Visit [https://enter.pollinations.ai](https://enter.pollinations.ai)
2. Sign up or log in
3. Generate a Secret Key (starts with `sk_`) for server-side use
4. Store your API key securely (never commit to git)

### Authentication Methods

The API supports two authentication methods:

#### Method 1: Bearer Token (Recommended)
```http
Authorization: Bearer sk_OGhhzmGVPhl6FFdSSHKiyAnHEx48dHlj
```

#### Method 2: Query Parameter
```http
https://gen.pollinations.ai/image/a%20cat?key=sk_OGhhzmGVPhl6FFdSSHKiyAnHEx48dHlj
```

## Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | `flux` | AI model: `flux`, `turbo`, `gptimage`, `kontext`, `seedream`, `veo`, `seedance` |
| `width` | int | `1024` | Image width in pixels |
| `height` | int | `1024` | Image height in pixels |
| `seed` | int | `0` | Random seed for reproducibility (-1 for random) |
| `enhance` | bool | `false` | Let AI improve your prompt |
| `negative_prompt` | string | `worst quality, blurry` | What to avoid in the image |
| `safe` | bool | `false` | Enable safety content filters |
| `quality` | string | `medium` | Quality level (gptimage only): `low`, `medium`, `high`, `hd` |
| `transparent` | bool | `false` | Transparent background (gptimage only) |

## Removing Backgrounds

To generate images with no background (isolated character):

### Option 1: Use Transparent Background (gptimage model)

```dart
final url = Uri.parse('https://gen.pollinations.ai/image/${Uri.encodeComponent(prompt)}')
    .replace(queryParameters: {
  'model': 'gptimage',
  'width': '1024',
  'height': '1024',
  'transparent': 'true',  // Removes background
});
```

### Option 2: Use Negative Prompt (all models)

```dart
final prompt = 'character portrait, professional quality';
final negativePrompt = 'background, scenery, environment, objects, text, watermark, border, frame';

final url = Uri.parse('https://gen.pollinations.ai/image/${Uri.encodeComponent(prompt)}')
    .replace(queryParameters: {
  'model': 'flux',
  'width': '1024',
  'height': '1024',
  'negative_prompt': negativePrompt,
});
```

### Option 3: Prompt for Isolated Subject

Include background-removal instructions in your prompt:

```dart
final prompt = '''
  Professional athlete character portrait, isolated on solid white background,
  cutout style, no surrounding scenery, studio lighting, character only,
  high quality 8k, professional digital art
''';
```

### Best Practice for Avatar Isolation

```dart
String _buildIsolatedPrompt(String subject) {
  return '''
    $subject,
    isolated on plain white background,
    studio photography,
    no scenery, no environment, no other objects,
    clean solid background, professional headshot style,
    centered composition, character only
  ''';
}

// Usage
final prompt = _buildIsolatedPrompt('Mystic sage character portrait, transcendent spiritual expression');
```

## Available Models

### Image Models
- **flux** - Default, high quality images
- **turbo** - Faster generation
- **gptimage** - GPT-based image generation, supports transparent backgrounds
- **kontext** - Context-aware images
- **seedream** - Dream-like images
- **seedream-pro** - Pro version of seedream
- **nanobanana** - Artistic style
- **nanobanana-pro** - Pro artistic style

### Video Models
- **veo** - Text-to-video (4-8 seconds)
- **seedance** - Text-to-video and image-to-video (2-10 seconds)

## Dart/Flutter Implementation

### Basic Service Class

```dart
import 'dart:io';
import 'package:http/http.dart' as http;

class PollinationsImageService {
  static const String _baseUrl = 'https://gen.pollinations.ai';
  final String apiKey;

  PollinationsImageService({required this.apiKey});

  /// Generate an image URL from a text prompt
  String generateImageUrl({
    required String prompt,
    int width = 1024,
    int height = 1024,
    String model = 'flux',
    bool enhance = true,
    String? negativePrompt,
  }) {
    final params = {
      'model': model,
      'width': width.toString(),
      'height': height.toString(),
      if (enhance) 'enhance': 'true',
      if (negativePrompt != null) 'negative_prompt': negativePrompt,
    };

    return Uri.parse('$_baseUrl/image/${Uri.encodeComponent(prompt)}')
        .replace(queryParameters: params)
        .toString();
  }

  /// Download and save an image
  Future<File> downloadImage({
    required String prompt,
    required String outputPath,
    int width = 1024,
    int height = 1024,
    String model = 'flux',
    String? negativePrompt,
  }) async {
    final params = {
      'model': model,
      'width': width.toString(),
      'height': height.toString(),
      'enhance': 'true',
      if (negativePrompt != null) 'negative_prompt': negativePrompt,
    };

    final url = Uri.parse('$_baseUrl/image/${Uri.encodeComponent(prompt)}')
        .replace(queryParameters: params);

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'image/*',
      },
    ).timeout(const Duration(minutes: 2));

    if (response.statusCode == 200) {
      final file = File(outputPath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Generate an avatar with transparent background
  Future<File> generateAvatar({
    required String subject,
    required String outputPath,
  }) async {
    // Use gptimage with transparent background
    final prompt = '''
      $subject,
      isolated on plain background,
      studio photography, character only,
      no scenery, no environment, centered composition
    ''';

    final url = Uri.parse('$_baseUrl/image/${Uri.encodeComponent(prompt)}')
        .replace(queryParameters: {
      'model': 'gptimage',
      'width': '512',
      'height': '512',
      'transparent': 'true',
      'quality': 'high',
    });

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'image/*',
      },
    ).timeout(const Duration(minutes: 2));

    if (response.statusCode == 200) {
      final file = File(outputPath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
```

## Usage Examples

### Generate Archetype Avatar

```dart
final service = PollinationsImageService(
  apiKey: 'your_api_key_here',
);

final prompt = '''
  Professional athlete character portrait, determined focused expression,
  athletic physique, sleek kinetic dynamic pose, wearing modern sportswear,
  golden warm lighting, high quality 8k, professional digital art
''';

final file = await service.downloadImage(
  prompt: prompt,
  outputPath: 'assets/images/archetypes/athlete.png',
  width: 1024,
  height: 1024,
);
```

### Generate Avatar Without Background

```dart
final file = await service.generateAvatar(
  subject: 'Professional athlete character portrait',
  outputPath: 'assets/images/archetypes/athlete_no_bg.png',
);
```

### Generate Milestone Image

```dart
final milestonePrompt = '''
  golden trophy glowing with warm light, celebration confetti,
  achievement unlocked banner, celebrating 30 days of meditation,
  inspirational, high quality 8k, detailed
''';

final file = await service.downloadImage(
  prompt: milestonePrompt,
  outputPath: 'assets/images/milestones/30-day-streak.png',
);
```

## Error Handling

### Common HTTP Status Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 200 | Success | Image generated |
| 400 | Bad Request | Check prompt parameters |
| 401 | Unauthorized | Invalid or missing API key |
| 402 | Payment Required | Insufficient pollen balance |
| 403 | Forbidden | API key lacks permissions for this model |
| 500 | Server Error | Pollinations.ai issue, retry later |

### Error Response Example

```dart
try {
  final file = await service.downloadImage(...);
} on http.ClientException catch (e) {
  print('Network error: $e');
} catch (e) {
  print('Generation failed: $e');
}
```

## Checking Account Balance

```dart
Future<int> getBalance() async {
  final response = await http.get(
    Uri.parse('https://gen.pollinations.ai/account/balance'),
    headers: {'Authorization': 'Bearer $apiKey'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['balance'] as int;
  }
  throw Exception('Failed to get balance');
}
```

## Best Practices

1. **Store API Key Securely**: Use environment variables or secure storage
2. **Add Fallback Images**: Keep SVG/PNG backups for when API is unavailable
3. **Cache Generated Images**: Store locally to avoid regenerating
4. **Use Enhance Parameter**: Let the AI improve your prompts
5. **Handle Timeouts**: Image generation can take 30-120 seconds
6. **Check Balance**: Monitor pollen usage to avoid interruptions
7. **For Transparent Backgrounds**: Use `gptimage` model with `transparent=true`
8. **For Isolated Subjects**: Include "isolated on plain background" in prompt

## Environment Configuration

Add to `app_config.dart`:

```dart
class AppConfig {
  static const String pollinationsApiKey = String.fromEnvironment(
    'POLLINATIONS_API_KEY',
    defaultValue: '', // Empty for development
  );

  static bool get hasPollinationsKey => pollinationsApiKey.isNotEmpty;
}
```

Run with API key:
```bash
flutter run --dart-define=POLLINATIONS_API_KEY=sk_your_key_here
```

## API Documentation

Official API docs: [https://gen.pollinations.ai](https://gen.pollinations.ai)
