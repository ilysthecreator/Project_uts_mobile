import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
 
abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets();
  Future<TicketModel> getTicketDetail(String id);
  Future<TicketModel> createTicket(
    String title,
    String description,
    String priority,
    String creatorId,
    String creatorName,
    String? imagePath,
  );
  Future<TicketModel> updateTicketStatus(
    String id,
    String status, {
    String? assigneeId,
    String? assigneeName,
  });
  Future<TicketCommentModel> addComment(
    String ticketId,
    String userId,
    String userName,
    String message,
  );
  Future<void> deleteTicket(String id);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final SupabaseClient _supabaseClient;

  TicketRemoteDataSourceImpl({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  Map<String, dynamic> _normalizeTicketJson(Map<String, dynamic> json) {
    // Menyesuaikan nama key dari tabel PostgreSQL ke model Dart
    final normalized = Map<String, dynamic>.from(json);
    
    // Mengubah snake_case ke camelCase jika diperlukan oleh json_serializable
    normalized['creatorId'] = json['creator_id'];
    normalized['creatorName'] = json['creator_name'];
    normalized['assigneeId'] = json['assignee_id'];
    normalized['assigneeName'] = json['assignee_name'];
    normalized['imagePath'] = json['image_path'];
    normalized['createdAt'] = json['created_at'];

    // Map tabel relasi ke key model
    if (json.containsKey('ticket_comments')) {
      normalized['comments'] = (json['ticket_comments'] as List<dynamic>).map((c) {
        final commentMap = Map<String, dynamic>.from(c);
        commentMap['ticketId'] = c['ticket_id'];
        commentMap['userId'] = c['user_id'];
        commentMap['userName'] = c['user_name'];
        commentMap['createdAt'] = c['created_at'];
        return commentMap;
      }).toList();
    } else {
      normalized['comments'] = [];
    }

    if (json.containsKey('ticket_history')) {
      normalized['history'] = (json['ticket_history'] as List<dynamic>).map((h) {
        final historyMap = Map<String, dynamic>.from(h);
        historyMap['ticketId'] = h['ticket_id'];
        historyMap['userId'] = h['user_id'];
        historyMap['userName'] = h['user_name'];
        historyMap['createdAt'] = h['created_at'];
        return historyMap;
      }).toList();
    } else {
      normalized['history'] = [];
    }

    return normalized;
  }

  @override
  Future<List<TicketModel>> getTickets() async {
    try {
      // Mengambil tiket beserta relasi komentar dan history
      final response = await _supabaseClient
          .from('tickets')
          .select('*, ticket_comments(*), ticket_history(*)')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final normalized = _normalizeTicketJson(json as Map<String, dynamic>);
        return TicketModel.fromJson(normalized);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar tiket: $e');
    }
  }

  @override
  Future<TicketModel> getTicketDetail(String id) async {
    try {
      final response = await _supabaseClient
          .from('tickets')
          .select('*, ticket_comments(*), ticket_history(*)')
          .eq('id', id)
          .single();

      final normalized = _normalizeTicketJson(response as Map<String, dynamic>);
      return TicketModel.fromJson(normalized);
    } catch (e) {
      throw Exception('Gagal mengambil detail tiket: $e');
    }
  }

  @override
  Future<TicketModel> createTicket(
    String title,
    String description,
    String priority,
    String creatorId,
    String creatorName,
    String? imagePath,
  ) async {
    try {
      String? imageUrl;
      
      // Upload gambar ke Supabase Storage jika ada
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
        
        await _supabaseClient.storage
            .from('ticket-attachments')
            .upload(fileName, file);
            
        imageUrl = _supabaseClient.storage
            .from('ticket-attachments')
            .getPublicUrl(fileName);
      }

      // 1. Simpan tiket baru ke database
      final ticketResponse = await _supabaseClient
          .from('tickets')
          .insert({
            'title': title,
            'description': description,
            'priority': priority,
            'creator_id': creatorId,
            'creator_name': creatorName,
            'image_path': imageUrl,
            'status': 'open',
          })
          .select()
          .single();

      final ticketId = ticketResponse['id'];

      // 2. Buat history awal
      final historyResponse = await _supabaseClient
          .from('ticket_history')
          .insert({
            'ticket_id': ticketId,
            'user_id': creatorId,
            'user_name': creatorName,
            'action': 'dibuat',
            'message': 'Tiket berhasil dibuat oleh $creatorName',
          })
          .select();

      // 3. Ambil ulang data tiket lengkap beserta history terbarunya
      return await getTicketDetail(ticketId);
    } catch (e) {
      throw Exception('Gagal membuat tiket baru: $e');
    }
  }

  @override
  Future<TicketModel> updateTicketStatus(
    String id,
    String status, {
    String? assigneeId,
    String? assigneeName,
  }) async {
    try {
      // 1. Ambil data tiket saat ini untuk mendeteksi perubahan
      final currentTicket = await getTicketDetail(id);

      final Map<String, dynamic> updateData = {
        'status': status,
      };

      if (assigneeId != null) {
        updateData['assignee_id'] = assigneeId;
      }
      if (assigneeName != null) {
        updateData['assignee_name'] = assigneeName;
      }

      // 2. Update tiket
      await _supabaseClient.from('tickets').update(updateData).eq('id', id);

      // 3. Tulis history jika ada penugasan baru
      if (assigneeId != null && assigneeId != currentTicket.assigneeId) {
        await _supabaseClient.from('ticket_history').insert({
          'ticket_id': id,
          'user_id': assigneeId,
          'user_name': assigneeName ?? 'Petugas',
          'action': 'ditugaskan',
          'message': 'Tiket ditugaskan kepada ${assigneeName ?? 'Petugas'}',
        });
      }

      // 4. Tulis history jika status berubah
      if (status != currentTicket.status) {
        await _supabaseClient.from('ticket_history').insert({
          'ticket_id': id,
          'user_id': assigneeId ?? currentTicket.creatorId,
          'user_name': assigneeName ?? currentTicket.creatorName,
          'action': 'status_diubah',
          'message': 'Status tiket diubah dari ${currentTicket.status.toUpperCase()} menjadi ${status.toUpperCase()}',
        });
      }

      // 5. Ambil detail terbaru
      return await getTicketDetail(id);
    } catch (e) {
      throw Exception('Gagal memperbarui status tiket: $e');
    }
  }

  @override
  Future<TicketCommentModel> addComment(
    String ticketId,
    String userId,
    String userName,
    String message,
  ) async {
    try {
      // 1. Insert komentar ke database
      final response = await _supabaseClient
          .from('ticket_comments')
          .insert({
            'ticket_id': ticketId,
            'user_id': userId,
            'user_name': userName,
            'message': message,
          })
          .select()
          .single();

      // 2. Tambahkan log history komentar
      await _supabaseClient.from('ticket_history').insert({
        'ticket_id': ticketId,
        'user_id': userId,
        'user_name': userName,
        'action': 'komentar_ditambahkan',
        'message': '$userName menambahkan komentar baru',
      });

      final commentMap = Map<String, dynamic>.from(response);
      commentMap['ticketId'] = response['ticket_id'];
      commentMap['userId'] = response['user_id'];
      commentMap['userName'] = response['user_name'];
      commentMap['createdAt'] = response['created_at'];

      return TicketCommentModel.fromJson(commentMap);
    } catch (e) {
      throw Exception('Gagal menambahkan komentar: $e');
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    try {
      await _supabaseClient.from('tickets').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus tiket: $e');
    }
  }
}
