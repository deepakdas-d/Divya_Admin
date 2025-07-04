import 'package:admin/Auth/sigin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  //signUp function to handle user registration
  Future<void> signUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      // Create user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // Store admin user data in Firestore
      await FirebaseFirestore.instance.collection('admins').doc(user!.uid).set({
        'email': email,
        'uid': user.uid,
        'role': 'admin', // Mark as admin
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin signup successful!')));

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Sigin()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';

      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Round image
          Positioned(
            right: screenHeight * -0.15,
            top: -screenHeight * 0.1,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.height * 0.3,
              child: Image.asset(
                'assets/images/round.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Top image
          Positioned(
            top: screenHeight * 0.02,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.33,
              width: MediaQuery.of(context).size.width * 0.33,
              child: Image.asset(
                'assets/images/Signup_top.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // icon button image
          Positioned(
            left: -screenHeight * 0.05,
            top: -screenHeight * 0.09,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Signup()),
                );
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

          //Welcome text
          Positioned(
            top: screenHeight * .27,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: Text(
              "LET'S GET STARTED",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF030047),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Sign up text
          Positioned(
            top: screenHeight * .31,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: Text(
              'SIGN UP',
              style: TextStyle(
                fontSize: 25,
                color: Color.fromARGB(255, 63, 97, 209),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Email text field
          Positioned(
            top: screenHeight * .39,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                suffixIcon: Icon(
                  Icons.email_outlined,
                  color: Color(0xFF030047),
                ),
                labelText: 'Email',
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
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              style: TextStyle(fontSize: 18),
              keyboardType: TextInputType.emailAddress,
            ),
          ),

          // Password text field
          Positioned(
            top: screenHeight * .47,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: TextField(
              controller: _passwordController,
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
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              style: TextStyle(fontSize: 18),
              obscureText: !_isPasswordVisible,
            ),
          ),

          // Bottom image (moved before confirm password field)
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

          // Confirm Password text field (moved after bottom image)
          Positioned(
            top: screenHeight * .55,
            left: screenHeight * .04,
            right: screenHeight * .04,
            child: TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Color(0xFF030047),
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                labelText: 'Confirm Password',
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
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              style: TextStyle(fontSize: 18),
              obscureText: !_isConfirmPasswordVisible,
            ),
          ),

          // Sign up button
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
                    signUp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFCC3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "SIGN UP",
                    style: TextStyle(
                      color: Color(0xFF030047),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Login link
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
                      "Already have an account? ",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Sigin()),
                        );
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFFFFCC3E),
                          fontSize: 20,
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
