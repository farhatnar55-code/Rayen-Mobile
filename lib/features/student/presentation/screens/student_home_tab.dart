import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/core/constants/app_dimensions.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/presentation/providers/course_provider.dart';
import 'package:rayen_mobile/features/course/presentation/screens/course_detail_screen.dart';
import 'package:rayen_mobile/features/course/presentation/screens/course_screen.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';
import 'package:rayen_mobile/features/training/presentation/providers/training_provider.dart';
import 'package:rayen_mobile/features/training/presentation/screens/student_session_detail_screen.dart';
import 'package:rayen_mobile/features/training/presentation/screens/student_sessions_screen.dart';
import 'package:rayen_mobile/features/training/presentation/screens/student_enrollments_screen.dart';
import 'package:rayen_mobile/features/recommendation/presentation/providers/recommendation_provider.dart';
import 'package:rayen_mobile/features/recommendation/presentation/widgets/recommendations_section.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  final PageController _carouselController = PageController(
    viewportFraction: 0.85,
  );
  Timer? _carouselTimer;
  int _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      final courseProvider = context.read<CourseProvider>();
      final trainingProvider = context.read<TrainingProvider>();
      final authProvider = context.read<AuthProvider>();
      final recommendationProvider = context.read<RecommendationProvider>();
      Future.microtask(() {
        if (!mounted) return;
        courseProvider.loadCourses();
        trainingProvider.loadPublishedSessions();

        final user = authProvider.user;
        if (user != null) {
          recommendationProvider.load(
            userId: user.uid,
            fieldOfStudies: user.fieldOfStudies ?? '',
          );
        }
      });
    });
  }

  void _startAutoScroll(int itemCount) {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_carouselController.hasClients) {
        final nextPage = (_currentCarouselPage + 1) % itemCount;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.fullName.split(' ').first ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        final courseProvider = context.read<CourseProvider>();
        final trainingProvider = context.read<TrainingProvider>();
        if (!mounted) return;
        await courseProvider.loadCourses();
        if (!mounted) return;
        await trainingProvider.loadPublishedSessions();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimatedSlide(
              controller: _entranceController,
              delay: 0.0,
              child: _buildGreetingBanner(firstName),
            ),
            const SizedBox(height: 20),
            _AnimatedSlide(
              controller: _entranceController,
              delay: 0.1,
              child: _buildPlatformStats(),
            ),
            const SizedBox(height: 20),
            _AnimatedSlide(
              controller: _entranceController,
              delay: 0.13,
              child: _buildMyTrainingsCard(context),
            ),
            const SizedBox(height: 20),
            _AnimatedSlide(
              controller: _entranceController,
              delay: 0.15,
              child: _buildCategorySection(context),
            ),
            const SizedBox(height: 20),
            _buildFeaturedCoursesCarousel(),
            const SizedBox(height: 20),
            const RecommendationsSection(),
            const SizedBox(height: 20),
            _AnimatedSlide(
              controller: _entranceController,
              delay: 0.25,
              child: _buildUpcomingSessions(),
            ),
            const SizedBox(height: 20),
            _AnimatedSlide(
              controller: _entranceController,
              delay: 0.3,
              child: _buildAboutBanner(),
            ),
            const SizedBox(height: 20),
            _AnimatedSlide(
              controller: _entranceController,
              delay: 0.35,
              child: _buildMotivationalCard(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingBanner(String firstName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
        ? 'Bon après-midi'
        : 'Bonsoir';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientDarkGreen, AppColors.primary],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: _PulsingCircle(
              size: 140,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: _PulsingCircle(
              size: 100,
              color: Colors.white.withValues(alpha: 0.05),
              delay: const Duration(milliseconds: 500),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $firstName',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prêt à apprendre quelque chose de nouveau aujourd\'hui ?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Continuez sur votre lancée !',
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
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              fallbackIcon: Icons.school_rounded,
              value: '106',
              label: 'Instructeurs',
              color: AppColors.primary,
              onTap: () => _openCoursesList(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatItem(
              fallbackIcon: Icons.people_rounded,
              value: '955',
              label: 'Étudiants',
              color: AppColors.info,
              onTap: () => _openSessionsList(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatItem(
              fallbackIcon: Icons.play_circle_rounded,
              value: '127',
              label: 'Vidéos',
              color: AppColors.accent,
              onTap: () => _openCoursesList(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTrainingsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentEnrollmentsScreen()),
        );
        HapticFeedback.lightImpact();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: AppDimensions.studentTrainingsCardHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.how_to_reg_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes Inscriptions',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consultez vos inscriptions',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    const categories = [
      _Category(
        label: 'Prépa 1',
        icon: Icons.looks_one_rounded,
        color: AppColors.categoryPrepa1,
        id: '1re-anne-Cycle-prparatoire',
        imageUrl:
            'https://rayen-academy.com/store/1060/icones%20pr%C3%A9pa/icone%20PREPA1.png',
      ),
      _Category(
        label: 'Prépa 2',
        icon: Icons.looks_two_rounded,
        color: AppColors.categoryPrepa2,
        id: '2me-anne-cycle-prparatoire',
        imageUrl:
            'https://rayen-academy.com/store/1060/icones%20pr%C3%A9pa/icone%20prepa2.jpeg',
      ),
      _Category(
        label: 'Intégré',
        icon: Icons.integration_instructions_rounded,
        color: AppColors.categoryPrepaIntegre,
        id: 'Cours-de-consolidation-cycle-prparatoire-Intgre',
        imageUrl: 'https://rayen-academy.com/store/1060/images%20(1).png',
      ),
      _Category(
        label: 'Qualification',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.categoryQualification,
        id: 'Qualification-des-comptences',
        imageUrl:
            'https://rayen-academy.com/store/1060/Qualification/logo-qualification.png',
      ),
      _Category(
        label: 'ISET',
        icon: Icons.business_center_rounded,
        color: AppColors.categoryISET,
        id: 'DépTechnologies de l\'informatique IT-ISET',
        imageUrl: 'https://rayen-academy.com/store/1060/images.png',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Catégories',
          subtitle: 'Explorez par domaine',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final cat = categories[i];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + i * 100),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0, end: 1),
                builder: (_, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: GestureDetector(
                  onTap: () {
                    context.read<CourseProvider>().selectCategory(cat.id);
                    _openCoursesList(context);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cat.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: cat.imageUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Icon(cat.icon, color: cat.color, size: 28),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cat.color,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCoursesCarousel() {
    return Consumer<CourseProvider>(
      builder: (_, provider, __) {
        if (provider.status == CourseLoadStatus.loading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                title: 'Publications en vedette',
                subtitle: 'Parcourez les cours en vedette',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => const _CourseCardSkeleton(),
                ),
              ),
            ],
          );
        }

        final courses = provider.courses.take(8).toList();
        if (courses.isEmpty) return const SizedBox.shrink();

        _startAutoScroll(courses.length);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Publications en vedette',
              subtitle: 'Parcourez les cours en vedette',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: PageView.builder(
                controller: _carouselController,
                onPageChanged: (page) {
                  setState(() => _currentCarouselPage = page);
                },
                itemCount: courses.length,
                itemBuilder: (_, i) {
                  final course = courses[i];
                  final isCurrent = i == _currentCarouselPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: _HeroCourseCard(
                      course: course,
                      isHighlighted: isCurrent,
                      onTap: () => _navigateToCourseDetail(context, course),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                courses.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentCarouselPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentCarouselPage == i
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingSessions() {
    return Consumer<TrainingProvider>(
      builder: (_, provider, __) {
        if (provider.sessionsStatus == TrainingLoadStatus.loading) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        final sessions = provider.sessions
            .where((s) => s.sessionDate.isAfter(now) && !s.isFull)
            .take(5)
            .toList();

        if (sessions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Sessions à venir',
              subtitle: 'Formations en ligne disponibles',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: AppDimensions.studentUpcomingSessionsListHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _SessionCard(
                  session: sessions[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, anim, __) =>
                            StudentSessionDetailScreen(session: sessions[i]),
                        transitionsBuilder: (_, anim, __, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.easeInOutCubic,
                                  ),
                                ),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 350),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          image: const DecorationImage(
            image: NetworkImage(
              'https://rayen-academy.com/store/1060/logooo%20(1).png',
            ),
            fit: BoxFit.contain,
            alignment: Alignment.centerRight,
            opacity: 0.06,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://rayen-academy.com/store/1060/logooo%20(1).png',
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Rayen Academy',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Votre partenaire e-learning pour la consolidation et la réussite académique.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nos experts qualifiés proposent des supports pédagogiques sous forme de vidéos pré-enregistrées avec des résumés précis, des exemples concrets, et des quiz interactifs.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeaturePill(
                  icon: Icons.video_library_rounded,
                  label: 'Vidéos HD',
                ),
                _FeaturePill(
                  icon: Icons.quiz_rounded,
                  label: 'Quiz interactifs',
                ),
                _FeaturePill(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Certifications',
                ),
                _FeaturePill(
                  icon: Icons.support_agent_rounded,
                  label: 'Téléconsultation',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalCard() {
    const quotes = [
      _Quote(
        text:
            'L\'éducation est l\'arme la plus puissante pour changer le monde.',
        author: 'Nelson Mandela',
      ),
      _Quote(
        text:
            'Le succès n\'est pas la clé du bonheur. Le bonheur est la clé du succès.',
        author: 'Albert Schweitzer',
      ),
      _Quote(
        text:
            'La connaissance est la seule chose qui grandit lorsqu\'on la partage.',
        author: 'Sagesse populaire',
      ),
      _Quote(
        text: 'Chaque expert a un jour été un débutant. Continuez à apprendre.',
        author: 'Helen Hayes',
      ),
    ];

    final quote = quotes[DateTime.now().day % quotes.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              quote.text,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '— ${quote.author}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCourseDetail(BuildContext context, CourseModel course) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => CourseDetailScreen(course: course),
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
  }

  void _openCoursesList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesScreen()),
    );
  }

  void _openSessionsList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentSessionsScreen()),
    );
  }
}

class _AnimatedSlide extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedSlide({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final start = delay;
        final end = (delay + 0.3).clamp(0.0, 1.0);
        final progress = ((controller.value - start) / (end - start)).clamp(
          0.0,
          1.0,
        );
        final curve = Curves.easeOutCubic.transform(progress);

        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: child,
          ),
        );
      },
    );
  }
}

class _PulsingCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration delay;

  const _PulsingCircle({
    required this.size,
    required this.color,
    this.delay = Duration.zero,
  });

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
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
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData fallbackIcon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatItem({
    required this.fallbackIcon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(fallbackIcon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCourseCard extends StatelessWidget {
  final CourseModel course;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _HeroCourseCard({
    required this.course,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isHighlighted ? 16 : 8,
              offset: Offset(0, isHighlighted ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: course.thumbnailUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  if (course.isFree)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Gratuit',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (course.categoryName != null)
                      Text(
                        course.categoryName!,
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
                      course.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      course.isFree
                          ? 'Gratuit'
                          : '${course.price.toStringAsFixed(0)} TND',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: course.isFree
                            ? AppColors.success
                            : AppColors.primary,
                      ),
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

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      color: AppColors.primarySurface,
      child: const Icon(
        Icons.school_outlined,
        color: AppColors.primary,
        size: 36,
      ),
    );
  }
}

class _CourseCardSkeleton extends StatelessWidget {
  const _CourseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 60, height: 8, color: AppColors.shimmerBase),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 10,
                    color: AppColors.shimmerBase,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 10,
                    color: AppColors.shimmerBase,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TrainingSessionModel session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = session.imageUrl != null && session.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.studentSessionCardWidth,
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
                  height: AppDimensions.studentSessionCardImageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(
                        height: AppDimensions.studentSessionCardImageHeight,
                        color: AppColors.primarySurface,
                      ),
                  errorWidget: (_, __, ___) => Container(
                    height: AppDimensions.studentSessionCardImageHeight,
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
                height: AppDimensions.studentSessionCardImageHeight,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.event_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.domain,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 10,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM', 'fr').format(session.sessionDate),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        session.isFree
                            ? 'Gratuit'
                            : '${session.price.toStringAsFixed(0)} TND',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: session.isFree
                              ? AppColors.success
                              : AppColors.primary,
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

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Category {
  final String label;
  final IconData icon;
  final Color color;
  final String id;
  final String imageUrl;

  const _Category({
    required this.label,
    required this.icon,
    required this.color,
    required this.id,
    required this.imageUrl,
  });
}

class _Quote {
  final String text;
  final String author;
  const _Quote({required this.text, required this.author});
}
