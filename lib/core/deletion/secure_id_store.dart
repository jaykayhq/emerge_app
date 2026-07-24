import 'package:emerge_app/core/deletion/delete_account_backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the deletionRequestId so a retry after app-kill resumes with the
/// SAME id — the server dedupes on it.
class SharedPreferencesIdStore implements SecureIdStore {
  const SharedPreferencesIdStore();

  @override
  Future<String> loadOrCreateId(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(key);
    if (existing != null) return existing;
    final generated =
        '${DateTime.now().microsecondsSinceEpoch}-${key.hashCode}';
    await prefs.setString(key, generated);
    return generated;
  }

  @override
  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
