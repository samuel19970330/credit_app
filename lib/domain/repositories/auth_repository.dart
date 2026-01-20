import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login({required String email, required String password});
  Future<void> logout();
  Future<bool> isSessionValid();
  Future<void> updateProfile({required String name, String? photoUrl});
  Future<void> changePassword(
      {required String currentPassword, required String newPassword});
}
