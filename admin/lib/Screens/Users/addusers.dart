// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class AddUserPage extends StatefulWidget {
//   const AddUserPage({super.key});

//   @override
//   State<AddUserPage> createState() => _AddUserPageState();
// }

// class _AddUserPageState extends State<AddUserPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _ageController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _placeController = TextEditingController();

//   // Focus nodes for automatic navigation
//   final _nameFocus = FocusNode();
//   final _emailFocus = FocusNode();
//   final _passwordFocus = FocusNode();
//   final _ageFocus = FocusNode();
//   final _phoneFocus = FocusNode();
//   final _placeFocus = FocusNode();
//   final _addressFocus = FocusNode();

//   String _selectedRole = 'SALESMEN';
//   String? _selectedGender;
//   File? _selectedImage;
//   bool _isLoading = false;
//   bool _passwordVisible = false;

//   final ImagePicker _picker = ImagePicker();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _ageController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _passwordController.dispose();
//     _placeController.dispose();

//     _nameFocus.dispose();
//     _emailFocus.dispose();
//     _passwordFocus.dispose();
//     _ageFocus.dispose();
//     _phoneFocus.dispose();
//     _placeFocus.dispose();
//     _addressFocus.dispose();

//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     try {
//       print('Opening image picker'); // Debug print
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         print('Image selected: ${image.path}'); // Debug print
//         setState(() {
//           _selectedImage = File(image.path);
//         });
//       } else {
//         print('No image selected'); // Debug print
//       }
//     } catch (e) {
//       print('Error picking image: $e'); // Debug print
//       _showErrorDialog('Error picking image: $e');
//     }
//   }

//   Future<String?> _uploadImage(String userId) async {
//     if (_selectedImage == null) return null;

//     try {
//       final ref = _storage.ref().child('salesperson_images/$userId.jpg');
//       final uploadTask = ref.putFile(_selectedImage!);
//       final snapshot = await uploadTask;
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }

//   Future<void> _createUser() async {
//     if (!_formKey.currentState!.validate()) {
//       print('Form validation failed'); // Debug print
//       setState(() => _isLoading = false);
//       return;
//     }

