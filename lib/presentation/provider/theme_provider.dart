import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends StateNotifier<bool> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'isDarkMode';

  ThemeNotifier() : super(false) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final value = await _storage.read(key: _key);
    state = value == 'true';
  }

  Future<void> toggleTheme() async {
    state = !state;
    await _storage.write(key: _key, value: state.toString());
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});
