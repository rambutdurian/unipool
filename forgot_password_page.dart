import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

// --- Constants (Color and Style Definitions) ---
const Color kPrimaryBlueColor = Color(0xFF15273C);
const Color kInputFillColor = Color(0xFFD9D9D9);
const Color kHintTextColor = Color(0xFF898686);
const Color kPrimaryBlack = Color(0xFF000000);
const Color kPrimaryWhite = Color(0xFFFFFFFF);

const TextStyle kBoldLabelStyle = TextStyle(
  color: kPrimaryBlack,
  fontSize: 12,
  fontWeight: FontWeight.bold,
);

const TextStyle kInputTextStyle = TextStyle(
  color: kHintTextColor,
  fontSize: 13,
);

const TextStyle kButtonTextStyle = TextStyle(
  color: Color(0xFFFFFFFF), // White text for the button
  fontSize: 13,
  fontWeight: FontWeight.bold,
);

// --- ForgotPasswordPage Widget ---

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Please enter a valid email address.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      // Navigate to confirmation page on success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordSentConfirmationPage(email: email),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'invalid-email') {
        message = 'The email format is invalid.';
      } else {
        message = 'An error occurred. Please try again later. (${e.code})';
      }
      log('Firebase Auth Error: ${e.code}', error: e);
      _showSnackBar(message, Colors.red);
      } catch (e) {
        log('Unexpected Error: $e', error: e);
        _showSnackBar('An unexpected error occurred.', Colors.red);
      } finally {
          // Check for context safety before calling setState after async operation
          if (mounted) { // Removed '&& Navigator.canPop(context)' as it's not strictly necessary here and can be simplified
            setState(() {
              _isLoading = false;
            });
          }
      }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = !_isLoading;
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: kPrimaryWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only( top: 273, bottom: 273, left: 16, right: 16),
                  child: IntrinsicHeight(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: kPrimaryBlack,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(40),
                        color: kPrimaryWhite,
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // --- START: Centered Logo Section (FIXED) ---
                          IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only(top: 7, bottom: 25), // Adjusted margin for proper spacing
                              width: double.infinity,
                              child: Center( // **FIX: Use Center to guarantee horizontal centering**
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // **FIX: Center the contents of the Row**
                                  mainAxisSize: MainAxisSize.min, // Shrink-wrap the Row horizontally
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: Image.network(
                                        "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/bg1h7g50_expires_30_days.png",
                                        fit: BoxFit.fill,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.car_rental, size: 30),
                                      ),
                                    ),
                                    const SizedBox(width: 8), // Spacing between icon and text
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        "UniPool",
                                        style: TextStyle(
                                          color: kPrimaryBlack,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // --- END: Centered Logo Section ---

                          Container(
                            margin: const EdgeInsets.only( bottom: 29, left: 29),
                            child: const Text(
                              "Enter your email to receive a password reset link",
                              style: TextStyle(
                                color: kHintTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.only( bottom: 8, left: 37),
                            child: const Text(
                              "Email",
                              style: kBoldLabelStyle,
                            ),
                          ),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: kInputFillColor,
                            ),
                            margin: const EdgeInsets.only( bottom: 25, left: 28, right: 28),
                            width: double.infinity,
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onSubmitted: (_) => isEnabled ? _sendPasswordResetEmail() : null,
                              style: kInputTextStyle.copyWith(color: kPrimaryBlack),
                              decoration: const InputDecoration(
                                hintText: "Enter your USM student email",
                                hintStyle: kInputTextStyle,
                                isDense: true,
                                contentPadding: EdgeInsets.only(top: 7, bottom: 7, left: 14, right: 14),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),

                          InkWell(
                            onTap: isEnabled ? _sendPasswordResetEmail : null,
                            child: IntrinsicHeight(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: kPrimaryBlueColor,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                margin: const EdgeInsets.only( bottom: 23, left: 28, right: 28),
                                width: double.infinity,
                                child: Center(
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
                                        "Send Reset Link",
                                        style:kButtonTextStyle,
                                      ),
                                ),
                              ),
                            ),
                          ),

                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: TextButton(
                                onPressed: isEnabled ? () => Navigator.pop(context) : null,
                                child: Text(
                                  "Back to Login",
                                  style: kBoldLabelStyle.copyWith(
                                    color: isEnabled ? kPrimaryBlack : kHintTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PasswordSentConfirmationPage Widget ---

class PasswordSentConfirmationPage extends StatelessWidget {
  final String email;
  const PasswordSentConfirmationPage({super.key, required this.email});

  Future<void> _resendResetEmail(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Another reset link has been sent to your email!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend link. Please check your network and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    // Basic email masking: show first char, then '****', then the domain
    final maskedEmail = email.replaceRange(1, email.indexOf('@'), '****');
        
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: kPrimaryWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only( top: 232, bottom: 232, left: 16, right: 16),
                  child: IntrinsicHeight(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: kPrimaryBlack,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(40),
                        color: kPrimaryWhite,
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // --- START: Centered Logo Section (FIXED) ---
                          IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only(top: 7, bottom: 25), // Adjusted margin for proper spacing
                              width: double.infinity,
                              child: Center( // Use Center to guarantee horizontal centering
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center the contents of the Row
                                  mainAxisSize: MainAxisSize.min, // Shrink-wrap the Row horizontally
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: Image.network(
                                        // **FIX: Replaced missing _logoIconUrl with the correct string URL**
                                        "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/v745e9e1_expires_30_days.png",
                                        fit: BoxFit.fill,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.car_rental, size: 30),
                                      ),
                                    ),
                                    const SizedBox(width: 8), // Spacing between icon and text
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        "UniPool",
                                        style: TextStyle(
                                          color: kPrimaryBlack,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // --- END: Centered Logo Section ---

                          IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only( bottom: 2),
                              width: double.infinity,
                              child: Center(
                                child: IntrinsicWidth(
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only( right: 10),
                                          width: 22,
                                          height: 22,
                                          child: Image.network(
                                            "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/pb61lwia_expires_30_days.png",
                                            fit: BoxFit.fill,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.mail, size: 22),
                                          )
                                        ),
                                        const Text(
                                          "Check Your Email",
                                          style: TextStyle(
                                            color: kPrimaryBlack,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ]
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only( bottom: 18),
                              width: double.infinity,
                              child: Center(
                                child: SizedBox(
                                  width: 215,
                                  child: Text(
                                    "We’ve sent a password reset link to \n$maskedEmail",
                                    style: kInputTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell( 
                            onTap: () {}, // Tap is intentionally disabled for this container
                            child: IntrinsicHeight(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: kInputFillColor,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                margin: const EdgeInsets.only( bottom: 33, left: 28, right: 28),
                                width: double.infinity,
                                child: Center(
                                  child: SizedBox(
                                    width: 243,
                                    child: Text(
                                      "Click the link in the email to reset your \npassword. The link will expire in 1 hour.\n\nDidn\'t receive the email? \nCheck your spam folder.",
                                      style: kInputTextStyle.copyWith(color: kPrimaryBlack),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _resendResetEmail(context),
                            child: IntrinsicHeight(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color:kPrimaryBlueColor,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                margin: const EdgeInsets.only( bottom: 23, left: 28, right: 28),
                                width: double.infinity,
                                child: const Center(
                                  child: Text(
                                    "Resend Reset Link",
                                    style: kButtonTextStyle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: TextButton(
                                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                                child: const Text(
                                  "Go to Login Page",
                                  style: kBoldLabelStyle,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ),
                    ),
                  ),
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}
