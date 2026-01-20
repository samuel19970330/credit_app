import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// User State
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref.watch(authRepositoryProvider));
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  UserNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUser(); // Load user immediately
  }

  Future<void> loadUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({required String name, String? photoUrl}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProfile(name: name, photoUrl: photoUrl);
      // Reload user to get updated data
      await loadUser();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // We don't necessarily need to set loading here if we handle it in the UI,
    // but keeping consistent state is good.
    // However, password change doesn't change the User object usually.
    // We'll just proxy the call.
    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
