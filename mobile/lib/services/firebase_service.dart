import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Phone Authentication Methods
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String verificationId, int? resendToken) onCodeSent,
    Function(String message) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError('Phone verification error: $e');
    }
  }

  Future<UserCredential?> signInWithOTP(
      String verificationId, String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      return result;
    } catch (e) {
      print('Error signing in with OTP: $e');
      return null;
    }
  }

  // Legacy Email Authentication Methods
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      print('SignUp Error: ${e.message}');
      return null;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      print('SignIn Error: ${e.message}');
      return null;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Firestore Methods
  Future<bool> savePrediction(Map<String, dynamic> data) async {
    try {
      User? user = getCurrentUser();
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('predictions')
          .add({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Save Prediction Error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPredictionHistory() async {
    try {
      User? user = getCurrentUser();
      if (user == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('predictions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Get History Error: $e');
      return [];
    }
  }

  Future<bool> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      User? user = getCurrentUser();
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Save Profile Error: $e');
      return false;
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }
}
