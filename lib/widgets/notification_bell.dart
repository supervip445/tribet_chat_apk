import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(
    BuildContext context,
    NotificationProvider notificationProvider,
  ) {
    _removeOverlay();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate position: align right edge of dropdown with right edge of screen (with padding)
    final dropdownWidth = 320.0;
    final rightPadding = 16.0; // Padding from right edge of screen
    final topPosition = offset.dy + size.height + 8;

    // Position dropdown on the right side
    final rightPosition = rightPadding;
    final maxHeight = screenHeight - topPosition - 16;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop to close on tap
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isOpen = false;
                });
                _removeOverlay();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // Notification dropdown - positioned on the right
          Positioned(
            right: rightPosition,
            top: topPosition,
            child: Material(
              elevation: 16,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black.withValues(alpha: 0.3),
              child: Container(
                width: dropdownWidth,
                constraints: BoxConstraints(
                  maxHeight: maxHeight > 400 ? 400 : maxHeight,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'အကြောင်းကြားချက်များ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (notificationProvider.unreadCount > 0)
                            TextButton(
                              onPressed: () {
                                notificationProvider.markAllAsRead();
                              },
                              child: const Text(
                                'အားလုံးဖတ်ပြီး',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Notifications list
                    Flexible(
                      child: notificationProvider.notifications.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: Text('အကြောင်းကြားချက် မရှိပါ'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount:
                                  notificationProvider.notifications.length,
                              itemBuilder: (context, index) {
                                final notification =
                                    notificationProvider.notifications[index];
                                return InkWell(
                                  onTap: () {
                                    notificationProvider.markAsRead(
                                      notification.id,
                                    );

                                    if (notification.route != null) {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(notification.route!);
                                    }

                                    setState(() {
                                      _isOpen = false;
                                    });
                                    _removeOverlay();
                                  },

                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: notification.read
                                          ? Colors.white
                                          : Colors.amber.shade50,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notification.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                notification.body,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                DateFormatUtil.formatNotificationDate(
                                                  notification.timestamp,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!notification.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Colors.amber,
                                              shape: BoxShape.circle,
                                            ),
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
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.grey[700],),
              onPressed: () {
                setState(() {
                  _isOpen = !_isOpen;
                });
                if (_isOpen) {
                  _showOverlay(context, notificationProvider);
                  if (notificationProvider.unreadCount > 0) {
                    notificationProvider.markAllAsRead();
                  }
                } else {
                  _removeOverlay();
                }
              },
            ),
            // Badge indicator - always show if there are unread notifications
            if (notificationProvider.unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: notificationProvider.unreadCount > 9 ? 5 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      notificationProvider.unreadCount > 99
                          ? '99+'
                          : notificationProvider.unreadCount > 9
                          ? '9+'
                          : notificationProvider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
