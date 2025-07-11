import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for current user ID
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// GetX Controller to manage the state of the ComplaintDetailPage
class ComplaintDetailController extends GetxController {
  // Firestore instance for database operations
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // Firebase Auth instance to get current user
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables for state management
  final RxString selectedStatus = 'pending'.obs;
  final RxBool isLoading = false.obs;
  final TextEditingController responseController = TextEditingController();

  // Storing complaint data passed to the page
  late Map<String, dynamic> complaintData;

  // Initialize controller with complaint data
  void initializeData(Map<String, dynamic> data) {
    complaintData = data;
    selectedStatus.value = complaintData['status'] ?? 'pending';
  }

  // Function to submit response to Firestore
  Future<void> submitResponse() async {
    if (responseController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a response message',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final batch = firestore.batch();
      final String? currentUserId = _auth.currentUser?.uid;

      if (currentUserId == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // Fetch the complaint document to get the userId
      final complaintDoc = await firestore
          .collection('complaints')
          .doc(complaintData['docId'])
          .get();

      final String complaintUserId = complaintDoc['userId'];

      // Use a consistent document ID based on complaintId + userId (or just complaintId)
      final String docId = '${complaintData['complaintId']}_$currentUserId';
      final responseRef = firestore
          .collection('complaint_responses')
          .doc(docId);

      batch.set(responseRef, {
        'complaintId': complaintData['complaintId'],
        'response': responseController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'respondedBy': currentUserId,
        'userId': complaintUserId,
        'statusChanged': true,
        'newStatus': selectedStatus.value,
        'complaint': complaintData['complaint'],
      }, SetOptions(merge: true)); // <-- Merge with existing doc if exists

      // Update the main complaint doc
      if (complaintData['docId'] != null) {
        final complaintRef = firestore
            .collection('complaints')
            .doc(complaintData['docId']);
        batch.update(complaintRef, {
          'status': selectedStatus.value,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      Get.snackbar(
        'Success',
        'Response updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      responseController.clear();
      complaintData['status'] = selectedStatus.value;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error updating response: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Clean up controller resources
  @override
  void onClose() {
    responseController.dispose();
    super.onClose();
  }
}
