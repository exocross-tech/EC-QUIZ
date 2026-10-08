import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  AppUser _mapFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
          (user) => user != null ? _mapFirebaseUser(user) : null,
        );
  }

  @override
  AppUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Sign-in failed: No user returned.');
      }
      return _mapFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during login: $e');
    }
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Sign-up failed: No user returned.');
      }
      return _mapFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during sign-up: $e');
    }
  }

  @override
  Future<AppUser> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw Exception('Guest sign-in failed: No user returned.');
      }
      return _mapFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during guest login: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName.trim());
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code.toLowerCase()) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email. Please create an account first.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid_login_credentials':
        return 'Incorrect email or password, or this account has not been created yet. Please check your credentials or sign up.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please log in instead.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection error. Check your internet connection.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is disabled in your Firebase project. Please enable Email/Password under Firebase Console -> Authentication -> Sign-in method.';
      default:
        return e.message ?? 'Authentication error occurred (${e.code}).';
    }
  }
}
