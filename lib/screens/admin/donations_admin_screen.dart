import 'package:dhamma_apk/widgets/admin/admin_pagination.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../widgets/admin/views_modal.dart';
import '../../services/admin/donation_service.dart';

class DonationsAdminScreen extends StatefulWidget {
  const DonationsAdminScreen({super.key});

  @override
  State<DonationsAdminScreen> createState() => _DonationsAdminScreenState();
}

class _DonationsAdminScreenState extends State<DonationsAdminScreen> {
  final AdminDonationService _donationService = AdminDonationService();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  List<dynamic> _donations = [];
  bool _loading = true;
  bool _showModal = false;
  bool _showViewsModal = false;
  Map<String, dynamic>? _editingDonation;
  Map<String, dynamic>? _selectedDonationForViews;

  final _donorNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _donationTypeController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _amountController.dispose();
    _donationTypeController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonations({bool loadMore = false}) async {
    if (loadMore && !_hasMorePages) return;

    setState(() {
      loadMore ? _isLoadingMore = true : _loading = true;
    });

    try {
      final response = await _donationService.getAll(_currentPage);
      final pagination = response['pagination'];

      final List<dynamic> fetchedDonations = response['data'] ?? [];

      setState(() {
        if (loadMore) {
          _donations.addAll(fetchedDonations);
        } else {
          _donations = fetchedDonations;
        }

        _hasMorePages = pagination['has_more_pages'] ?? false;
        _loading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _isLoadingMore = false;
      });
      _showError('Failed to load donations');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'donor_name': _donorNameController.text,
        'amount': double.parse(_amountController.text),
        'donation_type': _donationTypeController.text,
        'date': _dateController.text,
        'status': _status,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      if (_editingDonation != null) {
        await _donationService.update(_editingDonation!['id'], data);
        _showSuccess('Donation updated successfully');
      } else {
        await _donationService.create(data);
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
      _donationTypeController.text = donation['donation_type'] ?? '';
      _dateController.text = donation['date']?.split('T')[0] ?? '';
      _status = donation['status'] ?? 'pending';
      _notesController.text = donation['notes'] ?? '';
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
        await _donationService.delete(id);
        _showSuccess('Donation deleted successfully');
        _fetchDonations();
      } catch (e) {
        _showError('Error deleting donation: $e');
      }
    }
  }

  Future<void> _handleApprove(int id) async {
    try {
      await _donationService.approve(id);
      _showSuccess('Donation approved successfully');
      _fetchDonations();
    } catch (e) {
      _showError('Error approving donation: $e');
    }
  }

  Future<void> _handleReject(int id) async {
    try {
      await _donationService.reject(id);
      _showSuccess('Donation rejected successfully');
      _fetchDonations();
    } catch (e) {
      _showError('Error rejecting donation: $e');
    }
  }

  void _resetForm() {
    _donorNameController.clear();
    _amountController.clear();
    _donationTypeController.clear();
    _dateController.clear();
    _notesController.clear();
    _status = 'pending';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _handleViewCountClick(Map<String, dynamic> donation) {
    setState(() {
      _selectedDonationForViews = donation;
      _showViewsModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Donations',
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
                      label: const Text('Add New Donation'),
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
                    child: _donations.isEmpty
                        ? const Center(child: Text('No donations found'))
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
                                      DataColumn(label: Text('Donor Name')),
                                      DataColumn(label: Text('Amount')),
                                      DataColumn(label: Text('Type')),
                                      DataColumn(label: Text('Date')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Views')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: _donations.map((donation) {
                                      final date = donation['date'] != null
                                          ? DateFormat('yyyy-MM-dd').format(
                                              DateTime.parse(donation['date']),
                                            )
                                          : 'N/A';
                                      final status =
                                          donation['status'] ?? 'pending';
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(donation['donor_name'] ?? ''),
                                          ),
                                          DataCell(
                                            Text('${donation['amount'] ?? 0}'),
                                          ),
                                          DataCell(
                                            Text(
                                              donation['donation_type'] ?? '',
                                            ),
                                          ),
                                          DataCell(Text(date)),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  status,
                                                ).withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                    status,
                                                  ),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            InkWell(
                                              onTap: () =>
                                                  _handleViewCountClick(
                                                    donation,
                                                  ),
                                              child: Text(
                                                '${donation['views_count'] ?? 0}',
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
                                                if (status == 'pending') ...[
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.check,
                                                      color: Colors.green,
                                                    ),
                                                    onPressed: () =>
                                                        _handleApprove(
                                                          donation['id'],
                                                        ),
                                                    tooltip: 'Approve',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        _handleReject(
                                                          donation['id'],
                                                        ),
                                                    tooltip: 'Reject',
                                                  ),
                                                ],
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: Colors.amber[600],
                                                  ),
                                                  onPressed: () =>
                                                      _handleEdit(donation),
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _handleDelete(
                                                        donation['id'],
                                                      ),
                                                  tooltip: 'Delete',
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
                // Pagination outside scroll
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AdminPagination(
                      currentPage: _currentPage,
                      hasMorePages: _hasMorePages,
                      isLoading: _isLoadingMore,
                      onPrevious: () {
                        setState(() => _currentPage--);
                        _fetchDonations();
                      },
                      onNext: () {
                        setState(() => _currentPage++);
                        _fetchDonations();
                      },
                    ),
                  ],
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
                        // Form Content
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter donor name';
                                    }
                                    return null;
                                  },
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
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter amount';
                                    }
                                    if (double.tryParse(value) == null ||
                                        double.parse(value) < 0) {
                                      return 'Please enter a valid amount';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _donationTypeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Donation Type *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter donation type';
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a date';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _status,
                                  decoration: const InputDecoration(
                                    labelText: 'Status *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'pending',
                                      child: Text('Pending'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'approved',
                                      child: Text('Approved'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'rejected',
                                      child: Text('Rejected'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(
                                      () => _status = value ?? 'pending',
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _notesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
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
          // Views Modal
          ViewsModal(
            isOpen: _showViewsModal,
            onClose: () {
              setState(() {
                _showViewsModal = false;
                _selectedDonationForViews = null;
              });
            },
            viewableType: _selectedDonationForViews != null
                ? 'App\\Models\\Donation'
                : null,
            viewableId: _selectedDonationForViews?['id'],
          ),
        ],
      ),
    );
  }
}
