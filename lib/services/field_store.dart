import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FieldStore {
  SharedPreferences? _preferences;
  Future<void> _pending = Future.value();
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Map<String, dynamic>? read(String key) {
    final raw = _preferences?.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> write(String key, Map<String, Object?> data) {
    final encoded = jsonEncode(data);
    final result = _pending.then((_) async {
      final preferences = _preferences;
      if (preferences == null || !await preferences.setString(key, encoded)) {
        throw StateError('Local storage unavailable');
      }
    });
    _pending = result.catchError((Object _) {});
    return result;
  }
}
