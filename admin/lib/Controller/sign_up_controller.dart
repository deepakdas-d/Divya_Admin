import 'package:admin/Auth/sigin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar('Error', 'Passwords do not match');
      return;
    }

    if (await isPhoneRegisteredAnywhere(phone)) {
      Get.snackbar('Error', 'Phone number is already registered.');
      return;
    }

    if (await isEmailRegisteredAnywhere(email)) {
      Get.snackbar('Error', 'Email is already registered.');
      return;
    }

    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      await firestore.collection('admins').doc(user!.uid).set({
        'email': email,
        'phone': phone,
        'uid': user.uid,
        'role': 'admin',
        'createdAt': Timestamp.now(),
      });

      Get.snackbar('Success', 'Admin signup successful!');
      Get.offAll(() => Signin());
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      Get.snackbar('Error', message);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: $e');
    }
  }

  Future<bool> isPhoneRegisteredAnywhere(String phone) async {
    final collections = ['admins', 'Sales', 'Makers'];
    for (final collection in collections) {
      final query = await firestore
          .collection(collection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return true;
    }
    return false;
  }

  Future<bool> isEmailRegisteredAnywhere(String email) async {
    final collections = ['admins', 'Sales', 'Makers'];
    for (final collection in collections) {
      final query = await firestore
          .collection(collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return true;
    }
    return false;
  }

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
