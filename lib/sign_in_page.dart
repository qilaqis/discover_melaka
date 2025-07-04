import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to normalize email consistently
  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // Enhanced sign in method with better error handling
  Future<void> _signInWithEmail() async {
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

      debugPrint('=== EMAIL SIGN IN ATTEMPT ===');
      debugPrint('Email: $email');
      debugPrint('Password length: ${password.length}');

      // Validate inputs before attempting sign in
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }

      // Direct sign in
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('=== SIGN IN SUCCESSFUL ===');
      debugPrint('User UID: ${userCredential.user?.uid}');
      debugPrint('User Email: ${userCredential.user?.email}');
      debugPrint('User verified: ${userCredential.user?.emailVerified}');

      // Verify user object is not null
      if (userCredential.user == null) {
        throw Exception('User credential is null after successful sign in');
      }

      // Update last sign-in time (optional - don't block login if this fails)
      try {
        await _updateUserSignInTime(userCredential.user!);
      } catch (e) {
        debugPrint('Warning: Could not update sign-in time: $e');
        // Don't throw error here - this is not critical
      }

      if (mounted) {
        _showSuccessSnackBar('Welcome back!');

        // Add a small delay to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      debugPrint('=== FIREBASE AUTH ERROR ===');
      debugPrint('Error code: ${e.code}');
      debugPrint('Error message: ${e.message}');
      debugPrint('Error details: ${e.toString()}');

      String errorMessage = _getFirebaseAuthErrorMessage(e.code);
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
        _showErrorSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('=== GENERAL SIGN IN ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');

      String errorMessage = 'Sign in failed: ${e.toString()}';
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update user's last sign-in time
  Future<void> _updateUserSignInTime(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Updated sign-in time for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error updating sign-in time: $e');
      // Don't throw error for this non-critical operation
    }
  }

  // Get user-friendly error messages for Firebase Auth errors
  String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again.';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'missing-verification-code':
        return 'Missing verification code.';
      case 'missing-verification-id':
        return 'Missing verification ID.';
      case 'app-deleted':
        return 'App has been deleted.';
      case 'app-not-authorized':
        return 'App is not authorized.';
      case 'argument-error':
        return 'Invalid argument provided.';
      case 'invalid-api-key':
        return 'Invalid API key.';
      case 'invalid-user-token':
        return 'Invalid user token.';
      case 'network-request-failed':
        return 'Network request failed.';
      case 'web-storage-unsupported':
        return 'Web storage is not supported.';
      default:
        return 'Authentication failed: $errorCode';
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Email validator
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Password validator
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Test navigation to dashboard
  void _testDashboardNavigation() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      debugPrint('Dashboard navigation test failed: $e');
      _showErrorSnackBar('Dashboard page is not accessible: ${e.toString()}');
    }
  }

  // Navigate to sign up page
  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  // Reset password
  Future<void> _resetPassword() async {
    final email = _normalizeEmail(_emailController.text);
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email first');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccessSnackBar('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Failed to send password reset email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App logo or title
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 24),
                // Welcome text
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Error message display
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                // Sign in button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
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
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Add this after the "Sign In" button for testing
                TextButton(
                  onPressed: _testDashboardNavigation,
                  child: Text('Sign In'),
                ),

                // Forgot password
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 32),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: _navigateToSignUp,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}