// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class UserDetailPage extends StatefulWidget {
//   final String userId;
//   final Map<String, dynamic> userData;

//   const UserDetailPage({
//     super.key,
//     required this.userId,
//     required this.userData,
//   });

//   @override
//   State<UserDetailPage> createState() => _UserDetailPageState();
// }

// class _UserDetailPageState extends State<UserDetailPage>
//     with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final ImagePicker _picker = ImagePicker();
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _nameController;
//   late TextEditingController _emailController;
//   late TextEditingController _ageController;
//   late TextEditingController _phoneController;
//   late TextEditingController _addressController;
//   late TextEditingController _passwordController;
//   late TextEditingController _placeController;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   bool _isActive = true;
//   String? _imageUrl;
//   File? _selectedImage;
//   bool _isEditing = false;
//   bool _isLoading = false;
//   bool _passwordVisible = false;
//   String? _selectedGender;

//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//     _initializeAnimation();
//   }

//   void _initializeControllers() {
//     _nameController = TextEditingController(text: widget.userData['name']);
//     _emailController = TextEditingController(text: widget.userData['email']);
//     _ageController = TextEditingController(
//       text: widget.userData['age']?.toString() ?? '',
//     );
//     _phoneController = TextEditingController(text: widget.userData['phone']);
//     _addressController = TextEditingController(
//       text: widget.userData['address'],
//     );
//     _passwordController = TextEditingController();
//     _placeController = TextEditingController(
//       text: widget.userData['place'] ?? '',
//     );
//     _selectedGender = widget.userData['gender'];
//     _isActive = widget.userData['isActive'] ?? true;
//     _imageUrl = widget.userData['imageUrl'];
//   }

//   void _initializeAnimation() {
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _ageController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _passwordController.dispose();
//     _placeController.dispose();
//     _animationController.dispose();
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
//     if (_selectedImage == null) return _imageUrl;

//     try {
//       final ref = _storage.ref().child('salesperson_images/$userId.jpg');
//       final uploadTask = ref.putFile(_selectedImage!);
//       final snapshot = await uploadTask;
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       print('Error uploading image: $e');
//       _showErrorDialog('Error uploading image: $e');
//       return _imageUrl;
//     }
//   }

//   String? _validateEmail(String? value) {
//     if (value == null || value.trim().isEmpty) return 'Email is required';
//     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
//       return 'Enter valid email';
//     return null;
//   }

//   String? _validatePhone(String? value) {
//     if (value == null || value.trim().isEmpty)
//       return 'Phone number is required';
//     if (value.length < 10) return 'Enter valid phone number';
//     return null;
//   }

//   String? _validateAge(String? value) {
//     if (value == null || value.trim().isEmpty) return 'Age is required';
//     final age = int.tryParse(value);
//     if (age == null || age < 18 || age > 65) return 'Age must be 18-65';
//     return null;
//   }

//   String? _validateName(String? value) {
//     if (value == null || value.trim().isEmpty) return 'Name is required';
//     if (value.trim().length < 2) return 'Name must be at least 2 characters';
//     return null;
//   }

//   String? _validatePlace(String? value) {
//     if (value == null || value.trim().isEmpty) return 'Place is required';
//     if (value.trim().length < 2) return 'Place must be at least 2 characters';
//     return null;
//   }

//   String? _updateGender(String? value) {
//     if (value == null) return 'Gender is required';
//     return null;
//   }

//   String? _validatePassword(String? value) {
//     if (value != null && value.isNotEmpty && value.length < 6)
//       return 'Password must be at least 6 characters';
//     return null;
//   }

//   Future<void> _updateUser() async {
//     if (!_formKey.currentState!.validate()) {
//       print('Form validation failed'); // Debug print
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       // Check phone number uniqueness (excluding current user)
//       final phoneQuery = await _firestore
//           .collection('users')
//           .where('phone', isEqualTo: _phoneController.text.trim())
//           .get();

//       if (phoneQuery.docs.isNotEmpty &&
//           phoneQuery.docs.first.id != widget.userId) {
//         _showErrorDialog('Phone number is already in use');
//         setState(() => _isLoading = false);
//         return;
//       }

