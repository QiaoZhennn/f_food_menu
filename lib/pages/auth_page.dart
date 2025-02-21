import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthPage extends StatelessWidget {
  final VoidCallback onSignedIn;

  const AuthPage({super.key, required this.onSignedIn});

  Future<void> _handleGoogleSignIn() async {
    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        // Web-specific sign in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Mobile sign in
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }
      print('User credential: ${userCredential.user?.uid}');

      // Save user data to Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final user = UserModel.fromFirebase(userCredential);
        print('New User: ${user.toMap()}');

        // Use the configured Firestore instance
        final firestore = FirebaseFirestore.instance;

        try {
          await firestore
              .collection('users')
              .doc(userCredential.user?.uid)
              .set(user.toMap())
              .timeout(const Duration(seconds: 10));
          print('User saved to Firestore successfully');
        } catch (e) {
          print('Error saving to Firestore: $e');
        }
      }

      // Store session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedIn', true);

      onSignedIn();
    } catch (e) {
      debugPrint('Error signing in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Food Menu App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: Image.asset(
                'assets/icon/google_logo.png',
                height: 24,
              ),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
