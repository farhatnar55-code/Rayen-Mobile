import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/course/domain/models/course_lesson_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/presentation/providers/course_provider.dart';
import 'package:rayen_mobile/services/paymee_payment_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isProcessingEnrollment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<CourseProvider>().loadCourseDetails(
          userId: user.uid,
          courseId: widget.course.id,
        );
      }
    });
  }

  Future<void> _handleFreeEnrollment() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isProcessingEnrollment = true);

    final success = await context.read<CourseProvider>().enrollInFreeCourse(
      userId: user.uid,
      userFullName: user.fullName,
      courseId: widget.course.id,
      courseTitle: widget.course.title,
    );

    setState(() => _isProcessingEnrollment = false);

    if (mounted && success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inscription réussie!')));
    }
  }

  Future<void> _handlePaidEnrollment() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    if (user.phone == null || user.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez ajouter un numéro de téléphone à votre profil',
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessingEnrollment = true);

    final paymeeService = context.read<PaymeePaymentService>();
    final nameParts = user.fullName.trim().split(RegExp(r'\s+'));

    String firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
    String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : 'User';

    String phone = user.phone!;
    if (!phone.startsWith('+')) {
      if (phone.startsWith('216')) {
        phone = '+$phone';
      } else if (phone.length == 8 && int.tryParse(phone) != null) {
        phone = '+216$phone';
      }
    }

    final price = widget.course.price;
    final orderId =
        'CRS-${user.uid.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}';

    final result = await paymeeService.createPayment(
      amount: price,
      note: 'Cours: ${widget.course.title}',
      firstName: firstName,
      lastName: lastName,
      email: user.email,
      phone: phone,
      webhookUrl: 'https://rayen-academy.com/api/paymee/course-webhook',
      orderId: orderId,
    );

    if (!mounted) return;

    setState(() => _isProcessingEnrollment = false);

    if (result.success && result.paymentUrl != null) {
      final uri = Uri.parse(result.paymentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Erreur de paiement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CourseProvider, AuthProvider>(
      builder: (_, courseProvider, authProvider, __) {
        final isLoading =
            courseProvider.detailStatus == CourseDetailStatus.loading;
        final hasError =
            courseProvider.detailStatus == CourseDetailStatus.error;
        final isEnrolled = courseProvider.isEnrolled;
        final user = authProvider.user;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        courseProvider.detailErrorMessage ??
                            'Impossible de charger le cours.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 280,
                      backgroundColor: AppColors.primary,
                      leading: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildHero(),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 60,
                              left: 16,
                              right: 16,
                              child: _buildCourseBadges(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CourseHeaderCard(
                              course: widget.course,
                              isEnrolled: isEnrolled,
                            ),
                            if (!isEnrolled) ...[
                              const SizedBox(height: 20),
                              _EnrollmentCard(course: widget.course),
                            ],
                            if (isEnrolled) ...[
                              const SizedBox(height: 20),
                              _ModernProgressCard(
                                progress:
                                    (courseProvider.progress?.progressPercent ??
                                            0)
                                        .clamp(0, 100)
                                        .toDouble(),
                                lessonsDone:
                                    courseProvider
                                        .progress
                                        ?.completedLessonIds
                                        .length ??
                                    0,
                                totalLessons: courseProvider.lessons.length,
                                isFinished:
                                    courseProvider.progress?.isFinished ??
                                    false,
                              ),
                              const SizedBox(height: 20),
                              if (widget.course.pdfUrl != null &&
                                  widget.course.pdfUrl!.isNotEmpty)
                                _ModernPdfCard(pdfUrl: widget.course.pdfUrl!),
                              if (widget.course.pdfUrl != null &&
                                  widget.course.pdfUrl!.isNotEmpty)
                                const SizedBox(height: 20),
                              _SectionHeader(
                                title: 'Leçons du cours',
                                icon: Icons.play_circle_outline_rounded,
                                count: courseProvider.lessons.length,
                              ),
                              const SizedBox(height: 16),
                              if (courseProvider.lessons.isEmpty)
                                const _EmptyStateCard(
                                  icon: Icons.video_library_outlined,
                                  message: 'Aucune leçon disponible',
                                )
                              else
                                ...courseProvider.lessons.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _ModernLessonCard(
                                      lesson: entry.value,
                                      index: entry.key + 1,
                                      isCompleted:
                                          courseProvider
                                              .progress
                                              ?.completedLessonIds
                                              .contains(entry.value.id) ??
                                          false,
                                      onComplete: user == null
                                          ? null
                                          : () => context
                                                .read<CourseProvider>()
                                                .completeLesson(
                                                  userId: user.uid,
                                                  userFullName: user.fullName,
                                                  courseId: widget.course.id,
                                                  courseTitle:
                                                      widget.course.title,
                                                  lessonId: entry.value.id,
                                                  totalLessons: courseProvider
                                                      .lessons
                                                      .length,
                                                ),
                                    ),
                                  ),
                                ),
                              if (courseProvider.certificate != null) ...[
                                const SizedBox(height: 20),
                                _ModernCertificateCard(
                                  url: courseProvider
                                      .certificate!
                                      .certificateUrl,
                                ),
                              ],
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: user != null
              ? _buildBottomBar(
                  isEnrolled: isEnrolled,
                  isFree: widget.course.isFree,
                  isProcessing: _isProcessingEnrollment,
                )
              : null,
        );
      },
    );
  }

  Widget _buildHero() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.course.thumbnailUrl != null &&
            widget.course.thumbnailUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: widget.course.thumbnailUrl!,
            fit: BoxFit.cover,
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 80,
              color: Colors.white24,
            ),
          ),
      ],
    );
  }

  Widget _buildCourseBadges() {
    return Row(
      children: [
        _GradientBadge(
          label: widget.course.isFree == true
              ? 'Gratuit'
              : '${widget.course.price.toStringAsFixed(0)} DT',
          gradient: widget.course.isFree == true
              ? const LinearGradient(
                  colors: [AppColors.success, AppColors.gradientGreenDark],
                )
              : const LinearGradient(
                  colors: [AppColors.warning, AppColors.gradientOrangeDark],
                ),
        ),
        const SizedBox(width: 8),
        _GradientBadge(
          label: _getLevelLabel(widget.course.level),
          gradient: const LinearGradient(
            colors: [AppColors.info, AppColors.gradientBlue],
          ),
        ),
        const Spacer(),
        if (widget.course.studentsCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${widget.course.studentsCount}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getLevelLabel(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return 'Débutant';
      case CourseLevel.intermediate:
        return 'Intermédiaire';
      case CourseLevel.advanced:
        return 'Avancé';
      case CourseLevel.all:
        return 'Tous niveaux';
    }
  }

  Widget _buildBottomBar({
    required bool isEnrolled,
    required bool isFree,
    required bool isProcessing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: isEnrolled
            ? _AnimatedButton(
                onPressed: () {},
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                isProcessing: false,
                label: 'Commencer à apprendre',
                icon: Icons.play_arrow_rounded,
              )
            : isFree
            ? _AnimatedButton(
                onPressed: isProcessing ? null : _handleFreeEnrollment,
                gradient: const LinearGradient(
                  colors: [AppColors.success, AppColors.gradientGreenDark],
                ),
                isProcessing: isProcessing,
                label: "S'inscrire gratuitement",
                icon: Icons.school_rounded,
              )
            : _AnimatedButton(
                onPressed: isProcessing ? null : _handlePaidEnrollment,
                gradient: const LinearGradient(
                  colors: [AppColors.warning, AppColors.gradientOrangeDark],
                ),
                isProcessing: isProcessing,
                label: 'Acheter - ${widget.course.price.toStringAsFixed(2)} DT',
                icon: Icons.shopping_cart_rounded,
              ),
      ),
    );
  }
}

class _GradientBadge extends StatelessWidget {
  final String label;
  final LinearGradient gradient;

  const _GradientBadge({required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CourseHeaderCard extends StatelessWidget {
  final CourseModel course;
  final bool isEnrolled;

  const _CourseHeaderCard({required this.course, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              if (isEnrolled)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (course.instructorName != null)
                _InfoChip(
                  icon: Icons.person_rounded,
                  label: course.instructorName!,
                ),
              if (course.categoryName != null)
                _InfoChip(
                  icon: Icons.category_rounded,
                  label: course.categoryName!,
                ),
            ],
          ),
          if (course.shortDescription != null &&
              course.shortDescription!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      course.shortDescription!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final CourseModel course;

  const _EnrollmentCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final isFree = course.isFree == true;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isFree
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.success.withValues(alpha: 0.1),
                  AppColors.success.withValues(alpha: 0.05),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warning.withValues(alpha: 0.1),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isFree ? AppColors.success : AppColors.warning).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isFree ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isFree ? Icons.school_rounded : Icons.shopping_bag_rounded,
                  color: isFree ? AppColors.success : AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFree ? 'Cours gratuit' : 'Cours payant',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFree
                          ? 'Inscrivez-vous pour accéder au contenu complet'
                          : 'Achètez pour débloquer toutes les leçons',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const _FeatureChip(
                icon: Icons.play_lesson_rounded,
                label: 'Leçons vidéo',
              ),
              const SizedBox(width: 12),
              const _FeatureChip(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF inclus',
              ),
              const SizedBox(width: 12),
              if (course.certificateEnabled)
                const _FeatureChip(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Certificat',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernProgressCard extends StatelessWidget {
  final double progress;
  final int lessonsDone;
  final int totalLessons;
  final bool isFinished;

  const _ModernProgressCard({
    required this.progress,
    required this.lessonsDone,
    required this.totalLessons,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Progression',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFinished
                        ? [AppColors.success, AppColors.gradientGreenDark]
                        : [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                isFinished ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                icon: Icons.check_circle_outline_rounded,
                value: '$lessonsDone',
                label: 'Terminées',
                color: AppColors.success,
              ),
              _StatItem(
                icon: Icons.menu_book_rounded,
                value: '$totalLessons',
                label: 'Total',
                color: AppColors.primary,
              ),
              if (isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Terminé!',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
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

class _ModernPdfCard extends StatelessWidget {
  final String pdfUrl;
  const _ModernPdfCard({required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document du cours',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF complet du cours',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.error, AppColors.gradientDeepOrange],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(pdfUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernLessonCard extends StatelessWidget {
  final CourseLessonModel lesson;
  final int index;
  final bool isCompleted;
  final VoidCallback? onComplete;

  const _ModernLessonCard({
    required this.lesson,
    required this.index,
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? AppColors.success : AppColors.primary)
                .withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? const LinearGradient(
                            colors: [
                              AppColors.success,
                              AppColors.gradientGreenDark,
                            ],
                          )
                        : const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            '$index',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (lesson.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          lesson.description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    onPressed: lesson.videoUrl.isEmpty
                        ? null
                        : () async {
                            final uri = Uri.parse(lesson.videoUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Regarder',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    onPressed: isCompleted ? null : onComplete,
                    icon: isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    label: isCompleted ? 'Terminé' : 'Marquer',
                    color: isCompleted ? AppColors.success : AppColors.success,
                    filled: isCompleted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: onPressed == null ? AppColors.textSecondary : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onPressed == null ? AppColors.textSecondary : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernCertificateCard extends StatelessWidget {
  final String url;
  const _ModernCertificateCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientGold, AppColors.gradientOrange],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientGold.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Félicitations!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre certificat est disponible',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.download_rounded,
                  color: AppColors.gradientOrange,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final bool isProcessing;
  final String label;
  final IconData icon;

  const _AnimatedButton({
    required this.onPressed,
    required this.gradient,
    required this.isProcessing,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? AppColors.divider : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
