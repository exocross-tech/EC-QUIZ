import '../domain/app_user.dart';

/// Abstract contract for authentication operations.
/// Encapsulated behind an interface to allow swapping with mock implementations,
/// Google Sign-In, Anonymous sign-in, or other providers in the future.
abstract class AuthRepository {
  /// Emits changes in the user's authentication state.
  Stream<AppUser?> authStateChanges();

  /// Gets the currently authenticated user, or null if none.
  AppUser? get currentUser;

  /// Signs in a user using email and password.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs up a user using email and password.
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Updates the current user's display name in auth.
  Future<void> updateDisplayName(String displayName);
}
