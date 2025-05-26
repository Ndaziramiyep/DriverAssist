import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/providers/biometric_provider.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print('User is signed in: ${user.uid}');
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    final biometricProvider = Provider.of<BiometricProvider>(context, listen: false);
    
    if (!biometricProvider.isBiometricAvailable || !biometricProvider.isBiometricEnabled) {
      _showMessage("Biometric authentication is not available or not enabled");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authenticated = await biometricProvider.authenticate();
      if (authenticated) {
        // Here you would typically retrieve the stored credentials and sign in
        // For now, we'll just show a success message
        _showMessage("Biometric authentication successful!", success: true);
      } else {
        _showMessage("Biometric authentication failed");
      }
    } catch (e) {
      _showMessage("Biometric authentication error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Please enter both email and password");
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Attempting to sign in with email: ${_emailController.text.trim()}');
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Store credentials if biometric authentication is enabled
      final biometricProvider = Provider.of<BiometricProvider>(context, listen: false);
      await biometricProvider.storeCredentialsAfterLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Navigation will be handled by the auth state listener
      _showMessage("Login successful!", success: true);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }
      _showMessage(errorMessage);
    } catch (e) {
      print('Unexpected error during login: $e');
      _showMessage('An unexpected error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your email to reset password.");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMessage("Password reset email sent!", success: true);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Something went wrong.");
    }
  }

  void _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _showMessage("Signed in with Google", success: true);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showMessage("Google sign-in failed. ${e.toString()}"); //Added error
    }
  }

  void _showMessage(String message, {bool success = false}) {
    final color = success ? Colors.green : Colors.red;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Welcome Back 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Login to your DriverAssist account", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 40),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _forgotPassword, child: const Text("Forgot Password?")),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 14)),
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Login"),
                ),
                const SizedBox(height: 20),
                Consumer<BiometricProvider>(
                  builder: (context, biometricProvider, _) {
                    if (!biometricProvider.isBiometricAvailable || !biometricProvider.isBiometricEnabled) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const Text("Or", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _authenticateWithBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(
                            biometricProvider.availableBiometrics.contains(BiometricType.fingerprint)
                                ? "Login with Fingerprint"
                                : "Login with Face ID",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text("Continue with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text("Sign Up"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}