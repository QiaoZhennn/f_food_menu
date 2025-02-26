import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import '../theme/app_theme.dart';

class AuthPage extends StatelessWidget {
  final VoidCallback onSignedIn;

  const AuthPage({super.key, required this.onSignedIn});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        // Web-specific sign in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);

        // For web, we'll just call onSignedIn directly
        if (userCredential.user != null) {
          // Save user data to Firestore if it's a new user
          if (userCredential.additionalUserInfo?.isNewUser ?? false) {
            final user = UserModel.fromFirebase(userCredential);
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user?.uid)
                .set(user.toMap());
          }
          onSignedIn();
        }
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

        // Save user data to Firestore if it's a new user
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          final user = UserModel.fromFirebase(userCredential);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user?.uid)
              .set(user.toMap());
        }

        // Store session locally only for mobile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSignedIn', true);
        onSignedIn();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip login in debug/development mode
    if (!kReleaseMode) {
      // Use a post-frame callback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSignedIn();
      });

      // Show a temporary loading indicator while skipping
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Development Mode: Skipping login...'),
            ],
          ),
        ),
      );
    }

    // Regular login UI for production mode
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/icon/login_screen.jpg',
            fit: BoxFit.cover,
          ),
          // Dark overlay - reduced opacity from 0.5 to 0.35
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35), // Made more transparent
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Optional: Made text shadow stronger to ensure readability
                Text(
                  'Food Visualizer',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Translate menu items into visual delights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ElevatedButton(
                    onPressed: () => _handleGoogleSignIn(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/google_logo.png',
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
