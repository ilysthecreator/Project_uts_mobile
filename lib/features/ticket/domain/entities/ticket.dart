class TicketComment {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;

  const TicketComment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });
}

class TicketHistory {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String action; // 'dibuat', 'status_diubah', 'ditugaskan', 'komentar_ditambahkan'
  final String message; // Pesan detail aktivitas
  final DateTime createdAt;

  const TicketHistory({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.message,
    required this.createdAt,
  });
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final String status; // 'pending', 'proses', 'selesai', 'batal'
  final String priority; // 'low', 'medium', 'high'
  final String creatorId;
  final String creatorName;
  final String? assigneeId;
  final String? assigneeName;
  final String? imagePath;
  final DateTime createdAt;
  final List<TicketComment> comments;
  final List<TicketHistory> history;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.priority = 'medium',
    required this.creatorId,
    required this.creatorName,
    this.assigneeId,
    this.assigneeName,
    this.imagePath,
    required this.createdAt,
    this.comments = const [],
    this.history = const [],
  });

  Ticket copyWith({
    String? status,
    String? priority,
    String? assigneeId,
    String? assigneeName,
    List<TicketComment>? comments,
    List<TicketHistory>? history,
  }) {
    return Ticket(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      creatorId: creatorId,
      creatorName: creatorName,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      imagePath: imagePath,
      createdAt: createdAt,
      comments: comments ?? this.comments,
      history: history ?? this.history,
    );
  }
}
