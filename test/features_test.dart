import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_uts/features/auth/presentation/providers/auth_provider.dart';
import 'package:project_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:project_uts/features/notification/presentation/providers/notification_provider.dart';
import 'package:project_uts/features/auth/domain/entities/user.dart';
import 'package:project_uts/features/ticket/domain/entities/ticket.dart';
import 'package:project_uts/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:project_uts/features/auth/data/models/user_model.dart';
import 'package:project_uts/features/ticket/data/datasources/ticket_remote_datasource.dart';
import 'package:project_uts/features/ticket/data/models/ticket_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:project_uts/core/constants/supabase_constants.dart';

// --- FAKES FOR HERMETIC TESTING ---

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  final List<UserModel> _users = [
    const UserModel(id: '1', name: 'Super Admin', username: 'admin', role: 'admin', isActive: true),
    const UserModel(id: '2', name: 'Fadhil Ilyas', username: 'user', role: 'user', isActive: true),
    const UserModel(id: '3', name: 'Helpdesk 1', username: 'helpdesk1', role: 'helpdesk', isActive: true),
    const UserModel(id: '4', name: 'Helpdesk 2', username: 'helpdesk2', role: 'helpdesk', isActive: true),
    const UserModel(id: '5', name: 'Inactive User', username: 'inactive', role: 'user', isActive: false),
  ];

  @override
  Future<List<UserModel>> getUsers() async => _users;

  @override
  Future<UserModel> login(String username, String password) async => _users.firstWhere((u) => u.username == username);

  @override
  Future<UserModel> register(String username, String password, String name) async {
    final newUser = UserModel(id: DateTime.now().toString(), name: name, username: username, role: 'user', isActive: true);
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      _users[idx] = UserModel(
        id: _users[idx].id,
        name: _users[idx].name,
        username: _users[idx].username,
        role: _users[idx].role,
        isActive: isActive,
      );
    }
  }

  @override
  Future<UserModel> updateProfile(String userId, String name, String username) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    _users[idx] = UserModel(id: userId, name: name, username: username, role: _users[idx].role, isActive: _users[idx].isActive);
    return _users[idx];
  }
}

class FakeTicketRemoteDataSource implements TicketRemoteDataSource {
  final List<TicketModel> _tickets = [];

  @override
  Future<List<TicketModel>> getTickets() async => _tickets;

  @override
  Future<TicketModel> getTicketDetail(String id) async => _tickets.firstWhere((t) => t.id == id);

  @override
  Future<TicketModel> createTicket(String title, String description, String priority, String creatorId, String creatorName, String? imagePath) async {
    final id = DateTime.now().toString();
    final newTicket = TicketModel(
      id: id,
      title: title,
      description: description,
      status: 'open',
      priority: priority,
      creatorId: creatorId,
      creatorName: creatorName,
      createdAt: DateTime.now(),
      imagePath: imagePath,
      comments: const [],
      history: [
        TicketHistoryModel(
          id: 'h-$id',
          ticketId: id,
          userId: creatorId,
          userName: creatorName,
          action: 'dibuat',
          message: 'Tiket berhasil dibuat oleh $creatorName',
          createdAt: DateTime.now(),
        )
      ],
    );
    _tickets.add(newTicket);
    return newTicket;
  }

  @override
  Future<TicketModel> updateTicketStatus(String id, String status, {String? assigneeId, String? assigneeName}) async {
    final idx = _tickets.indexWhere((t) => t.id == id);
    final existing = _tickets[idx];
    
    final List<TicketHistoryModel> updatedHistory = List.from(existing.history);
    if (assigneeId != null && assigneeId != existing.assigneeId) {
      updatedHistory.add(TicketHistoryModel(
        id: 'h-assign-$id',
        ticketId: id,
        userId: assigneeId,
        userName: assigneeName ?? 'Petugas',
        action: 'ditugaskan',
        message: 'Tiket ditugaskan kepada ${assigneeName ?? 'Petugas'}',
        createdAt: DateTime.now(),
      ));
    }
    if (status != existing.status) {
      updatedHistory.add(TicketHistoryModel(
        id: 'h-status-$id',
        ticketId: id,
        userId: assigneeId ?? existing.creatorId,
        userName: assigneeName ?? existing.creatorName,
        action: 'status_diubah',
        message: 'Status tiket diubah dari ${existing.status.toUpperCase()} menjadi ${status.toUpperCase()}',
        createdAt: DateTime.now(),
      ));
    }

    final updated = TicketModel(
      id: existing.id,
      title: existing.title,
      description: existing.description,
      status: status,
      priority: existing.priority,
      creatorId: existing.creatorId,
      creatorName: existing.creatorName,
      assigneeId: assigneeId ?? existing.assigneeId,
      assigneeName: assigneeName ?? existing.assigneeName,
      createdAt: existing.createdAt,
      comments: existing.comments,
      history: updatedHistory,
    );
    _tickets[idx] = updated;
    return updated;
  }

