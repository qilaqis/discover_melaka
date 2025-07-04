import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'sign_in_page.dart';
import 'dashboard_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Helper method to normalize email consistently
  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // Save user data to Firestore with better error handling
  Future<bool> _saveUserToFirestore(User user, String displayName) async {
    try {
      debugPrint('=== SAVING USER TO FIRESTORE ===');
      debugPrint('User UID: ${user.uid}');
      debugPrint('User Email: ${user.email}');
      debugPrint('Display Name: $displayName');

      // Normalize email before saving
      String normalizedEmail = _normalizeEmail(user.email ?? '');

      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': normalizedEmail,
        'displayName': displayName.isNotEmpty ? displayName : (user.displayName ?? ''),
        'photoURL': user.photoURL ?? '',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'signUpMethod': 'email', // Track how user signed up
      };

      // Use merge: true to avoid overwriting existing data
      await _firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));
      debugPrint('✅ User data saved successfully to Firestore');
      return true;
    } catch (e) {
      debugPrint('=== FIRESTORE SAVE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (mounted) {
        _showErrorSnackBar('Failed to save user data: ${e.toString()}');
      }
      return false;
    }
  }

  // Enhanced email registration with better error handling
  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String email = _normalizeEmail(_emailController.text);
      String password = _passwordController.text;
      String name = _nameController.text.trim();

      debugPrint('=== EMAIL SIGN UP ATTEMPT ===');
      debugPrint('Email: $email');
      debugPrint('Name: $name');

      // Check if user already exists in Firebase Auth
      try {
        List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
        if (signInMethods.isNotEmpty) {
          setState(() {
            _errorMessage = 'An account already exists with this email address.';
          });
          _showErrorSnackBar(_errorMessage!);
          return;
        }
      } catch (e) {
        debugPrint('Error checking existing user: $e');
        // Continue with registration if check fails
      }

      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('=== FIREBASE AUTH SUCCESSFUL ===');
      debugPrint('User UID: ${userCredential.user?.uid}');

      // Update display name in Firebase Auth
      if (name.isNotEmpty) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload(); // Refresh user data
      }

      // Save user data to Firestore
      bool dataSaved = await _saveUserToFirestore(userCredential.user!, name);

      if (!dataSaved) {
        debugPrint('⚠ WARNING: User data was not saved to Firestore');
        // Don't return here, still navigate to success
      }

      if (mounted) {
        _showSuccessSnackBar('Account created successfully!');

        // Navigate directly to dashboard after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }

    } on FirebaseAuthException catch (e) {
      debugPrint('=== FIREBASE AUTH ERROR ===');
      debugPrint('Error code: ${e.code}');
      debugPrint('Error message: ${e.message}');

      String errorMessage = _getFirebaseAuthErrorMessage(e.code);
      setState(() {
        _errorMessage = errorMessage;
      });
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      debugPrint('=== GENERAL SIGN UP ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');

      String errorMessage = 'An unexpected error occurred: ${e.toString()}';
      setState(() {
        _errorMessage = errorMessage;
      });
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fixed Google Sign-Up with proper error handling
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=== GOOGLE SIGN UP ATTEMPT ===');

      // Sign out any existing Google sessions
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-Up cancelled by user');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Ensure we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      debugPrint('=== GOOGLE SIGN UP SUCCESSFUL ===');
      debugPrint('User: ${userCredential.user?.email}');

      // Save user data to Firestore with Google-specific info
      String displayName = userCredential.user?.displayName ??
          googleUser.displayName ??
          '';

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': _normalizeEmail(userCredential.user!.email ?? ''),
        'displayName': displayName,
        'photoURL': userCredential.user?.photoURL ?? '',
        'emailVerified': userCredential.user?.emailVerified ?? false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'signUpMethod': 'google',
      };

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData, SetOptions(merge: true));

      if (mounted) {
        _showSuccessSnackBar('Account created successfully with Google!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }

    } catch (e) {
      debugPrint('=== GOOGLE SIGN UP ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');

      String errorMessage = 'Google Sign-Up failed: ${e.toString()}';
      setState(() {
        _errorMessage = errorMessage;
      });
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fixed Apple Sign-Up with proper error handling
  Future<void> _signUpWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=== APPLE SIGN UP ATTEMPT ===');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Ensure we have the required token
      if (credential.identityToken == null) {
        throw Exception('Failed to get Apple ID token');
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);

      debugPrint('=== APPLE SIGN UP SUCCESSFUL ===');
      debugPrint('User: ${userCredential.user?.email}');

      // Handle Apple name
      String displayName = '';
      if (credential.givenName != null && credential.familyName != null) {
        displayName = '${credential.givenName} ${credential.familyName}';
      } else if (userCredential.user?.displayName != null) {
        displayName = userCredential.user!.displayName!;
      }

      // Save user data to Firestore with Apple-specific info
      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': _normalizeEmail(userCredential.user!.email ?? ''),
        'displayName': displayName,
        'photoURL': userCredential.user?.photoURL ?? '',
        'emailVerified': userCredential.user?.emailVerified ?? false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'signUpMethod': 'apple',
      };

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData, SetOptions(merge: true));

      if (mounted) {
        _showSuccessSnackBar('Account created successfully with Apple!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }

    } catch (e) {
      debugPrint('=== APPLE SIGN UP ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');

      String errorMessage = 'Apple Sign-Up failed: ${e.toString()}';
      setState(() {
        _errorMessage = errorMessage;
      });
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Get user-friendly error messages
  String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Registration failed: $errorCode';
    }
  }

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Show messages
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Logo/Icon
                const Icon(
                  Icons.location_city,
                  size: 80,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 24),
                // Welcome Text
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up to get started with Discover Melaka',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Error Message Display
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                // Name Field
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => _signUpWithEmail(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Sign Up Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUpWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or sign up with',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 20),
                // Social Sign Up Buttons
                Row(
                  children: [
                    // Google Sign Up
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signUpWithGoogle,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 20,
                          width: 20,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.login, color: Colors.red),
                        ),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Apple Sign Up
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signUpWithApple,
                        icon: const Icon(Icons.apple, color: Colors.black),
                        label: const Text('Apple'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInPage()),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}