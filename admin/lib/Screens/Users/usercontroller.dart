import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddUserController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final placeController = TextEditingController();

  // Focus nodes
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final ageFocus = FocusNode();
  final phoneFocus = FocusNode();
  final placeFocus = FocusNode();
  final addressFocus = FocusNode();

  // Reactive variables
  var selectedRole = 'SALESMEN'.obs;
  var selectedGender = RxString('');
  var selectedImage = Rx<File?>(null);
  var isLoading = false.obs;
  var passwordVisible = false.obs;

  final ImagePicker picker = ImagePicker();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  @override
  void onClose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    placeController.dispose();

    // Dispose focus nodes
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    ageFocus.dispose();
    phoneFocus.dispose();
    placeFocus.dispose();
    addressFocus.dispose();

    // Clear image file reference
    selectedImage.value = null;

    super.onClose();
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone validation (adjust pattern as needed)
  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,15}$').hasMatch(phone);
  }

  // Password validation
  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password);
  }

  // Validate form with custom rules
  bool _validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      _showErrorDialog('Please enter a valid email address');
      return false;
    }

    if (!_isValidPhone(phoneController.text.trim())) {
      _showErrorDialog('Please enter a valid phone number');
      return false;
    }

    if (!_isValidPassword(passwordController.text.trim())) {
      _showErrorDialog(
        'Password must be at least 8 characters with uppercase, lowercase, and number',
      );
      return false;
    }

    if (selectedGender.value.isEmpty) {
      _showErrorDialog('Please select a gender');
      return false;
    }

    return true;
  }

  Future<void> pickImage() async {
    try {
      print('Opening image picker');
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('Image selected: ${image.path}');
        selectedImage.value = File(image.path);
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (selectedImage.value == null) return null;

    try {
      final ref = storage.ref().child('salesperson_images/$userId.jpg');
      final uploadTask = ref.putFile(selectedImage.value!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Check for duplicate phone using transaction for better consistency
  Future<bool> _isPhoneDuplicate(String phone) async {
    try {
      final result = await firestore.runTransaction((transaction) async {
        final phoneQuery = await firestore
            .collection('users')
            .where('phone', isEqualTo: phone.trim())
            .limit(1)
            .get();
        return phoneQuery.docs.isNotEmpty;
      });
      return result;
    } catch (e) {
      print('Error checking phone duplicate: $e');
      return false; // Assume no duplicate on error to allow continuation
    }
  }

  Future<void> createUser() async {
    if (isLoading.value) return; // Prevent multiple calls

    if (!_validateForm()) {
      return;
    }

    // Handle missing image
    if (selectedImage.value == null) {
      final bool proceed = await _showImageConfirmationDialog();
      if (!proceed) return;
    }

    isLoading.value = true;

    try {
      // Check for duplicate phone
      final phoneExists = await _isPhoneDuplicate(phoneController.text.trim());
      if (phoneExists) {
        _showErrorDialog('Phone number is already in use');
        return;
      }

      // TODO: Replace with server-side user creation
      // This should be done via Cloud Functions or your backend API
      final UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final User? user = userCredential.user;
      if (user != null) {
        String? imageUrl;

        // Upload image if selected
        if (selectedImage.value != null) {
          try {
            imageUrl = await _uploadImage(user.uid);
          } catch (e) {
            print('Image upload failed: $e');
            // Continue without image instead of failing completely
            _showErrorDialog('User created but image upload failed');
          }
        }

        // Save user data to Firestore
        await firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'age': int.tryParse(ageController.text.trim()) ?? 0,
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'place': placeController.text.trim(),
          'gender': selectedGender.value,
          'role': selectedRole.value.toLowerCase(),
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': auth.currentUser?.uid,
          'isActive': true,
          'latitude': null,
          'longitude': null,
        });

        // Update display name
        await user.updateDisplayName(nameController.text.trim());

        _showSuccessDialog('User created successfully!');
        clearForm(); // Clear form after success
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      print('Error creating user: $e');
      _showErrorDialog('Error creating user: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with mix of letters and numbers';
      case 'invalid-email':
        return 'Invalid email address format';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication error: $errorCode';
    }
  }

  Future<bool> _showImageConfirmationDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('No Image Selected'),
            content: const Text(
              'No profile image is selected. Do you want to proceed without an image?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('Success', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Pop back to previous screen
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[50],
              foregroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('Error', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    ageController.clear();
    phoneController.clear();
    addressController.clear();
    passwordController.clear();
    placeController.clear();
    selectedImage.value = null;
    selectedRole.value = 'SALESMEN';
    selectedGender.value = '';
    passwordVisible.value = false;
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'dart:io';

// class AddUserController extends GetxController {
//   final formKey = GlobalKey<FormState>();
//   final nameController = TextEditingController();
//   final emailController = TextEditingController();
//   final ageController = TextEditingController();
//   final phoneController = TextEditingController();
//   final addressController = TextEditingController();
//   final passwordController = TextEditingController();
//   final placeController = TextEditingController();

//   // Focus nodes
//   final nameFocus = FocusNode();
//   final emailFocus = FocusNode();
//   final passwordFocus = FocusNode();
//   final ageFocus = FocusNode();
//   final phoneFocus = FocusNode();
//   final placeFocus = FocusNode();
//   final addressFocus = FocusNode();

//   // Reactive variables
//   var selectedRole = 'SALESMEN'.obs;
//   var selectedGender = RxString('');
//   var selectedImage = Rx<File?>(null);
//   var isLoading = false.obs;
//   var passwordVisible = false.obs;
  
//   // Location variables
//   var currentLatitude = RxnDouble();
//   var currentLongitude = RxnDouble();
//   var currentAddress = RxString('');
//   var isLocationLoading = false.obs;

//   final ImagePicker picker = ImagePicker();
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final FirebaseStorage storage = FirebaseStorage.instance;

//   @override
//   void onInit() {
//     super.onInit();
//     // Automatically get location when controller initializes
//     getCurrentLocation();
//   }

//   @override
//   void onClose() {
//     // Dispose controllers
//     nameController.dispose();
//     emailController.dispose();
//     ageController.dispose();
//     phoneController.dispose();
//     addressController.dispose();
//     passwordController.dispose();
//     placeController.dispose();

//     // Dispose focus nodes
//     nameFocus.dispose();
//     emailFocus.dispose();
//     passwordFocus.dispose();
//     ageFocus.dispose();
//     phoneFocus.dispose();
//     placeFocus.dispose();
//     addressFocus.dispose();

//     // Clear image file reference
//     selectedImage.value = null;

//     super.onClose();
//   }

//   // Location Permission and Service Check
//   Future<bool> _handleLocationPermission() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Check if location services are enabled
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showErrorDialog('Location services are disabled. Please enable location services.');
//       return false;
//     }

//     // Check location permissions
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showErrorDialog('Location permissions are denied. Please grant location permission.');
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showErrorDialog('Location permissions are permanently denied. Please enable from settings.');
//       return false;
//     }

//     return true;
//   }

//   // Get Current Location
//   Future<void> getCurrentLocation() async {
//     if (isLocationLoading.value) return;
    
//     isLocationLoading.value = true;
    
//     try {
//       // Check permissions first
//       final hasPermission = await _handleLocationPermission();
//       if (!hasPermission) {
//         isLocationLoading.value = false;
//         return;
//       }

//       // Get current position
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );

//       currentLatitude.value = position.latitude;
//       currentLongitude.value = position.longitude;

//       // Get address from coordinates
//       await _getAddressFromCoordinates(position.latitude, position.longitude);

//       print('Location obtained: ${position.latitude}, ${position.longitude}');
      
//     } catch (e) {
//       print('Error getting location: $e');
//       _showErrorDialog('Error getting location: ${e.toString()}');
//     } finally {
//       isLocationLoading.value = false;
//     }
//   }

//   // Get Address from Coordinates
//   Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         currentAddress.value = [
//           place.street,
//           place.subLocality,
//           place.locality,
//           place.administrativeArea,
//           place.country
//         ].where((element) => element != null && element.isNotEmpty).join(', ');
        
//         // Auto-fill place field if empty
//         if (placeController.text.isEmpty && place.locality != null) {
//           placeController.text = place.locality!;
//         }
        
//         // Auto-fill address field if empty
//         if (addressController.text.isEmpty) {
//           addressController.text = currentAddress.value;
//         }
//       }
//     } catch (e) {
//       print('Error getting address: $e');
//       currentAddress.value = 'Address not available';
//     }
//   }

//   // Manual Location Refresh
//   Future<void> refreshLocation() async {
//     await getCurrentLocation();
//     Get.snackbar(
//       'Location Updated',
//       'Current location has been refreshed',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.green[100],
//       colorText: Colors.green[800],
//       icon: const Icon(Icons.location_on, color: Colors.green),
//     );
//   }

//   // Email validation
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }

//   // Phone validation (adjust pattern as needed)
//   bool _isValidPhone(String phone) {
//     return RegExp(r'^\+?[\d\s\-\(\)]{10,15}$').hasMatch(phone);
//   }

//   // Password validation
//   bool _isValidPassword(String password) {
//     return password.length >= 8 &&
//         RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password);
//   }

//   // Validate form with custom rules
//   bool _validateForm() {
//     if (!formKey.currentState!.validate()) {
//       return false;
//     }

//     if (!_isValidEmail(emailController.text.trim())) {
//       _showErrorDialog('Please enter a valid email address');
//       return false;
//     }

//     if (!_isValidPhone(phoneController.text.trim())) {
//       _showErrorDialog('Please enter a valid phone number');
//       return false;
//     }

//     if (!_isValidPassword(passwordController.text.trim())) {
//       _showErrorDialog(
//         'Password must be at least 8 characters with uppercase, lowercase, and number',
//       );
//       return false;
//     }

//     if (selectedGender.value.isEmpty) {
//       _showErrorDialog('Please select a gender');
//       return false;
//     }

//     // Check if location is available
//     if (currentLatitude.value == null || currentLongitude.value == null) {
//       _showErrorDialog('Location is required. Please allow location access and try again.');
//       return false;
//     }

//     return true;
//   }

//   Future<void> pickImage() async {
//     try {
//       print('Opening image picker');
//       final XFile? image = await picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         print('Image selected: ${image.path}');
//         selectedImage.value = File(image.path);
//       } else {
//         print('No image selected');
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//       _showErrorDialog('Error picking image: $e');
//     }
//   }

//   Future<String?> _uploadImage(String userId) async {
//     if (selectedImage.value == null) return null;

//     try {
//       final ref = storage.ref().child('salesperson_images/$userId.jpg');
//       final uploadTask = ref.putFile(selectedImage.value!);
//       final snapshot = await uploadTask;
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//       print('Image uploaded successfully: $downloadUrl');
//       return downloadUrl;
//     } catch (e) {
//       print('Error uploading image: $e');
//       throw Exception('Failed to upload image: $e');
//     }
//   }

//   // Check for duplicate phone using transaction for better consistency
//   Future<bool> _isPhoneDuplicate(String phone) async {
//     try {
//       final result = await firestore.runTransaction((transaction) async {
//         final phoneQuery = await firestore
//             .collection('users')
//             .where('phone', isEqualTo: phone.trim())
//             .limit(1)
//             .get();
//         return phoneQuery.docs.isNotEmpty;
//       });
//       return result;
//     } catch (e) {
//       print('Error checking phone duplicate: $e');
//       return false; // Assume no duplicate on error to allow continuation
//     }
//   }

//   Future<void> createUser() async {
//     if (isLoading.value) return; // Prevent multiple calls

//     if (!_validateForm()) {
//       return;
//     }

//     // Handle missing image
//     if (selectedImage.value == null) {
//       final bool proceed = await _showImageConfirmationDialog();
//       if (!proceed) return;
//     }

//     isLoading.value = true;

//     try {
//       // Check for duplicate phone
//       final phoneExists = await _isPhoneDuplicate(phoneController.text.trim());
//       if (phoneExists) {
//         _showErrorDialog('Phone number is already in use');
//         return;
//       }

//       // TODO: Replace with server-side user creation
//       // This should be done via Cloud Functions or your backend API
//       final UserCredential userCredential = await auth
//           .createUserWithEmailAndPassword(
//             email: emailController.text.trim(),
//             password: passwordController.text.trim(),
//           );

//       final User? user = userCredential.user;
//       if (user != null) {
//         String? imageUrl;

//         // Upload image if selected
//         if (selectedImage.value != null) {
//           try {
//             imageUrl = await _uploadImage(user.uid);
//           } catch (e) {
//             print('Image upload failed: $e');
//             // Continue without image instead of failing completely
//             _showErrorDialog('User created but image upload failed');
//           }
//         }

//         // Save user data to Firestore with location
//         await firestore.collection('users').doc(user.uid).set({
//           'uid': user.uid,
//           'name': nameController.text.trim(),
//           'email': emailController.text.trim(),
//           'age': int.tryParse(ageController.text.trim()) ?? 0,
//           'phone': phoneController.text.trim(),
//           'address': addressController.text.trim(),
//           'place': placeController.text.trim(),
//           'gender': selectedGender.value,
//           'role': selectedRole.value.toLowerCase(),
//           'imageUrl': imageUrl,
//           'createdAt': FieldValue.serverTimestamp(),
//           'createdBy': auth.currentUser?.uid,
//           'isActive': true,
//           'latitude': currentLatitude.value,
//           'longitude': currentLongitude.value,
//           'locationAddress': currentAddress.value,
//           'locationUpdatedAt': FieldValue.serverTimestamp(),
//         });

//         // Update display name
//         await user.updateDisplayName(nameController.text.trim());

//         _showSuccessDialog('User created successfully with location data!');
//         clearForm(); // Clear form after success
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = _getAuthErrorMessage(e.code);
//       _showErrorDialog(errorMessage);
//     } catch (e) {
//       print('Error creating user: $e');
//       _showErrorDialog('Error creating user: ${e.toString()}');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   String _getAuthErrorMessage(String errorCode) {
//     switch (errorCode) {
//       case 'email-already-in-use':
//         return 'This email is already registered';
//       case 'weak-password':
//         return 'Password is too weak. Use at least 8 characters with mix of letters and numbers';
//       case 'invalid-email':
//         return 'Invalid email address format';
//       case 'operation-not-allowed':
//         return 'Email/password accounts are not enabled';
//       case 'network-request-failed':
//         return 'Network error. Please check your connection';
//       default:
//         return 'Authentication error: $errorCode';
//     }
//   }

//   Future<bool> _showImageConfirmationDialog() async {
//     return await Get.dialog<bool>(
//           AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text('No Image Selected'),
//             content: const Text(
//               'No profile image is selected. Do you want to proceed without an image?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Get.back(result: false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Get.back(result: true),
//                 child: const Text('Proceed'),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   void _showSuccessDialog(String message) {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.green[600], size: 28),
//             const SizedBox(width: 12),
//             const Text('Success', style: TextStyle(color: Colors.green)),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Get.back(); // Close dialog
//               Get.back(); // Pop back to previous screen
//             },
//             style: TextButton.styleFrom(
//               backgroundColor: Colors.green[50],
//               foregroundColor: Colors.green[700],
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.error_outline, color: Colors.red[600], size: 28),
//             const SizedBox(width: 12),
//             const Text('Error', style: TextStyle(color: Colors.red)),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             style: TextButton.styleFrom(
//               backgroundColor: Colors.red[50],
//               foregroundColor: Colors.red[700],
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void clearForm() {
//     nameController.clear();
//     emailController.clear();
//     ageController.clear();
//     phoneController.clear();
//     addressController.clear();
//     passwordController.clear();
//     placeController.clear();
//     selectedImage.value = null;
//     selectedRole.value = 'SALESMEN';
//     selectedGender.value = '';
//     passwordVisible.value = false;
//     // Clear location data
//     currentLatitude.value = null;
//     currentLongitude.value = null;
//     currentAddress.value = '';
//   }
// }