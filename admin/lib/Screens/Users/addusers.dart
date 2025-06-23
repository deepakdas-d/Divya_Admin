// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class AddSalespersonPage extends StatefulWidget {
//   const AddSalespersonPage({super.key});

//   @override
//   State<AddSalespersonPage> createState() => _AddSalespersonPageState();
// }

// class _AddSalespersonPageState extends State<AddSalespersonPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _ageController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _passwordController = TextEditingController();

//   String _selectedStatus = 'SALES';
//   File? _selectedImage;
//   bool _isLoading = false;

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
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         setState(() {
//           _selectedImage = File(image.path);
//         });
//       }
//     } catch (e) {
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

//   Future<void> _createSalesperson() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Create user with email and password
//       final UserCredential userCredential = await _auth
//           .createUserWithEmailAndPassword(
//             email: _emailController.text.trim(),
//             password: _passwordController.text.trim(),
//           );

//       final User? user = userCredential.user;
//       if (user != null) {
//         // Upload image if selected
//         String? imageUrl;
//         if (_selectedImage != null) {
//           imageUrl = await _uploadImage(user.uid);
//         }

//         // Save salesperson data to Firestore
//         await _firestore.collection('salespersons').doc(user.uid).set({
//           'uid': user.uid,
//           'name': _nameController.text.trim(),
//           'email': _emailController.text.trim(),
//           'age': int.tryParse(_ageController.text.trim()) ?? 0,
//           'phone': _phoneController.text.trim(),
//           'address': _addressController.text.trim(),
//           'status': _selectedStatus,
//           'role': 'salesperson',
//           'imageUrl': imageUrl,
//           'createdAt': FieldValue.serverTimestamp(),
//           'createdBy': _auth.currentUser?.uid,
//           'isActive': true,
//         });

//         // Update user display name
//         await user.updateDisplayName(_nameController.text.trim());

//         // Show success message
//         _showSuccessDialog();
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
//       _showErrorDialog('Error creating salesperson: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Success'),
//         content: const Text('Salesperson created successfully!'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _clearForm();
//             },
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
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
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
//     setState(() {
//       _selectedImage = null;
//       _selectedStatus = 'SALES';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1E1E2E),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E1E2E),
//         foregroundColor: Colors.white,
//         title: const Text('Create User'),
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               // Profile Image Section
//               GestureDetector(
//                 onTap: _pickImage,
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(60),
//                     border: Border.all(color: Colors.grey[400]!),
//                   ),
//                   child: _selectedImage != null
//                       ? ClipRRect(
//                           borderRadius: BorderRadius.circular(60),
//                           child: Image.file(_selectedImage!, fit: BoxFit.cover),
//                         )
//                       : const Icon(
//                           Icons.camera_alt,
//                           size: 40,
//                           color: Colors.grey,
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Tap to select image',
//                 style: TextStyle(color: Colors.grey[400], fontSize: 12),
//               ),
//               const SizedBox(height: 30),

//               // Name Field
//               _buildTextField(
//                 controller: _nameController,
//                 label: 'Name :',
//                 hint: 'Please Enter Name',
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Name is required';
//                   }
//                   return null;
//                 },
//               ),

//               // Email Field
//               _buildTextField(
//                 controller: _emailController,
//                 label: 'E-mail :',
//                 hint: 'Please Enter E-mail',
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Email is required';
//                   }
//                   if (!RegExp(
//                     r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                   ).hasMatch(value)) {
//                     return 'Enter a valid email';
//                   }
//                   return null;
//                 },
//               ),

//               // Password Field
//               _buildTextField(
//                 controller: _passwordController,
//                 label: 'Password :',
//                 hint: 'Please Enter Password',
//                 obscureText: true,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Password is required';
//                   }
//                   if (value.length < 6) {
//                     return 'Password must be at least 6 characters';
//                   }
//                   return null;
//                 },
//               ),

//               // Age Field
//               _buildTextField(
//                 controller: _ageController,
//                 label: 'Age :',
//                 hint: 'Please Enter Age',
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Age is required';
//                   }
//                   final age = int.tryParse(value);
//                   if (age == null || age < 18 || age > 65) {
//                     return 'Enter a valid age (18-65)';
//                   }
//                   return null;
//                 },
//               ),

//               // Phone Number Field
//               _buildTextField(
//                 controller: _phoneController,
//                 label: 'Phone Number :',
//                 hint: 'Please Enter Phone Number',
//                 keyboardType: TextInputType.phone,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Phone number is required';
//                   }
//                   if (value.length < 10) {
//                     return 'Enter a valid phone number';
//                   }
//                   return null;
//                 },
//               ),

//               // Address Field
//               _buildTextField(
//                 controller: _addressController,
//                 label: 'Address :',
//                 hint: 'Please Enter Address',
//                 maxLines: 3,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Address is required';
//                   }
//                   return null;
//                 },
//               ),

//               // Status Field
//               _buildStatusField(),

//               const SizedBox(height: 40),

//               // Create Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _createSalesperson,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF2D3748),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                             Colors.white,
//                           ),
//                         )
//                       : const Text(
//                           'CREATE',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     TextInputType? keyboardType,
//     bool obscureText = false,
//     int maxLines = 1,
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
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             obscureText: obscureText,
//             maxLines: maxLines,
//             validator: validator,
//             style: const TextStyle(color: Colors.black),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: TextStyle(color: Colors.grey[500]),
//               filled: true,
//               fillColor: Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide.none,
//               ),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusField() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Status :',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: _selectedStatus,
//                       isExpanded: true,
//                       items: ['SALES', 'MANAGER', 'SUPERVISOR']
//                           .map(
//                             (status) => DropdownMenuItem(
//                               value: status,
//                               child: Text(status),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: (value) {
//                         if (value != null) {
//                           setState(() {
//                             _selectedStatus = value;
//                           });
//                         }
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _selectedStatus == 'SALES'
//                       ? Colors.blue[100]
//                       : Colors.green[100],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   _selectedStatus,
//                   style: TextStyle(
//                     color: _selectedStatus == 'SALES'
//                         ? Colors.blue[800]
//                         : Colors.green[800],
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'SALESMEN';
  File? _selectedImage;
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;
    
    try {
      final ref = _storage.ref().child('salesperson_images/$userId.jpg');
      final uploadTask = ref.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Upload image if selected
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _uploadImage(user.uid);
        }

        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'role': _selectedRole.toLowerCase(), // 'salesmen' or 'maker'
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid,
          'isActive': true,
        });

        // Update user display name
        await user.updateDisplayName(_nameController.text.trim());

        // Show success message
        _showSuccessDialog('User created successfully!');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = e.message ?? 'Authentication error';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('Error creating user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _ageController.clear();
    _phoneController.clear();
    _addressController.clear();
    _passwordController.clear();
    setState(() {
      _selectedImage = null;
      _selectedRole = 'SALESMEN';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        title: const Text('Create User'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to select image',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 30),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Name :',
                hint: 'Please Enter Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'E-mail :',
                hint: 'Please Enter E-mail',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: 'Password :',
                hint: 'Please Enter Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              // Age Field
              _buildTextField(
                controller: _ageController,
                label: 'Age :',
                hint: 'Please Enter Age',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 65) {
                    return 'Enter a valid age (18-65)';
                  }
                  return null;
                },
              ),

              // Phone Number Field
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number :',
                hint: 'Please Enter Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: 'Address :',
                hint: 'Please Enter Address',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),

              // Role Field
              _buildRoleField(),

              const SizedBox(height: 40),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3748),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'CREATE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
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
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role :',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      items: ['SALESMEN', 'MAKER']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _selectedRole == 'SALESMEN' 
                      ? Colors.blue[100] 
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedRole,
                  style: TextStyle(
                    color: _selectedRole == 'SALESMEN' 
                        ? Colors.blue[800] 
                        : Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}