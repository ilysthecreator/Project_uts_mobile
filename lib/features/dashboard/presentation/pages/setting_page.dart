import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
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
          'Pengaturan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── App Settings ───────────────────────────
            Text(
              'PENGATURAN APLIKASI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            _buildSettingsCard(
              isDark: isDark,
              items: [
                _buildSettingsItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode Gelap',
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) =>
                        ref.read(themeNotifierProvider.notifier).toggleTheme(),
                    activeColor: AppColors.primary,
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark ? AppColors.borderDark : AppColors.dividerLight,
                ),
                _buildSettingsItem(
                  icon: Icons.language_rounded,
                  title: 'Bahasa',
                  isDark: isDark,
                  trailing: Text(
                    'Indonesia',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.05),

            const SizedBox(height: 28),

            // ─── Support Settings ────────────────────────
            Text(
              'DUKUNGAN',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),

            _buildSettingsCard(
              isDark: isDark,
              items: [
                _buildSettingsItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Pusat Bantuan',
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fitur Pusat Bantuan akan segera hadir!',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark ? AppColors.borderDark : AppColors.dividerLight,
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Tentang Aplikasi',
                  isDark: isDark,
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'E-Ticketing Helpdesk',
                      applicationVersion: '2.0.0',
                      applicationIcon: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Aplikasi E-Ticketing Helpdesk untuk pelaporan, monitoring, dan penyelesaian masalah IT. Dibuat menggunakan Flutter & Clean Architecture.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
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
}
