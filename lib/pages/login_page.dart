import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email validation (basic check for @ and domain)
  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  // Password validation (no spaces or invalid characters)
  bool _isValidPassword(String password) {
    if (password.isEmpty) return false;
    return RegExp(
      r'^(?=.*?[a-zA-Z])(?=.*?[0-9]).{8,}$',
    ).hasMatch(password);
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() {
        _isLoading = false;
        _emailError = 'Invalid email format';
      });
      return;
    }

    if (!_isValidPassword(password)) {
      setState(() {
        _isLoading = false;
        _passwordError = 'Password must be at least 8 characters, with letters and numbers';
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      setState(() {
        _isLoading = false;
      });

      if (userCredential.user != null) {
        if (kDebugMode) {
          print('User signed up: ${userCredential.user!.uid}');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful!')),
        );
        widget.onLoginSuccess?.call();
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'email-already-in-use':
            _emailError = 'Email is already registered';
            break;
          case 'invalid-email':
            _emailError = 'Invalid email format';
            break;
          case 'weak-password':
            _passwordError = 'Password is too weak';
            break;
          case 'unknown':
            _emailError = 'Signup failed: Please check your network or try again later';
            break;
          default:
            _emailError = 'Error: ${e.message}';
        }
      });
      if (kDebugMode) print('Signup error: $e');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _emailError = 'Failed to signup';
      });
      if (kDebugMode) print('Signup error: $e');
    }
  }

  Future<void> _logIn() async {
    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _emailError = email.isEmpty ? 'Email is required' : null;
        _passwordError = password.isEmpty ? 'Password is required' : null;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _isLoading = false;
        _emailError = 'Invalid email format';
      });
      return;
    }

    if (!_isValidPassword(password)) {
      setState(() {
        _isLoading = false;
        _passwordError = 'Invalid password format';
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      setState(() {
        _isLoading = false;
      });

      if (userCredential.user != null) {
        if (kDebugMode) {
          print('User signed in: ${userCredential.user!.uid}');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        widget.onLoginSuccess?.call();
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
            _passwordError = 'Invalid email or password';
            break;
          case 'invalid-email':
            _emailError = 'Invalid email format';
            break;
          default:
            _emailError = 'Failed to sign in: ${e.message}';
        }
      });
      if (kDebugMode) print('Sign-in error: $e');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _emailError = 'Failed to connect to Firebase. Please try again';
      });
      if (kDebugMode) print('Login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                errorText: _emailError,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                hintText: '8+ chars, with letters and numbers',
                errorText: _passwordError,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _logIn,
                      child: const Text('Login'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: const Text('Sign Up'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Continue without login'),
            ),
          ],
        ),
      ),
    );
  }
}
