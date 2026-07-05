import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

// --- Injection Providers ---
final ticketDataSourceProvider = Provider<TicketRemoteDataSource>((ref) {
  return TicketRemoteDataSourceImpl();
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepositoryImpl(
    remoteDataSource: ref.watch(ticketDataSourceProvider),
  );
});

// --- State Classes ---
class TicketListState {
  final bool isLoading;
  final List<Ticket> tickets;
  final String? errorMessage;
  final String filterStatus; // 'semua', 'open', 'assign', 'on progress', 'close'
  final String searchQuery;
  final bool isDescending;

  const TicketListState({
    this.isLoading = false,
    this.tickets = const [],
    this.errorMessage,
    this.filterStatus = 'semua',
    this.searchQuery = '',
    this.isDescending = true,
  });

  TicketListState copyWith({
    bool? isLoading,
    List<Ticket>? tickets,
    String? errorMessage,
    String? filterStatus,
    String? searchQuery,
    bool? isDescending,
  }) {
    return TicketListState(
      isLoading: isLoading ?? this.isLoading,
      tickets: tickets ?? this.tickets,
      errorMessage: errorMessage,
      filterStatus: filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      isDescending: isDescending ?? this.isDescending,
    );
  }

  List<Ticket> get filteredTickets {
    List<Ticket> list = List.from(tickets);
    
    // Filter by status
    if (filterStatus != 'semua') {
      list = list.where((t) => t.status == filterStatus).toList();
    }
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((t) => 
        t.title.toLowerCase().contains(query) || 
        t.description.toLowerCase().contains(query)
      ).toList();
    }
    
    // Sort
    list.sort((a, b) => isDescending 
      ? b.createdAt.compareTo(a.createdAt) 
      : a.createdAt.compareTo(b.createdAt));
      
    return list;
  }
}

// --- Notifiers ---
class TicketListNotifier extends Notifier<TicketListState> {
  late TicketRepository _repository;
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  RealtimeChannel? _ticketsRealtimeChannel;

  @override
  TicketListState build() {
    _repository = ref.watch(ticketRepositoryProvider);
    
    // Subscribe to realtime database changes for tickets
    _subscribeToTicketsRealtime();

    ref.onDispose(() {
      _unsubscribeFromTicketsRealtime();
    });

    Future.microtask(() => loadTickets());
    return const TicketListState();
  }

  void _subscribeToTicketsRealtime() {
    _unsubscribeFromTicketsRealtime();

    // Dengarkan perubahan pada tabel tickets dan ticket_comments agar UI list & detail terupdate live
    _ticketsRealtimeChannel = _supabaseClient
        .channel('public:tickets_and_comments_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            loadTickets();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ticket_comments',
          callback: (payload) {
            loadTickets();
            // Invalidate detail tiket yang aktif agar obrolan komentar langsung muncul
            if (payload.newRecord.isNotEmpty) {
              final ticketId = payload.newRecord['ticket_id'] as String?;
              if (ticketId != null) {
                ref.invalidate(ticketDetailProvider(ticketId));
              }
            }
          },
        );

    _ticketsRealtimeChannel?.subscribe();
  }

  void _unsubscribeFromTicketsRealtime() {
    if (_ticketsRealtimeChannel != null) {
      _supabaseClient.removeChannel(_ticketsRealtimeChannel!);
      _ticketsRealtimeChannel = null;
    }
  }

