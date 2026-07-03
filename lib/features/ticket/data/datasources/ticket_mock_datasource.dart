import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';

// Singleton in-memory database with Local Persistence fallback
class TicketMockDataSource {
  static final TicketMockDataSource _instance = TicketMockDataSource._internal();
  factory TicketMockDataSource() => _instance;
  TicketMockDataSource._internal();

  List<TicketModel> _tickets = [];
  SharedPreferences? _prefs;
  static const String _key = 'persisted_tickets';

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _saveToStorage() async {
    await _initPrefs();
    final jsonList = _tickets.map((t) => t.toJson()).toList();
    await _prefs!.setString(_key, jsonEncode(jsonList));
  }

  Future<void> _loadFromStorage() async {
    if (_tickets.isNotEmpty) return; // Already loaded

    await _initPrefs();
    final jsonString = _prefs!.getString(_key);
    
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      _tickets = decoded.map((item) => TicketModel.fromJson(item)).toList();
    } else {
      // Load default mock data if storage is empty
      _tickets = _getDefaultMocks();
    }
  }

  List<TicketModel> _getDefaultMocks() {
    final now = DateTime.now();
    return [
      TicketModel(
        id: 'mock-ticket-1',
        title: 'Aplikasi Error saat Login',
        description: 'Ketika saya mencoba login, selalu muncul error 500.',
        status: 'open',
        priority: 'high',
        creatorId: '2',
        creatorName: 'Fadhil Ilyas',
        createdAt: now.subtract(const Duration(hours: 2)),
        comments: [],
        history: [
          TicketHistoryModel(
            id: 'h-mock-1-1',
            ticketId: 'mock-ticket-1',
            userId: '2',
            userName: 'Fadhil Ilyas',
            action: 'dibuat',
            message: 'Tiket berhasil dibuat oleh Fadhil Ilyas',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      TicketModel(
        id: 'mock-ticket-2',
        title: 'Lupa Password tidak mengirim email',
        description: 'Saya sudah request reset password dari kemarin.',
        status: 'on progress',
        priority: 'medium',
        creatorId: '2',
        creatorName: 'Fadhil Ilyas',
        assigneeId: '1',
        assigneeName: 'Super Admin',
        createdAt: now.subtract(const Duration(days: 1)),
        comments: [
          TicketCommentModel(
            id: 'c1',
            ticketId: 'mock-ticket-2',
            userId: '1',
            userName: 'Super Admin',
            message: 'Halo, sedang kami cek masalah pada server SMTP.',
            createdAt: now.subtract(const Duration(hours: 10)),
          ),
        ],
        history: [
          TicketHistoryModel(
            id: 'h-mock-2-1',
            ticketId: 'mock-ticket-2',
            userId: '2',
            userName: 'Fadhil Ilyas',
            action: 'dibuat',
            message: 'Tiket berhasil dibuat oleh Fadhil Ilyas',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          TicketHistoryModel(
            id: 'h-mock-2-2',
            ticketId: 'mock-ticket-2',
            userId: '1',
            userName: 'Super Admin',
            action: 'ditugaskan',
            message: 'Tiket ditugaskan kepada Super Admin',
            createdAt: now.subtract(const Duration(hours: 12)),
          ),
          TicketHistoryModel(
            id: 'h-mock-2-3',
            ticketId: 'mock-ticket-2',
            userId: '1',
            userName: 'Super Admin',
            action: 'status_diubah',
            message: 'Status tiket diubah menjadi ON PROGRESS oleh Super Admin',
            createdAt: now.subtract(const Duration(hours: 12)),
          ),
          TicketHistoryModel(
            id: 'h-mock-2-4',
            ticketId: 'mock-ticket-2',
            userId: '1',
            userName: 'Super Admin',
            action: 'komentar_ditambahkan',
            message: 'Super Admin menambahkan komentar baru',
            createdAt: now.subtract(const Duration(hours: 10)),
          ),
        ],
      ),
    ];
  }

  Future<List<TicketModel>> getTickets() async {
    await _loadFromStorage();
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_tickets);
  }

  Future<TicketModel> getTicketDetail(String id) async {
    await _loadFromStorage();
    await Future.delayed(const Duration(milliseconds: 300));
    final ticket = _tickets.firstWhere((t) => t.id == id, orElse: () => throw Exception('Ticket not found'));
    return ticket;
  }

  Future<TicketModel> createTicket(String title, String description, String priority, String creatorId, String creatorName, String? imagePath) async {
    await _loadFromStorage();
    await Future.delayed(const Duration(seconds: 1));
    final ticketId = const Uuid().v4();
    final newHistory = TicketHistoryModel(
      id: const Uuid().v4(),
      ticketId: ticketId,
      userId: creatorId,
      userName: creatorName,
      action: 'dibuat',
      message: 'Tiket berhasil dibuat oleh $creatorName',
      createdAt: DateTime.now(),
    );
    final newTicket = TicketModel(
      id: ticketId,
      title: title,
      description: description,
      status: 'open',
      priority: priority,
      creatorId: creatorId,
      creatorName: creatorName,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      comments: [],
      history: [newHistory],
    );
    _tickets.add(newTicket);
    await _saveToStorage();
    return newTicket;
  }

  Future<TicketModel> updateTicketStatus(String id, String status, {String? assigneeId, String? assigneeName}) async {
    await _loadFromStorage();
    await Future.delayed(const Duration(seconds: 1));
    final index = _tickets.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final existing = _tickets[index];
      final List<TicketHistoryModel> updatedHistory = List.from(existing.history);
      
      String? newAssigneeId = assigneeId ?? existing.assigneeId;
      String? newAssigneeName = assigneeName ?? existing.assigneeName;
      
      // Jika penugasan berubah
      if (assigneeId != null && assigneeId != existing.assigneeId) {
        updatedHistory.add(TicketHistoryModel(
          id: const Uuid().v4(),
          ticketId: id,
          userId: assigneeId,
          userName: assigneeName ?? 'Petugas',
          action: 'ditugaskan',
          message: 'Tiket ditugaskan kepada ${assigneeName ?? 'Petugas'}',
          createdAt: DateTime.now(),
        ));
      }
      
      // Jika status berubah
      if (status != existing.status) {
        updatedHistory.add(TicketHistoryModel(
          id: const Uuid().v4(),
          ticketId: id,
          userId: assigneeId ?? 'system',
          userName: assigneeName ?? 'System',
          action: 'status_diubah',
          message: 'Status tiket diubah dari ${existing.status.toUpperCase()} menjadi ${status.toUpperCase()}',
          createdAt: DateTime.now(),
        ));
      }
      
      final updated = existing.copyWithModel(
        status: status, 
        assigneeId: newAssigneeId, 
        assigneeName: newAssigneeName,
        history: updatedHistory,
      );
      _tickets[index] = updated;
      await _saveToStorage();
      return updated;
    }
    throw Exception('Ticket not found');
  }

  Future<TicketCommentModel> addComment(String ticketId, String userId, String userName, String message) async {
    await _loadFromStorage();
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index >= 0) {
      final existing = _tickets[index];
      final newComment = TicketCommentModel(
        id: const Uuid().v4(),
        ticketId: ticketId,
        userId: userId,
        userName: userName,
        message: message,
        createdAt: DateTime.now(),
      );
      
      final currentComments = List<TicketCommentModel>.from(existing.comments)..add(newComment);
      
      final List<TicketHistoryModel> updatedHistory = List.from(existing.history);
      updatedHistory.add(TicketHistoryModel(
        id: const Uuid().v4(),
        ticketId: ticketId,
        userId: userId,
        userName: userName,
        action: 'komentar_ditambahkan',
        message: '$userName menambahkan komentar baru',
        createdAt: DateTime.now(),
      ));
      
      _tickets[index] = existing.copyWithModel(
        comments: currentComments,
        history: updatedHistory,
      );
      await _saveToStorage();
      return newComment;
    }
    throw Exception('Ticket not found');
  }

  Future<void> deleteTicket(String id) async {
    await _loadFromStorage();
    await Future.delayed(const Duration(milliseconds: 500));
    _tickets.removeWhere((t) => t.id == id);
    await _saveToStorage();
  }
}
