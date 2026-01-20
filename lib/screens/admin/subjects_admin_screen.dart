import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/subject_service.dart';

class SubjectsAdminScreen extends StatefulWidget {
  const SubjectsAdminScreen({super.key});

  @override
  State<SubjectsAdminScreen> createState() => _SubjectsAdminScreenState();
}

class _SubjectsAdminScreenState extends State<SubjectsAdminScreen> {
  final AdminSubjectService _service = AdminSubjectService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _subjects = [];
  bool _loading = true;
  bool _showModal = false;
  bool _showDetailModal = false;
  Map<String, dynamic>? _editingSubject;
  Map<String, dynamic>? _viewingSubject;

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditHoursController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _creditHoursController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _loading = true);
    try {
      final response = await _service.getAll();
      setState(() {
        _subjects = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching subjects: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'name': _nameController.text,
        'code': _codeController.text,
        'credit_hours': int.tryParse(_creditHoursController.text) ?? 1,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'is_active': _isActive,
      };

      if (_editingSubject != null) {
        await _service.update(_editingSubject!['id'], data);
        _showSuccess('Subject updated successfully');
      } else {
        await _service.create(data);
        _showSuccess('Subject created successfully');
      }

      _resetForm();
      _fetchSubjects();
    } catch (e) {
      _showError('Error saving subject: $e');
    }
  }

  void _handleView(Map<String, dynamic> subject) {
    setState(() {
      _viewingSubject = subject;
      _showDetailModal = true;
    });
  }

  void _handleEdit(Map<String, dynamic> subject) {
    setState(() {
      _editingSubject = subject;
      _nameController.text = subject['name'] ?? '';
      _codeController.text = subject['code'] ?? '';
      _descriptionController.text = subject['description'] ?? '';
      _creditHoursController.text = (subject['credit_hours'] ?? 1).toString();
      _isActive = subject['is_active'] ?? true;
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this subject?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.delete(id);
        _showSuccess('Subject deleted successfully');
        _fetchSubjects();
      } catch (e) {
        _showError('Error deleting subject: $e');
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _codeController.clear();
    _descriptionController.clear();
    _creditHoursController.text = '1';
    _isActive = true;
    _editingSubject = null;
    _showModal = false;
  }

  void _showSuccess(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

  void _showError(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Subjects',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _resetForm();
                      setState(() => _showModal = true);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Subject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Scrollbar(
                              thumbVisibility: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        columnSpacing: 24,
                                        headingRowHeight: 48,
                                        dataRowMinHeight: 48,
                                        dataRowMaxHeight: 64,
                                        columns: const [
                                          DataColumn(label: Text('Name')),
                                          DataColumn(label: Text('Code')),
                                          DataColumn(label: Text('Credit Hours')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: _subjects.map<DataRow>((subject) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(subject['name'] ?? '')),
                                              DataCell(Text(subject['code'] ?? '')),
                                              DataCell(
                                                Text(
                                                  '${subject['credit_hours'] ?? 1}',
                                                ),
                                              ),
                                              DataCell(_buildStatusChip(subject)),
                                              DataCell(_buildActions(subject)),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_showModal) _buildModal(context),
          if (_showDetailModal && _viewingSubject != null)
            _buildDetailModal(context),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> subject) {
    final isActive = subject['is_active'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green[800] : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> subject) {
    return Row(
      spacing: 8,
      children: [
        TextButton(
          onPressed: () => _handleView(subject),
          child: const Text('View'),
        ),
        TextButton(
          onPressed: () => _handleEdit(subject),
          child: const Text('Edit'),
        ),
        TextButton(
          onPressed: () => _handleDelete(subject['id']),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Widget _buildModal(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
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
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingSubject != null
                          ? 'Edit Subject'
                          : 'Create New Subject',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _showModal = false);
                        _resetForm();
                      },
                    ),
                  ],
                ),
              ),
              // Body
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
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Code *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _creditHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Credit Hours',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Is Active'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v ?? true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
                          _editingSubject != null ? 'Update' : 'Create',
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
    );
  }

  Widget _buildDetailModal(BuildContext context) {
    final subject = _viewingSubject!;
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subject Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showDetailModal = false;
                        _viewingSubject = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Name', subject['name'] ?? 'N/A'),
                    _buildDetailRow('Code', subject['code'] ?? 'N/A'),
                    _buildDetailRow(
                      'Credit Hours',
                      '${subject['credit_hours'] ?? 1}',
                    ),
                    _buildDetailRow(
                      'Status',
                      subject['is_active'] == true ? 'Active' : 'Inactive',
                    ),
                    if (subject['description'] != null)
                      _buildDetailRow('Description', subject['description']),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showDetailModal = false;
                          _viewingSubject = null;
                        });
                      },
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showDetailModal = false;
                        });
                        _handleEdit(subject);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
