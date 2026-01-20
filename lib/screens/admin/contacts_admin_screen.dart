import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/contact_service.dart';

class ContactsAdminScreen extends StatefulWidget {
  const ContactsAdminScreen({super.key});

  @override
  State<ContactsAdminScreen> createState() => _ContactsAdminScreenState();
}

class _ContactsAdminScreenState extends State<ContactsAdminScreen> {
  final AdminContactService _contactService = AdminContactService();

  List<dynamic> _contacts = [];
  bool _loading = true;
  bool _showDetailModal = false;
  Map<String, dynamic>? _viewingContact;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _loading = true);
    try {
      final response = await _contactService.getAll();
      setState(() {
        _contacts = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching contacts: $e');
    }
  }

  void _handleView(Map<String, dynamic> contact) {
    setState(() {
      _viewingContact = contact;
      _showDetailModal = true;
    });
    // Mark as read if not already read
    if (contact['is_read'] != true) {
      _handleMarkAsRead(contact['id']);
    }
  }

  Future<void> _handleMarkAsRead(int id) async {
    try {
      await _contactService.markAsRead(id);
      _fetchContacts();
    } catch (e) {
      _showError('Error marking contact as read: $e');
    }
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
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
        await _contactService.delete(id);
        _showSuccess('Contact deleted successfully');
        _fetchContacts();
      } catch (e) {
        _showError('Error deleting contact: $e');
      }
    }
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
    final unreadCount = _contacts.where((c) => c['is_read'] != true).length;

    return AdminLayout(
      title: 'Contacts',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount unread message${unreadCount > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.amber[700], fontSize: 14),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Expanded(
                    child: _contacts.isEmpty
                        ? const Center(child: Text('No contacts found'))
                        : ListView.builder(
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            final isRead = contact['is_read'] == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isRead ? Colors.white : Colors.amber[50],
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isRead ? Colors.grey[300] : Colors.amber[600],
                                  child: Icon(
                                    isRead ? Icons.mail_outline : Icons.mail,
                                    color: isRead ? Colors.grey[600] : Colors.white,
                                  ),
                                ),
                                title: Text(
                                  contact['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact['subject'] ?? 'No subject',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.email, size: 12, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            contact['email'] ?? '',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isRead)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.blue),
                                      onPressed: () => _handleView(contact),
                                      tooltip: 'View',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _handleDelete(contact['id']),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
              ],
            ),
          ),
          // Detail Modal
          if (_showDetailModal && _viewingContact != null)
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Contact Details',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _showDetailModal = false;
                                  _viewingContact = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Name', _viewingContact!['name'] ?? 'N/A'),
                              const SizedBox(height: 16),
                              _buildDetailRow('Email', _viewingContact!['email'] ?? 'N/A'),
                              const SizedBox(height: 16),
                              _buildDetailRow('Phone', _viewingContact!['phone'] ?? 'N/A'),
                              const SizedBox(height: 16),
                              _buildDetailRow('Subject', _viewingContact!['subject'] ?? 'N/A'),
                              const SizedBox(height: 16),
                              const Text(
                                'Message',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  _viewingContact!['message'] ?? 'No message',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                'Status',
                                _viewingContact!['is_read'] == true ? 'Read' : 'Unread',
                              ),
                            ],
                          ),
                        ),
                      ),
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
                                    _viewingContact = null;
                                  });
                                },
                                child: const Text('Close'),
                              ),
                            ),
                            if (_viewingContact!['is_read'] != true) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _handleMarkAsRead(_viewingContact!['id']);
                                    setState(() {
                                      _viewingContact!['is_read'] = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Mark as Read'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
