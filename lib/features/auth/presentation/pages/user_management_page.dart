import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userManagementNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Kelola Pengguna',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: state.isLoading && state.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Text(
                    'Error: ${state.errorMessage}',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(userManagementNotifierProvider.notifier).loadUsers(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      return _buildUserCard(context, ref, user, isDark)
                          .animate()
                          .fadeIn(delay: (index * 80).ms, duration: 400.ms)
                          .slideY(begin: 0.08);
                    },
                  ),
                ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    WidgetRef ref,
    User user,
    bool isDark,
  ) {
    // Current logged-in user cannot deactivate themselves
    final currentUser = ref.watch(authNotifierProvider).user;
    final isSelf = currentUser?.id == user.id;

    Color roleColor;
    Color roleBgColor;
    switch (user.role) {
      case 'admin':
        roleColor = AppColors.primary;
        roleBgColor = AppColors.primary.withOpacity(isDark ? 0.15 : 0.08);
        break;
      case 'helpdesk':
        roleColor = AppColors.secondary;
        roleBgColor = AppColors.secondary.withOpacity(isDark ? 0.15 : 0.08);
        break;
      default:
        roleColor = AppColors.accent;
        roleBgColor = AppColors.accent.withOpacity(isDark ? 0.15 : 0.08);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkCardGradient
                    : LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Center(
                child: Text(
                  user.name[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '@${user.username}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle Switch
            if (!isSelf)
              Switch.adaptive(
                value: user.isActive,
                activeColor: AppColors.success,
                inactiveThumbColor: AppColors.textTertiary,
                onChanged: (value) async {
                  final success = await ref
                      .read(userManagementNotifierProvider.notifier)
                      .toggleUserStatus(user.id, value);
                  if (context.mounted && !success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal memperbarui status pengguna',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
