import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/notification_model.dart';
import '../../../models/user_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        UserModel? userModel = await _authService.getUserById(user.uid);
        setState(() {
          _currentUser = userModel;
        });
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _notificationService.markAllNotificationsAsRead(
                    _currentUser!.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Mark All Read'),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService.getUserNotifications(
                _currentUser!.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<AppNotification> notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'You\'ll see notifications here when they arrive',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    AppNotification notification = notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      onTap: () async {
                        await _notificationService.markNotificationAsRead(
                          notification.id,
                        );
                      },
                      onDelete: () async {
                        await _notificationService.deleteNotification(
                          notification.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: notification.status == NotificationStatus.unread ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _getNotificationColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getNotificationIcon(),
                  size: 20.sp,
                  color: _getNotificationColor(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight:
                                  notification.status ==
                                          NotificationStatus.unread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        if (notification.status == NotificationStatus.unread)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.typeDisplayName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _getNotificationColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.requestAssigned:
        return Colors.blue;
      case NotificationType.requestAccepted:
        return Colors.green;
      case NotificationType.requestDeclined:
        return Colors.red;
      case NotificationType.requestStatusUpdate:
        return Colors.orange;
      case NotificationType.newMessage:
        return Colors.purple;
      case NotificationType.driverOutForCollection:
        return Colors.teal;
      case NotificationType.cargoCollected:
        return Colors.green[700]!;
      case NotificationType.customerNotAvailable:
        return Colors.red[700]!;
      case NotificationType.systemAlert:
        return Colors.grey[600]!;
    }
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.requestAssigned:
        return Icons.assignment_ind;
      case NotificationType.requestAccepted:
        return Icons.check_circle;
      case NotificationType.requestDeclined:
        return Icons.cancel;
      case NotificationType.requestStatusUpdate:
        return Icons.update;
      case NotificationType.newMessage:
        return Icons.chat;
      case NotificationType.driverOutForCollection:
        return Icons.local_shipping;
      case NotificationType.cargoCollected:
        return Icons.inventory;
      case NotificationType.customerNotAvailable:
        return Icons.person_off;
      case NotificationType.systemAlert:
        return Icons.warning;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
