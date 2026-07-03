import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ticket.dart';

abstract class TicketRepository {
  Future<Either<Failure, List<Ticket>>> getTickets();
  Future<Either<Failure, Ticket>> getTicketDetail(String id);
  Future<Either<Failure, Ticket>> createTicket(String title, String description, String priority, String creatorId, String creatorName, String? imagePath);
  Future<Either<Failure, Ticket>> updateTicketStatus(String id, String status, {String? assigneeId, String? assigneeName});
  Future<Either<Failure, TicketComment>> addComment(String ticketId, String userId, String userName, String message);
  Future<Either<Failure, void>> deleteTicket(String id);
}