//       // Upload new image if selected
//       final newImageUrl = await _uploadImage(widget.userId);

//       final updatedData = {
//         'name': _nameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'age': int.tryParse(_ageController.text.trim()) ?? 0,
//         'phone': _phoneController.text.trim(),
//         'address': _addressController.text.trim(),
//         'place': _placeController.text.trim(),
//         'gender': _selectedGender,
//         'isActive': _isActive,
//         'imageUrl': newImageUrl,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       // Update Firestore document
//       await _firestore
//           .collection('users')
//           .doc(widget.userId)
//           .update(updatedData);

//       // Update password if provided
//       if (_passwordController.text.trim().isNotEmpty) {
//         await _auth.currentUser?.updatePassword(
//           _passwordController.text.trim(),
//         );
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.white),
//                 SizedBox(width: 8),
//                 Text('User updated successfully'),
//               ],
//             ),
//             backgroundColor: Colors.green[600],
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//         setState(() {
//           _isEditing = false;
//           _imageUrl = newImageUrl;
//           _selectedImage = null;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorDialog('Error updating user: $e');
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _deleteUser() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.red[600]),
//             const SizedBox(width: 8),
//             const Text('Confirm Delete'),
//           ],
//         ),
//         content: const Text(
//           'Are you sure you want to delete this user? This action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red[600],
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       setState(() => _isLoading = true);
//       try {
//         await _firestore.collection('users').doc(widget.userId).delete();
//         if (mounted) {
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.white),
//                   SizedBox(width: 8),
//                   Text('User deleted successfully'),
//                 ],
//               ),
//               backgroundColor: Colors.green[600],
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           _showErrorDialog('Error deleting user: $e');
//         }
//       } finally {
//         if (mounted) {
//           setState(() => _isLoading = false);
//         }
//       }
//     }
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: _buildAppBar(),
//       body: _isLoading ? _buildLoadingIndicator() : _buildBody(),
//       floatingActionButton: _isEditing ? _buildFloatingActionButton() : null,
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.grey[800],
//       title: Text(
//         _isEditing ? 'Edit User' : 'User Details',
//         style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
//       ),
//       elevation: 0,
//       centerTitle: true,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: Colors.grey[200]),
//       ),
//       actions: [
//         if (!_isEditing)
//           IconButton(
//             icon: Icon(Icons.edit, color: Colors.blue[600]),
//             onPressed: () => setState(() => _isEditing = true),
//             tooltip: 'Edit User',
//           ),
//         IconButton(
//           icon: Icon(Icons.delete, color: Colors.red[600]),
//           onPressed: _isLoading ? null : _deleteUser,
//           tooltip: 'Delete User',
//         ),
//         const SizedBox(width: 8),
//       ],
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(),
//           SizedBox(height: 16),
//           Text(
//             'Processing...',
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBody() {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildProfileSection(),
//               const SizedBox(height: 32),
//               _buildPersonalInfoSection(),
//               const SizedBox(height: 24),
//               _buildContactInfoSection(),
//               const SizedBox(height: 24),
//               _buildSecuritySection(),
//               const SizedBox(height: 24),
//               _buildStatusSection(),
//               const SizedBox(height: 100), // Space for FAB
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileSection() {
//     return Center(
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               GestureDetector(
//                 onTap: _isEditing ? _pickImage : null,
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.grey[200],
//                     border: Border.all(color: Colors.grey[300]!, width: 2),
//                   ),
//                   child: _selectedImage != null
//                       ? ClipOval(
//                           child: Image.file(
//                             _selectedImage!,
//                             width: 100,
//                             height: 100,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : _imageUrl != null
//                       ? ClipOval(
//                           child: Image.network(
//                             _imageUrl!,
//                             width: 100,
//                             height: 100,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Icon(
//                                 Icons.person,
//                                 size: 50,
//                                 color: Colors.grey[500],
//                               );
//                             },
//                           ),
//                         )
//                       : Icon(Icons.person, size: 50, color: Colors.grey[500]),
//                 ),
//               ),
//               if (_isEditing)
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: GestureDetector(
//                     onTap: _pickImage,
//                     child: Container(
//                       width: 32,
//                       height: 32,
//                       decoration: BoxDecoration(
//                         color: Colors.blue[600],
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                       child: const Icon(
//                         Icons.camera_alt,
//                         size: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _nameController.text.isNotEmpty ? _nameController.text : 'No Name',
//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: _isActive ? Colors.green[50] : Colors.red[50],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: _isActive ? Colors.green[200]! : Colors.red[200]!,
//                 width: 1,
//               ),
//             ),
//             child: Text(
//               _isActive ? 'Active' : 'Inactive',
//               style: TextStyle(
//                 color: _isActive ? Colors.green[700] : Colors.red[700],
//                 fontWeight: FontWeight.w500,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPersonalInfoSection() {
//     return _buildSection(
//       title: 'Personal Information',
//       icon: Icons.person_outline,
//       children: [
//         _buildTextField(
//           controller: _nameController,
//           label: 'Full Name',
//           icon: Icons.person,
//           validator: _validateName,
//         ),
//         const SizedBox(height: 16),
//         _buildGenderField(),
//         const SizedBox(height: 16),
//         _buildTextField(
//           controller: _ageController,
//           label: 'Age',
//           icon: Icons.cake,
//           keyboardType: TextInputType.number,
//           validator: _validateAge,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           controller: _placeController,
//           label: 'Place',
//           icon: Icons.place_outlined,
//           validator: _validatePlace,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           controller: _addressController,
//           label: 'Address',
//           icon: Icons.location_on,
//           maxLines: 3,
//           validator: (value) => value == null || value.trim().isEmpty
//               ? 'Address is required'
//               : null,
//         ),
//       ],
//     );
//   }

//   Widget _buildContactInfoSection() {
//     return _buildSection(
//       title: 'Contact Information',
//       icon: Icons.contact_phone,
//       children: [
//         _buildTextField(
//           controller: _emailController,
//           label: 'Email Address',
//           icon: Icons.email,
//           keyboardType: TextInputType.emailAddress,
//           validator: _validateEmail,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           controller: _phoneController,
//           label: 'Phone Number',
//           icon: Icons.phone,
//           keyboardType: TextInputType.phone,
//           validator: _validatePhone,
//         ),
//       ],
//     );
//   }

//   Widget _buildSecuritySection() {
//     if (!_isEditing) return const SizedBox.shrink();

//     return _buildSection(
//       title: 'Security',
//       icon: Icons.security,
//       children: [
//         _buildTextField(
//           controller: _passwordController,
//           label: 'New Password (optional)',
//           icon: Icons.lock,
//           obscureText: !_passwordVisible,
//           suffixIcon: IconButton(
//             icon: Icon(
//               _passwordVisible ? Icons.visibility_off : Icons.visibility,
//               color: Colors.grey[600],
//             ),
//             onPressed: () =>
//                 setState(() => _passwordVisible = !_passwordVisible),
//           ),
//           validator: _validatePassword,
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusSection() {
//     return _buildSection(
//       title: 'Account Status',
//       icon: Icons.toggle_on,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[200]!),
//           ),
//           child: SwitchListTile(
//             title: const Text(
//               'Active Status',
//               style: TextStyle(fontWeight: FontWeight.w500),
//             ),
//             subtitle: Text(
//               _isActive
//                   ? 'User account is currently active'
//                   : 'User account is currently inactive',
//               style: TextStyle(color: Colors.grey[600], fontSize: 12),
//             ),
//             value: _isActive,
//             onChanged: _isEditing
//                 ? (value) => setState(() => _isActive = value)
//                 : null,
//             activeColor: Colors.green[600],
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildGenderField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Gender',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Color.fromARGB(255, 15, 80, 133),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           decoration: BoxDecoration(
//             color: _isEditing ? Colors.white : Colors.grey[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: _isEditing
//               ? DropdownButtonHideUnderline(
//                   child: DropdownButtonFormField<String>(
//                     value: _selectedGender,
//                     isExpanded: true,
//                     icon: Icon(
//                       Icons.keyboard_arrow_down,
//                       color: Colors.grey[600],
//                     ),
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                     decoration: const InputDecoration(border: InputBorder.none),
//                     validator: (value) =>
//                         value == null ? 'Gender is required' : null,
//                     items: const [
//                       DropdownMenuItem(value: 'Male', child: Text('Male')),
//                       DropdownMenuItem(value: 'Female', child: Text('Female')),
//                       DropdownMenuItem(value: 'Other', child: Text('Other')),
//                     ],
//                     onChanged: (value) {
//                       if (value != null)
//                         setState(() => _selectedGender = value);
//                     },
//                     hint: Text(
//                       'Select gender',
//                       style: TextStyle(color: Colors.grey[400]),
//                     ),
//                   ),
//                 )
//               : Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   child: Text(
//                     _selectedGender ?? 'Not specified',
//                     style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSection({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(icon, color: Colors.blue[600], size: 20),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType? keyboardType,
//     bool obscureText = false,
//     int maxLines = 1,
//     String? Function(String?)? validator,
//     Widget? suffixIcon,
//   }) {
//     return TextFormField(
//       controller: controller,
//       enabled: _isEditing,
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       maxLines: maxLines,
//       validator: validator,
//       autovalidateMode: AutovalidateMode.onUserInteraction,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: Colors.blue[600]),
//         suffixIcon: suffixIcon,
//         filled: true,
//         fillColor: _isEditing ? Colors.white : Colors.grey[50],
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.red[400]!, width: 2),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.red[400]!, width: 2),
//         ),
//         disabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//       ),
//     );
//   }

//   Widget? _buildFloatingActionButton() {
//     return FloatingActionButton.extended(
//       onPressed: _isLoading ? null : _updateUser,
//       backgroundColor: Colors.blue[600],
//       foregroundColor: Colors.white,
//       icon: const Icon(Icons.save),
//       label: const Text('Save Changes'),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  late TextEditingController _placeController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isActive = true;
  String? _imageUrl;
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _selectedGender;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimation();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _ageController = TextEditingController(
      text: widget.userData['age']?.toString() ?? '',
    );
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _addressController = TextEditingController(
      text: widget.userData['address'],
    );
    _passwordController = TextEditingController();
    _placeController = TextEditingController(
      text: widget.userData['place'] ?? '',
    );
    _selectedGender = widget.userData['gender'];
    _isActive = widget.userData['isActive'] ?? true;
    _imageUrl = widget.userData['imageUrl'];
    _selectedRole = widget.userData['role'] ?? 'salesmen';
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _placeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      print('Opening image picker'); // Debug print
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('Image selected: ${image.path}'); // Debug print
        setState(() {
          _selectedImage = File(image.path);
        });
      } else {
        print('No image selected'); // Debug print
      }
    } catch (e) {
      print('Error picking image: $e'); // Debug print
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return _imageUrl;

    try {
      final ref = _storage.ref().child('salesperson_images/$userId.jpg');
      final uploadTask = ref.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      _showErrorDialog('Error uploading image: $e');
      return _imageUrl;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
      return 'Enter valid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Phone number is required';
    if (value.length < 10) return 'Enter valid phone number';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null || age < 18 || age > 65) return 'Age must be 18-65';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validatePlace(String? value) {
    if (value == null || value.trim().isEmpty) return 'Place is required';
    if (value.trim().length < 2) return 'Place must be at least 2 characters';
    return null;
  }

  String? _validateRole(String? value) {
    if (value == null) return 'Role is required';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value != null && value.isNotEmpty && value.length < 6)
      return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed'); // Debug print
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check phone number uniqueness (excluding current user)
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: _phoneController.text.trim())
          .get();

      if (phoneQuery.docs.isNotEmpty &&
          phoneQuery.docs.first.id != widget.userId) {
        _showErrorDialog('Phone number is already in use');
        setState(() => _isLoading = false);
        return;
      }

      // Upload new image if selected
      final newImageUrl = await _uploadImage(widget.userId);

      final updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'place': _placeController.text.trim(),
        'gender': _selectedGender,
        'role': _selectedRole,
        'isActive': _isActive,
        'imageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .update(updatedData);

      // Update password if provided
      if (_passwordController.text.trim().isNotEmpty) {
        await _auth.currentUser?.updatePassword(
          _passwordController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('User updated successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _isEditing = false;
          _imageUrl = newImageUrl;
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error updating user: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // Delete the user from Firebase Authentication
        User? userToDelete =
            _auth.currentUser; // Assuming admin context or same user
        if (userToDelete == null) {
          // If not the current user, fetch the user by UID
          final userRecord = await _auth.fetchSignInMethodsForEmail(
            widget.userData['email'],
          );
          if (userRecord.isNotEmpty) {
            // This is a workaround; for admin SDK or proper deletion, use Admin SDK
            // For client-side, re-authentication might be needed
            print(
              'Re-authentication or admin privileges required to delete user ${widget.userId}',
            );
            _showErrorDialog(
              'Unable to delete authentication record. Admin privileges required.',
            );
            setState(() => _isLoading = false);
            return;
          }
        } else if (userToDelete.uid == widget.userId) {
          // If deleting the current user, proceed with deletion
          await userToDelete.delete();
        } else {
          // For admin deletion, you would need the Firebase Admin SDK
          print('Admin SDK required to delete user ${widget.userId} from auth');
          _showErrorDialog('Admin privileges required to delete this user.');
          setState(() => _isLoading = false);
          return;
        }

        // Delete the user document from Firestore
        await _firestore.collection('users').doc(widget.userId).delete();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('User deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Error deleting user: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingIndicator() : _buildBody(),
      floatingActionButton: _isEditing ? _buildFloatingActionButton() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      title: Text(
        _isEditing ? 'Edit User' : 'User Details',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue[600]),
            onPressed: () => setState(() => _isEditing = true),
            tooltip: 'Edit User',
          ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red[600]),
          onPressed: _isLoading ? null : _deleteUser,
          tooltip: 'Delete User',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 32),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildContactInfoSection(),
              const SizedBox(height: 24),
              _buildSecuritySection(),
              const SizedBox(height: 24),
              _buildStatusSection(),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _imageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey[500],
                              );
                            },
                          ),
                        )
                      : Icon(Icons.person, size: 50, color: Colors.grey[500]),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'No Name',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isActive ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isActive ? Colors.green[200]! : Colors.red[200]!,
                width: 1,
              ),
            ),
            child: Text(
              _isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _isActive ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person,
          validator: _validateName,
        ),
        const SizedBox(height: 16),
        _buildGenderField(),
        const SizedBox(height: 16),
        _buildRoleField(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ageController,
          label: 'Age',
          icon: Icons.cake,
          keyboardType: TextInputType.number,
          validator: _validateAge,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _placeController,
          label: 'Place',
          icon: Icons.place_outlined,
          validator: _validatePlace,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on,
          maxLines: 3,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Address is required'
              : null,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    if (!_isEditing) return const SizedBox.shrink();

    return _buildSection(
      title: 'Security',
      icon: Icons.security,
      children: [
        _buildTextField(
          controller: _passwordController,
          label: 'New Password (optional)',
          icon: Icons.lock,
          obscureText: !_passwordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          ),
          validator: _validatePassword,
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return _buildSection(
      title: 'Account Status',
      icon: Icons.toggle_on,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SwitchListTile(
            title: const Text(
              'Active Status',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _isActive
                  ? 'User account is currently active'
                  : 'User account is currently inactive',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            value: _isActive,
            onChanged: _isEditing
                ? (value) => setState(() => _isActive = value)
                : null,
            activeColor: Colors.green[600],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
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
            color: _isEditing ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _isEditing
              ? DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(border: InputBorder.none),
                    validator: (value) =>
                        value == null ? 'Gender is required' : null,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value != null)
                        setState(() => _selectedGender = value);
                    },
                    hint: Text(
                      'Select gender',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _selectedGender ?? 'Not specified',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRoleField() {
    return Column(
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
            color: _isEditing ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _isEditing
              ? DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(border: InputBorder.none),
                    validator: _validateRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'salesmen',
                        child: Text('Salesmen'),
                      ),
                      DropdownMenuItem(value: 'maker', child: Text('Maker')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRole = value);
                    },
                    hint: Text(
                      'Select role',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _selectedRole ?? 'Not specified',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[50],
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
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _updateUser,
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      icon: const Icon(Icons.save),
      label: const Text('Save Changes'),
    );
  }
}
