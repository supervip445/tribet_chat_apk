import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/monastery_service.dart';

class MonasteriesAdminScreen extends StatefulWidget {
  const MonasteriesAdminScreen({super.key});

  @override
  State<MonasteriesAdminScreen> createState() => _MonasteriesAdminScreenState();
}

class _MonasteriesAdminScreenState extends State<MonasteriesAdminScreen> {
  final AdminMonasteryService _monasteryService = AdminMonasteryService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _monasteries = [];
  bool _loading = true;
  bool _showModal = false;
  Map<String, dynamic>? _editingMonastery;

  final _nameController = TextEditingController();
  final _monasteryNameController = TextEditingController();
  final _monksController = TextEditingController();
  final _novicesController = TextEditingController();
  final _orderController = TextEditingController();
  String _type = 'monastery';

  @override
  void initState() {
    super.initState();
    _fetchMonasteries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monasteryNameController.dispose();
    _monksController.dispose();
    _novicesController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _fetchMonasteries() async {
    setState(() => _loading = true);
    try {
      final response = await _monasteryService.getAll();
      setState(() {
        _monasteries = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching monasteries: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'name': _nameController.text,
        'type': _type,
        'monastery_name': _type == 'building'
            ? _monasteryNameController.text
            : null,
        'monks': int.parse(_monksController.text),
        'novices': int.parse(_novicesController.text),
        'order': _orderController.text.isEmpty
            ? null
            : int.parse(_orderController.text),
      };

      if (_editingMonastery != null) {
        await _monasteryService.update(_editingMonastery!['id'], data);
        _showSuccess('Monastery updated successfully');
      } else {
        await _monasteryService.create(data);
        _showSuccess('Monastery created successfully');
      }

      _resetForm();
      _fetchMonasteries();
    } catch (e) {
      _showError('Error saving monastery: $e');
    }
  }

  void _handleEdit(Map<String, dynamic> monastery) {
    setState(() {
      _editingMonastery = monastery;
      _nameController.text = monastery['name'] ?? '';
      _type = monastery['type'] ?? 'monastery';
      _monasteryNameController.text = monastery['monastery_name'] ?? '';
      _monksController.text = monastery['monks']?.toString() ?? '0';
      _novicesController.text = monastery['novices']?.toString() ?? '0';
      _orderController.text = monastery['order']?.toString() ?? '';
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Monastery'),
        content: const Text('Are you sure you want to delete this monastery?'),
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
        await _monasteryService.delete(id);
        _showSuccess('Monastery deleted successfully');
        _fetchMonasteries();
      } catch (e) {
        _showError('Error deleting monastery: $e');
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _monasteryNameController.clear();
    _monksController.clear();
    _novicesController.clear();
    _orderController.clear();
    _type = 'monastery';
    _editingMonastery = null;
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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Monasteries',
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
                      label: const Text('Add New Monastery'),
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
                    child: _monasteries.isEmpty
                        ? const Center(child: Text('No monasteries found'))
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
                                      DataColumn(label: Text('Type')),
                                      DataColumn(label: Text('Monks')),
                                      DataColumn(label: Text('Novices')),
                                      DataColumn(label: Text('Total')),
                                      DataColumn(label: Text('Order')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: _monasteries.map((monastery) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(monastery['name'] ?? '')),
                                          DataCell(Text(monastery['type'] ?? '')),
                                          DataCell(
                                            Text('${monastery['monks'] ?? 0}'),
                                          ),
                                          DataCell(
                                            Text('${monastery['novices'] ?? 0}'),
                                          ),
                                          DataCell(
                                            Text('${monastery['total'] ?? 0}'),
                                          ),
                                          DataCell(
                                            Text('${monastery['order'] ?? 0}'),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      _handleEdit(monastery),
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      color: Colors.amber[600],
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _handleDelete(
                                                    monastery['id'],
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
                                _editingMonastery != null
                                    ? 'Edit Monastery'
                                    : 'Create New Monastery',
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
                                      return 'Please enter name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _type,
                                  decoration: const InputDecoration(
                                    labelText: 'Type *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'monastery',
                                      child: Text('Monastery'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'building',
                                      child: Text('Building'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(
                                      () => _type = value ?? 'monastery',
                                    );
                                  },
                                ),
                                if (_type == 'building') ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _monasteryNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Parent Monastery Name',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _monksController,
                                        decoration: const InputDecoration(
                                          labelText: 'Monks *',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          if (int.tryParse(value) == null ||
                                              int.parse(value) < 0) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _novicesController,
                                        decoration: const InputDecoration(
                                          labelText: 'Novices *',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          if (int.tryParse(value) == null ||
                                              int.parse(value) < 0) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _orderController,
                                  decoration: const InputDecoration(
                                    labelText: 'Order',
                                    border: OutlineInputBorder(),
                                    helperText: 'Display order (optional)',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ),
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
                                    _editingMonastery != null
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
        ],
      ),
    );
  }
}
