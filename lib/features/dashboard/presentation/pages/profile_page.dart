import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ticket/presentation/providers/ticket_provider.dart';
import '../../../ticket/presentation/pages/create_ticket_page.dart';
import '../providers/theme_provider.dart';
import 'setting_page.dart';
import '../../../auth/presentation/pages/user_management_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final themeMode = ref.watch(themeNotifierProvider);
    final ticketState = ref.watch(ticketListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ─── Role-Based Stats & Labels ───────────────────
    String totalLabel = 'Total';
    String completedLabel = 'Selesai';
    String pendingLabel = 'Pending';
    Color pendingColor = AppColors.statusPending;

    int totalTickets = 0;
    int completedTickets = 0;
    int pendingTickets = 0;

    if (user?.role == 'admin') {
      totalLabel = 'Total Tiket';
      completedLabel = 'Selesai';
      pendingLabel = 'Pending';
      pendingColor = AppColors.statusPending;

      totalTickets = ticketState.tickets.length;
      completedTickets = ticketState.tickets.where((t) => t.status == 'close').length;
      pendingTickets = ticketState.tickets.where((t) => t.status == 'open' || t.status == 'assign').length;
    } else if (user?.role == 'helpdesk') {
      totalLabel = 'Ditugaskan';
      completedLabel = 'Selesai';
      pendingLabel = 'Proses';
      pendingColor = AppColors.statusProcess;

      final helpdeskTickets = ticketState.tickets.where((t) => t.assigneeId == user?.id).toList();
      totalTickets = helpdeskTickets.length;
      completedTickets = helpdeskTickets.where((t) => t.status == 'close').length;
      pendingTickets = helpdeskTickets.where((t) => t.status == 'on progress').length;
    } else {
      totalLabel = 'Tiket Saya';
      completedLabel = 'Selesai';
      pendingLabel = 'Pending';
      pendingColor = AppColors.statusPending;

      final userTickets = ticketState.tickets.where((t) => t.creatorId == user?.id).toList();
      totalTickets = userTickets.length;
      completedTickets = userTickets.where((t) => t.status == 'close').length;
      pendingTickets = userTickets.where((t) => t.status == 'open' || t.status == 'assign').length;
    }

    // ─── Role-Based Colors & Badges ──────────────────
    Gradient avatarGradient;
    Color badgeColor;
    String roleText;

    if (user?.role == 'admin') {
      avatarGradient = AppColors.premiumGradient;
      badgeColor = AppColors.primary;
      roleText = 'ADMINISTRATOR';
    } else if (user?.role == 'helpdesk') {
      avatarGradient = AppColors.successGradient;
      badgeColor = AppColors.success;
      roleText = 'HELPDESK SUPPORT';
    } else {
      avatarGradient = AppColors.warmGradient;
      badgeColor = AppColors.accent;
      roleText = 'PELAPOR UTAMA';
    }

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ─── Header ─────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient background
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: avatarGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative shapes
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: -30,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar
                Positioned(
                  bottom: -46,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.backgroundDark : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: avatarGradient,
                        ),
                        child: Center(
                          child: Text(
                            user?.name[0].toUpperCase() ?? 'U',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                ),

                // Header title
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profil',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                          ),
                          onPressed: () => _showEditProfileBottomSheet(context, ref, user),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 56),

            // ─── User Info ──────────────────────────
            Column(
              children: [
                Text(
                  user?.name ?? 'Guest User',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                const SizedBox(height: 4),

                Text(
                  '@${user?.username ?? 'guest'}',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    roleText,
                    style: GoogleFonts.plusJakartaSans(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(),
              ],
            ),

            const SizedBox(height: 28),

            // ─── Stats Row ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
                  ),
                  boxShadow: isDark ? [] : AppColors.softShadow,
                ),
                child: Row(
                  children: [
                    _buildStatItem(totalLabel, totalTickets.toString(), AppColors.primary, isDark),
                    _buildDivider(isDark),
                    _buildStatItem(completedLabel, completedTickets.toString(), AppColors.success, isDark),
                    _buildDivider(isDark),
                    _buildStatItem(pendingLabel, pendingTickets.toString(), pendingColor, isDark),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 28),

            // ─── Menu Utama ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MENU UTAMA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),

                  _buildSettingsCard(
                    context,
                    isDark: isDark,
                    items: [
                      _buildSettingsItem(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan Aplikasi',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingPage(),
                            ),
                          );
                        },
                      ),
                      if (user?.role == 'admin') ...[
                        Divider(
                          height: 1,
                          indent: 56,
                          color: isDark ? AppColors.borderDark : AppColors.dividerLight,
                        ),
                        _buildSettingsItem(
                          icon: Icons.people_outline_rounded,
                          title: 'Kelola Pengguna',
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserManagementPage(),
                              ),
                            );
                          },
                        ),
                      ],
                      if (user?.role == 'helpdesk') ...[
                        Divider(
                          height: 1,
                          indent: 56,
                          color: isDark ? AppColors.borderDark : AppColors.dividerLight,
                        ),
                        _buildSettingsItem(
                          icon: Icons.assignment_outlined,
                          title: 'Daftar Tugas Tiket',
                          isDark: isDark,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Silakan buka tab "Tiket" di bagian bawah untuk melihat daftar tugas Anda.',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ],
                      if (user?.role == 'user') ...[
                        Divider(
                          height: 1,
                          indent: 56,
                          color: isDark ? AppColors.borderDark : AppColors.dividerLight,
                        ),
                        _buildSettingsItem(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Buat Tiket Baru',
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CreateTicketPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.05),

                  const SizedBox(height: 28),

                  // ─── Logout Button ────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                            title: Text(
                              'Keluar',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            content: Text(
                              'Apakah Anda yakin ingin keluar dari akun?',
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ref.read(authNotifierProvider.notifier).logout();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Keluar',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'Keluar dari Akun',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.error.withOpacity(0.12)
                            : AppColors.errorSoft,
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1),

                  const SizedBox(height: 28),

                  // Version info
                  Center(
                    child: Text(
                      'E-Ticket Helpdesk v2.0.0',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1100.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? AppColors.borderDark : AppColors.dividerLight,
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required bool isDark,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: items),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
            size: 20,
          ),
      onTap: onTap,
    );
  }

  // ─── Edit Profile Bottom Sheet ────────────────────
  void _showEditProfileBottomSheet(BuildContext context, WidgetRef ref, User? user) {
    if (user == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: user.name);
    final usernameController = TextEditingController(text: user.username);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Edit Profil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              
              // Name Input
              Text(
                'NAMA LENGKAP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nama Lengkap',
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 18),
              
              // Username Input
              Text(
                'USERNAME',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: usernameController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Username tidak boleh kosong' : null,
              ),
              const SizedBox(height: 28),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .updateProfile(nameController.text.trim(), usernameController.text.trim());
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success ? 'Profil berhasil diperbarui!' : 'Gagal memperbarui profil',
                                style: GoogleFonts.plusJakartaSans(),
                              ),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
