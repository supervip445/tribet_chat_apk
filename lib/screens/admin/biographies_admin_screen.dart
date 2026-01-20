import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../widgets/admin/views_modal.dart';
import '../../services/admin/biography_service.dart';
import '../../services/api_service.dart';
import 'dart:io';

class BiographiesAdminScreen extends StatefulWidget {
  const BiographiesAdminScreen({super.key});

  @override
  State<BiographiesAdminScreen> createState() => _BiographiesAdminScreenState();
}

class _BiographiesAdminScreenState extends State<BiographiesAdminScreen> {
  final AdminBiographyService _biographyService = AdminBiographyService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _biographies = [];
  bool _loading = true;
  bool _showModal = false;
  bool _showViewsModal = false;
  Map<String, dynamic>? _editingBiography;
  Map<String, dynamic>? _selectedBiographyForViews;

  final _nameController = TextEditingController();
  // final _birthYearController = TextEditingController();
  // final _sanghaEntryYearController = TextEditingController();
  // final _disciplesController = TextEditingController();
  // final _teachingMonasteryController = TextEditingController();
  final _sanghaDhammaController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchBiographies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    // _birthYearController.dispose();
    // _sanghaEntryYearController.dispose();
    // _disciplesController.dispose();
    // _teachingMonasteryController.dispose();
    _sanghaDhammaController.dispose();
    super.dispose();
  }

  Future<void> _fetchBiographies() async {
    setState(() => _loading = true);
    try {
      final response = await _biographyService.getAll();
      setState(() {
        _biographies = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching biographies: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final formData = FormData();
      formData.append('name', _nameController.text);
      // formData.append('birth_year', _birthYearController.text);
      // formData.append('sangha_entry_year', _sanghaEntryYearController.text);
      // formData.append('disciples', _disciplesController.text);
      // formData.append('teaching_monastery', _teachingMonasteryController.text);
      formData.append('sangha_dhamma', _sanghaDhammaController.text);

      if (_imageFile != null) {
        formData.append('image', _imageFile!);
      }

      if (_editingBiography != null) {
        await _biographyService.update(_editingBiography!['id'], formData);
        _showSuccess('Promotion updated successfully');
      } else {
        await _biographyService.create(formData);
        _showSuccess('Promotion created successfully');
      }

      _resetForm();
      _fetchBiographies();
    } catch (e) {
      _showError('Error saving promotion: $e');
    }
  }

  void _handleEdit(Map<String, dynamic> biography) {
    setState(() {
      _editingBiography = biography;
      _nameController.text = biography['name'] ?? '';
      // _birthYearController.text = biography['birth_year'] ?? '';
      // _sanghaEntryYearController.text = biography['sangha_entry_year'] ?? '';
      // _disciplesController.text = biography['disciples'] ?? '';
      // _teachingMonasteryController.text = biography['teaching_monastery'] ?? '';
      _sanghaDhammaController.text = biography['sangha_dhamma'] ?? '';
      _imageFile = null;
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: const Text('Are you sure you want to delete this promotion?'),
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
        await _biographyService.delete(id);
        _showSuccess('Promotion deleted successfully');
        _fetchBiographies();
      } catch (e) {
        _showError('Error deleting promotion: $e');
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    // _birthYearController.clear();
    // _sanghaEntryYearController.clear();
    // _disciplesController.clear();
    // _teachingMonasteryController.clear();
    _sanghaDhammaController.clear();
    _imageFile = null;
    _editingBiography = null;
    _showModal = false;
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

  void _handleViewCountClick(Map<String, dynamic> biography) {
    setState(() {
      _selectedBiographyForViews = biography;
      _showViewsModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Promotions',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _resetForm();
                        setState(() => _showModal = true);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Promotion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Expanded(
                    child: _biographies.isEmpty
                        ? const Center(child: Text('No promotions found'))
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Name')),
                                      // DataColumn(label: Text('Birth Year')),
                                      // DataColumn(label: Text('Sangha Entry')),
                                      // DataColumn(label: Text('Disciples')),
                                      DataColumn(label: Text('Views')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: _biographies.map((biography) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(biography['name'] ?? '')),
                                          // DataCell(
                                          //   Text(biography['birth_year'] ?? ''),
                                          // ),
                                          // DataCell(
                                          //   Text(
                                          //     biography['sangha_entry_year'] ??
                                          //         '',
                                          //   ),
                                          // ),
                                          // DataCell(
                                          //   Text(biography['disciples'] ?? ''),
                                          // ),
                                          DataCell(
                                            InkWell(
                                              onTap: () => _handleViewCountClick(
                                                biography,
                                              ),
                                              child: Text(
                                                '${biography['views_count'] ?? 0}',
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      _handleEdit(biography),
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      color: Colors.amber[600],
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _handleDelete(
                                                    biography['id'],
                                                  ),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
          // Modal
          if (_showModal)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _editingBiography != null
                                    ? 'Edit Promotion'
                                    : 'Create New Promotion',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _showModal = false),
                              ),
                            ],
                          ),
                        ),
                        // Form Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Row(
                                //   children: [
                                //     Expanded(
                                //       child: TextFormField(
                                //         controller: _birthYearController,
                                //         decoration: const InputDecoration(
                                //           labelText: 'Birth Year',
                                //           border: OutlineInputBorder(),
                                //         ),
                                //       ),
                                //     ),
                                //     const SizedBox(width: 16),
                                //     Expanded(
                                //       child: TextFormField(
                                //         controller: _sanghaEntryYearController,
                                //         decoration: const InputDecoration(
                                //           labelText: 'Sangha Entry Year',
                                //           border: OutlineInputBorder(),
                                //         ),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // const SizedBox(height: 16),
                                // TextFormField(
                                //   controller: _disciplesController,
                                //   decoration: const InputDecoration(
                                //     labelText: 'Disciples',
                                //     border: OutlineInputBorder(),
                                //   ),
                                // ),
                                // const SizedBox(height: 16),
                                // TextFormField(
                                //   controller: _teachingMonasteryController,
                                //   decoration: const InputDecoration(
                                //     labelText: 'Teaching Monastery',
                                //     border: OutlineInputBorder(),
                                //   ),
                                // ),
                                // const SizedBox(height: 16),
                                TextFormField(
                                  controller: _sanghaDhammaController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Sangha Dhamma',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Image'),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.image),
                                  label: Text(
                                    _imageFile != null
                                        ? 'Change Image'
                                        : 'Select Image',
                                  ),
                                ),
                                if (_imageFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Image.file(
                                      _imageFile!,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (_editingBiography != null &&
                                    _editingBiography!['image'] != null &&
                                    _imageFile == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Current Image:'),
                                        const SizedBox(height: 8),
                                        Image.network(
                                          _editingBiography!['image'],
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() => _showModal = false);
                                    _resetForm();
                                  },
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
                                  ),
                                  child: Text(
                                    _editingBiography != null
                                        ? 'Update'
                                        : 'Create',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Views Modal
          ViewsModal(
            isOpen: _showViewsModal,
            onClose: () {
              setState(() {
                _showViewsModal = false;
                _selectedBiographyForViews = null;
              });
            },
            viewableType: _selectedBiographyForViews != null
                ? 'App\\Models\\Biography'
                : null,
            viewableId: _selectedBiographyForViews?['id'],
          ),
        ],
      ),
    );
  }
}
