import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/banner_text_service.dart';

class BannerTextsAdminScreen extends StatefulWidget {
  const BannerTextsAdminScreen({super.key});

  @override
  State<BannerTextsAdminScreen> createState() => _BannerTextsAdminScreenState();
}

class _BannerTextsAdminScreenState extends State<BannerTextsAdminScreen> {
  final AdminBannerTextService _bannerTextService = AdminBannerTextService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _bannerTexts = [];
  bool _loading = true;
  Map<String, dynamic>? _editingBannerText;

  final _textController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fetchBannerTexts();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchBannerTexts() async {
    setState(() => _loading = true);
    try {
      final response = await _bannerTextService.getAll();
      setState(() {
        _bannerTexts = response['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching banner texts: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {'text': _textController.text, 'is_active': _isActive};

      if (_editingBannerText != null) {
        await _bannerTextService.update(_editingBannerText!['id'], data);
        _showSuccess('Banner text updated successfully');
      } else {
        await _bannerTextService.create(data);
        _showSuccess('Banner text created successfully');
      }

      _resetForm();
      _fetchBannerTexts();
      if( mounted ) Navigator.pop(context);
    } catch (e) {
      _showError('Error saving banner text: $e');
    }
  }

  void _handleEdit(Map<String, dynamic> bannerText) {
    _editingBannerText = bannerText;
    _textController.text = bannerText['text'] ?? '';
    _isActive = bannerText['is_active'] ?? true;
    _showBannerDialog();
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner Text'),
        content: const Text(
          'Are you sure you want to delete this banner text?',
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
        await _bannerTextService.delete(id);
        _showSuccess('Banner text deleted successfully');
        _fetchBannerTexts();
      } catch (e) {
        _showError('Error deleting banner text: $e');
      }
    }
  }

  void _resetForm() {
    _textController.clear();
    _isActive = true;
    _editingBannerText = null;
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
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editingBannerText != null
                          ? 'Edit Banner Text'
                          : 'Create New Banner Text',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Banner Text *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Maximum 1000 characters',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 4,
                      maxLength: 1000,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter banner text';
                        }
                        if (value.length > 1000) {
                          return 'Maximum 1000 characters allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Is Active',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Active banner texts are displayed to public',
                      ),
                      value: _isActive,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setStateDialog(() => _isActive = value);
                      },
                    ),
                    const SizedBox(height: 24),
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
                              _editingBannerText != null ? 'Update' : 'Create',
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
    return AdminLayout(
      title: 'Banner Texts',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _resetForm();
                    _showBannerDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Banner Text'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_bannerTexts.isEmpty)
              const Center(
                child: Text(
                  'No banner texts found',
                  style: TextStyle(fontSize: 16),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _bannerTexts.length,
                  itemBuilder: (context, index) {
                    final bannerText = _bannerTexts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        title: Text(
                          bannerText['text'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              bannerText['is_active'] == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: bannerText['is_active'] == true
                                  ? Colors.green
                                  : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              bannerText['is_active'] == true
                                  ? 'Active'
                                  : 'Inactive',
                              style: TextStyle(
                                color: bannerText['is_active'] == true
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.amber[600]),
                              onPressed: () => _handleEdit(bannerText),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _handleDelete(bannerText['id']),
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
    );
  }
}