//     // Optional image validation
//     if (_selectedImage == null) {
//       final bool proceed =
//           await showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               title: const Text('No Image Selected'),
//               content: const Text(
//                 'No profile image is selected. Do you want to proceed without an image?',
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text('Cancel'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   child: const Text('Proceed'),
//                 ),
//               ],
//             ),
//           ) ??
//           false;

//       if (!proceed) {
//         setState(() => _isLoading = false);
//         return;
//       }
//     }

//     setState(() => _isLoading = true);

//     try {
//       // Check if phone number already exists
//       final phoneQuery = await _firestore
//           .collection('users')
//           .where('phone', isEqualTo: _phoneController.text.trim())
//           .get();

//       if (phoneQuery.docs.isNotEmpty) {
//         _showErrorDialog('Phone number is already in use');
//         setState(() => _isLoading = false);
//         return;
//       }

//       // Create user with email and password
//       final UserCredential userCredential = await _auth
//           .createUserWithEmailAndPassword(
//             email: _emailController.text.trim(),
//             password: _passwordController.text.trim(),
//           );

//       final User? user = userCredential.user;
//       if (user != null) {
//         String? imageUrl;
//         if (_selectedImage != null) {
//           imageUrl = await _uploadImage(user.uid);
//         }

//         await _firestore.collection('users').doc(user.uid).set({
//           'uid': user.uid,
//           'name': _nameController.text.trim(),
//           'email': _emailController.text.trim(),
//           'age': int.tryParse(_ageController.text.trim()) ?? 0,
//           'phone': _phoneController.text.trim(),
//           'address': _addressController.text.trim(),
//           'place': _placeController.text.trim(),
//           'gender': _selectedGender,
//           'role': _selectedRole.toLowerCase(),
//           'imageUrl': imageUrl,
//           'createdAt': FieldValue.serverTimestamp(),
//           'createdBy': _auth.currentUser?.uid,
//           'isActive': true,
//           'latitude': null,
//           'longitude': null,
//         });

//         await user.updateDisplayName(_nameController.text.trim());

//         _showSuccessDialog('User created successfully!');
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'An error occurred';
//       switch (e.code) {
//         case 'email-already-in-use':
//           errorMessage = 'This email is already registered';
//           break;
//         case 'weak-password':
//           errorMessage = 'Password is too weak';
//           break;
//         case 'invalid-email':
//           errorMessage = 'Invalid email address';
//           break;
//         default:
//           errorMessage = e.message ?? 'Authentication error';
//       }
//       _showErrorDialog(errorMessage);
//     } catch (e) {
//       _showErrorDialog('Error creating user: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showSuccessDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
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
//               Navigator.of(context).pop();
//               Navigator.of(context).pop(); // Pop back to previous screen
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
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
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
//             onPressed: () => Navigator.of(context).pop(),
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

//   void _clearForm() {
//     _nameController.clear();
//     _emailController.clear();
//     _ageController.clear();
//     _phoneController.clear();
//     _addressController.clear();
//     _passwordController.clear();
//     _placeController.clear();
//     setState(() {
//       _selectedImage = null;
//       _selectedRole = 'SALESMEN';
//       _selectedGender = null;
//       _passwordVisible = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.grey[800],
//         title: const Text(
//           'Create New User',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         elevation: 0.5,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         child: Container(
//           margin: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Profile Image Section
//                 Center(
//                   child: Column(
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           print('Profile image tapped'); // Debug print
//                           _pickImage();
//                         },
//                         child: Container(
//                           width: 120,
//                           height: 120,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             borderRadius: BorderRadius.circular(60),
//                             border: Border.all(
//                               color: Colors.grey[300]!,
//                               width: 2,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color.fromARGB(255, 168, 203, 231),
//                                 spreadRadius: 1,
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: _selectedImage != null
//                               ? ClipRRect(
//                                   borderRadius: BorderRadius.circular(58),
//                                   child: Image.file(
//                                     _selectedImage!,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 )
//                               : Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.add_a_photo_outlined,
//                                       size: 32,
//                                       color: Colors.grey[400],
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       'Add Photo',
//                                       style: TextStyle(
//                                         color: Colors.grey[500],
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         _selectedImage != null
//                             ? 'Tap to change image'
//                             : 'Tap to select profile image',
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // Form Fields
//                 _buildTextField(
//                   controller: _nameController,
//                   focusNode: _nameFocus,
//                   nextFocus: _emailFocus,
//                   label: 'Full Name',
//                   hint: 'Enter full name',
//                   icon: Icons.person_outline,
//                   textInputAction: TextInputAction.next,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty)
//                       return 'Name is required';
//                     if (value.trim().length < 2)
//                       return 'Name must be at least 2 characters';
//                     return null;
//                   },
//                 ),

//                 _buildTextField(
//                   controller: _emailController,
//                   focusNode: _emailFocus,
//                   nextFocus: _passwordFocus,
//                   label: 'Email Address',
//                   hint: 'Enter email address',
//                   icon: Icons.email_outlined,
//                   keyboardType: TextInputType.emailAddress,
//                   textInputAction: TextInputAction.next,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty)
//                       return 'Email is required';
//                     if (!RegExp(
//                       r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                     ).hasMatch(value))
//                       return 'Enter a valid email address';
//                     return null;
//                   },
//                 ),

//                 _buildTextField(
//                   controller: _passwordController,
//                   focusNode: _passwordFocus,
//                   nextFocus: _ageFocus,
//                   label: 'Password',
//                   hint: 'Enter password',
//                   icon: Icons.lock_outline,
//                   obscureText: !_passwordVisible,
//                   textInputAction: TextInputAction.next,
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _passwordVisible
//                           ? Icons.visibility_off
//                           : Icons.visibility,
//                       color: Colors.grey[600],
//                     ),
//                     onPressed: () =>
//                         setState(() => _passwordVisible = !_passwordVisible),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty)
//                       return 'Password is required';
//                     if (value.length < 6)
//                       return 'Password must be at least 6 characters';
//                     return null;
//                   },
//                 ),

//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildTextField(
//                         controller: _ageController,
//                         focusNode: _ageFocus,
//                         nextFocus: _phoneFocus,
//                         label: 'Age',
//                         hint: 'Enter age',
//                         icon: Icons.cake_outlined,
//                         keyboardType: TextInputType.number,
//                         textInputAction: TextInputAction.next,
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty)
//                             return 'Age is required';
//                           final age = int.tryParse(value);
//                           if (age == null || age < 18 || age > 65)
//                             return 'Age must be 18-65';
//                           return null;
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       flex: 2,
//                       child: _buildTextField(
//                         controller: _phoneController,
//                         focusNode: _phoneFocus,
//                         nextFocus: _placeFocus,
//                         label: 'Phone Number',
//                         hint: 'Enter phone number',
//                         icon: Icons.phone_outlined,
//                         keyboardType: TextInputType.phone,
//                         textInputAction: TextInputAction.next,
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty)
//                             return 'Phone number is required';
//                           if (value.length < 10)
//                             return 'Enter valid phone number';
//                           return null;
//                         },
//                       ),
//                     ),
//                   ],
//                 ),

