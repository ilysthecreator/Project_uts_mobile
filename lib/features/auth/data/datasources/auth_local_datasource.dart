import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel userToCache);
  Future<UserModel?> getCachedUser();
  Future<void> clearCachedUser();
  
  // User Management
  Future<List<UserModel>> getUsers();
  Future<void> saveUsers(List<UserModel> users);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const CACHED_USER = 'CACHED_USER';
  static const USERS_LIST = 'USERS_LIST';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel userToCache) async {
    await sharedPreferences.setString(
      CACHED_USER,
      json.encode(userToCache.toJson()),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(CACHED_USER);
    if (jsonString != null) {
      return UserModel.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> clearCachedUser() async {
    await sharedPreferences.remove(CACHED_USER);
  }

  @override
  Future<List<UserModel>> getUsers() async {
    final jsonString = sharedPreferences.getString(USERS_LIST);
    if (jsonString != null) {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((item) => UserModel.fromJson(item)).toList();
    }
    
    // Seed default users if empty
    final defaultUsers = _getDefaultUsers();
    await saveUsers(defaultUsers);
    return defaultUsers;
  }

  @override
  Future<void> saveUsers(List<UserModel> users) async {
    final jsonString = json.encode(users.map((u) => u.toJson()).toList());
    await sharedPreferences.setString(USERS_LIST, jsonString);
  }

  List<UserModel> _getDefaultUsers() {
    return const [
      UserModel(id: '1', name: 'Super Admin', username: 'admin', role: 'admin', isActive: true),
      UserModel(id: '2', name: 'Fadhil Ilyas', username: 'user', role: 'user', isActive: true),
      UserModel(id: 'h1', name: 'Budi - Networking', username: 'budi', role: 'helpdesk', isActive: true),
      UserModel(id: 'h2', name: 'Siti - Software', username: 'siti', role: 'helpdesk', isActive: true),
      UserModel(id: 'h3', name: 'Agus - Hardware', username: 'agus', role: 'helpdesk', isActive: true),
    ];
  }
}
