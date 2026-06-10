abstract interface class SecureStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Map<String, String> dumpForTests();
}

abstract interface class PlainPreferences {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Map<String, String> dumpForTests();
}

class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Map<String, String> dumpForTests() => Map.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class InMemoryPreferences implements PlainPreferences {
  final Map<String, String> _values = {};

  static const _blockedKeyParts = [
    'token',
    'passcode',
    'note',
    'name',
    'email',
    'phone',
    'user_id',
    'userid',
  ];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Map<String, String> dumpForTests() => Map.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    final normalized = key.toLowerCase();
    if (_blockedKeyParts.any(normalized.contains)) {
      throw ArgumentError('Sensitive values must not be stored in preferences');
    }
    _values[key] = value;
  }
}
