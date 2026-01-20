import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserPhoto = 'user_photo';
  static const _keyLoginTime = 'login_time';
  static const _keyPassword = 'user_password';

  // Session duration: 1 hour
  static const _sessionDuration = Duration(hours: 1);

  // Hardcoded credentials for demo
  static const _adminEmail = 'admin@admin.com';
  static const _adminPassword = 'admin123';
  static const _adminName = 'Administrador';

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Validate credentials
    if (email == _adminEmail && password == _adminPassword) {
      const user = User(
        id: '1',
        name: _adminName,
        email: _adminEmail,
        photoUrl: null,
      );

      // Store session data
      await _storage.write(key: _keyUserId, value: user.id);
      await _storage.write(key: _keyUserName, value: user.name);
      await _storage.write(key: _keyUserEmail, value: user.email);
      await _storage.write(key: _keyUserPhoto, value: user.photoUrl ?? '');
      await _storage.write(key: _keyPassword, value: password);
      await _storage.write(
          key: _keyLoginTime, value: DateTime.now().toIso8601String());

      return user;
    } else {
      throw Exception('Credenciales incorrectas');
    }
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  @override
  Future<bool> isSessionValid() async {
    final loginTimeStr = await _storage.read(key: _keyLoginTime);
    if (loginTimeStr == null) return false;

    try {
      final loginTime = DateTime.parse(loginTimeStr);
      final now = DateTime.now();
      final difference = now.difference(loginTime);

      return difference < _sessionDuration;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if session is valid
    if (!await isSessionValid()) {
      return null;
    }

    // Retrieve user data from storage
    final id = await _storage.read(key: _keyUserId);
    final name = await _storage.read(key: _keyUserName);
    final email = await _storage.read(key: _keyUserEmail);
    final photoUrl = await _storage.read(key: _keyUserPhoto);

    if (id == null || name == null || email == null) {
      return null;
    }

    return User(
      id: id,
      name: name,
      email: email,
      photoUrl: photoUrl!.isEmpty ? null : photoUrl,
    );
  }

  @override
  Future<void> updateProfile({required String name, String? photoUrl}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Update stored user data
    await _storage.write(key: _keyUserName, value: name);
    if (photoUrl != null) {
      await _storage.write(key: _keyUserPhoto, value: photoUrl);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final storedPassword = await _storage.read(key: _keyPassword);
    if (storedPassword != currentPassword) {
      throw Exception('La contraseña actual es incorrecta');
    }

    await _storage.write(key: _keyPassword, value: newPassword);
  }
}
