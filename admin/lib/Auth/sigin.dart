import 'package:admin/Auth/forgot_password.dart';
// import 'package:admin/Auth/signup.dart';
import 'package:admin/Controller/sign_in_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Signin extends StatelessWidget {
  const Signin({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final controller = Get.put(SigninController());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              // Top image
              Positioned(
                top: screenHeight * .08,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: screenHeight * 0.23,
                  width: screenWidth * 0.23,
                  child: Image.asset(
                    'assets/images/top.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Icon button image
              Positioned(
                left: screenHeight * .010,
                top: -screenHeight * .01,
                child: SizedBox(
                  height:
                      screenHeight * 0.2, // Optional: adjust or keep for layout
                  width: screenWidth * 0.2,
                  child: GestureDetector(
                    onTap: () {
                      SystemChannels.platform.invokeMethod(
                        'SystemNavigator.pop',
                      );
                    },
                    child: Container(
                      width: 30, // Smaller width
                      height: 30, // Smaller height
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFCC3E),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF030047),
                          size: 30, // Optional: smaller icon to fit
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Round image
              Positioned(
                right: -screenHeight * .14,
                top: -screenHeight * .13,
                child: SizedBox(
                  height: screenHeight * 0.3,
                  width: screenHeight * 0.3,
                  child: Image.asset(
                    'assets/images/round.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Welcome Back text
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

              // Sign In title
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

              // Email or Phone field
              Positioned(
                top: MediaQuery.of(context).size.height * 0.45,
                left: 30,
                right: 30,
                child: TextField(
                  controller: controller.emailOrPhoneController,
                  decoration: InputDecoration(
                    suffixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFF030047),
                    ),
                    labelText: "Email or Phone Number",
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 193, 204, 240),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Color(0xFF030047),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Color(0xFFE1E5F2),
                  ),
                ),
              ),

              // Bottom image
              Positioned(
                bottom: -screenHeight * .1,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: screenHeight * 0.6,
                  width: screenWidth,
                  child: Image.asset(
                    'assets/images/bottom.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Password field
              Positioned(
                top: MediaQuery.of(context).size.height * 0.53,
                left: 30,
                right: 30,
                child: Obx(
                  () => TextField(
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Color(0xFF030047),
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      labelText: "Password",
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 193, 204, 240),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Color(0xFF030047),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFFE1E5F2),
                    ),
                  ),
                ),
              ),

              // Forgot Password
              Positioned(
                bottom: screenHeight * .36,
                right: screenHeight * .04,
                child: TextButton(
                  onPressed: () => Get.offAll(() => ForgotPasswordPage()),
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
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
                    width: screenWidth * 0.8,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: controller.handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC3E),
                      ),
                      child: const Text(
                        "SIGN IN",
                        style: TextStyle(
                          color: Color(0xFF030047),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Sign Up
              // Positioned(
              //   bottom: screenHeight * .06,
              //   left: 0,
              //   right: 0,
              //   child: Center(
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Text(
              //           "Don't have an account? ",
              //           style: TextStyle(
              //             color: Colors.white,
              //             fontSize: screenHeight * .02,
              //           ),
              //         ),
              //         TextButton(
              //           onPressed: () {
              //             Get.offAll(() => Signup());
              //           },
              //           child: Text(
              //             "Create one now",
              //             style: TextStyle(
              //               color: const Color(0xFFFFCC3E),
              //               fontSize: screenHeight * .022,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
