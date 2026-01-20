import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/class_service.dart';
import '../../services/admin/academic_year_service.dart';
import '../../services/admin/user_service.dart';

class ClassesAdminScreen extends StatefulWidget {
  const ClassesAdminScreen({super.key});

  @override
  State<ClassesAdminScreen> createState() => _ClassesAdminScreenState();
}

class _ClassesAdminScreenState extends State<ClassesAdminScreen> {
  final AdminClassService _classService = AdminClassService();
  final AdminAcademicYearService _academicYearService =
      AdminAcademicYearService();
  final AdminUserService _userService = AdminUserService();

  final _formKey = GlobalKey<FormState>();

  List<dynamic> _classes = [];
  List<dynamic> _academicYears = [];
  List<dynamic> _teachers = [];

  bool _loading = true;
  bool _showFormModal = false;
  bool _showViewModal = false;

  Map<String, dynamic>? _editingClass;
  Map<String, dynamic>? _viewingClass;

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _sectionController = TextEditingController();

  int _gradeLevel = 1;
  int _capacity = 30;
  String _selectedAcademicYearId = '';
  String _selectedTeacherId = '';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        _classService.getAll(),
        _academicYearService.getAll(),
        _userService.getAll(),
      ]);

      setState(() {
        _classes = res[0]['data'] ?? [];
        _academicYears = res[1]['data'] ?? [];
        _teachers = res[2]['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      _loading = false;
      _showError('Failed to load data');
    }
  }

  // ───────────────── CRUD ─────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text,
      'code': _codeController.text,
      'grade_level': _gradeLevel,
      'section': _sectionController.text,
      'capacity': _capacity,
      'is_active': _isActive,
      'academic_year_id': _selectedAcademicYearId,
      'class_teacher_id': _selectedTeacherId.isEmpty
          ? null
          : _selectedTeacherId,
    };

    try {
      if (_editingClass != null) {
        await _classService.update(_editingClass!['id'], data);
        _showSuccess('Class updated');
      } else {
        await _classService.create(data);
        _showSuccess('Class created');
      }

      _resetForm();
      _fetchData();
    } catch (_) {
      _showError('Failed to save class');
    }
  }

  void _handleEdit(Map<String, dynamic> c) {
    setState(() {
      _editingClass = c;
      _nameController.text = c['name'] ?? '';
      _codeController.text = c['code'] ?? '';
      _sectionController.text = c['section'] ?? '';
      _gradeLevel = c['grade_level'] ?? 1;
      _capacity = c['capacity'] ?? 30;
      _selectedAcademicYearId = c['academic_year_id']?.toString() ?? '';
      _selectedTeacherId = c['class_teacher_id']?.toString() ?? '';
      _isActive = c['is_active'] ?? true;
      _showFormModal = true;
    });
  }

  void _handleView(Map<String, dynamic> c) {
    setState(() {
      _viewingClass = c;
      _showViewModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure?'),
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

    if (ok == true) {
      await _classService.delete(id);
      _showSuccess('Class deleted');
      _fetchData();
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _codeController.clear();
      _sectionController.clear();
      _gradeLevel = 1;
      _capacity = 30;
      _selectedAcademicYearId = '';
      _selectedTeacherId = '';
      _isActive = true;
      _editingClass = null;
      _showFormModal = false;
      _showViewModal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Classes',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildTable(),
            if (_showFormModal) _buildFormOverlay(),
            if (_showViewModal) _buildViewOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: ElevatedButton.icon(
            onPressed: () {
              _resetForm();
              setState(() => _showFormModal = true);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Class'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Grade')),
                    DataColumn(label: Text('Teacher')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _classes.map((c) {
                    return DataRow(
                      cells: [
                        DataCell(Text(c['name'] ?? '')),
                        DataCell(Text(c['code'] ?? '')),
                        DataCell(Text('${c['grade_level'] ?? ''}')),
                        DataCell(Text(c['class_teacher']?['name'] ?? '—')),
                        DataCell(Text(c['is_active'] ? 'Active' : 'Inactive')),
                        DataCell(
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _handleView(c),
                                child: const Text('View'),
                              ),
                              TextButton(
                                onPressed: () => _handleEdit(c),
                                child: Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.amber[700]),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _handleDelete(c['id']),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
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
      ],
    );
  }

  // overlay
  Widget _buildFormOverlay() {
    return _baseOverlay(
      title: _editingClass != null ? 'Edit Class' : 'Create Class',
      body: Form(key: _formKey, child: _buildFormFields()),
      onSubmit: _handleSubmit,
      submitText: _editingClass != null ? 'Update' : 'Create',
      onClose: _resetForm,
    );
  }

  Widget _buildViewOverlay() {
    final c = _viewingClass!;
    return _baseOverlay(
      title: 'Class Details',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detail('Name', c['name']),
          _detail('Code', c['code']),
          _detail('Grade Level', '${c['grade_level']}'),
          _detail('Section', c['section']),
          _detail('Capacity', '${c['capacity']}'),
          _detail('Academic Year', c['academic_year']?['name']),
          _detail('Teacher', c['class_teacher']?['name']),
          _detail('Status', c['is_active'] ? 'Active' : 'Inactive'),
        ],
      ),
      onSubmit: () {
        setState(() {
          _showViewModal = false;
          _handleEdit(c);
        });
      },
      submitText: 'Edit',
      onClose: () => setState(() => _showViewModal = false),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Code *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedAcademicYearId.isEmpty
              ? null
              : _selectedAcademicYearId,
          decoration: const InputDecoration(
            labelText: 'Academic Year *',
            border: OutlineInputBorder(),
          ),
          items: _academicYears
              .map(
                (y) => DropdownMenuItem(
                  value: y['id'].toString(),
                  child: Text(y['name']),
                ),
              )
              .toList(),
          validator: (v) => v == null ? 'Required' : null,
          onChanged: (v) => setState(() => _selectedAcademicYearId = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedTeacherId.isEmpty ? null : _selectedTeacherId,
          decoration: const InputDecoration(
            labelText: 'Class Teacher',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('None')),
            ..._teachers.map(
              (t) => DropdownMenuItem(
                value: t['id'].toString(),
                child: Text(t['name']),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedTeacherId = v ?? ''),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Active'),
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v ?? true),
        ),
      ],
    );
  }

  Widget _baseOverlay({
    required String title,
    required Widget body,
    required VoidCallback onSubmit,
    required String submitText,
    required VoidCallback onClose,
  }) {
    return Container(
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
          child: Column(
            children: [
              _overlayHeader(title, onClose),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: body,
                ),
              ),
              _overlayFooter(onSubmit, submitText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayHeader(String title, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }

  Widget _overlayFooter(VoidCallback onSubmit, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() {
                _showFormModal = false;
                _showViewModal = false;
              }),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value?.toString() ?? '—', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _showSuccess(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

  void _showError(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
}
