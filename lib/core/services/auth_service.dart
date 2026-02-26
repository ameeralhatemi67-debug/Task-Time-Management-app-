import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- NEW: Guest State Management ---
  final _guestStateController = StreamController<bool>.broadcast();

  // Expose guest stream
  Stream<bool> get guestStateChanges => _guestStateController.stream;

  // Stream to listen to auth state (Logged In vs Logged Out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User Helper
  User? get currentUser => _auth.currentUser;

  // --- NEW: Enter Guest Mode ---
  void enterGuestMode() {
    _guestStateController.add(true); // Signal the wrapper to let them in
  }

  // Sign In Logic
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      // 2. Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      _guestStateController.add(false); // Reset guest state on successful login
      return userCredential.user;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  // Sign Out Logic
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _guestStateController.add(false); // Reset guest state on logout
  }
}
