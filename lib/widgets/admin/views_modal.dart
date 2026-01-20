import 'package:flutter/material.dart';
import '../../services/admin/view_service.dart';
import 'package:intl/intl.dart';

class ViewsModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String? viewableType;
  final int? viewableId;

  const ViewsModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.viewableType,
    this.viewableId,
  });

  @override
  State<ViewsModal> createState() => _ViewsModalState();
}

class _ViewsModalState extends State<ViewsModal> {
  final AdminViewService _viewService = AdminViewService();
  List<dynamic> _views = [];
  Map<String, dynamic>? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen && widget.viewableType != null && widget.viewableId != null) {
      _fetchViews();
    }
  }

  @override
  void didUpdateWidget(ViewsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && 
        widget.viewableType != null && 
        widget.viewableId != null &&
        (oldWidget.viewableId != widget.viewableId || !oldWidget.isOpen)) {
      _fetchViews();
    }
  }

  Future<void> _fetchViews() async {
    if (widget.viewableType == null || widget.viewableId == null) return;

    setState(() => _loading = true);
    try {
      final response = await _viewService.getViews(widget.viewableType!, widget.viewableId!);
      setState(() {
        _views = response['data'] ?? [];
        _stats = response['stats'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading view data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'View Statistics & IP Addresses',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const Divider(),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics
                        if (_stats != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Views',
                                  value: '${_stats!['total_views'] ?? 0}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  title: 'Unique IPs',
                                  value: '${_stats!['unique_ips'] ?? 0}',
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  title: 'Views (24h)',
                                  value: '${_stats!['recent_views_24h'] ?? 0}',
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        // IP Addresses Table
                        const Text(
                          'IP Addresses',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _views.isEmpty
                              ? const Center(child: Text('No views recorded yet'))
                              : ListView.builder(
                                  itemCount: _views.length,
                                  itemBuilder: (context, index) {
                                    final view = _views[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(
                                          view['ip_address'] ?? 'N/A',
                                          style: const TextStyle(fontFamily: 'monospace'),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              view['user_agent'] ?? 'N/A',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              view['created_at'] != null
                                                  ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                                      .format(DateTime.parse(view['created_at']))
                                                  : 'N/A',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

