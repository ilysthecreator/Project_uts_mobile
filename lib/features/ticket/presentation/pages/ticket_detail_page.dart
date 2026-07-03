import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_tracking_page.dart';

class TicketDetailPage extends ConsumerWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final user = ref.watch(authNotifierProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: GoogleFonts.plusJakartaSans()),
        ),
        data: (ticket) => Stack(
          children: [
            // ─── Header Background ──────────────────
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: AppColors.premiumGradient,
              ),
            ),

            // ─── Decorative Shape ───────────────────
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // ─── Content ────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          Text(
                            'Detail Tiket',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          user?.role == 'admin'
                               ? IconButton(
                                   icon: Container(
                                     padding: const EdgeInsets.all(8),
                                     decoration: BoxDecoration(
                                       color: AppColors.error.withOpacity(0.2),
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: const Icon(
                                       Icons.delete_forever_rounded,
                                       color: Colors.white,
                                       size: 18,
                                     ),
                                   ),
                                   onPressed: () => _confirmDelete(context, ref, ticketId),
                                 )
                               : const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ─── Main Card ──────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMainCard(context, ticket, isDark),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // ─── Info Grid ──────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildInfoGrid(ticket, isDark),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // ─── Description ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildDescriptionSection(ticket, isDark),
                    ).animate().fadeIn(delay: 300.ms),

                    // ─── Attachment ─────────────────────
                    if (ticket.imagePath != null) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildAttachmentSection(ticket, isDark),
                      ).animate().fadeIn(delay: 350.ms),
                    ],

                    const SizedBox(height: 20),

                    // ─── Comments ────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildCommentsSection(ticket, isDark),
                    ).animate().fadeIn(delay: 400.ms),

                    SizedBox(
                      height: (user?.role == 'admin' || user?.role == 'helpdesk') ? 120 : 40,
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bottom Admin Actions ───────────────
            if (user?.role == 'admin' || user?.role == 'helpdesk')
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildAdminActions(context, ref, ticket, isDark)
                    .animate()
                    .slideY(begin: 1, delay: 500.ms),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Main Ticket Card ───────────────────────────────
  Widget _buildMainCard(BuildContext context, dynamic ticket, bool isDark) {
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
        statusIcon = Icons.info_rounded;
    }

    Color priorityColor;
    String priorityLabel;
    IconData priorityIcon;
    final priority = ticket.priority;

    switch (priority) {
      case 'low':
        priorityColor = AppColors.success;
        priorityLabel = 'RENDAH';
        priorityIcon = Icons.arrow_downward_rounded;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityLabel = 'SEDANG';
        priorityIcon = Icons.remove_rounded;
        break;
      case 'high':
        priorityColor = AppColors.error;
        priorityLabel = 'TINGGI';
        priorityIcon = Icons.arrow_upward_rounded;
        break;
      default:
        priorityColor = Colors.orange;
        priorityLabel = 'SEDANG';
        priorityIcon = Icons.remove_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
        boxShadow: isDark ? [] : AppColors.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? statusColor.withOpacity(0.12) : statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      ticket.status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(priorityIcon, color: priorityColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      priorityLabel,
                      style: GoogleFonts.plusJakartaSans(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '#${ticket.id.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.jetBrainsMono(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            ticket.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TicketTrackingPage(ticketId: ticket.id),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(
                'Lacak Perjalanan Tiket',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(isDark ? 0.12 : 0.08),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Grid ──────────────────────────────────────
  Widget _buildInfoGrid(dynamic ticket, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Pembuat',
            value: ticket.creatorName,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.support_agent_rounded,
            label: 'Petugas',
            value: ticket.assigneeName ?? 'Belum ditugaskan',
            color: ticket.assigneeName != null ? AppColors.success : AppColors.textTertiary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Description ────────────────────────────────────
  Widget _buildDescriptionSection(dynamic ticket, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'DESKRIPSI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            ticket.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.7,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Attachment ─────────────────────────────────────
  Widget _buildAttachmentSection(dynamic ticket, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 18,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'LAMPIRAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ticket.imagePath!.startsWith('http')
                ? Image.network(
                    ticket.imagePath!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Image.file(
                    File(ticket.imagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Comments Section ───────────────────────────────
  Widget _buildCommentsSection(dynamic ticket, bool isDark) {
    final comments = ticket.comments as List<dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.forum_outlined,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Aktivitas & Komentar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${comments.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.surfaceElevatedLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Belum ada aktivitas',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              final isLast = index == comments.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dots + line
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          comment.userName[0].toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      comment.userName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              comment.message,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        _CommentInputWidget(ticketId: ticket.id),
      ],
    );
  }

  // ─── Admin/Helpdesk Actions (Bottom) ────────────────
  Widget _buildAdminActions(BuildContext context, WidgetRef ref, dynamic ticket, bool isDark) {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return const SizedBox.shrink();

    Widget? actionWidget;

    if (user.role == 'admin') {
      if (ticket.status == 'open') {
        // Tombol Terima Tiket
        actionWidget = Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await ref
                  .read(ticketListNotifierProvider.notifier)
                  .updateStatus(ticket.id, 'assign');
              if (success) {
                ref.invalidate(ticketDetailProvider(ticket.id));
              }
            },
            icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
            label: Text(
              'Terima Tiket',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      } else if (ticket.status == 'assign') {
        // Tombol Tugaskan Petugas
        actionWidget = OutlinedButton.icon(
          onPressed: () => _showAssignDialog(context, ref, ticket.id),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: Text(
            'Tugaskan Petugas',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.primary.withOpacity(0.3),
            ),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      } else if (ticket.status == 'on progress') {
        // Tombol Selesai Pekerjaan
        actionWidget = Container(
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await ref
                  .read(ticketListNotifierProvider.notifier)
                  .updateStatus(ticket.id, 'close');
              if (success) {
                ref.invalidate(ticketDetailProvider(ticket.id));
              }
            },
            icon: const Icon(Icons.task_alt_rounded, size: 18, color: Colors.white),
            label: Text(
              'Selesai Pekerjaan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      }
    } else if (user.role == 'helpdesk') {
      if (ticket.status == 'on progress' && ticket.assigneeId == user.id) {
        // Tombol Selesai Pekerjaan untuk Helpdesk
        actionWidget = Container(
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await ref
                  .read(ticketListNotifierProvider.notifier)
                  .updateStatus(ticket.id, 'close');
              if (success) {
                ref.invalidate(ticketDetailProvider(ticket.id));
              }
            },
            icon: const Icon(Icons.task_alt_rounded, size: 18, color: Colors.white),
            label: Text(
              'Selesai Pekerjaan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      }
    }

    if (actionWidget == null) return const SizedBox.shrink();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white).withOpacity(0.92),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: actionWidget),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref, String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responders = [
      {'id': 'h1', 'name': 'Budi - Networking'},
      {'id': 'h2', 'name': 'Siti - Software'},
      {'id': 'h3', 'name': 'Agus - Hardware'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Text(
              'Tugaskan Petugas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih petugas penanggung jawab',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ...responders.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      r['name']![0],
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  r['name']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  ref.read(ticketListNotifierProvider.notifier).updateStatus(
                    id, 'on progress',
                    assigneeId: r['id'],
                    assigneeName: r['name'],
                  );
                  Navigator.pop(context);
                  ref.invalidate(ticketDetailProvider(id));
                },
              ),
            )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Hapus Tiket',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus tiket ini secara permanen?',
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
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog konfirmasi
              final success = await ref.read(ticketListNotifierProvider.notifier).deleteTicket(id);
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // Kembali ke halaman daftar tiket
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tiket berhasil dihapus!',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus tiket',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
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
              'Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputWidget extends ConsumerStatefulWidget {
  final String ticketId;

  const _CommentInputWidget({required this.ticketId});

  @override
  ConsumerState<_CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends ConsumerState<_CommentInputWidget> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(ticketListNotifierProvider.notifier)
        .addComment(widget.ticketId, user.id, user.name, text);

    if (mounted) {
      if (success) {
        _controller.clear();
        ref.invalidate(ticketDetailProvider(widget.ticketId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Komentar berhasil ditambahkan', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan komentar', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.statusCancel,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  onPressed: _submitComment,
                ),
        ],
      ),
    );
  }
}