  @override
  Future<TicketCommentModel> addComment(String ticketId, String userId, String userName, String message) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    final existing = _tickets[idx];
    final comment = TicketCommentModel(
      id: DateTime.now().toString(),
      ticketId: ticketId,
      userId: userId,
      userName: userName,
      message: message,
      createdAt: DateTime.now(),
    );
    final updatedComments = List<TicketCommentModel>.from(existing.comments)..add(comment);
    final updatedHistory = List<TicketHistoryModel>.from(existing.history)..add(TicketHistoryModel(
      id: 'h-comment-${comment.id}',
      ticketId: ticketId,
      userId: userId,
      userName: userName,
      action: 'komentar_ditambahkan',
      message: '$userName menambahkan komentar baru',
      createdAt: DateTime.now(),
    ));

    _tickets[idx] = TicketModel(
      id: existing.id,
      title: existing.title,
      description: existing.description,
      status: existing.status,
      priority: existing.priority,
      creatorId: existing.creatorId,
      creatorName: existing.creatorName,
      assigneeId: existing.assigneeId,
      assigneeName: existing.assigneeName,
      createdAt: existing.createdAt,
      comments: updatedComments,
      history: updatedHistory,
    );
    return comment;
  }

  @override
  Future<void> deleteTicket(String id) async {
    _tickets.removeWhere((t) => t.id == id);
  }
}

class FakeNotificationNotifier extends NotificationNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(id: '1', title: 'Status Tiket Diperbarui', body: 'Tiket #1 diubah statusnya', createdAt: DateTime.now(), isRead: false, type: 'status', ticketId: 'test-1'),
    AppNotification(id: '2', title: 'Komentar Baru', body: 'Ada komentar baru', createdAt: DateTime.now(), isRead: false, type: 'comment', ticketId: 'test-2'),
    AppNotification(id: '3', title: 'Tiket Baru', body: 'Tiket baru dibuat', createdAt: DateTime.now(), isRead: false, type: 'created', ticketId: 'test-3'),
  ];

  @override
  NotificationState build() {
    state = NotificationState(notifications: _notifications);
    return state;
  }

  @override
  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
    required String ticketId,
    String? userId,
  }) async {
    final newNotif = AppNotification(
      id: DateTime.now().toString(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
      type: type,
      ticketId: ticketId,
    );
    _notifications.insert(0, newNotif);
    state = state.copyWith(notifications: List.from(_notifications));
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    state = state.copyWith(notifications: List.from(_notifications));
  }
}

