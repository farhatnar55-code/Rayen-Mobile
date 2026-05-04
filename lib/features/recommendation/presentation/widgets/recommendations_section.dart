import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/core/constants/app_dimensions.dart';
import 'package:rayen_mobile/features/course/presentation/screens/course_detail_screen.dart';
import 'package:rayen_mobile/features/course/presentation/providers/course_provider.dart';
import 'package:rayen_mobile/features/recommendation/domain/entities/recommendation_item.dart';
import 'package:rayen_mobile/features/recommendation/presentation/providers/recommendation_provider.dart';
import 'package:rayen_mobile/features/training/presentation/providers/training_provider.dart';
import 'package:rayen_mobile/features/training/presentation/screens/student_session_detail_screen.dart';

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();

    if (provider.state == RecommendationState.loading) {
      return _buildShimmer();
    }

    if (provider.state != RecommendationState.loaded ||
        provider.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.courses.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Cours recommandés',
            subtitle: 'Sélectionnés pour vous',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: AppDimensions.recommendationCourseSectionHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.courses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _RecommendedCourseCard(
                item: provider.courses[i],
                onTap: () => _navigateToCourse(context, provider.courses[i]),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (provider.sessions.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Sessions recommandées',
            subtitle: 'Formations adaptées à votre profil',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: AppDimensions.recommendationSessionSectionHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.sessions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _RecommendedSessionCard(
                item: provider.sessions[i],
                imageUrl: _resolveSessionImage(context, provider.sessions[i]),
                onTap: () => _navigateToSession(context, provider.sessions[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 20,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendedCourseCard extends StatelessWidget {
  final RecommendationItem item;
  final VoidCallback onTap;
  const _RecommendedCourseCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.recommendationCourseCardWidth,
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
                      height: AppDimensions.recommendationCourseImageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _CoursePlaceholder(),
                    )
                  : _CoursePlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _recommendationReason(item),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

void _navigateToCourse(BuildContext context, RecommendationItem item) {
  HapticFeedback.lightImpact();
  final courseProvider = context.read<CourseProvider>();
  final existingCourse = courseProvider.courses
      .where((c) => c.id == item.id)
      .firstOrNull;

  if (existingCourse != null) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            CourseDetailScreen(course: existingCourse),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails du cours "${item.title}" bientôt disponibles.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

void _navigateToSession(BuildContext context, RecommendationItem item) {
  HapticFeedback.lightImpact();
  final trainingProvider = context.read<TrainingProvider>();
  final existingSession = trainingProvider.sessions
      .where((s) => s.id == item.id)
      .firstOrNull;

  if (existingSession != null) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            StudentSessionDetailScreen(session: existingSession),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails de la session "${item.title}" bientôt disponibles.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

String _recommendationReason(RecommendationItem item) {
  final reasons = <String>[];

  if (item.category.isNotEmpty) {
    reasons.add('Correspond à votre intérêt pour ${item.category}');
  } else if (item.subtitle != null && item.subtitle!.isNotEmpty) {
    reasons.add('Aligné avec vos préférences en ${item.subtitle}');
  }

  if (item.popularityScore >= 0.7) {
    reasons.add('très demandé par les apprenants');
  } else if (item.recencyScore >= 0.7) {
    reasons.add('contenu récent');
  } else if (item.isFree) {
    reasons.add('accès gratuit');
  }

  if (reasons.isEmpty) {
    return 'Basé sur votre profil et votre activité récente.';
  }

  return 'Pourquoi: ${reasons.join(' • ')}.';
}

class _CoursePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.recommendationCourseImageHeight,
      color: AppColors.primarySurface,
      child: const Icon(
        Icons.play_circle_outline_rounded,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }
}

class _RecommendedSessionCard extends StatelessWidget {
  final RecommendationItem item;
  final String? imageUrl;
  final VoidCallback onTap;

  const _RecommendedSessionCard({
    required this.item,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.recommendationSessionCardWidth,
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  height: AppDimensions.recommendationSessionImageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(
                        height: AppDimensions.recommendationSessionImageHeight,
                        color: AppColors.primarySurface,
                      ),
                  errorWidget: (_, __, ___) => Container(
                    height: AppDimensions.recommendationSessionImageHeight,
                    color: AppColors.primarySurface,
                    child: const Icon(
                      Icons.event_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: AppDimensions.recommendationSessionImageHeight,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.event_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _recommendationReason(item),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recommandé',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _resolveSessionImage(BuildContext context, RecommendationItem item) {
  if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty) {
    return item.thumbnailUrl;
  }
  final trainingProvider = context.read<TrainingProvider>();
  final matchedSession = trainingProvider.sessions
      .where((s) => s.id == item.id)
      .firstOrNull;
  return matchedSession?.imageUrl;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
