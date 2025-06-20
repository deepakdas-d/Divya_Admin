import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _materialsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    print('ProductDetailsScreen initialized');
    // Test Firestore
    FirebaseFirestore.instance
        .collection('test')
        .doc('test')
        .set({'data': 'test'})
        .then((_) {
          print('Firestore write successful');
        })
        .catchError((e) {
          print('Firestore error: $e');
        });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productIdController.dispose();
    _materialsController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      // Check and request photo permission
      PermissionStatus status = await Permission.photos.status;
      print('Photo permission status: $status');
      if (!status.isGranted) {
        status = await Permission.photos.request();
        print('Photo permission after request: $status');
        if (!status.isGranted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Photo permission denied')));
          return;
        }
      }

      final List<XFile> images = await _picker.pickMultiImage();
      print('Picked images: $images');
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e, stackTrace) {
      print('Image picker error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        String fileName =
            'products/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(_selectedImages[i]);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }
    return imageUrls;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      List<String> imageUrls = await _uploadImages();
      Map<String, dynamic> productData = {
        'productName': _productNameController.text.trim(),
        'productId': _productIdController.text.trim(),
        'materials': _materialsController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'size': _sizeController.text.trim(),
        'images': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('products').add(productData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearForm();
    } catch (e, stackTrace) {
      print('Submit error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _clearForm() {
    _productNameController.clear();
    _productIdController.clear();
    _materialsController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _sizeController.clear();
    setState(() {
      _selectedImages.clear();
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          suffixIcon: Icon(icon, color: Color(0xFF030047)),
          labelText: labelText,
          labelStyle: TextStyle(color: Color.fromARGB(255, 193, 204, 240)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.transparent, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Color(0xFF030047), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Color(0xFFE1E5F2),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building ProductDetailsScreen');
    try {
      return Scaffold(
        backgroundColor: Color(0xFF030047),
        appBar: AppBar(
          backgroundColor: Color(0xFF030047),
          elevation: 0,
          leading: IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.arrow_back, color: Color(0xFF030047)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Product Details',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Container(
          margin: EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Color(0xFFE1E5F2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: _selectedImages.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _selectedImages[0],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Image error: $error');
                                      return Text('Image load failed');
                                    },
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                                    Text(
                                      'image',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Color(0xFFE1E5F2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: _selectedImages.length > 1
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _selectedImages[1],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Image error: $error');
                                      return Text('Image load failed');
                                    },
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                                    Text(
                                      'image',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _productNameController,
                    labelText: 'Product Name',
                    icon: Icons.shopping_bag_outlined,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Product name is required'
                        : null,
                  ),
                  _buildTextField(
                    controller: _productIdController,
                    labelText: 'Product ID',
                    icon: Icons.qr_code,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Product ID is required'
                        : null,
                  ),
                  _buildTextField(
                    controller: _materialsController,
                    labelText: 'Materials',
                    icon: Icons.construction_outlined,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Materials are required'
                        : null,
                  ),
                  _buildTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Description is required'
                        : null,
                  ),
                  _buildTextField(
                    controller: _priceController,
                    labelText: 'Price',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _sizeController,
                    labelText: 'Size',
                    icon: Icons.straighten,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Size is required'
                        : null,
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF030047),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isUploading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Uploading...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
    } catch (e, stackTrace) {
      print('Build error: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(body: Center(child: Text('Error rendering screen: $e')));
    }
  }
}
