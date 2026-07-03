import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/ticket_provider.dart';
import 'create_ticket_page.dart';
import 'ticket_detail_page.dart';

class TicketListPage extends ConsumerWidget {
  const TicketListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketState = ref.watch(ticketListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Tiket',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ticketState.isDescending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              onPressed: () => ref.read(ticketListNotifierProvider.notifier).toggleSortOrder(),
              tooltip: 'Urutkan Waktu',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.transparent,
                ),
              ),
              child: TextField(
                onChanged: (value) =>
                    ref.read(ticketListNotifierProvider.notifier).setSearchQuery(value),
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari tiket bantuan...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15),

          // Filter Chips
          _buildFilterBar(ref, ticketState.filterStatus, isDark)
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: -0.1),

          // Ticket List
          Expanded(
            child: ticketState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ticketState.filteredTickets.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(ticketListNotifierProvider.notifier).loadTickets(),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: ticketState.filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = ticketState.filteredTickets[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OpenContainer(
                                transitionDuration: const Duration(milliseconds: 500),
                                openBuilder: (context, _) =>
                                    TicketDetailPage(ticketId: ticket.id),
                                closedElevation: 0,
                                closedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                closedColor: isDark ? AppColors.cardDark : Colors.white,
                                closedBuilder: (context, openContainer) =>
                                    _buildTicketCard(ticket, openContainer, isDark),
                              ).animate()
                                  .fadeIn(delay: (index * 80).ms, duration: 400.ms)
                                  .slideY(begin: 0.08),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateTicketPage()),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 6,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: Text(
            'Tiket Baru',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? AppColors.primaryLight : AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak ada tiket ditemukan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Buat tiket baru untuk memulai',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFilterBar(WidgetRef ref, String currentFilter, bool isDark) {
    final filters = [
      {'key': 'semua', 'label': 'Semua', 'icon': Icons.all_inclusive_rounded},
      {'key': 'open', 'label': 'Open', 'icon': Icons.schedule_rounded},
      {'key': 'assign', 'label': 'Assigned', 'icon': Icons.assignment_ind_rounded},
      {'key': 'on progress', 'label': 'On Progress', 'icon': Icons.sync_rounded},
      {'key': 'close', 'label': 'Closed', 'icon': Icons.check_circle_outline_rounded},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = currentFilter == filter['key'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                ref.read(ticketListNotifierProvider.notifier)
                    .setFilter(filter['key'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : Colors.transparent),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textDarkSecondary : AppColors.textTertiary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(dynamic ticket, VoidCallback openContainer, bool isDark) {
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

    return InkWell(
      onTap: openContainer,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              height: 100,
              margin: const EdgeInsets.only(left: 1),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? statusColor.withOpacity(0.12) : statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                ticket.status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '#${ticket.id.substring(0, 6).toUpperCase()}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ticket.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ticket.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
                          ),
                        ),
                        if (ticket.assigneeName != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    ticket.assigneeName!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
