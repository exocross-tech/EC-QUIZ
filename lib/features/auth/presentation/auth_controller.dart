import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/app_user.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../profile/data/firestore_user_profile_repository.dart';
import '../../profile/domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value(null);
  }
  final profileRepo = ref.watch(userProfileRepositoryProvider);
  return profileRepo.watchProfile(user.uid);
});

class GuestUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void setGuest(AppUser user) => state = user;
  void clear() => state = null;
}

final guestUserProvider =
    NotifierProvider<GuestUserNotifier, AppUser?>(GuestUserNotifier.new);

final effectiveUserProvider = Provider<AppUser?>((ref) {
  final firebaseUser = ref.watch(authStateProvider).asData?.value;
  if (firebaseUser != null) return firebaseUser;
  return ref.watch(guestUserProvider);
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is idle
    return null;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInAnonymously();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String avatarPresetId,
    required String avatarColor,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final profileRepo = ref.read(userProfileRepositoryProvider);

      final user = await authRepo.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update auth display name
      await authRepo.updateDisplayName(displayName);

      // Create initial Firestore user profile
      final initialProfile = UserProfile(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        avatarType: 'preset',
        avatarPresetId: avatarPresetId,
        avatarColor: avatarColor,
        contestsPlayed: 0,
        totalPoints: 0,
        wins: 0,
      );
      await profileRepo.saveProfile(initialProfile);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
