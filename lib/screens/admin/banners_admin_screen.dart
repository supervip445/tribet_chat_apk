import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/banner_service.dart';
import '../../services/api_service.dart';

class BannersAdminScreen extends StatefulWidget {
  const BannersAdminScreen({super.key});

  @override
  State<BannersAdminScreen> createState() => _BannersAdminScreenState();
}

class _BannersAdminScreenState extends State<BannersAdminScreen> {
  final AdminBannerService _bannerService = AdminBannerService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _banners = [];
  bool _loading = true;

  Map<String, dynamic>? _editingBanner;

  File? _image;
  final _orderController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  @override
  void dispose() {
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    setState(() => _loading = true);
    try {
      final response = await _bannerService.getAll();
      setState(() {
        _banners = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching banners: $e');
    }
  }

  Future<void> _pickImage(void Function(void Function()) setStateDialog) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setStateDialog(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_editingBanner == null && _image == null) {
      _showError('Please select an image');
      return;
    }

    try {
      final formData = FormData();
      if (_image != null) {
        formData.append('image', _image!);
      }

      final orderText = _orderController.text.trim();
      if (orderText.isNotEmpty) {
        final orderValue = int.tryParse(orderText);
        if (orderValue != null && orderValue >= 0) {
          formData.append('order', orderValue.toString());
        }
      }

      formData.append('is_active', _isActive ? '1' : '0');

      if (_editingBanner != null) {
        await _bannerService.update(_editingBanner!['id'], formData);
        _showSuccess('Banner updated successfully');
      } else {
        await _bannerService.create(formData);
        _showSuccess('Banner created successfully');
      }
      
      _resetForm();
      _fetchBanners();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Error saving banner: $e');
    }
  }

  void _handleEdit(Map<String, dynamic> banner) {
    setState(() {
      _editingBanner = banner;
      _orderController.text = banner['order']?.toString() ?? '0';
      _isActive = banner['is_active'] ?? true;
      _image = null;
    });
    _showBannerDialog();
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bannerService.delete(id);
        _showSuccess('Banner deleted successfully');
        _fetchBanners();
      } catch (e) {
        _showError('Error deleting banner: $e');
      }
    }
  }

  void _resetForm() {
    _image = null;
    _orderController.clear();
    _isActive = true;
    _editingBanner = null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showBannerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      _editingBanner != null
                          ? 'Edit Banner'
                          : 'Create New Banner',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage(setStateDialog),
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100],
                                ),
                                child: _image != null
                                    ? Image.file(_image!, fit: BoxFit.cover)
                                    : _editingBanner != null &&
                                          _editingBanner!['image'] != null
                                    ? Image.network(
                                        _editingBanner!['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                  ),
                                                ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _orderController,
                              decoration: const InputDecoration(
                                labelText: 'Display Order',
                                border: OutlineInputBorder(),
                                helperText: 'Lower numbers appear first',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text(
                                'Is Active',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Active banners are displayed to public',
                              ),
                              value: _isActive,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                setStateDialog(() => _isActive = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetForm();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              elevation: 1,
                            ),
                            child: Text(
                              _editingBanner != null ? 'Update' : 'Create',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final double cardWidth =
        (screenWidth - 16 * (crossAxisCount + 1)) / crossAxisCount;
    final double cardHeight = 300;
    final double aspectRatio = cardWidth / cardHeight;

    return AdminLayout(
      title: 'Banners',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _resetForm();
                    _showBannerDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: _banners.isEmpty
                  ? const Center(child: Text('No banners found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Card(
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: banner['image'] != null
                                      ? Image.network(
                                          banner['image'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                  ),
                                                );
                                              },
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          banner['is_active'] == true
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: banner['is_active'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Order: ${banner['order'] ?? 0}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.amber[600],
                                            size: 20,
                                          ),
                                          onPressed: () => _handleEdit(banner),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _handleDelete(banner['id']),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
