import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_datasource.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Ticket>>> getTickets() async {
    try {
      final tickets = await remoteDataSource.getTickets();
      return Right(tickets);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ticket>> getTicketDetail(String id) async {
    try {
      final ticket = await remoteDataSource.getTicketDetail(id);
      return Right(ticket);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ticket>> createTicket(String title, String description, String priority, String creatorId, String creatorName, String? imagePath) async {
    try {
      final ticket = await remoteDataSource.createTicket(title, description, priority, creatorId, creatorName, imagePath);
      return Right(ticket);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ticket>> updateTicketStatus(String id, String status, {String? assigneeId, String? assigneeName}) async {
    try {
      final ticket = await remoteDataSource.updateTicketStatus(id, status, assigneeId: assigneeId, assigneeName: assigneeName);
      return Right(ticket);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TicketComment>> addComment(String ticketId, String userId, String userName, String message) async {
    try {
      final comment = await remoteDataSource.addComment(ticketId, userId, userName, message);
      return Right(comment);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTicket(String id) async {
    try {
      await remoteDataSource.deleteTicket(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
