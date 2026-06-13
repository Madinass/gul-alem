import 'package:flutter/material.dart';

import '../notification_screen.dart';
import '../services/api_service.dart';

class NotificationBadgeButton extends StatefulWidget {
  final Color color;
  final double size;
  final EdgeInsetsGeometry padding;

  const NotificationBadgeButton({
    super.key,
    this.color = Colors.black,
    this.size = 28,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<NotificationBadgeButton> createState() =>
      _NotificationBadgeButtonState();
}

class _NotificationBadgeButtonState extends State<NotificationBadgeButton>
    with WidgetsBindingObserver {
  int _unreadCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUnreadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnreadCount();
    }
  }

  Future<void> _refreshUnreadCount() async {
    if (_loading) return;
    _loading = true;
    try {
      final notifications = await ApiService.fetchNotifications();
      final unreadCount = notifications.where((item) => !item.read).length;
      if (!mounted) return;
      setState(() => _unreadCount = unreadCount);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unreadCount = 0);
    } finally {
      _loading = false;
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
    if (mounted) {
      _refreshUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: widget.padding,
      onPressed: _openNotifications,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none,
            color: widget.color,
            size: widget.size,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60064),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
