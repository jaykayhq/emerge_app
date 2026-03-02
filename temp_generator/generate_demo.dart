import 'dart:io';

void main() async {
  final artifactDir =
      r"C:\Users\HP\.gemini\antigravity\brain\02a764b0-2d74-4b22-8cc7-aa611767e0d9";
  final apiKey = "sk_OGhhzmGVPhl6FFdSSHKiyAnHEx48dHlj";

  final prompts = {
    "overhead_forest_peak_growth.png": {
      "prompt":
          "Stylized overhead top-down map view of a magical forest environment landscape, avant-garde minimalist art style, vibrant canopy of ancient trees from above, a clear and prominent glowing dirt pathway winding purposefully through the center designed for placing level nodes, softly illuminated geometric clearings, vibrant bioluminescent moss and ethereal teal water features, cinematic overhead atmospheric lighting, deep forest greens mixed with soft gold accents, tranquil and inspiring world map design, devoid of UI or text, premium mobile game map background, clean abstract composition, masterpiece, 8k resolution",
      "negative":
          "side view, perspective view, sky, characters, realistic photograph, messy overgrown paths, UI, text, low quality",
    },
    "overhead_forest_moderate_decay.png": {
      "prompt":
          "Stylized overhead top-down map view of a mysterious overgrown forest landscape, avant-garde abstract art style, fading canopy view from above, creeping stylized mist obscuring the edges, a clear but slightly overgrown winding pathway cutting through the center designed for level nodes with stylized brambles creeping onto the edges, muted greens and deep shadowy teal, atmospheric overhead cinematic lighting but slightly dimmed, a sense of entropy and encroaching stillness in map design, devoid of UI or text, premium mobile game world map background, clean top-down composition, masterpiece, 8k resolution",
      "negative":
          "vibrant bright colors, side view, sky, characters, realistic photograph, UI, text, low quality",
    },
    "overhead_forest_severe_decay.png": {
      "prompt":
          "Stylized overhead top-down map view of a desolate petrified forest environment, avant-garde minimalist art style, bare crystalline trees viewed from above, heavy thick stylized fog dominating the scene, a clear but stark and rocky pathway winding through the center designed for level nodes, monochromatic dark greys and deep obsidian with very faint dying embers of teal, oppressive overhead atmospheric lighting, a sense of deep entropy and loss in map design, devoid of UI or text, premium mobile game world map background, clean abstract top-down composition, masterpiece, 8k resolution",
      "negative":
          "green canopy, sunlight, vibrant colors, side view, sky, characters, realistic photograph, UI, text, low quality",
    },
    "overhead_city_peak_growth.png": {
      "prompt":
          "Stylized overhead top-down map view of a monumental futuristic cityscape skyline, avant-garde minimalist architecture, geometric grid layout from above, a clear bright glowing energetic neon pathway acting as a central axis designed for placing level nodes, warm golden and crisp cyan architectural lighting cutting through the grid, pristine structured plazas, cinematic overhead atmospheric perspective, a sense of thriving structured civilization in map design, devoid of vehicles or UI, premium mobile game world map background, clean top-down composition, masterpiece, 8k resolution",
      "negative":
          "side view, sky, ruins, smog, characters, traffic, cars, realistic photograph, UI, text, low quality",
    },
    "overhead_city_moderate_decay.png": {
      "prompt":
          "Stylized overhead top-down map view of a cityscape landscape, avant-garde abstract architecture, geometric layout viewed from above with flickering or dimmed lighting, creeping shadows across the city blocks, a clear but shadowed winding asphalt pathway acting as a central route designed for level nodes, stylized smog drifting through the streets, muted steel blues and rusty amber accents, atmospheric overhead cinematic lighting but subdued, a sense of neglected infrastructure in map design, devoid of vehicles or UI, premium mobile game world map background, clean top-down composition, masterpiece, 8k resolution",
      "negative":
          "bright neon lights, side view, sky, vibrant colors, characters, traffic, cars, realistic photograph, UI, text, low quality",
    },
    "overhead_city_severe_decay.png": {
      "prompt":
          "Stylized overhead top-down map view of a ruined monolithic cityscape, avant-garde minimalist art style, crumbling geometric building footprints viewed from above, completely powerless with no artificial light, heavy stylized fog swallowing the lower areas, a stark clear rocky pathway cutting through the ruins designed for level nodes, monochromatic dark greys and oppressive obsidian, a sense of total structural collapse and entropy in map design, devoid of UI or text, premium mobile game world map background, abstract clean overhead composition, masterpiece, 8k resolution",
      "negative":
          "lights, neon, side view, sky, glowing, vibrant colors, characters, realistic photograph, cars, UI, text, low quality",
    },
    "overhead_mountain_peak.png": {
      "prompt":
          "Stylized overhead top-down map view of a majestic mountain terrain, avant-garde minimalist art style, sharp crystalline geometric rock formations viewed from above, a clear bright mountain trail winding distinctly through the valleys and ridges designed for placing level nodes, illuminated by sharp golden hour sunlight, deep obsidian stone mixed with vibrant ruby red and gold accents, an inspiring challenging world map design, devoid of UI or text, premium mobile game map background, clean abstract composition, masterpiece, 8k resolution",
      "negative":
          "side view, sky, clouds, characters, trees, realistic photograph, UI, text, low quality",
    },
    "overhead_sanctuary_peak.png": {
      "prompt":
          "Stylized overhead top-down map view of an ethereal sacred sanctuary landscape, avant-garde minimalist art style, geometric floating platforms and zen gardens viewed from above, a clear luminous bridge pathway connecting the areas designed for placing level nodes, glowing incense mist, deep regal purples mixed with pure white and silver accents, tranquil and spiritual world map design, devoid of UI or text, premium mobile game map background, clean abstract composition, masterpiece, 8k resolution",
      "negative":
          "side view, sky, darkness, characters, realistic photograph, messy, UI, text, low quality",
    },
  };

  final client = HttpClient()..connectionTimeout = const Duration(minutes: 5);

  print('Starting authenticated image generation for overhead maps...');

  for (final entry in prompts.entries) {
    final filename = entry.key;
    final data = entry.value;

    final params = {
      'model': 'flux',
      'width': '1024',
      'height': '1024',
      'enhance': 'false',
      'negative_prompt': data['negative']!,
    };

    final promptEncoded = Uri.encodeComponent(data['prompt']!);
    final uri = Uri.parse(
      'https://gen.pollinations.ai/image/$promptEncoded',
    ).replace(queryParameters: params);

    try {
      print('Downloading $filename. This might take 30-120 seconds...');
      final request = await client.getUrl(uri);

      // Use Bearer Token auth as per Pollinations.ai guide
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.headers.set(HttpHeaders.acceptHeader, 'image/*');

      final response = await request.close();

      if (response.statusCode == 200) {
        final outPath = '$artifactDir\\$filename';
        final file = File(outPath);
        await response.pipe(file.openWrite());
        print('Saved $filename successfully.');
      } else {
        print('Failed $filename: HTTP ${response.statusCode}');
        final bodyBytes = await response.toList();
        final body = String.fromCharCodes(bodyBytes.expand((x) => x));
        print('Response body: $body');
      }
    } catch (e) {
      print('Failed $filename with error: $e');
    }
  }

  client.close();
  print('Finished generation process.');
}
