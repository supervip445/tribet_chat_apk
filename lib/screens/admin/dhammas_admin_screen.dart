import 'package:dhamma_apk/widgets/admin/admin_pagination.dart';
import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/api_service.dart';
import '../../widgets/admin/simple_rich_text_editor.dart';
import '../../widgets/admin/image_uploader.dart';
import '../../widgets/admin/views_modal.dart';
import '../../services/admin/dhamma_service.dart';
import 'dart:io';

class DhammasAdminScreen extends StatefulWidget {
  const DhammasAdminScreen({super.key});

  @override
  State<DhammasAdminScreen> createState() => _DhammasAdminScreenState();
}

class _DhammasAdminScreenState extends State<DhammasAdminScreen> {
  final AdminDhammaService _dhammaService = AdminDhammaService();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  List<dynamic> _dhammas = [];
  bool _loading = true;
  bool _showModal = false;
  bool _showViewsModal = false;
  Map<String, dynamic>? _editingDhamma;
  Map<String, dynamic>? _selectedDhammaForViews;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _speakerController = TextEditingController();
  final _dateController = TextEditingController();
  List<File> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchDhammas();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _speakerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchDhammas({bool loadMore = false}) async {
    if (loadMore && !_hasMorePages) return;

    setState(() {
      loadMore ? _isLoadingMore = true : _loading = true;
    });

    try {
      final response = await _dhammaService.getAll(_currentPage);
      final pagination = response['pagination'];

      setState(() {
        _dhammas = response['data'] ?? [];
        _hasMorePages = pagination['has_more_pages'] ?? false;
        _loading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _isLoadingMore = false;
      });
      _showError('Failed to load dhammas');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final formData = FormData();
      formData.append('title', _titleController.text);
      formData.append('content', _contentController.text);
      formData.append('speaker', _speakerController.text);
      formData.append('date', _dateController.text);

      // Append images
      for (int i = 0; i < _images.length; i++) {
        formData.append('images[$i]', _images[i]);
      }

      if (_editingDhamma != null) {
        await _dhammaService.update(_editingDhamma!['id'], formData);
        _showSuccess('Dhamma talk updated successfully');
      } else {
        await _dhammaService.create(formData);
        _showSuccess('Dhamma talk created successfully');
      }

      _resetForm();
      _fetchDhammas();
    } catch (e) {
      _showError('Error saving dhamma talk: $e');
    }
  }

  void _handleEdit(Map<String, dynamic> dhamma) {
    setState(() {
      _editingDhamma = dhamma;
      _titleController.text = dhamma['title'] ?? '';
      _contentController.text = dhamma['content'] ?? '';
      _speakerController.text = dhamma['speaker'] ?? '';
      _dateController.text = dhamma['date']?.split('T')[0] ?? '';
      _images = [];
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dhamma Talk'),
        content: const Text(
          'Are you sure you want to delete this dhamma talk?',
        ),
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
        await _dhammaService.delete(id);
        _showSuccess('Dhamma talk deleted successfully');
        _fetchDhammas();
      } catch (e) {
        _showError('Error deleting dhamma talk: $e');
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _speakerController.clear();
    _dateController.clear();
    _images = [];
    _editingDhamma = null;
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

  void _handleViewCountClick(Map<String, dynamic> dhamma) {
    setState(() {
      _selectedDhammaForViews = dhamma;
      _showViewsModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dhamma Talks',
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
                      label: const Text('Add New Dhamma Talk'),
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
                    child: Column(
                      children: [
                        /// 🧾 TABLE
                        Expanded(
                          child: _dhammas.isEmpty
                              ? const Center(
                                  child: Text('No dhamma talks found'),
                                )
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
                                      // ✅ VERTICAL
                                      child: SingleChildScrollView(
                                        // ✅ HORIZONTAL
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: MediaQuery.of(
                                              context,
                                            ).size.width,
                                          ),
                                          child: DataTable(
                                            columnSpacing: 24,
                                            columns: const [
                                              DataColumn(label: Text('Title')),
                                              DataColumn(
                                                label: Text('Speaker'),
                                              ),
                                              DataColumn(label: Text('Date')),
                                              DataColumn(label: Text('Views')),
                                              DataColumn(
                                                label: Text('Actions'),
                                              ),
                                            ],
                                            rows: _dhammas.map((dhamma) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    SizedBox(
                                                      width: 200,
                                                      child: Text(
                                                        dhamma['title'] ?? '',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      dhamma['speaker'] ?? '',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      dhamma['date'] != null
                                                          ? dhamma['date']
                                                                .toString()
                                                                .split('T')[0]
                                                          : 'N/A',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    InkWell(
                                                      onTap: () =>
                                                          _handleViewCountClick(
                                                            dhamma,
                                                          ),
                                                      child: Text(
                                                        '${dhamma['views_count'] ?? 0}',
                                                        style: const TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              _handleEdit(
                                                                dhamma,
                                                              ),
                                                          child: Text(
                                                            'Edit',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .amber[600],
                                                            ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              _handleDelete(
                                                                dhamma['id'],
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
                        ),

                        // pagination stay outside of the scroll
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AdminPagination(
                              currentPage: _currentPage,
                              hasMorePages: _hasMorePages,
                              isLoading: _isLoadingMore,
                              onPrevious: () {
                                setState(() => _currentPage--);
                                _fetchDhammas();
                              },
                              onNext: () {
                                setState(() => _currentPage++);
                                _fetchDhammas();
                              },
                            ),
                          ],
                        ),
                      ],
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
                                _editingDhamma != null
                                    ? 'Edit Dhamma Talk'
                                    : 'Create New Dhamma Talk',
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
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _speakerController,
                                  decoration: const InputDecoration(
                                    labelText: 'Speaker *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter speaker name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _dateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Date *',
                                    border: OutlineInputBorder(),
                                    helperText: 'YYYY-MM-DD format',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a date';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text('Content *'),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 300,
                                  child: SimpleRichTextEditor(
                                    value: _contentController.text,
                                    onChange: (value) {
                                      setState(() {
                                        _contentController.text = value;
                                      });
                                    },
                                    placeholder:
                                        'Write the dhamma talk content here...',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _contentController,
                                  maxLines: 10,
                                  decoration: const InputDecoration(
                                    labelText: 'Content (HTML) *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter content';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text('Images'),
                                const SizedBox(height: 8),
                                ImageUploader(
                                  images: _images,
                                  onImagesChange: (images) {
                                    setState(() => _images = images);
                                  },
                                  maxImages: 10,
                                ),
                                if (_editingDhamma != null &&
                                    _editingDhamma!['image'] != null &&
                                    _images.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Current Image:'),
                                        const SizedBox(height: 8),
                                        Image.network(
                                          _editingDhamma!['image'],
                                          height: 128,
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
                                    _editingDhamma != null
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
                _selectedDhammaForViews = null;
              });
            },
            viewableType: _selectedDhammaForViews != null
                ? 'App\\Models\\Dhamma'
                : null,
            viewableId: _selectedDhammaForViews?['id'],
          ),
        ],
      ),
    );
  }
}
