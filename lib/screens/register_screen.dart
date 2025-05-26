import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    // Navigation will be handled after registration
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters long");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userCredential = await authProvider.registerWithEmailAndPassword(name, email, password);
      final user = userCredential.user;

      if (user != null) {
        debugPrint('[RegisterScreen] User created successfully: ${user.uid}');
        debugPrint('[RegisterScreen] Attempting to send email verification...');
        await user.sendEmailVerification();
        debugPrint('[RegisterScreen] Email verification sent!');
        _showMessage("Account created successfully! Please check your email to verify your account.", success: true);
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        debugPrint('[RegisterScreen] Registration failed: No user created.');
        _showMessage("Registration failed. No user created.");
      }
    } on Exception catch (e) {
      print('Registration Error: $e');
      debugPrint('[RegisterScreen] Registration failed with exception: ${e.toString()}');
      String errorMessage = 'Registration failed';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak';
      } else if (e.toString().contains('operation-not-allowed')) {
        errorMessage = 'Email/password accounts are not enabled';
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      _showMessage(errorMessage);
    } finally {
      setState(() => _isLoading = false);
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
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: ListView(
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
                const Text("Create Account 👤", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Register for DriverAssist", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value!)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a password';
                    }
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 14)),
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Register"),
                ),
                const SizedBox(height: 20),
                const Center(child: Text("Or", style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.signInWithGoogle();
                      _showMessage("Welcome to DriverAssist!", success: true);
                    } catch (e) {
                      _showMessage("Google sign-in failed. Please try again.");
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text("Sign Up with Google"),
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
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text("Login"),
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