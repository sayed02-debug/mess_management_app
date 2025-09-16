import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up method
  Future<User?> signUp(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      // Display name আপডেট
      await user.updateDisplayName(name);

      // Firestore-এ user সংযুক্ত করা (inviteToken বাদ দিয়ে)
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'role': 'user', // শুধুমাত্র সাধারণ user role
        'emailVerified': false,
        'joined_at': Timestamp.now(),
      });

      // Email verification পাঠানো
      await user.sendEmailVerification();
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign-up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign-up error: $e');
    }
  }

  // Sign in method
  Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        throw Exception('Sign-in failed');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign-in failed: ${e.message}');
    }
  }

  // Resend email verification
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        throw Exception('User not found or already verified.');
      }
    } catch (e) {
      throw Exception('Error resending verification email: $e');
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Error resetting password: ${e.message}');
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }
}
