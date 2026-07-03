import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
  Future<UserModel> register(String username, String password, String name);
  Future<List<UserModel>> getUsers();
  Future<void> updateUserActiveStatus(String userId, bool isActive);
  Future<UserModel> updateProfile(String userId, String name, String username);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AuthRemoteDataSourceImpl({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<UserModel> login(String username, String password) async {
    try {
      final email = username.contains('@') 
          ? username.trim() 
          : '${username.trim()}@helpdesk.local';

      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('User tidak ditemukan');
      }

      // Ambil detail profil dari tabel public.profiles
      final profileData = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(profileData);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Username atau Password yang anda masukan salah');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> register(
      String username, String password, String name) async {
    try {
      final email = username.contains('@') 
          ? username.trim() 
          : '${username.trim()}@helpdesk.local';

      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'username': username.trim(),
          'role': 'user',
        },
      );

      if (response.user == null) {
        throw Exception('Registrasi gagal');
      }

      // Beri sedikit delay untuk memastikan trigger database selesai dieksekusi
      await Future.delayed(const Duration(milliseconds: 500));

      // Ambil detail profil yang dibuat oleh trigger
      final profileData = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(profileData);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _supabaseClient.from('profiles').select();
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar pengguna: $e');
    }
  }

  @override
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _supabaseClient
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Gagal memperbarui status aktif pengguna: $e');
    }
  }

  @override
  Future<UserModel> updateProfile(
      String userId, String name, String username) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .update({
            'name': name,
            'username': username.trim(),
          })
          .eq('id', userId)
          .select()
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }
}
