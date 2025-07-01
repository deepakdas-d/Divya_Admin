// import 'package:admin/Auth/sigin.dart';
// import 'package:admin/Controller/sign_up_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class Signup extends StatelessWidget {
//   final SignupController controller = Get.put(SignupController());

//   Signup({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;

//     return WillPopScope(
//       onWillPop: () async {
//         Get.off(() => Signin());
//         return false;
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         body: SingleChildScrollView(
//           child: SizedBox(
//             height: screenHeight,
//             child: Stack(
//               children: [
//                 // Round image
//                 Positioned(
//                   right: screenHeight * -0.15,
//                   top: -screenHeight * 0.1,
//                   child: SizedBox(
//                     height: MediaQuery.of(context).size.height * 0.3,
//                     width: MediaQuery.of(context).size.height * 0.3,
//                     child: Image.asset(
//                       'assets/images/round.png',
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ),

//                 // Top image
//                 Positioned(
//                   top: screenHeight * 0.02,
//                   left: 0,
//                   right: 0,
//                   child: SizedBox(
//                     height: MediaQuery.of(context).size.height * 0.33,
//                     width: MediaQuery.of(context).size.width * 0.33,
//                     child: Image.asset(
//                       'assets/images/Signup_top.png',
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ),

//                 // icon button image
//                 Positioned(
//                   left: -screenHeight * 0.05,
//                   top: -screenHeight * 0.09,
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => Signup()),
//                       );
//                     },
//                     child: SizedBox(
//                       height: MediaQuery.of(context).size.height * 0.4,
//                       width: MediaQuery.of(context).size.width * 0.4,
//                       child: Image.asset(
//                         'assets/images/icon button.png',
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                   ),
//                 ),

//                 //Welcome text
//                 Positioned(
//                   top: screenHeight * .27,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Text(
//                     "LET'S GET STARTED",
//                     style: TextStyle(
//                       fontSize: 30,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF030047),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),

//                 // Sign up text
//                 Positioned(
//                   top: screenHeight * .31,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Text(
//                     'SIGN UP',
//                     style: TextStyle(
//                       fontSize: 25,
//                       color: Color.fromARGB(255, 63, 97, 209),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),

//                 // Email text field
//                 Positioned(
//                   top: screenHeight * .39,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: TextField(
//                     controller: controller.emailController,
//                     decoration: InputDecoration(
//                       suffixIcon: Icon(
//                         Icons.email_outlined,
//                         color: Color(0xFF030047),
//                       ),
//                       labelText: 'Email',
//                       labelStyle: TextStyle(
//                         color: Color.fromARGB(255, 193, 204, 240),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Colors.transparent,
//                           width: 2,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Color(0xFF030047),
//                           width: 2,
//                         ),
//                       ),
//                       filled: true,
//                       fillColor: Color(0xFFE1E5F2),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 15,
//                       ),
//                     ),
//                     style: TextStyle(fontSize: 18),
//                     keyboardType: TextInputType.emailAddress,
//                   ),
//                 ),

//                 // Phone number text field
//                 Positioned(
//                   top: screenHeight * .47,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: TextField(
//                     controller: controller.phoneController,
//                     decoration: InputDecoration(
//                       suffixIcon: Icon(
//                         Icons.phone_outlined,
//                         color: Color(0xFF030047),
//                       ),
//                       labelText: 'Phone Number',
//                       labelStyle: TextStyle(
//                         color: Color.fromARGB(255, 193, 204, 240),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Colors.transparent,
//                           width: 2,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Color(0xFF030047),
//                           width: 2,
//                         ),
//                       ),
//                       filled: true,
//                       fillColor: Color(0xFFE1E5F2),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 15,
//                       ),
//                     ),
//                     style: TextStyle(fontSize: 18),
//                     keyboardType: TextInputType.phone,
//                   ),
//                 ),

//                 //respositioned bottom image
//                 Positioned(
//                   bottom: -screenHeight * .17,
//                   left: screenHeight * -.001,
//                   right: 0,
//                   child: SizedBox(
//                     height: MediaQuery.of(context).size.height * 0.6,
//                     width: MediaQuery.of(context).size.width,
//                     child: Image.asset(
//                       'assets/images/bottom.png',
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 // Password text field
//                 Positioned(
//                   top: screenHeight * .55,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Obx(
//                     () => TextField(
//                       controller: controller.passwordController,
//                       obscureText: !controller.isPasswordVisible.value,
//                       decoration: InputDecoration(
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             controller.isPasswordVisible.value
//                                 ? Icons.visibility_outlined
//                                 : Icons.visibility_off_outlined,
//                             color: Color(0xFF030047),
//                           ),
//                           onPressed: controller.togglePasswordVisibility,
//                         ),
//                         labelText: 'Password',
//                         labelStyle: TextStyle(
//                           color: Color.fromARGB(255, 193, 204, 240),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Colors.transparent,
//                             width: 2,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Color(0xFF030047),
//                             width: 2,
//                           ),
//                         ),
//                         filled: true,
//                         fillColor: Color(0xFFE1E5F2),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 15,
//                         ),
//                       ),
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ),
//                 ),

//                 // Confirm Password text field
//                 Positioned(
//                   top: screenHeight * .63,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Obx(
//                     () => TextField(
//                       controller: controller.confirmPasswordController,
//                       obscureText: !controller.isConfirmPasswordVisible.value,
//                       decoration: InputDecoration(
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             controller.isConfirmPasswordVisible.value
//                                 ? Icons.visibility_outlined
//                                 : Icons.visibility_off_outlined,
//                             color: Color(0xFF030047),
//                           ),
//                           onPressed: controller.toggleConfirmPasswordVisibility,
//                         ),
//                         labelText: 'Confirm Password',
//                         labelStyle: TextStyle(
//                           color: Color.fromARGB(255, 193, 204, 240),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Colors.transparent,
//                             width: 2,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Color(0xFF030047),
//                             width: 2,
//                           ),
//                         ),
//                         filled: true,
//                         fillColor: Color(0xFFE1E5F2),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 15,
//                         ),
//                       ),
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ),
//                 ),

//                 // Sign up button
//                 Positioned(
//                   bottom: screenHeight * .13,
//                   left: 0,
//                   right: 0,
//                   child: Center(
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.8,
//                       height: 60,
//                       child: ElevatedButton(
//                         onPressed: controller.signUp,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xFFFFCC3E),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         child: Text(
//                           "SIGN UP",
//                           style: TextStyle(
//                             color: Color(0xFF030047),
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Login link
//                 Positioned(
//                   bottom: screenHeight * .06,
//                   left: 0,
//                   right: 0,
//                   child: Center(
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.9,
//                       height: 60,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Already have an account? ",
//                             style: TextStyle(color: Colors.white, fontSize: 20),
//                           ),
//                           TextButton(
//                             onPressed: () => Get.offAll(() => Signin()),
//                             child: Text(
//                               "Login",
//                               style: TextStyle(
//                                 color: Color(0xFFFFCC3E),
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
