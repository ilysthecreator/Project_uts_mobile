import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ticket/presentation/pages/ticket_list_page.dart';
import '../../../ticket/presentation/providers/ticket_provider.dart';
import 'package:project_uts/features/notification/presentation/pages/notification_page.dart';
import '../../../../core/services/report_service.dart';
import 'profile_page.dart';
import 'report_preview_page.dart';
import '../../../auth/presentation/pages/user_management_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardSummaryView(),
    const TicketListPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.cardDark
                        : Colors.white)
                    .withOpacity(isDark ? 0.85 : 0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.space_dashboard_outlined,
                    activeIcon: Icons.space_dashboard_rounded,
                    label: 'Beranda',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.confirmation_number_outlined,
                    activeIcon: Icons.confirmation_number_rounded,
                    label: 'Tiket',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profil',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textDarkSecondary : AppColors.textTertiary),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Dashboard Summary View
// ──────────────────────────────────────────────────────
class DashboardSummaryView extends ConsumerWidget {
  const DashboardSummaryView({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final ticketState = ref.watch(ticketListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalTickets = ticketState.tickets.length;
    final pendingTickets = ticketState.tickets.where((t) => t.status == 'open' || t.status == 'assign').length;
    final activeTickets = ticketState.tickets.where((t) => t.status == 'on progress').length;
    final completedTickets = ticketState.tickets.where((t) => t.status == 'close').length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              user?.name ?? 'User',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          // Notification bell
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => ref.read(authNotifierProvider.notifier).logout(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    user?.name[0].toUpperCase() ?? 'U',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Admin Report Banner ────────────────────
            if (user?.role == 'admin' || user?.role == 'helpdesk') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.analytics_rounded,
                        size: 100,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ADMIN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Pusat Kendali Laporan',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Unduh ringkasan data tiket dalam format PDF',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        user?.role == 'admin'
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ReportPreviewPage(tickets: ticketState.tickets),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                                      label: Text(
                                        'Laporan',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primary,
                                        minimumSize: const Size(0, 48),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const UserManagementPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.people_alt_rounded, size: 16),
                                      label: Text(
                                        'Kelola User',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.25),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 48),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ReportPreviewPage(tickets: ticketState.tickets),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                  label: Text(
                                    'Tinjau & Cetak Laporan',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    minimumSize: const Size(double.infinity, 50),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
              const SizedBox(height: 24),
            ],

            // ─── Section Title ──────────────────────────
            Text(
              'Ringkasan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 14),

            // ─── Stats Grid ─────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildStatCard(
                    title: 'Total Tiket',
                    count: totalTickets.toString(),
                    icon: Icons.receipt_long_rounded,
                    gradient: AppColors.primaryGradient,
                    height: 170,
                    isDark: isDark,
                  ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildMiniStatCard(
                        title: 'Pending',
                        count: pendingTickets.toString(),
                        icon: Icons.schedule_rounded,
                        color: AppColors.statusPending,
                        bgColor: AppColors.statusPendingBg,
                        isDark: isDark,
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.15),
                      const SizedBox(height: 14),
                      _buildMiniStatCard(
                        title: 'Diproses',
                        count: activeTickets.toString(),
                        icon: Icons.sync_rounded,
                        color: AppColors.statusProcess,
                        bgColor: AppColors.statusProcessBg,
                        isDark: isDark,
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.15),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Completed card (full width)
            _buildFullWidthStatCard(
              title: 'Tiket Selesai',
              count: completedTickets.toString(),
              icon: Icons.check_circle_rounded,
              color: AppColors.statusDone,
              bgColor: AppColors.statusDoneBg,
              isDark: isDark,
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

            const SizedBox(height: 28),

            // ─── Recent Activity ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aktivitas Terbaru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 8),
            _buildRecentActivityList(ticketState, isDark).animate().fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }

  // ─── Stats Card (Large) ─────────────────────────────
  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Gradient gradient,
    required double height,
    required bool isDark,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(icon, color: Colors.white.withOpacity(0.12), size: 80),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats Card (Mini) ──────────────────────────────
  Widget _buildMiniStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : color.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Full Width Stat Card ───────────────────────────
  Widget _buildFullWidthStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : color.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  count,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.trending_up_rounded,
            color: color.withOpacity(0.5),
            size: 32,
          ),
        ],
      ),
    );
  }

  // ─── Recent Activity ────────────────────────────────
  Widget _buildRecentActivityList(TicketListState ticketState, bool isDark) {
    if (ticketState.isLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
      );
    }

    if (ticketState.tickets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceElevatedLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada aktivitas',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final recentTickets = ticketState.tickets.take(3).toList();

    return Column(
      children: recentTickets.map((ticket) {
        Color statusColor;
        Color statusBgColor;
        IconData statusIcon;
        switch (ticket.status) {
          case 'open':
            statusColor = AppColors.statusPending;
            statusBgColor = AppColors.statusPendingBg;
            statusIcon = Icons.schedule_rounded;
            break;
          case 'assign':
            statusColor = Colors.blue;
            statusBgColor = Colors.blue.withOpacity(0.08);
            statusIcon = Icons.assignment_ind_rounded;
            break;
          case 'on progress':
            statusColor = AppColors.statusProcess;
            statusBgColor = AppColors.statusProcessBg;
            statusIcon = Icons.sync_rounded;
            break;
          case 'close':
            statusColor = AppColors.statusDone;
            statusBgColor = AppColors.statusDoneBg;
            statusIcon = Icons.check_circle_rounded;
            break;
          default:
            statusColor = AppColors.textTertiary;
            statusBgColor = AppColors.surfaceElevatedLight;
            statusIcon = Icons.info_outline_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.4),
            ),
            boxShadow: isDark ? [] : AppColors.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? statusColor.withOpacity(0.12) : statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ticket.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
