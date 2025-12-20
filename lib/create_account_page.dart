import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'login_page.dart';

enum UserRole {
  passenger,
  driver,
}

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserRole _currentRole = UserRole.passenger; // Use the enum
  String? licenseFileName;
  Uint8List? _licenseFileBytes;
  bool isLoading = false;

  String _countryCode = '+60'; // Default to Malaysia's code
  String _phoneNumber = ''; // Stores the national number part
  String _finalE164PhoneNumber = ''; // Stores the combined E.164 number

  String _emergencyCountryCode = '+60'; 
  String _emergencyPhoneNumber = ''; 
  String _finalE164EmergencyNumber = ''; 

  static const String _passengerIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/hid6fyeh_expires_30_days.png";
  static const String _driverIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/fm2fw7gz_expires_30_days.png";
  static const String _logoIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/1vfnjyz3_expires_30_days.png";

  final Map<String, String> passenger = {
    "name": "",
    "email": "",
    "phone": "",
    "emergencyPhone": "",
    "matricNumber": "",
    "graduationDate": "",
    "password": "",
    "confirmPassword": "",
  };

  final Map<String, String> driver = {
    "name": "",
    "email": "",
    "phone": "",
    "emergencyPhone": "",
    "matricNumber": "",
    "graduationDate": "",
    "licenseNumber": "",
    "carModel": "",
    "plateNumber": "",
    "password": "",
    "confirmPassword": "",
  };

  void _setRole(UserRole role) {
    if (_currentRole != role) {
      setState(() {
        _currentRole = role;
        if (role == UserRole.passenger) {
          licenseFileName = null;
          _licenseFileBytes = null;
        }
      });
    }
  }

  Future<void> pickLicenseFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["jpg", "png", "jpeg"],
      withData: true, 
    );
    if (result != null && result.files.isNotEmpty) {
      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;
      int quality = 90;
      while (fileBytes.length > 600000 && quality > 10) {
        log('Compressing... Current size: ${fileBytes.length} bytes');
        fileBytes = await FlutterImageCompress.compressWithList(
          fileBytes,
          minHeight: 1080, 
          minWidth: 1920,
          quality: quality,
        ); 
        quality -= 10; 
      }
      if (fileBytes.length > 800000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is still too large. Please use a smaller photo.')),
        );
        return;
      }
      setState(() {
        licenseFileName = fileName;
        _licenseFileBytes = fileBytes;
      });
      log('Final compressed size: ${fileBytes.length} bytes');
    }
  } catch (e) {
    log('File pick/compress error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick file'),
          backgroundColor: Colors.red,
        ),
      );
    }
    }
  }

  Future<void> _selectGraduationDate(Map<String, String> userData) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showMonthYearPicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)), 
      firstDate: DateTime(now.year), 
      lastDate: DateTime(now.year + 5, 12), 
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF15273C), 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final String month = pickedDate.month.toString().padLeft(2, '0');
      final String year = pickedDate.year.toString();
      final String formattedDate = '$month/$year';
      setState(() {
        userData["graduationDate"] = formattedDate;
      });
      log('Graduation Date selected: $formattedDate');
    }
  }

  String? validateFields(Map<String, String> userData, bool isPassenger) {
    final required = [
      "name", "email", "phone", "matricNumber", "graduationDate", "password", "confirmPassword"
    ];

    // --- 1. Check for Empty Fields ---
    for (final key in required) {
      if ((userData[key] ?? "").trim().isEmpty) {
        final fieldName = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').toLowerCase().trim();
        return 'Please enter your $fieldName.';
      }
    }

    // --- 2. Driver Specific Field Checks ---
    if (!isPassenger) {
      if ((userData["licenseNumber"] ?? "").trim().isEmpty) return 'License number required.';
      if ((userData["carModel"] ?? "").trim().isEmpty) return 'Car model/color required.';
      if ((userData["plateNumber"] ?? "").trim().isEmpty) return 'Plate number required.';
      if (_licenseFileBytes == null) return 'Please upload license photo.';
    }

    // --- 3. Password Match Check ---
    if (userData["password"] != userData["confirmPassword"]) return 'Passwords do not match.';

    // --- 4. Password Strength Check ---
    // Regex for: at least 8 characters, one uppercase, one lowercase, one number, and one symbol.
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>$])(.{8,})$').hasMatch(userData["password"]!)) {
      return 'Password must be 8+ chars with uppercase, lowercase, number, and symbol.';
    }

    // --- 5. Email Format Check  ---
    final email = userData["email"] ?? "";
    // Check for the specific USM student domain
    const usmStudentDomain = '@student.usm.my';
    if (!userData["email"]!.toLowerCase().endsWith('@student.usm.my')) {
      return 'Email must be a valid USM student email (ending in $usmStudentDomain).';
    }

    // Basic email format check for the part before the domain
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@').hasMatch(email)) {
      return 'Please enter a valid email address (username part is invalid).';
    }

    // --- 6. Phone Number Format Check  ---
    final phone = userData["phone"] ?? "";
    const e164Regex = r'^\+\d{7,20}$';
    if (!RegExp(e164Regex).hasMatch(phone)) return 'Please enter a valid phone number.';
    if ((userData["emergencyPhone"] ?? "").isEmpty) return 'Please enter an emergency contact.';
    if (userData["phone"] == userData["emergencyPhone"]) return 'Emergency contact cannot be the same as your phone number.';

    // --- 7. Matric Number Check  ---
    final matricNumber = userData["matricNumber"] ?? "";
    if (!RegExp(r'^[a-zA-Z0-9]{6,20}$').hasMatch(matricNumber)) {
      return 'Please enter a valid matric number.';
    }
    return null;
  }

  void handleSignup(bool isPassenger) async {
    final userData = isPassenger ? passenger : driver;
    userData["phone"] = _finalE164PhoneNumber;

    final validationMessage = validateFields(userData, isPassenger);
    if (validationMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationMessage), backgroundColor: Colors.red,));
      log('Signup validation failed: $validationMessage');
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: userData["email"]!.trim(),
        password: userData["password"]!,
      );
      final user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        String? base64License;
        if (!isPassenger && _licenseFileBytes != null) {
          base64License = base64Encode(_licenseFileBytes!);
        }
        
        // --- 4. Firestore Date Prepare ---
        final Map<String, dynamic> firestoreData = {
          "uid": user.uid,
          "email": userData["email"]!.toLowerCase(),
          "role": isPassenger ? "passenger" : "driver",
          "name": userData["name"]!.toUpperCase(),
          "phone": userData["phone"],
          "emergencyPhone": userData["emergencyPhone"],
          "matricNumber": userData["matricNumber"],
          "graduationDate": userData["graduationDate"],
          "createdAt": FieldValue.serverTimestamp(),
          "isVerified": false, 
        };

        if (!isPassenger) {
          firestoreData["licenseNumber"] = userData["licenseNumber"];
          firestoreData["carModel"] = userData["carModel"];
          firestoreData["plateNumber"] = userData["plateNumber"];
          firestoreData["licenseData"] = base64License; 
          firestoreData["isAdminApproved"] = false; 
          firestoreData["ratingCount"] = 0;      
          firestoreData["totalRatingValue"] = 0; 
          firestoreData["averageRating"] = 5.0;  
        }

        // --- 4. Firestore Write ---
        try {
          await _db.collection('users').doc(user.uid).set(firestoreData);
        } on FirebaseException catch (dbError) {
          log('Firestore Write Error: ${dbError.code}', error: dbError);
          // Clean up the Auth user if the DB write fails
          await user.delete();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile data. Please try again. ${dbError.code}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // --- 5. Success and Navigation ---
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Check your email for a verification link.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during account creation. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak. Please meet the criteria.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      }
      log('Firebase Auth Error: ${e.code}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0xFFD9D9D9)),
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.only(bottom: 28, left: 28, right: 28),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Expanded(child: InkWell(
          onTap: () => _setRole(UserRole.passenger),
          child: _buildRoleButton(role: UserRole.passenger, iconUrl: _passengerIconUrl, text: "Passenger")),
        ),
        Expanded(child: InkWell(
          onTap: () => _setRole(UserRole.driver),
          child: _buildRoleButton(role: UserRole.driver, iconUrl: _driverIconUrl, text: "Driver")),
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
        boxShadow: isActive ? const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))] : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(iconUrl, width: 20, height: 20, fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF000000), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, String hint, ValueChanged<String> onChanged, bool isPassword, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8, left: 37),
          child: Text(label, style: const TextStyle(color: Color(0xFF000000), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFD9D9D9)),
          margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
          width: double.infinity,
          child: TextField(
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(color: Color(0xFF898686), fontSize: 13,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(hintText: hint, isDense: true,
              contentPadding: const EdgeInsets.only(top: 7, bottom: 7, left: 14, right: 14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInternationalPhoneField({
    required String label,
    required String initialCountryCode,
    required ValueChanged<String> onCountryChanged,
    required ValueChanged<String> onNumberChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 37),
        child: Text(label, style: const TextStyle(color: Color(0xFF000000), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
        decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            CountryCodePicker(
              initialSelection: initialCountryCode,
              onChanged: (c) => onCountryChanged(c.dialCode!),
            ),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                onChanged: onNumberChanged,
                style: const TextStyle(color: Color(0xFF898686), fontSize: 13),
                decoration: const InputDecoration(hintText: "Enter phone number", border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildGraduationDateField(Map<String, String> userData) {
  final String dateValue = userData["graduationDate"] ?? ""; 
  const String placeholderText = "mm/yyyy";
  final bool isPlaceholder = dateValue.isEmpty;
  final String displayDate = isPlaceholder ? placeholderText : dateValue;
  const Color hintColor = Color(0xFF898686);
  const Color inputColor = Color(0xFF000000); 

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 8, left: 37),
        child: Text("Graduation Date", style: TextStyle(color: Color(0xFF000000), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      InkWell(
        onTap: () => _selectGraduationDate(userData),
        child: Container(alignment: Alignment.centerLeft, height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFD9D9D9),
          ),
          margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(displayDate,
                style: TextStyle(color: isPlaceholder ? hintColor : inputColor, fontSize: 13,
                ),
              ),
              const Icon(Icons.calendar_today, size: 16, color: hintColor),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildUploadButton() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(padding: EdgeInsets.only(bottom: 8, left: 37), child: Text("License Photo", style: TextStyle(color: Color(0xFF000000), fontSize: 12, fontWeight: FontWeight.bold))),
      Container(
        margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
        child: OutlinedButton.icon(
        onPressed: pickLicenseFile,
          icon: const Icon(Icons.upload, color: Color(0xFF15273C)),
          label: Text(licenseFileName ?? "Choose Image", style: TextStyle(color: licenseFileName != null ? Colors.black87 : const Color(0xFF15273C)),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFD9D9D9),
            minimumSize: const Size.fromHeight(40),
            side: const BorderSide(color: Color(0xFFD9D9D9)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  final isPassenger = _currentRole == UserRole.passenger;
  final userData = isPassenger ? passenger : driver;
  final signupButtonText = isPassenger ? "Create Account as Passenger" : "Create Account as Driver";
  final signupButtonColor = const Color(0xFF15273C);
  
  final List<Widget> commonFields = [
    _buildTextField("Full Name", "Enter your full name", (v) => userData["name"] = v, false),
    _buildTextField("Email", "Enter your USM student email", (v) => userData["email"] = v, false, keyboardType: TextInputType.emailAddress),
    
    _buildInternationalPhoneField(
      label: "Phone Number",
      initialCountryCode: 'MY',
      onCountryChanged: (code) {
        setState(() {
          _countryCode = code;
          _finalE164PhoneNumber = _countryCode + _phoneNumber.replaceAll(' ', '');
          userData["phone"] = _finalE164PhoneNumber;
        });
      },
      onNumberChanged: (v) {
        setState(() {
          _phoneNumber = v;
          _finalE164PhoneNumber = _countryCode + v.replaceAll(' ', '');
          userData["phone"] = _finalE164PhoneNumber;
        });
      },
    ),

    _buildInternationalPhoneField(
      label: "Emergency Contact Phone Number",
      initialCountryCode: 'MY',
      onCountryChanged: (code) {
        setState(() {
          _emergencyCountryCode = code;
          _finalE164EmergencyNumber = _emergencyCountryCode + _emergencyPhoneNumber.replaceAll(' ', '');
          userData["emergencyPhone"] = _finalE164EmergencyNumber;
        });
      },
      onNumberChanged: (v) {
        setState(() {
          _emergencyPhoneNumber = v;
          _finalE164EmergencyNumber = _emergencyCountryCode + v.replaceAll(' ', '');
          userData["emergencyPhone"] = _finalE164EmergencyNumber;
        });
      },
    ),
      
    _buildTextField("Matric Number", "Enter your matric number", (v) => userData["matricNumber"] = v, false),
    _buildGraduationDateField(userData),
  ];

  final List<Widget> driverFields = [
    _buildTextField("Car Model & Color", "e.g. Myvi (Blue)", (v) => userData["carModel"] = v, false),
    _buildTextField("Plate Number", "e.g. PNB 1234", (v) => userData["plateNumber"] = v, false),
    _buildTextField("License Number", "Enter license number", (v) => userData["licenseNumber"] = v, false),
    _buildUploadButton(),
  ];

  final List<Widget> passwordFields = [
    _buildTextField("Password", "Create a password", (v) => userData["password"] = v, true),
    _buildTextField("Confirm Password", "Confirm your password", (v) => userData["confirmPassword"] = v, true),
  ];

  return Scaffold(
    body: SafeArea(child: Container(
      constraints: const BoxConstraints.expand(),
      color: const Color(0xFFFFFFFF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Container(constraints: const BoxConstraints(maxWidth: 400), 
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF000000), width: 1),
              borderRadius: BorderRadius.circular(20), color: const Color(0xFFFFFFFF)),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(_logoIconUrl, width: 30, height: 30, fit: BoxFit.fill, errorBuilder: (context, error, stackTrace) => const Icon(Icons.car_rental, size: 30)),
                      const SizedBox(width: 8),
                      const Text("UniPool", style: TextStyle(color: Color(0xFF000000), fontSize: 16)),
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.only(bottom: 29, top: 10),
                  child: Text("Create your account to get started.", style: TextStyle(color: Color(0xFF898686), fontSize: 13)),
                ),
                _buildRoleToggle(),
                      
                ...commonFields,
                if (!isPassenger) ...driverFields,
                ...passwordFields,

                Padding(padding: const EdgeInsets.only(bottom: 26, left: 28, right: 28),
                  child: InkWell(onTap: isLoading ? null : () => handleSignup(isPassenger),
                    child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: signupButtonColor.withAlpha(isLoading ? 153 : 255)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    width: double.infinity,
                    child: Center(child: isLoading ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                    : Text(signupButtonText, style: const TextStyle(color: Color(0xFFFFFDFD), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.only(bottom: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?", style: TextStyle(color: Color(0xFF898686), fontSize: 13)),
                      const SizedBox(width: 6),
                      InkWell(onTap: () => Navigator.pop(context),
                        child: const Text("Log In", style: TextStyle(color: Color(0xFF000000), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
        ],
        ))),
      ),
    );
  }
}
