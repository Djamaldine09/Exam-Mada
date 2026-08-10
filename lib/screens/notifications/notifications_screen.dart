import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../model/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<AppNotification> _notifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiClient.get(ApiConfig.notifications);
      // Le backend renvoie { notifications: [...], unreadCount: n }
      final rawList = response is Map<String, dynamic>
          ? response['notifications'] as List<dynamic>? ?? []
          : (response as List<dynamic>? ?? []);
      final list = rawList.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      setState(() => _notifications = list);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.lue) return;
    try {
      await ApiClient.put(ApiConfig.notificationRead(n.id));
      setState(() {
        _notifications = _notifications
            .map((e) => e.id == n.id
                ? AppNotification(
                    id: e.id, titre: e.titre, message: e.message, type: e.type, lue: true, lien: e.lien, createdAt: e.createdAt)
                : e)
            .toList();
      });
    } catch (_) {
      // Échec silencieux : pas critique pour l'UX.
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'SUCCESS':
        return Icons.check_circle_outline;
      case 'WARNING':
        return Icons.warning_amber_outlined;
      case 'ERROR':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'SUCCESS':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Aucune notification', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          final color = _colorFor(n.type);
                          return InkWell(
                            onTap: () => _markAsRead(n),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n.lue ? Colors.white : color.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black.withOpacity(0.06)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                                    child: Icon(_iconFor(n.type), color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(n.titre.isEmpty ? 'Notification' : n.titre,
                                            style: TextStyle(
                                                fontWeight: n.lue ? FontWeight.w500 : FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text(n.message, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                        if (n.createdAt != null) ...[
                                          const SizedBox(height: 6),
                                          Text(n.createdAt.toString().split('.').first,
                                              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!n.lue)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}