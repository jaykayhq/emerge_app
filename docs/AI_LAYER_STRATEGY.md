# AI Layer Strategy: The Groq Approach

This document outlines the specific strategy to integrate Artificial Intelligence into Emerge using **Groq** as the exclusive provider.

## 1. The Strategy: Instant Intelligence

We will use **Groq** to power the "AI Habit Coach" and "Smart Insights". Groq's LPU (Language Processing Unit) architecture delivers inference speeds of ~300+ tokens/second, providing a near-instant, "native-feeling" experience without the latency typical of other cloud APIs.

### The Chosen Engine
*   **Provider:** Groq
*   **Model ID:** `llama-3.1-8b-instant`
*   **Why:**
    *   **Speed:** Extremely low latency, essential for a smooth mobile UX.
    *   **Cost:** Currently offers a generous free tier ($0).
    *   **Logic:** The 8B parameter model is perfectly sized for habit coaching, sentiment analysis, and motivation—it is smart enough to be helpful but small enough to be incredibly fast.

---

## 2. Technical Implementation

We will implement a streamlined `AiRepository` that communicates solely with the Groq API.

### API Specifications
*   **Endpoint:** `https://api.groq.com/openai/v1/chat/completions`
    *   *Note:* Groq offers an OpenAI-compatible API, making it easy to use standard libraries or simple HTTP requests.
*   **Headers:**
    *   `Authorization`: `Bearer $GROQ_API_KEY`
    *   `Content-Type`: `application/json`

### Implementation Example (Dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqAiService {
  final String apiKey;
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Hardcoded model ID as per strategy
  final String _modelId = 'llama-3.1-8b-instant';

  GroqAiService({required this.apiKey});

  Future<String> getCoachAdvice(String userContext, String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelId,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert Habit Coach based on Atomic Habits principles. '
                         'Keep your answers short (under 2 sentences) and motivating. '
                         'Context: $userContext'
            },
            {
              'role': 'user',
              'content': userMessage
            }
          ],
          'temperature': 0.7,
          'max_tokens': 150, // Keep responses concise
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Groq API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback logic (e.g., return a static quote)
      return "Keep going! You're doing great.";
    }
  }
}
```

## 3. Rate Limits & Management (Free Tier)

Groq's free tier is generous but has specific limits for the `llama-3.1-8b-instant` model (as of late 2024):

*   **Requests:** ~30 RPM (Requests Per Minute)
*   **Tokens:** ~6,000 TPM (Tokens Per Minute)

**Mitigation Strategy:**
1.  **Debouncing:** Ensure the app doesn't fire API calls on every keystroke. Only send when the user explicitly hits "Send" or finishes a significant interaction.
2.  **Concise Context:** Keep the `system` prompt and `userContext` concise to stay well under the 6k TPM limit.
3.  **Local Fallback:** If a `429 Too Many Requests` error occurs, silently fall back to a local list of motivational quotes instead of showing an error to the user.

## 4. Privacy & Security

*   **API Key Storage:** Never hardcode the API key in the source code. Use `flutter_dotenv` to load it from a `.env` file during development and secure storage (or a backend proxy) in production.
*   **Data Minimization:** Send only the necessary habit metadata (e.g., "Streak: 5 days, Habit: Gym"). Do not send PII (Personally Identifiable Information) like real names or email addresses to the AI.