  Future<void> loadTickets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getTickets();
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (tickets) => state = state.copyWith(isLoading: false, tickets: List.from(tickets)),
    );
  }

  void setFilter(String status) {
    state = state.copyWith(filterStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSortOrder() {
    state = state.copyWith(isDescending: !state.isDescending);
  }

  Future<bool> createTicket(String title, String desc, String priority, String creatorId, String creatorName, String? imagePath) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.createTicket(title, desc, priority, creatorId, creatorName, imagePath);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (newTicket) {
        final updatedList = List<Ticket>.from(state.tickets)..insert(0, newTicket);
        state = state.copyWith(isLoading: false, tickets: updatedList);
        
        // Pemicu Notifikasi Dinamis (Kirim ke pembuat tiket bahwa tiket berhasil dibuat)
        ref.read(notificationNotifierProvider.notifier).addNotification(
          title: 'Tiket Baru Berhasil Dibuat',
          body: 'Tiket #${newTicket.id.substring(0, 8).toUpperCase()} - ${newTicket.title} telah berhasil dibuat.',
          type: 'created',
          ticketId: newTicket.id,
          userId: newTicket.creatorId,
        );
        
        return true;
      },
    );
  }

  Future<bool> updateStatus(String id, String status, {String? assigneeId, String? assigneeName}) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.updateTicketStatus(id, status, assigneeId: assigneeId, assigneeName: assigneeName);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (updatedTicket) {
        final index = state.tickets.indexWhere((t) => t.id == id);
        if (index >= 0) {
          final newList = List<Ticket>.from(state.tickets);
          newList[index] = updatedTicket;
          state = state.copyWith(isLoading: false, tickets: newList);
        } else {
           state = state.copyWith(isLoading: false);
        }
        
        // Pemicu Notifikasi Dinamis (Kirim ke pembuat tiket)
        final ticket = state.tickets.firstWhere((t) => t.id == id);
        ref.read(notificationNotifierProvider.notifier).addNotification(
          title: 'Status Tiket Diperbarui',
          body: 'Tiket #${id.substring(0, 8).toUpperCase()} diubah statusnya menjadi ${status.toUpperCase()}',
          type: 'status',
          ticketId: id,
          userId: ticket.creatorId,
        );
        
        // Pemicu Notifikasi ke Petugas (Jika ada penugasan baru)
        if (assigneeId != null) {
          ref.read(notificationNotifierProvider.notifier).addNotification(
            title: 'Penugasan Tiket Baru',
            body: 'Anda telah ditugaskan untuk menangani Tiket #${id.substring(0, 8).toUpperCase()} - ${ticket.title}.',
            type: 'status',
            ticketId: id,
            userId: assigneeId,
          );
        }
        
        return true;
      },
    );
  }

  Future<bool> addComment(String ticketId, String userId, String userName, String message) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.addComment(ticketId, userId, userName, message);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (newComment) {
        final index = state.tickets.indexWhere((t) => t.id == ticketId);
        if (index >= 0) {
          final ticket = state.tickets[index];
          final currentComments = List<TicketComment>.from(ticket.comments)..add(newComment);
          final currentHistory = List<TicketHistory>.from(ticket.history)
            ..add(TicketHistory(
              id: newComment.id,
              ticketId: ticketId,
              userId: userId,
              userName: userName,
              action: 'komentar_ditambahkan',
              message: '$userName menambahkan komentar baru',
              createdAt: newComment.createdAt,
            ));
          final newList = List<Ticket>.from(state.tickets);
          newList[index] = ticket.copyWith(
            comments: currentComments,
            history: currentHistory,
          );
          state = state.copyWith(isLoading: false, tickets: newList);
          
          // Pemicu Notifikasi Dinamis (Kirim ke pihak lawan)
          final targetUserId = userId == ticket.creatorId ? ticket.assigneeId : ticket.creatorId;
          if (targetUserId != null) {
            ref.read(notificationNotifierProvider.notifier).addNotification(
              title: 'Komentar Baru',
              body: '$userName mengomentari tiket #${ticketId.substring(0, 8).toUpperCase()}',
              type: 'comment',
              ticketId: ticketId,
              userId: targetUserId,
            );
          }
        } else {
          state = state.copyWith(isLoading: false);
        }

        return true;
      },
    );
  }

  Future<bool> deleteTicket(String id) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.deleteTicket(id);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        final newList = state.tickets.where((t) => t.id != id).toList();
        state = state.copyWith(isLoading: false, tickets: newList);
        return true;
      },
    );
  }
}

// --- Providers ---
final ticketListNotifierProvider = NotifierProvider<TicketListNotifier, TicketListState>(() {
  return TicketListNotifier();
});

// A provider for fetching detail dynamically
final ticketDetailProvider = FutureProvider.family<Ticket, String>((ref, id) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final result = await repo.getTicketDetail(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (ticket) => ticket,
  );
});
