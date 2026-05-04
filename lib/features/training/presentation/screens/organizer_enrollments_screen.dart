import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/training/domain/models/session_enrollment_model.dart';
import 'package:rayen_mobile/features/training/presentation/providers/training_provider.dart';

class OrganizerEnrollmentsScreen extends StatefulWidget {
  final String organizerId;

  const OrganizerEnrollmentsScreen({super.key, required this.organizerId});

  @override
  State<OrganizerEnrollmentsScreen> createState() =>
      _OrganizerEnrollmentsScreenState();
}

class _OrganizerEnrollmentsScreenState extends State<OrganizerEnrollmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    final provider = context.read<TrainingProvider>();
    await provider.loadSessionsByOrganizer(widget.organizerId);
    for (final session in provider.sessions) {
      await provider.loadEnrollmentsBySession(session.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        title: Text(
          'Inscriptions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Approuvées'),
            Tab(text: 'Rejetées'),
          ],
        ),
      ),
      body: Consumer<TrainingProvider>(
        builder: (_, provider, __) {
          if (provider.sessionsStatus == TrainingLoadStatus.loading ||
              provider.enrollmentsStatus == TrainingLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pending = provider.enrollments
              .where((e) => e.status == EnrollmentRequestStatus.pending)
              .toList();
          final approved = provider.enrollments
              .where((e) => e.status == EnrollmentRequestStatus.approved)
              .toList();
          final rejected = provider.enrollments
              .where((e) => e.status == EnrollmentRequestStatus.rejected)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _EnrollmentList(
                enrollments: pending,
                showActions: true,
                emptyMessage: 'Aucune demande en attente.',
                emptyIcon: Icons.inbox_rounded,
              ),
              _EnrollmentList(
                enrollments: approved,
                showActions: false,
                emptyMessage: 'Aucune inscription approuvée.',
                emptyIcon: Icons.check_circle_outline_rounded,
              ),
              _EnrollmentList(
                enrollments: rejected,
                showActions: false,
                emptyMessage: 'Aucune inscription rejetée.',
                emptyIcon: Icons.cancel_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EnrollmentList extends StatelessWidget {
  final List<SessionEnrollmentModel> enrollments;
  final bool showActions;
  final String emptyMessage;
  final IconData emptyIcon;

  const _EnrollmentList({
    required this.enrollments,
    required this.showActions,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(emptyIcon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final provider = context.read<TrainingProvider>();
        for (final e in enrollments) {
          await provider.loadEnrollmentsBySession(e.sessionId);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: enrollments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _EnrollmentCard(
          enrollment: enrollments[i],
          showActions: showActions,
        ),
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final SessionEnrollmentModel enrollment;
  final bool showActions;

  const _EnrollmentCard({required this.enrollment, required this.showActions});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TrainingProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.userFullName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      enrollment.userEmail,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: enrollment.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.event_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  enrollment.sessionTitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Demandé le ${DateFormat('dd MMM yyyy', 'fr').format(enrollment.requestedAt)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.respondToEnrollment(
                      enrollment.id,
                      EnrollmentRequestStatus.rejected,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Rejeter',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.respondToEnrollment(
                      enrollment.id,
                      EnrollmentRequestStatus.approved,
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Approuver',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _borderColor() {
    switch (enrollment.status) {
      case EnrollmentRequestStatus.pending:
        return AppColors.warning.withValues(alpha: 0.4);
      case EnrollmentRequestStatus.approved:
        return AppColors.success.withValues(alpha: 0.4);
      case EnrollmentRequestStatus.rejected:
        return AppColors.error.withValues(alpha: 0.4);
    }
  }
}

class _StatusPill extends StatelessWidget {
  final EnrollmentRequestStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color(),
        ),
      ),
    );
  }

  Color _color() {
    switch (status) {
      case EnrollmentRequestStatus.pending:
        return AppColors.warning;
      case EnrollmentRequestStatus.approved:
        return AppColors.success;
      case EnrollmentRequestStatus.rejected:
        return AppColors.error;
    }
  }

  String _label() {
    switch (status) {
      case EnrollmentRequestStatus.pending:
        return 'En attente';
      case EnrollmentRequestStatus.approved:
        return 'Approuvé';
      case EnrollmentRequestStatus.rejected:
        return 'Rejeté';
    }
  }
}
