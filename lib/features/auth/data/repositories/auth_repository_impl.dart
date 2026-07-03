import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      final user = await remoteDataSource.login(username, password);
      
      if (!user.isActive) {
        throw Exception('Akun Anda telah dinonaktifkan. Silakan hubungi Admin.');
      }
      
      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, User>> register(String username, String password, String name) async {
    try {
      final userModel = await remoteDataSource.register(username, password, name);
      
      // Cache user saat ini (auto-login)
      await localDataSource.cacheUser(userModel);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearCachedUser();
      await Supabase.instance.client.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure("Failed to logout"));
    }
  }

  @override
  Future<Either<Failure, User>> checkAuthStatus() async {
    try {
      final userModel = await localDataSource.getCachedUser();
      if (userModel != null) {
        // Verifikasi apakah user masih aktif di database remote
        final users = await remoteDataSource.getUsers();
        final currentUser = users.firstWhere((u) => u.id == userModel.id, orElse: () => userModel);
        
        if (!currentUser.isActive) {
          await localDataSource.clearCachedUser();
          await Supabase.instance.client.auth.signOut();
          return const Left(CacheFailure("Akun dinonaktifkan"));
        }
        
        // Update cache lokal dengan data terbaru dari server
        await localDataSource.cacheUser(currentUser);
        return Right(currentUser);
      } else {
        // Cek jika session Supabase masih ada
        final supabaseUser = Supabase.instance.client.auth.currentUser;
        if (supabaseUser != null) {
          final users = await remoteDataSource.getUsers();
          final currentUser = users.firstWhere((u) => u.id == supabaseUser.id);
          await localDataSource.cacheUser(currentUser);
          return Right(currentUser);
        }
        return const Left(CacheFailure("No user cached"));
      }
    } catch (e) {
      return Left(CacheFailure("Error decoding cache"));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getUsers() async {
    try {
      final users = await remoteDataSource.getUsers();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure("Gagal memuat daftar pengguna"));
    }
  }

  @override
  Future<Either<Failure, void>> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      await remoteDataSource.updateUserActiveStatus(userId, isActive);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure("Gagal memperbarui status pengguna"));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(String userId, String name, String username) async {
    try {
      final updatedUser = await remoteDataSource.updateProfile(userId, name, username);
      
      // Perbarui cache jika user yang diupdate adalah user yang sedang login
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null && cachedUser.id == userId) {
        await localDataSource.cacheUser(updatedUser);
      }
      return Right(updatedUser);
    } catch (e) {
      return Left(ServerFailure("Gagal memperbarui profil"));
    }
  }
}
