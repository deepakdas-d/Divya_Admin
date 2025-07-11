import 'dart:io';
import 'package:admin/Screens/product/Model/productmodel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
// Import the model

class ProductDetailPage extends StatefulWidget {
  final String productId; // Receive the document ID

  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _formKey = GlobalKey<FormState>(); // Add a GlobalKey for the Form
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  Product? _product;
  File? _imageFile; // To hold the new image if selected

  // Text editing controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _materialsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _nameController.dispose();
    _idController.dispose();
    _materialsController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final docSnapshot = await _firestore
          .collection('products')
          .doc(widget.productId)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          _product = Product.fromFirestore(docSnapshot);
          // Initialize controllers with product data
          _nameController.text = _product!.name;
          _idController.text = _product!.productId;
          _materialsController.text = _product!.materials;
          _descriptionController.text = _product!.description;
          _priceController.text = _product!.price.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching product: $e')));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProduct() async {
    // First, validate the form
    if (!_formKey.currentState!.validate()) {
      return; // If validation fails, do not proceed
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = _product?.imageUrl;

      // If a new image was selected, upload it
      if (_imageFile != null) {
        final ref = _storage.ref().child(
          'products/${DateTime.now().millisecondsSinceEpoch}',
        );
        final uploadTask = ref.putFile(_imageFile!);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Prepare the data to update
      final updatedData = {
        'name': _nameController.text,
        'id': _idController.text,
        'materials': _materialsController.text,
        'description': _descriptionController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'imageUrl': imageUrl,
      };

      // Update the document in Firestore
      await _firestore
          .collection('products')
          .doc(widget.productId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
      Navigator.of(context).pop(); // Go back to the list page
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteProduct() async {
    // Show a confirmation dialog before deleting
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => _isSaving = true);
      try {
        // Delete the document from Firestore
        await _firestore.collection('products').doc(widget.productId).delete();

        // Optional: Delete the image from Firebase Storage
        if (_product != null && _product!.imageUrl.isNotEmpty) {
          await _storage.refFromURL(_product!.imageUrl).delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        Navigator.of(context).pop(); // Go back to the list page
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete product: $e')));
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Loading...' : 'Edit Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _isSaving ? null : _deleteProduct,
            tooltip: 'Delete Product',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    // Wrap your column in a Form widget
                    key: _formKey, // Assign the key
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Image Display and Picker ---
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : (_product?.imageUrl.isNotEmpty ?? false)
                                  ? Image.network(
                                      _product!.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.add_a_photo,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap image to change',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        // --- Text Fields with Validators ---
                        _buildTextField(
                          controller: _nameController,
                          label: 'Product Name',
                          icon: Icons.shopping_bag_outlined,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _idController,
                          label: 'Product ID',
                          icon: Icons.qr_code_scanner_outlined,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter an ID'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _materialsController,
                          label: 'Materials',
                          icon: Icons.blender_outlined,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter materials'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a description'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _priceController,
                          label: 'Price',
                          icon: Icons.attach_money_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        // --- Update Button ---
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.save_alt_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'UPDATE PRODUCT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isSaving ? null : _updateProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }

  // Helper widget for text fields with added validator parameter
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator, // Make validator optional
  }) {
    return TextFormField(
      controller: controller,
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
      validator: validator, // Pass the validator to the TextFormField
      autovalidateMode:
          AutovalidateMode.onUserInteraction, // Validate as the user types
    );
  }
}