void main() {
  // Setup mock SharedPreferences
  late SharedPreferences prefs;

  setUpAll(() async {
    // Inisialisasi binding testing dan mock SharedPreferences sebelum Supabase
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    // Inisialisasi Supabase untuk testing
    await Supabase.initialize(
      url: SupabaseConstants.url,
      publishableKey: SupabaseConstants.anonKey,
    );
  });

  setUp(() async {
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSource()),
        ticketDataSourceProvider.overrideWithValue(FakeTicketRemoteDataSource()),
        notificationNotifierProvider.overrideWith(() => FakeNotificationNotifier()),
      ],
    );
  }

  group('Uji Coba Fitur Notifikasi (FR-008, BR-003)', () {
    test('Harus memuat notifikasi default dan mendukung penambahan notifikasi baru', () async {
      final container = createContainer();
      
      // Ambil notifier
      final notifier = container.read(notificationNotifierProvider.notifier);
      
      // Tunggu inisialisasi selesai
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 1. Verifikasi notifikasi awal (default seed data)
      var state = container.read(notificationNotifierProvider);
      expect(state.notifications.length, equals(3));
      expect(state.notifications[0].title, equals('Status Tiket Diperbarui'));
      expect(state.notifications[0].isRead, isFalse);

      // 2. Tambah notifikasi baru
      await notifier.addNotification(
        title: 'Tiket Baru',
        body: 'Tiket printer macet berhasil dibuat',
        type: 'created',
        ticketId: 'test-id-123',
      );

      state = container.read(notificationNotifierProvider);
      expect(state.notifications.length, equals(4));
      expect(state.notifications[0].title, equals('Tiket Baru'));
      expect(state.notifications[0].isRead, isFalse);

      // 3. Tandai semua sebagai dibaca
      await notifier.markAllAsRead();
      state = container.read(notificationNotifierProvider);
      expect(state.notifications.every((n) => n.isRead), isTrue);
    });
  });

  group('Uji Coba Kelola Pengguna oleh Admin (FR-007.7, BR-002.9)', () {
    test('Harus memuat daftar pengguna dan mendukung perubahan status keaktifan user', () async {
      final container = createContainer();
      final notifier = container.read(userManagementNotifierProvider.notifier);

      // Tunggu inisialisasi selesai
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. Verifikasi daftar user awal (default seed data)
      var state = container.read(userManagementNotifierProvider);
      expect(state.users.length, equals(5));
      expect(state.users.any((u) => u.username == 'user'), isTrue);

      // Ambil user biasa
      final targetUser = state.users.firstWhere((u) => u.username == 'user');
      expect(targetUser.isActive, isTrue);

      // 2. Nonaktifkan user
      final success = await notifier.toggleUserStatus(targetUser.id, false);
      expect(success, isTrue);

      state = container.read(userManagementNotifierProvider);
      final updatedUser = state.users.firstWhere((u) => u.id == targetUser.id);
      expect(updatedUser.isActive, isFalse);
    });
  });

  group('Uji Coba Riwayat & Lacak Tiket (FR-010, FR-011, BR-005, BR-002)', () {
    test('Harus mendukung pembuatan tiket, perubahan status, komentar, dan mencatat riwayat log otomatis', () async {
      final container = createContainer();
      final listNotifier = container.read(ticketListNotifierProvider.notifier);

      // Tunggu inisialisasi selesai
      await Future.delayed(const Duration(milliseconds: 600));

      var state = container.read(ticketListNotifierProvider);
      final initialCount = state.tickets.length;

      // 1. Buat tiket baru
      final createSuccess = await listNotifier.createTicket(
        'Server Hang',
        'Server utama mati tiba-tiba',
        'high',
        '2',
        'Fadhil Ilyas',
        null,
      );
      expect(createSuccess, isTrue);

      state = container.read(ticketListNotifierProvider);
      expect(state.tickets.length, equals(initialCount + 1));

      // Ambil tiket yang baru dibuat (paling atas)
      final newTicket = state.tickets.first;
      expect(newTicket.title, equals('Server Hang'));
      
      // Verifikasi riwayat pembuatan otomatis tercatat
      expect(newTicket.history.length, equals(1));
      expect(newTicket.history[0].action, equals('dibuat'));
      expect(newTicket.history[0].message, contains('Fadhil Ilyas'));

      // 2. Ubah status tiket & verifikasi riwayat tercatat
      final updateSuccess = await listNotifier.updateStatus(
        newTicket.id,
        'on progress',
        assigneeId: '1',
        assigneeName: 'Super Admin',
      );
      expect(updateSuccess, isTrue);
 
      state = container.read(ticketListNotifierProvider);
      final inProgressTicket = state.tickets.firstWhere((t) => t.id == newTicket.id);
      expect(inProgressTicket.status, equals('on progress'));
      expect(inProgressTicket.assigneeName, equals('Super Admin'));
      
      // Harus ada 3 log riwayat sekarang: 1 dibuat, 1 ditugaskan, 1 status_diubah
      expect(inProgressTicket.history.length, equals(3));
      expect(inProgressTicket.history.any((h) => h.action == 'ditugaskan'), isTrue);
      expect(inProgressTicket.history.any((h) => h.action == 'status_diubah'), isTrue);

      // 3. Tambah komentar & verifikasi riwayat tercatat
      final commentSuccess = await listNotifier.addComment(
        newTicket.id,
        '1',
        'Super Admin',
        'Sedang diperbaiki',
      );
      expect(commentSuccess, isTrue);

      state = container.read(ticketListNotifierProvider);
      final commentedTicket = state.tickets.firstWhere((t) => t.id == newTicket.id);
      expect(commentedTicket.comments.length, equals(1));
      expect(commentedTicket.comments[0].message, equals('Sedang diperbaiki'));
      
      // Harus ada log komentar di riwayat
      expect(commentedTicket.history.length, equals(4));
      expect(commentedTicket.history.last.action, equals('komentar_ditambahkan'));

      // 4. Hapus tiket (BR-002.8)
      final deleteSuccess = await listNotifier.deleteTicket(newTicket.id);
      expect(deleteSuccess, isTrue);

      state = container.read(ticketListNotifierProvider);
      expect(state.tickets.length, equals(initialCount));
      expect(state.tickets.any((t) => t.id == newTicket.id), isFalse);
    });
  });
}
