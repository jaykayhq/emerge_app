import 'package:cloud_functions/cloud_functions.dart';

class GroqAiService {
  final FirebaseFunctions _functions;

  GroqAiService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  Future<String> getCoachAdvice(String userContext, String userMessage) async {
    try {
      final result = await _functions.httpsCallable('getGroqCoachAdvice').call({
        'userContext': userContext,
        'userMessage': userMessage,
      });

      if (result.data != null && result.data['advice'] != null) {
        return result.data['advice'].toString().trim();
      }

      throw Exception('Unexpected response format from AI Coach function');
    } on FirebaseFunctionsException catch (e) {
      throw Exception('AI Coach Service Error: ${e.code} - ${e.message}');
    } catch (e) {
      // Re-throw to be handled by the repository (which will decide on fallback)
      rethrow;
    }
  }
}
