import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProductAddPage extends StatefulWidget {
  @override
  _ProductAddPageState createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // State variables
  File? _imageFile;
  bool _isUploading = false;

  // Form data
  final Map<String, dynamic> _product = {
    'name': '',
    'id': '',
    'materials': '',
    'description': '',
    'price': null,
    'imageUrl': '',
    'timestamp': FieldValue.serverTimestamp(),
  };

  // Image Picker
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle any errors
      print("Image picking failed: $e");
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do not proceed.
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product image.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    _formKey.currentState!.save();

    try {
      // 1. Upload image to Firebase Storage
      String fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.png';
      UploadTask uploadTask = _storage
          .ref()
          .child(fileName)
          .putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      _product['imageUrl'] = downloadUrl;

      // 2. Add product data to Firestore
      await _firestore.collection('products').add(_product);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _imageFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  _buildTextField(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Product Name',
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a name' : null,
                    onSaved: (value) => _product['name'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.qr_code_scanner_outlined,
                    label: 'Product ID',
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an ID' : null,
                    onSaved: (value) => _product['id'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.blender_outlined,
                    label: 'Materials Used',
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter materials' : null,
                    onSaved: (value) => _product['materials'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.description_outlined,
                    label: 'Description',
                    maxLines: 4,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a description' : null,
                    onSaved: (value) => _product['description'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.attach_money_outlined,
                    label: 'Price',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter a price';

                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null) return 'Enter a valid number';

                      // Check if the number before the decimal point has more than 6 digits
                      final parts = value.split('.');
                      if (parts[0].length > 6)
                        return 'Price must be less than 6 digits';

                      return null;
                    },
                    onSaved: (value) =>
                        _product['price'] = double.parse(value!),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'SUBMIT PRODUCT',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // A helper method to build styled TextFormFields
  Widget _buildTextField({
    required IconData icon,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo.shade800, width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      textInputAction: TextInputAction.next,
    );
  }

  // A helper method for the image picker UI
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.grey[600],
                      size: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add product image',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
