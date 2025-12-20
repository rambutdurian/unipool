import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import 'create_account_page.dart';

enum UserRole { passenger, driver }

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Login());
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static const String _requiredDomain = '@student.usm.my';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const String _passengerIconUrl =
      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/hid6fyeh_expires_30_days.png";
  static const String _driverIconUrl =
      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/fm2fw7gz_expires_30_days.png";
  static const String _logoIconUrl =
      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/1vfnjyz3_expires_30_days.png";

  UserRole _currentRole = UserRole.passenger;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String requestedRole = _currentRole == UserRole.passenger
        ? 'passenger'
        : 'driver';

    try {
      // --- 1. Basic Validation (Empty Fields) ---
      if (email.isEmpty || password.isEmpty) {
        throw const AuthException('Please enter both your email and password.');
      }

      // --- 2. Email Domain Check  ---
      if (!email.toLowerCase().endsWith(_requiredDomain)) {
        throw AuthException(
          'Login requires a valid student email ending with $_requiredDomain.',
        );
      }

      // --- 3. Firebase Authentication (Sign In) ---
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException('Authentication failed. Please try again.');
      }

      // --- 4. Email Verification Check ---
      await user.reload();
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        throw const AuthException(
          'Account not verified. A new link has been sent. Please check your email.',
        );
      }

      // --- 5. Firestore Document Fetch & Verification Sync ---
      final userDocRef = _db.collection('users').doc(user.uid);
      DocumentSnapshot docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        throw const AuthException(
          'User data not found in database. Contact support.',
        );
      }
      final Map<String, dynamic>? data =
          docSnapshot.data() as Map<String, dynamic>?;
      final bool isVerifiedInDB = data?['isVerified'] as bool? ?? false;

      if (user.emailVerified && !isVerifiedInDB) {
        log(
          'Email verification sync: Firebase Auth is verified, but Firestore is not. UPDATING DB...',
        );

        await userDocRef.update({
          'isVerified': true,
          'emailVerifiedAt': FieldValue.serverTimestamp(),
        });

        docSnapshot = await userDocRef.get();
      }

      final Map<String, dynamic>? latestData =
          docSnapshot.data() as Map<String, dynamic>?;
      final savedRole = latestData?['role'] as String? ?? 'unknown';

      if (savedRole != requestedRole) {
        String displayRole =
            savedRole.substring(0, 1).toUpperCase() +
            savedRole.substring(1).toLowerCase();
        throw AuthException(
          'You are registered as a $displayRole. Please switch your role selection.',
        );
      }

      // --- LOGIN SUCCESS ---
      log('Login successful as $requestedRole with Email: $email');
      if (!mounted) return;

      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on AuthException catch (e) {
      // Catch custom exceptions (validation errors)
      log('Validation Error: ${e.message}');
      _showSnackBar(e.message, Colors.orange);
    } on FirebaseAuthException catch (e) {
      String message = 'An unexpected login error occurred.';

      switch (e.code) {
        case 'invalid-email':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Try again later.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Contact support.';
          break;
      }

      log('Firebase Auth Error: ${e.code}');
      _showSnackBar(message, Colors.red);
    } catch (e, st) {
      log('General Login Error: $e', error: e, stackTrace: st);
      _showSnackBar(
        'An unexpected error occurred. Please try again.',
        Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFD9D9D9),
      ),
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.only(bottom: 28, left: 28, right: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Passenger Toggle Button
          Expanded(
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () => setState(() => _currentRole = UserRole.passenger),
              child: _buildRoleButton(
                role: UserRole.passenger,
                iconUrl: _passengerIconUrl,
                text: "Passenger",
              ),
            ),
          ),
          // Driver Toggle Button
          Expanded(
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () => setState(() => _currentRole = UserRole.driver),
              child: _buildRoleButton(
                role: UserRole.driver,
                iconUrl: _driverIconUrl,
                text: "Driver",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String iconUrl,
    required String text,
  }) {
    final bool isActive = _currentRole == role;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? Colors.white : Colors.transparent,
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            iconUrl,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF000000), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 37),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFD9D9D9),
          ),
          margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
          width: double.infinity,
          child: TextField(
            enabled: !_isLoading,
            controller: controller,
            keyboardType: isPassword
                ? TextInputType.visiblePassword
                : TextInputType.emailAddress,
            obscureText: isPassword ? !_isPasswordVisible : false,
            style: const TextStyle(color: Color(0xFF898686), fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.only(
                top: 7,
                bottom: 7,
                left: 14,
                right: 14,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,

              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF898686),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPassenger = _currentRole == UserRole.passenger;
    final loginButtonText = isPassenger
        ? "Log In as Passenger"
        : "Log In as Driver";
    const loginButtonColor = Color(0xFF15273C);

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF000000),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFFFFFFF),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // UniPool Logo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              _logoIconUrl,
                              width: 30,
                              height: 30,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.car_rental, size: 30),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "UniPool",
                              style: TextStyle(
                                color: Color(0xFF000000),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 29, top: 10),
                        child: Text(
                          "Welcome back! Log in to your account.",
                          style: TextStyle(
                            color: Color(0xFF898686),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Role Toggle
                      _buildRoleToggle(),

                      // Email Field
                      _buildTextField(
                        label: "Email",
                        hint: "Enter your email",
                        controller: _emailController,
                      ),

                      // Password Field
                      _buildTextField(
                        label: "Password",
                        hint: "Enter your password",
                        controller: _passwordController,
                        isPassword: true,
                      ),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 34, right: 32),
                          child: InkWell(
                            onTap: _isLoading
                                ? null
                                : () => log('Forgot Password clicked'),
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: _isLoading
                                    ? const Color(0xFF898686)
                                    : const Color(0xFF000000),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Login Button
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 26,
                          left: 28,
                          right: 28,
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: loginButtonColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            disabledBackgroundColor: loginButtonColor.withAlpha(
                              153,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  loginButtonText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      // Create Account Link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don’t have an account?",
                              style: TextStyle(
                                color: Color(0xFF898686),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateAccountPage(),
                                      ),
                                    ),
                              child: Text(
                                "Create Account",
                                style: TextStyle(
                                  color: _isLoading
                                      ? const Color(0xFF898686)
                                      : const Color(0xFF000000),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
