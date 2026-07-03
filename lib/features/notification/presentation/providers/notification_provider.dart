import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'status', 'comment', 'created'
  final String ticketId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    required this.ticketId,
  });

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
      ticketId: ticketId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type,
      'ticket_id': ticketId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool,
      type: json['type'] as String,
      ticketId: json['ticket_id'] as String,
    );
  }
}

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  @override
  NotificationState build() {
    // Listen to Auth State changes to reload notifications
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.user != null) {
        _loadFromDatabase();
      } else {
        state = const NotificationState();
      }
    });

    Future.microtask(() => _loadFromDatabase());
    return const NotificationState();
  }

  Future<void> _loadFromDatabase() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) {
      state = const NotificationState();
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(notifications: [], isLoading: false);
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
    required String ticketId,
    String? userId,
  }) async {
    final targetUserId = userId ?? ref.read(authNotifierProvider).user?.id;
    if (targetUserId == null) return;

    try {
      final response = await _supabaseClient
          .from('notifications')
          .insert({
            'user_id': targetUserId,
            'title': title,
            'body': body,
            'type': type,
            'ticket_id': ticketId,
          })
          .select()
          .single();

      // Jika user yang aktif saat ini sama dengan target penerima notifikasi, update UI
      final currentUser = ref.read(authNotifierProvider).user;
      if (currentUser != null && currentUser.id == targetUserId) {
        final newNotif = AppNotification.fromJson(response as Map<String, dynamic>);
        final updatedList = List<AppNotification>.from(state.notifications)..insert(0, newNotif);
        state = state.copyWith(notifications: updatedList);
      }
    } catch (e) {
      // Gagal menyimpan ke database
    }
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    try {
      await _supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id);

      final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      // Gagal update database
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);

      final updatedList = state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      // Gagal update database
    }
  }
}

final notificationNotifierProvider = NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});
