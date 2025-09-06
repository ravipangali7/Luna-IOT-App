import 'dart:convert';
import 'package:luna_iot/models/user_model.dart';

class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final User sentBy;
  final DateTime createdAt;
  final List<UserNotification>? userNotifications;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.sentBy,
    required this.createdAt,
    this.userNotifications,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      sentBy: json['sentBy'] != null
          ? User.fromJson(json['sentBy'] as Map<String, dynamic>)
          : User(
              id: 0,
              name: 'Unknown',
              phone: '',
              status: 'INACTIVE',
              role: Role.defaultRole(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      userNotifications: json['userNotifications'] != null
          ? (json['userNotifications'] as List)
                .map(
                  (item) =>
                      UserNotification.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'sentBy': sentBy.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'userNotifications': userNotifications
          ?.map((item) => item.toJson())
          .toList(),
    };
  }
}

class UserNotification {
  final int id;
  final User user;
  final Notification notification;
  final bool isRead;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.user,
    required this.notification,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : User(
              id: 0,
              name: 'Unknown',
              phone: '',
              status: 'INACTIVE',
              role: Role.defaultRole(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      notification: json['notification'] != null
          ? Notification.fromJson(json['notification'] as Map<String, dynamic>)
          : Notification(
              id: 0,
              title: '',
              message: '',
              type: '',
              sentBy: User(
                id: 0,
                name: 'Unknown',
                phone: '',
                status: 'INACTIVE',
                role: Role.defaultRole(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              createdAt: DateTime.now(),
            ),
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'notification': notification.toJson(),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
