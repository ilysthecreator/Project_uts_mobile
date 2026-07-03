import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/ticket.dart';

part 'ticket_model.g.dart';

@JsonSerializable()
class TicketCommentModel extends TicketComment {
  const TicketCommentModel({
    required super.id,
    required super.ticketId,
    required super.userId,
    required super.userName,
    required super.message,
    required super.createdAt,
  });

  factory TicketCommentModel.fromJson(Map<String, dynamic> json) => _$TicketCommentModelFromJson(json);
  Map<String, dynamic> toJson() => _$TicketCommentModelToJson(this);
}

@JsonSerializable()
class TicketHistoryModel extends TicketHistory {
  const TicketHistoryModel({
    required super.id,
    required super.ticketId,
    required super.userId,
    required super.userName,
    required super.action,
    required super.message,
    required super.createdAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) => _$TicketHistoryModelFromJson(json);
  Map<String, dynamic> toJson() => _$TicketHistoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TicketModel extends Ticket {
  @override
  @JsonKey(defaultValue: [])
  final List<TicketCommentModel> comments;

  @override
  @JsonKey(defaultValue: [])
  final List<TicketHistoryModel> history;

  const TicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    super.priority = 'medium',
    required super.creatorId,
    required super.creatorName,
    super.assigneeId,
    super.assigneeName,
    super.imagePath,
    required super.createdAt,
    this.comments = const [],
    this.history = const [],
  }) : super(comments: comments, history: history);

  factory TicketModel.fromJson(Map<String, dynamic> json) => _$TicketModelFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TicketModelToJson(this);

  TicketModel copyWithModel({
    String? status,
    String? priority,
    String? assigneeId,
    String? assigneeName,
    List<TicketCommentModel>? comments,
    List<TicketHistoryModel>? history,
  }) {
    return TicketModel(
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
