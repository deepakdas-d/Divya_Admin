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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool isEmailEmpty = true;
  bool isEmailValid = false;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() {
      final email = _emailController.text.trim();

      setState(() {
        isEmailEmpty = email.isEmpty;
        isEmailValid = _isValidEmail(email); // <- validate format
      });
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      print("Attempting to sign in with email: $email"); // Debug log

      // First sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;
      print("Sign in successful, UID: $uid"); // Debug log

      // Check if the user exists in the 'admins' collection
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        Map<String, dynamic> adminData =
            adminDoc.data() as Map<String, dynamic>;

        if (adminData['role'] == 'admin') {
          print("Admin login verified.");
          return null; // allow login
        } else {
          // Not an admin
          await FirebaseAuth.instance.signOut();
          return 'Access denied. You are not an admin.';
        }
      } else {
        // No admin record found
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
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill in both fields")));
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      String? result = await signIn(email, password);

      // Remove the loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signed in successfully"),
            backgroundColor: Color(0xFFFFCC3E),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Dashboard()), // Fix class name
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

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
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

          // icon button image
          Positioned(
            left: -screenHeight * .05,
            top: -screenHeight * .09,
            child: TextButton(
              onPressed: () {
                // Exit the app
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

          //Welcome text
          Positioned(
            top: screenHeight * .3,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: Text(
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
            child: Text(
              'SIGN IN',
              style: TextStyle(
                fontSize: 25,
                // fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 63, 97, 209),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          //text fields of email
          Positioned(
            top: screenHeight * .44,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                suffixIcon: Icon(
                  Icons.email_outlined,
                  color: Color(0xFF030047),
                ),
                labelText: 'Email or Username',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 193, 204, 240),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.transparent, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Color(0xFF030047), width: 2),
                ),
                filled: true,
                fillColor: Color(0xFFE1E5F2),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenHeight * .02,
                  vertical: screenHeight * .015,
                ),
              ),
              style: TextStyle(fontSize: 18),
              keyboardType: TextInputType.emailAddress,
            ),
          ),

          // Bottom image
          Positioned(
            bottom: -screenHeight * .1,
            left: 1,
            right: 0,
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.6, // Adjust based on screen size
              width: MediaQuery.of(context).size.width * 0.6,
              child: Image.asset('assets/images/bottom.png', fit: BoxFit.cover),
            ),
          ),
          //text fields of password
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
                    color: Color(0xFF030047),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 193, 204, 240),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.transparent, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Color(0xFF030047), width: 2),
                ),
                filled: true,
                fillColor: Color(0xFFE1E5F2),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenHeight * .02,
                  vertical: screenHeight * .015,
                ),
              ),
              style: TextStyle(fontSize: 18),
            ),
          ),

          //forgot password text
          Positioned(
            bottom: screenHeight * .35,
            right: screenHeight * .04,
            child: TextButton(
              onPressed: (!isEmailEmpty && isEmailValid)
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OTPVerification(
                            email: _emailController.text.trim(),
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: (!isEmailEmpty && isEmailValid)
                      ? Colors.blue
                      : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          //  Button above the image
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
                    backgroundColor: Color(0xFFFFCC3E),
                  ),
                  child: Text(
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
                width:
                    MediaQuery.of(context).size.width *
                    0.9, // 90% of screen width
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "don't have an account? ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * .02,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signup()),
                        );
                      },
                      child: Text(
                        "create one now",
                        style: TextStyle(
                          color: Color(0xFFFFCC3E),
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