//                 _buildGenderField(),

//                 _buildTextField(
//                   controller: _placeController,
//                   focusNode: _placeFocus,
//                   nextFocus: _addressFocus,
//                   label: 'Place',
//                   hint: 'Enter city/town',
//                   icon: Icons.place_outlined,
//                   textInputAction: TextInputAction.next,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty)
//                       return 'Place is required';
//                     if (value.trim().length < 2)
//                       return 'Place must be at least 2 characters';
//                     return null;
//                   },
//                 ),

//                 _buildTextField(
//                   controller: _addressController,
//                   focusNode: _addressFocus,
//                   label: 'Address',
//                   hint: 'Enter complete address',
//                   icon: Icons.location_on_outlined,
//                   maxLines: 3,
//                   textInputAction: TextInputAction.done,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty)
//                       return 'Address is required';
//                     return null;
//                   },
//                 ),

//                 _buildRoleField(),

//                 const SizedBox(height: 32),

//                 // Create Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _createUser,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[600],
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 2,
//                       shadowColor: Colors.blue.withOpacity(0.3),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 Colors.white,
//                               ),
//                             ),
//                           )
//                         : Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Icon(Icons.person_add, size: 20),
//                               const SizedBox(width: 8),
//                               const Text(
//                                 'CREATE USER',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   letterSpacing: 0.5,
//                                 ),
//                               ),
//                             ],
//                           ),
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Clear Form Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 48,
//                   child: OutlinedButton(
//                     onPressed: _isLoading ? null : _clearForm,
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.grey[600],
//                       side: BorderSide(color: Colors.grey[300]!),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.clear, size: 18, color: Colors.black),
//                         const SizedBox(width: 8),
//                         Text(
//                           'CLEAR FORM',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
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

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     FocusNode? focusNode,
//     FocusNode? nextFocus,
//     TextInputType? keyboardType,
//     bool obscureText = false,
//     int maxLines = 1,
//     TextInputAction? textInputAction,
//     Widget? suffixIcon,
//     String? Function(String?)? validator,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color.fromARGB(255, 15, 80, 133),
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: controller,
//             focusNode: focusNode,
//             keyboardType: keyboardType,
//             obscureText: obscureText,
//             maxLines: maxLines,
//             validator: validator,
//             textInputAction: textInputAction,
//             autovalidateMode:
//                 AutovalidateMode.onUserInteraction, // Show errors on input
//             onFieldSubmitted: (_) {
//               if (nextFocus != null)
//                 FocusScope.of(context).requestFocus(nextFocus);
//             },
//             style: const TextStyle(fontSize: 16, color: Colors.black87),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
//               prefixIcon: Icon(icon, color: Colors.black, size: 22),
//               suffixIcon: suffixIcon,
//               filled: true,
//               fillColor: Colors.grey[50],
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
//               ),
//               errorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(color: Colors.red, width: 1),
//               ),
//               focusedErrorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(color: Colors.red, width: 2),
//               ),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 16,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGenderField() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Gender',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color.fromARGB(255, 15, 80, 133),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButtonFormField<String>(
//                 value: _selectedGender,
//                 isExpanded: true,
//                 icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
//                 style: const TextStyle(fontSize: 16, color: Colors.black87),
//                 decoration: const InputDecoration(border: InputBorder.none),
//                 validator: (value) =>
//                     value == null ? 'Gender is required' : null,
//                 autovalidateMode: AutovalidateMode
//                     .onUserInteraction, // Show errors on interaction
//                 items: const [
//                   DropdownMenuItem(value: 'Male', child: Text('Male')),
//                   DropdownMenuItem(value: 'Female', child: Text('Female')),
//                   DropdownMenuItem(value: 'Other', child: Text('Other')),
//                 ],
//                 onChanged: (value) {
//                   if (value != null) setState(() => _selectedGender = value);
//                 },
//                 hint: Text(
//                   'Select gender',
//                   style: TextStyle(color: Colors.grey[400]),
//                 ),
//               ),
//             ),
//           ),
//           if (_selectedGender != null) ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.purple[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.purple[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.person, color: Colors.purple[600], size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Selected: $_selectedGender',
//                     style: TextStyle(
//                       color: Colors.purple[700],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildRoleField() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Role',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color.fromARGB(255, 15, 80, 133),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _selectedRole,
//                 isExpanded: true,
//                 icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
//                 style: const TextStyle(fontSize: 16, color: Colors.black87),
//                 items: [
//                   DropdownMenuItem(
//                     value: 'SALESMEN',
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.person_pin,
//                           color: Colors.blue[600],
//                           size: 20,
//                         ),
//                         const SizedBox(width: 12),
//                         const Text('Salesperson'),
//                       ],
//                     ),
//                   ),
//                   DropdownMenuItem(
//                     value: 'MAKER',
//                     child: Row(
//                       children: [
//                         Icon(Icons.build, color: Colors.green[600], size: 20),
//                         const SizedBox(width: 12),
//                         const Text('Maker'),
//                       ],
//                     ),
//                   ),
//                 ],
//                 onChanged: (value) {
//                   if (value != null) setState(() => _selectedRole = value);
//                 },
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: _selectedRole == 'SALESMEN'
//                   ? Colors.blue[50]
//                   : Colors.green[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: _selectedRole == 'SALESMEN'
//                     ? Colors.blue[200]!
//                     : Colors.green[200]!,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   _selectedRole == 'SALESMEN' ? Icons.person_pin : Icons.build,
//                   color: _selectedRole == 'SALESMEN'
//                       ? Colors.blue[600]
//                       : Colors.green[600],
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Selected: ${_selectedRole == 'SALESMEN' ? 'Salesperson' : 'Maker'}',
//                   style: TextStyle(
//                     color: _selectedRole == 'SALESMEN'
//                         ? Colors.blue[700]
//                         : Colors.green[700],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:admin/Controller/usercontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddUserPage extends StatelessWidget {
  const AddUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddUserController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: const Text(
          'Create New User',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Section
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: controller.pickImage,
                        child: Obx(
                          () => Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    168,
                                    203,
                                    231,
                                  ),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: controller.selectedImage.value != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(58),
                                    child: Image.file(
                                      controller.selectedImage.value!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 32,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Text(
                          controller.selectedImage.value != null
                              ? 'Tap to change image'
                              : 'Tap to select profile image',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField(
                  controller: controller.nameController,
                  focusNode: controller.nameFocus,
                  nextFocus: controller.emailFocus,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Name is required';
                    if (value.trim().length < 2)
                      return 'Name must be at least 2 characters';
                    return null;
                  },
                ),

                _buildTextField(
                  controller: controller.emailController,
                  focusNode: controller.emailFocus,
                  nextFocus: controller.passwordFocus,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Email is required';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value))
                      return 'Enter a valid email address';
                    return null;
                  },
                ),

                Obx(
                  () => _buildTextField(
                    controller: controller.passwordController,
                    focusNode: controller.passwordFocus,
                    nextFocus: controller.ageFocus,
                    label: 'Password',
                    hint: 'Enter password',
                    icon: Icons.lock_outline,
                    obscureText: !controller.passwordVisible.value,
                    textInputAction: TextInputAction.next,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.passwordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => controller.passwordVisible.value =
                          !controller.passwordVisible.value,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Password is required';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.ageController,
                        focusNode: controller.ageFocus,
                        nextFocus: controller.phoneFocus,
                        label: 'Age',
                        hint: 'Enter age',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Age is required';
                          final age = int.tryParse(value);
                          if (age == null || age < 18 || age > 65)
                            return 'Age must be 18-65';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: controller.phoneController,
                        focusNode: controller.phoneFocus,
                        nextFocus: controller.placeFocus,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Phone number is required';
                          if (value.length < 10)
                            return 'Enter valid phone number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                _buildGenderField(controller),

                _buildTextField(
                  controller: controller.placeController,
                  focusNode: controller.placeFocus,
                  nextFocus: controller.addressFocus,
                  label: 'Place',
                  hint: 'Enter city/town',
                  icon: Icons.place_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Place is required';
                    if (value.trim().length < 2)
                      return 'Place must be at least 2 characters';
                    return null;
                  },
                ),

                _buildTextField(
                  controller: controller.addressController,
                  focusNode: controller.addressFocus,
                  label: 'Address',
                  hint: 'Enter complete address',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Address is required';
                    return null;
                  },
                ),

                _buildRoleField(controller),

                const SizedBox(height: 32),

                // Create Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.createUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'CREATE USER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Clear Form Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.clearForm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.clear, size: 18, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            'CLEAR FORM',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 15, 80, 133),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            validator: validator,
            textInputAction: textInputAction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) {
              if (nextFocus != null)
                FocusScope.of(Get.context!).requestFocus(nextFocus);
            },
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
              prefixIcon: Icon(icon, color: Colors.black, size: 22),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fixed Gender Field
  Widget _buildGenderField(AddUserController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 15, 80, 133),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Obx(
              () => DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedGender.value.isEmpty
                      ? null
                      : controller
                            .selectedGender
                            .value, // Fix: Handle empty value
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: const InputDecoration(border: InputBorder.none),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Gender is required'
                      : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.selectedGender.value = value;
                  },
                  hint: Text(
                    'Select gender',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () =>
                controller
                    .selectedGender
                    .value
                    .isNotEmpty // Fix: Check for non-empty
                ? Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.purple[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Selected: ${controller.selectedGender.value}',
                              style: TextStyle(
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Fixed Role Field
  Widget _buildRoleField(AddUserController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 15, 80, 133),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Obx(
              () => DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  // Changed to DropdownButtonFormField
                  value: controller.selectedRole.value.isEmpty
                      ? null
                      : controller
                            .selectedRole
                            .value, // Fix: Handle empty value
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: const InputDecoration(border: InputBorder.none),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Role is required'
                      : null, // Add validation
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  hint: Text(
                    'Select role',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'SALESMEN',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_pin,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text('Salesperson'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'MAKER',
                      child: Row(
                        children: [
                          Icon(Icons.build, color: Colors.green[600], size: 20),
                          const SizedBox(width: 12),
                          const Text('Maker'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.selectedRole.value = value;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () =>
                controller
                    .selectedRole
                    .value
                    .isNotEmpty // Fix: Check for non-empty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: controller.selectedRole.value == 'SALESMEN'
                          ? Colors.blue[50]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: controller.selectedRole.value == 'SALESMEN'
                            ? Colors.blue[200]!
                            : Colors.green[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.selectedRole.value == 'SALESMEN'
                              ? Icons.person_pin
                              : Icons.build,
                          color: controller.selectedRole.value == 'SALESMEN'
                              ? Colors.blue[600]
                              : Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected: ${controller.selectedRole.value == 'SALESMEN' ? 'Salesperson' : 'Maker'}',
                          style: TextStyle(
                            color: controller.selectedRole.value == 'SALESMEN'
                                ? Colors.blue[700]
                                : Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
