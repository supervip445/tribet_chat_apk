import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/academic_year_service.dart';

class AcademicYearsAdminScreen extends StatefulWidget {
  const AcademicYearsAdminScreen({super.key});

  @override
  State<AcademicYearsAdminScreen> createState() =>
      _AcademicYearsAdminScreenState();
}

class _AcademicYearsAdminScreenState extends State<AcademicYearsAdminScreen> {
  final AdminAcademicYearService _service = AdminAcademicYearService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _academicYears = [];
  bool _loading = true;
  bool _showModal = false;
  bool _showDetailModal = false;
  Map<String, dynamic>? _viewingYear;
  Map<String, dynamic>? _editingYear;

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final response = await _service.getAll();
      setState(() {
        _academicYears = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching academic years: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showError('Please select start and end dates');
      return;
    }

    try {
      final data = {
        'name': _nameController.text,
        'code': _codeController.text,
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate!.toIso8601String().split('T')[0],
        'is_active': _isActive,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      };

      if (_editingYear != null) {
        await _service.update(_editingYear!['id'], data);
        _showSuccess('Academic year updated successfully');
      } else {
        await _service.create(data);
        _showSuccess('Academic year created successfully');
      }

      _resetForm();
      _fetchData();
    } catch (e) {
      _showError('Error saving academic year: $e');
    }
  }

  void _handleView(Map<String, dynamic> year) {
    setState(() {
      _viewingYear = year;
      _showDetailModal = true;
    });
  }

  void _handleEdit(Map<String, dynamic> year) {
    setState(() {
      _editingYear = year;
      _nameController.text = year['name'] ?? '';
      _codeController.text = year['code'] ?? '';
      _descriptionController.text = year['description'] ?? '';
      _startDate = year['start_date'] != null
          ? DateTime.parse(year['start_date'])
          : null;
      _endDate = year['end_date'] != null
          ? DateTime.parse(year['end_date'])
          : null;
      _isActive = year['is_active'] ?? false;
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this academic year?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.delete(id);
        _showSuccess('Academic year deleted successfully');
        _fetchData();
      } catch (e) {
        _showError('Error deleting academic year: $e');
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _codeController.clear();
    _descriptionController.clear();
    _startDate = null;
    _endDate = null;
    _isActive = false;
    _editingYear = null;
    _showModal = false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Academic Years',
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
                    label: const Text('Add New Academic Year'),
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Code')),
                                        DataColumn(label: Text('Start Date')),
                                        DataColumn(label: Text('End Date')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: _academicYears.map((year) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(year['name'] ?? '')),
                                            DataCell(Text(year['code'] ?? '')),
                                            DataCell(Text(
                                                year['start_date'] != null
                                                    ? DateFormat('yyyy-MM-dd')
                                                        .format(DateTime.parse(
                                                            year['start_date']))
                                                    : 'N/A')),
                                            DataCell(Text(
                                                year['end_date'] != null
                                                    ? DateFormat('yyyy-MM-dd')
                                                        .format(DateTime.parse(
                                                            year['end_date']))
                                                    : 'N/A')),
                                            DataCell(Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: year['is_active'] == true
                                                    ? Colors.green[100]
                                                    : Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                year['is_active'] == true
                                                    ? 'Active'
                                                    : 'Inactive',
                                                style: TextStyle(
                                                  color: year['is_active'] == true
                                                      ? Colors.green[800]
                                                      : Colors.grey[800],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )),
                                            DataCell(Row(
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      _handleView(year),
                                                  child: const Text('View'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      _handleEdit(year),
                                                  child: const Text('Edit'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      _handleDelete(year['id']),
                                                  style: TextButton.styleFrom(
                                                      foregroundColor: Colors.red),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            )),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (_showModal) _buildModal(context),
          if (_showDetailModal && _viewingYear != null)
            _buildDetailModal(context),
        ],
      ),
    );
  }

  Widget _buildModal(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12)
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
                        _editingYear != null
                            ? 'Edit Academic Year'
                            : 'Create New Academic Year',
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
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Code *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date *',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _startDate != null
                                        ? DateFormat('yyyy-MM-dd')
                                            .format(_startDate!)
                                        : 'Select Start Date',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Date *',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _endDate != null
                                        ? DateFormat('yyyy-MM-dd')
                                            .format(_endDate!)
                                        : 'Select End Date',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Set as Active Academic Year'),
                          subtitle: const Text(
                            '(Activating this will deactivate all other academic years)',
                          ),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value ?? false),
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
                            _editingYear != null ? 'Update' : 'Create',
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
    );
  }

  Widget _buildDetailModal(BuildContext context) {
    final year = _viewingYear!;
    return Container(
      color: Colors.white,
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
                    const Text(
                      'Academic Year Details',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showDetailModal = false;
                          _viewingYear = null;
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
                      _buildDetailRow('Name', year['name'] ?? 'N/A'),
                      _buildDetailRow('Code', year['code'] ?? 'N/A'),
                      _buildDetailRow(
                        'Start Date',
                        year['start_date'] != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(DateTime.parse(year['start_date']))
                            : 'N/A',
                      ),
                      _buildDetailRow(
                        'End Date',
                        year['end_date'] != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(DateTime.parse(year['end_date']))
                            : 'N/A',
                      ),
                      _buildDetailRow(
                        'Status',
                        year['is_active'] == true ? 'Active' : 'Inactive',
                      ),
                      if (year['description'] != null)
                        _buildDetailRow('Description', year['description']),
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
                          setState(() {
                            _showDetailModal = false;
                            _viewingYear = null;
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
                          _handleEdit(year);
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
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
  }
}
