import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ticket.dart';
import '../providers/ticket_provider.dart';

class TicketTrackingPage extends ConsumerWidget {
  final String ticketId;

  const TicketTrackingPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
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
          'Lacak Tiket',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Gagal memuat riwayat: $err',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
        data: (ticket) {
          final sortedHistory = List<TicketHistory>.from(ticket.history)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Terbaru di atas

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Ticket Summary Card ────────────────────
                _buildTicketSummaryCard(ticket, isDark)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.05),

                const SizedBox(height: 28),

                Text(
                  'Riwayat Perjalanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // ─── Timeline List ──────────────────────────
                if (sortedHistory.isEmpty)
                  _buildEmptyState(isDark).animate().fadeIn(delay: 300.ms)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedHistory.length,
                    itemBuilder: (context, index) {
                      final log = sortedHistory[index];
                      final isFirst = index == 0;
                      final isLast = index == sortedHistory.length - 1;

                      return _buildTimelineTile(log, isFirst, isLast, isDark)
                          .animate()
                          .fadeIn(delay: (index * 100 + 300).ms, duration: 400.ms)
                          .slideX(begin: 0.05);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketSummaryCard(Ticket ticket, bool isDark) {
    Color statusColor;
    Color statusBgColor;
    switch (ticket.status) {
      case 'open':
        statusColor = AppColors.statusPending;
        statusBgColor = AppColors.statusPendingBg;
        break;
      case 'assign':
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.08);
        break;
      case 'on progress':
        statusColor = AppColors.statusProcess;
        statusBgColor = AppColors.statusProcessBg;
        break;
      case 'close':
        statusColor = AppColors.statusDone;
        statusBgColor = AppColors.statusDoneBg;
        break;
      default:
        statusColor = AppColors.textTertiary;
        statusBgColor = AppColors.surfaceElevatedLight;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${ticket.id.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? statusColor.withOpacity(0.12) : statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dibuat oleh: ${ticket.creatorName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(TicketHistory log, bool isFirst, bool isLast, bool isDark) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (log.action) {
      case 'dibuat':
        icon = Icons.add_circle_outline_rounded;
        color = AppColors.primary;
        bgColor = AppColors.primary.withOpacity(0.1);
        break;
      case 'ditugaskan':
        icon = Icons.person_add_alt_1_rounded;
        color = AppColors.secondary;
        bgColor = AppColors.secondary.withOpacity(0.1);
        break;
      case 'status_diubah':
        if (log.message.contains('CLOSE')) {
          icon = Icons.check_circle_outline_rounded;
          color = AppColors.statusDone;
          bgColor = AppColors.statusDoneBg;
        } else if (log.message.contains('ON PROGRESS')) {
          icon = Icons.sync_rounded;
          color = AppColors.statusProcess;
          bgColor = AppColors.statusProcessBg;
        } else if (log.message.contains('ASSIGN')) {
          icon = Icons.assignment_ind_rounded;
          color = Colors.blue;
          bgColor = Colors.blue.withOpacity(0.15);
        } else {
          icon = Icons.schedule_rounded;
          color = AppColors.statusPending;
          bgColor = AppColors.statusPendingBg;
        }
        break;
      case 'komentar_ditambahkan':
        icon = Icons.chat_bubble_outline_rounded;
        color = AppColors.accent;
        bgColor = AppColors.accent.withOpacity(0.1);
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = AppColors.textTertiary;
        bgColor = AppColors.surfaceElevatedLight;
    }

    if (isDark && bgColor != AppColors.surfaceElevatedLight) {
      bgColor = color.withOpacity(0.15);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Left Timeline (Indicator) ─────────────
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isFirst ? color : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(isFirst ? 0.3 : 0.6),
                    width: 3,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isFirst ? Colors.white : color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // ─── Right Content (Card) ──────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? (isFirst ? color.withOpacity(0.25) : AppColors.borderDark)
                      : (isFirst ? color.withOpacity(0.2) : AppColors.borderLight.withOpacity(0.5)),
                  width: isFirst ? 1.5 : 1,
                ),
                boxShadow: isDark ? [] : AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getActionTitle(log.action),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(log.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    log.message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 12,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Aktor: ${log.userName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'dibuat':
        return 'Tiket Dibuat';
      case 'ditugaskan':
        return 'Penugasan Petugas';
      case 'status_diubah':
        return 'Perubahan Status';
      case 'komentar_ditambahkan':
        return 'Komentar Baru';
      default:
        return 'Aktivitas';
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 40,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat aktivitas',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
