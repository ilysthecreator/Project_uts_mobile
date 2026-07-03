// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketCommentModel _$TicketCommentModelFromJson(Map<String, dynamic> json) =>
    TicketCommentModel(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TicketCommentModelToJson(TicketCommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticketId': instance.ticketId,
      'userId': instance.userId,
      'userName': instance.userName,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
    };

TicketHistoryModel _$TicketHistoryModelFromJson(Map<String, dynamic> json) =>
    TicketHistoryModel(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      action: json['action'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TicketHistoryModelToJson(TicketHistoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticketId': instance.ticketId,
      'userId': instance.userId,
      'userName': instance.userName,
      'action': instance.action,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
    };

TicketModel _$TicketModelFromJson(Map<String, dynamic> json) => TicketModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  status: json['status'] as String,
  priority: json['priority'] as String? ?? 'medium',
  creatorId: json['creatorId'] as String,
  creatorName: json['creatorName'] as String,
  assigneeId: json['assigneeId'] as String?,
  assigneeName: json['assigneeName'] as String?,
  imagePath: json['imagePath'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  comments:
      (json['comments'] as List<dynamic>?)
          ?.map((e) => TicketCommentModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => TicketHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$TicketModelToJson(TicketModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'priority': instance.priority,
      'creatorId': instance.creatorId,
      'creatorName': instance.creatorName,
      'assigneeId': instance.assigneeId,
      'assigneeName': instance.assigneeName,
      'imagePath': instance.imagePath,
      'createdAt': instance.createdAt.toIso8601String(),
      'comments': instance.comments.map((e) => e.toJson()).toList(),
      'history': instance.history.map((e) => e.toJson()).toList(),
    };
