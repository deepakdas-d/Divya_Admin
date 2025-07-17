// import 'package:admin/Auth/forgot_password.dart';
import 'package:admin/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SigninController extends GetxController {
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isInputEmpty = true.obs;
  var isInputValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailOrPhoneController.addListener(() {
      final input = emailOrPhoneController.text.trim();
      isInputEmpty.value = input.isEmpty;
      isInputValid.value = _isValidEmail(input) || _isValidPhone(input);
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

  Future<String?> signIn(String input, String password) async {
    try {
      String? email;
      String? uid;

      if (_isValidEmail(input)) {
        email = input;
      } else if (_isValidPhone(input)) {
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('admins')
            .where('phone', isEqualTo: input)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          email = query.docs.first.get('email');
          uid = query.docs.first.get('uid');
        } else {
          return 'No account found for this phone number.';
        }
      } else {
        return 'Invalid email or phone number format.';
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password);

      uid ??= userCredential.user!.uid;

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (adminDoc.exists && adminDoc.get('role') == 'admin') {
        return null;
      } else {
        await FirebaseAuth.instance.signOut();
        return 'Access denied. You are not an admin.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  Future<void> handleSignIn() async {
    final input = emailOrPhoneController.text.trim();
    final password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in both fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final result = await signIn(input, password);
    Get.back(); // Remove loading

    if (result == null) {
      Get.offAll(() => Dashboard());
      Get.snackbar(
        "Success",
        "Signed in successfully",
        backgroundColor: const Color(0xFFFFCC3E),
        colorText: const Color(0xFF030047),
      );
    } else {
      Get.snackbar(
        "Login Failed",
        "Please Enter valid email, phone number, or password",
      );
    }
  }

  // Future<void> navigateToForgotPassword() async {
  //   final input = emailOrPhoneController.text.trim();
  //   String? email;

  //   if (_isValidEmail(input)) {
  //     email = input;
  //   } else if (_isValidPhone(input)) {
  //     QuerySnapshot query = await FirebaseFirestore.instance
  //         .collection('admins')
  //         .where('phone', isEqualTo: input)
  //         .limit(1)
  //         .get();
  //     if (query.docs.isNotEmpty) {
  //       email = query.docs.first.get('email');
  //     } else {
  //       Get.snackbar('Error', 'No account found for this phone number');
  //       return;
  //     }
  //   } else {
  //     Get.snackbar('Error', 'Invalid email or phone number format');
  //     return;
  //   }

  //   Get.to(() => ForgotPasswordPage(email: email!));
  // }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
