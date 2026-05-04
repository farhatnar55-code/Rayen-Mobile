import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';
import 'package:rayen_mobile/features/training/presentation/providers/training_provider.dart';
import 'package:intl/intl.dart';

class TrainerSessionsScreen extends StatefulWidget {
  final String trainerId;

  const TrainerSessionsScreen({super.key, required this.trainerId});

  @override
  State<TrainerSessionsScreen> createState() => _TrainerSessionsScreenState();
}

class _TrainerSessionsScreenState extends State<TrainerSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainingProvider>().loadSessionsByTrainer(widget.trainerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingProvider>(
      builder: (_, provider, __) {
        if (provider.sessionsStatus == TrainingLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.sessions.isEmpty) {
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
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune session assignée',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos sessions apparaîtront ici.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _SessionCard(session: provider.sessions[i]),
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TrainingSessionModel session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final hasImage = session.imageUrl != null && session.imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: session.imageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(height: 100, color: AppColors.primarySurface),
                errorWidget: (_, __, ___) => Container(
                  height: 100,
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.image_not_supported_rounded),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusBadge(status: session.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  session.domain,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: DateFormat(
                        'dd MMM yyyy',
                        'fr',
                      ).format(session.sessionDate),
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label: '${session.durationMinutes} min',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.people_rounded,
                      label:
                          '${session.enrolledCount}/${session.maxParticipants}',
                    ),
                  ],
                ),
                if (session.meetingLink != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          session.meetingLink!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.info,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SessionStatus status;
  const _StatusBadge({required this.status});

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
      case SessionStatus.draft:
        return AppColors.textSecondary;
      case SessionStatus.published:
        return AppColors.success;
      case SessionStatus.cancelled:
        return AppColors.error;
      case SessionStatus.completed:
        return AppColors.info;
    }
  }

  String _label() {
    switch (status) {
      case SessionStatus.draft:
        return 'Brouillon';
      case SessionStatus.published:
        return 'Publié';
      case SessionStatus.cancelled:
        return 'Annulé';
      case SessionStatus.completed:
        return 'Terminé';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
