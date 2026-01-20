import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/monastery_building_donation_service.dart';

class MonasteryBuildingDonationsAdminScreen extends StatefulWidget {
  const MonasteryBuildingDonationsAdminScreen({super.key});

  @override
  State<MonasteryBuildingDonationsAdminScreen> createState() =>
      _MonasteryBuildingDonationsAdminScreenState();
}

class _MonasteryBuildingDonationsAdminScreenState
    extends State<MonasteryBuildingDonationsAdminScreen> {
  final AdminMonasteryBuildingDonationService _service =
      AdminMonasteryBuildingDonationService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _donations = [];
  bool _loading = true;
  bool _showModal = false;
  Map<String, dynamic>? _editingDonation;

  final _donorNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonations() async {
    setState(() => _loading = true);
    try {
      final response = await _service.getAll();
      setState(() {
        _donations = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching donations: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'donor_name': _donorNameController.text,
        'amount': double.parse(_amountController.text),
        'donation_purpose': _purposeController.text,
        'date': _dateController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      };

      if (_editingDonation != null) {
        await _service.update(_editingDonation!['id'], data);
        _showSuccess('Donation updated successfully');
      } else {
        await _service.create(data);
        _showSuccess('Donation created successfully');
      }

      _resetForm();
      _fetchDonations();
    } catch (e) {
      _showError('Error saving donation: $e');
    }
  }

  void _handleEdit(Map<String, dynamic> donation) {
    setState(() {
      _editingDonation = donation;
      _donorNameController.text = donation['donor_name'] ?? '';
      _amountController.text = donation['amount']?.toString() ?? '';
      _purposeController.text = donation['donation_purpose'] ?? '';
      _dateController.text = donation['date']?.split('T')[0] ?? '';
      _descriptionController.text = donation['description'] ?? '';
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Donation'),
        content: const Text('Are you sure you want to delete this donation?'),
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
        await _service.delete(id);
        _showSuccess('Donation deleted successfully');
        _fetchDonations();
      } catch (e) {
        _showError('Error deleting donation: $e');
      }
    }
  }

  void _resetForm() {
    _donorNameController.clear();
    _amountController.clear();
    _purposeController.clear();
    _dateController.clear();
    _descriptionController.clear();
    _editingDonation = null;
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
      title: 'Building Donations',
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
                      label: const Text('Add New'),
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
                    child: Container(
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Donor')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Purpose')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _donations.map((donation) {
                                final date = donation['date'] != null
                                    ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(DateTime.parse(donation['date']))
                                    : 'N/A';
                                return DataRow(
                                  cells: [
                                    DataCell(Text(donation['donor_name'] ?? '')),
                                    DataCell(Text('${donation['amount'] ?? 0}')),
                                    DataCell(
                                      Text(donation['donation_purpose'] ?? ''),
                                    ),
                                    DataCell(Text(date)),
                                    DataCell(
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                _handleEdit(donation),
                                            child: Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: Colors.amber[600],
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                _handleDelete(donation['id']),
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
                  ),
              ],
            ),
          ),
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
                                _editingDonation != null
                                    ? 'Edit Donation'
                                    : 'Create New Donation',
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
                                  controller: _donorNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Donor Name *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _amountController,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value!) == null ||
                                        double.parse(value) < 0) {
                                      return 'Invalid amount';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _purposeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Donation Purpose *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _dateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Date *',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (date != null) {
                                      _dateController.text = DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(date);
                                    }
                                  },
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
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
                                    _editingDonation != null
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
