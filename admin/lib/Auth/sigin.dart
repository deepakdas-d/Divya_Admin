import 'package:admin/Auth/otp-verification.dart';
import 'package:admin/Auth/signup.dart';
import 'package:admin/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Sigin extends StatefulWidget {
  const Sigin({super.key});

  @override
  State<Sigin> createState() => SiginState();
}

class SiginState extends State<Sigin> {
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool isInputEmpty = true;
  bool isInputValid = false;

  @override
  void initState() {
    super.initState();

    _emailOrPhoneController.addListener(() {
      final input = _emailOrPhoneController.text.trim();

      setState(() {
        isInputEmpty = input.isEmpty;
        isInputValid = _isValidEmail(input) || _isValidPhone(input);
      });
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> signIn(String input, String password) async {
    try {
      print("Attempting to sign in with input: $input"); // Debug log

      String? email;
      String? uid;

      // Check if input is an email or phone number
      if (_isValidEmail(input)) {
        // Input is an email
        email = input;
      } else if (_isValidPhone(input)) {
        // Input is a phone number, query Firestore to find matching email
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('admins')
            .where('phone', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          email = query.docs.first.get('email') as String;
          uid = query.docs.first.get('uid') as String;
          print("Found email for phone: $email"); // Debug log
        } else {
          return 'No account found for this phone number.';
        }
      } else {
        return 'Invalid email or phone number format.';
      }

      // Sign in with Firebase Auth using the email
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password);

      uid ??= userCredential.user!.uid;
      print("Sign in successful, UID: $uid"); // Debug log

      // Verify admin role in Firestore
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        Map<String, dynamic> adminData =
            adminDoc.data() as Map<String, dynamic>;

        if (adminData['role'] == 'admin') {
          print("Admin login verified.");
          return null; // Allow login
        } else {
          await FirebaseAuth.instance.signOut();
          return 'Access denied. You are not an admin.';
        }
      } else {
        await FirebaseAuth.instance.signOut();
        return 'No admin record found.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  void handleSignIn() async {
    String input = _emailOrPhoneController.text.trim();
    String password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both fields")),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String? result = await signIn(input, password);

      // Remove the loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Signed in successfully"),
            backgroundColor: const Color(0xFFFFCC3E),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $result")));
      }
    } catch (e) {
      // Remove loading dialog if still showing
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
  }

  Future<String?> _getEmailFromPhone(String phone) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('admins')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.get('email') as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Top image
          Positioned(
            top: screenHeight * .08,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.23,
              width: MediaQuery.of(context).size.width * 0.23,
              child: Image.asset('assets/images/top.png', fit: BoxFit.contain),
            ),
          ),

          // Icon button image
          Positioned(
            left: -screenHeight * .05,
            top: -screenHeight * .09,
            child: TextButton(
              onPressed: () {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width * 0.4,
                child: Image.asset(
                  'assets/images/icon button.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Round image
          Positioned(
            right: -screenHeight * .14,
            top: -screenHeight * .13,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.height * 0.3,
              child: Image.asset(
                'assets/images/round.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Welcome text
          Positioned(
            top: screenHeight * .3,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Color(0xFF030047),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Sign in text
          Positioned(
            top: screenHeight * .35,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: const Text(
              'SIGN IN',
              style: TextStyle(
                fontSize: 25,
                color: Color.fromARGB(255, 63, 97, 209),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Email or Phone text field
          Positioned(
            top: screenHeight * .44,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: TextField(
              controller: _emailOrPhoneController,
              decoration: InputDecoration(
                suffixIcon: Icon(
                  _isValidEmail(_emailOrPhoneController.text.trim())
                      ? Icons.email_outlined
                      : Icons.phone_outlined,
                  color: const Color(0xFF030047),
                ),
                labelText: 'Email or Phone Number',
                labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 193, 204, 240),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF030047),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFE1E5F2),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenHeight * .02,
                  vertical: screenHeight * .015,
                ),
              ),
              style: const TextStyle(fontSize: 18),
              keyboardType: TextInputType.text,
            ),
          ),

          // Bottom image
          Positioned(
            bottom: -screenHeight * .1,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width,
              child: Image.asset('assets/images/bottom.png', fit: BoxFit.cover),
            ),
          ),

          // Password text field
          Positioned(
            top: screenHeight * .54,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF030047),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                labelText: 'Password',
                labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 193, 204, 240),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF030047),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFE1E5F2),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenHeight * .02,
                  vertical: screenHeight * .015,
                ),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),

          // Forgot password text
          Positioned(
            bottom: screenHeight * .35,
            right: screenHeight * .04,
            child: TextButton(
              onPressed: (!isInputEmpty && isInputValid)
                  ? () async {
                      String? email;
                      String? phone;
                      final input = _emailOrPhoneController.text.trim();

                      if (_isValidEmail(input)) {
                        email = input;
                      } else if (_isValidPhone(input)) {
                        phone = input;
                        email = await _getEmailFromPhone(input);
                        if (email == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "No account found for this phone number.",
                              ),
                            ),
                          );
                          return;
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Invalid email or phone number format.",
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OTPVerification(email: email ?? '', phone: phone),
                        ),
                      );
                    }
                  : null,
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: (!isInputEmpty && isInputValid)
                      ? Colors.blue
                      : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Sign In button
          Positioned(
            bottom: screenHeight * .15,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    handleSignIn();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC3E),
                  ),
                  child: const Text(
                    "SIGN IN",
                    style: TextStyle(color: Color(0xFF030047), fontSize: 16),
                  ),
                ),
              ),
            ),
          ),

          // Sign Up text
          Positioned(
            bottom: screenHeight * .06,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * .02,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Signup(),
                          ),
                        );
                      },
                      child: Text(
                        "Create one now",
                        style: TextStyle(
                          color: const Color(0xFFFFCC3E), // Fixed color value
                          fontSize: screenHeight * .022,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
