import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCourses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 100, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Analyse'),
              Tab(text: 'Cours'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_CoursesAnalyticsTab(), _CoursesListTab()],
          ),
        ),
      ],
    );
  }
}

class _CoursesAnalyticsTab extends StatelessWidget {
  const _CoursesAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (_, provider, __) {
        if (provider.coursesStatus == AdminLoadStatus.loading &&
            provider.courses.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCards(provider),
              const SizedBox(height: 24),
              _buildFreeVsPaidChart(provider),
              const SizedBox(height: 24),
              _buildPublishedChart(provider),
              const SizedBox(height: 24),
              _buildCoursesByCategoryChart(provider),
              const SizedBox(height: 24),
              _buildTopRatedCourses(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(AdminProvider provider) {
    final freeCourses = provider.courses
        .where((c) => c.price == 0 || c.price == 0.0)
        .length;
    final paidCourses = provider.courses.length - freeCourses;

    final cards = [
      (
        'Total',
        '${provider.courses.length}',
        Icons.library_books_rounded,
        AppColors.primary,
        const [AppColors.primary, AppColors.primaryLight],
      ),
      (
        'Gratuits',
        '$freeCourses',
        Icons.card_giftcard_rounded,
        AppColors.success,
        null,
      ),
      (
        'Payants',
        '$paidCourses',
        Icons.paid_rounded,
        AppColors.accent,
        const [AppColors.accent, AppColors.accentLight],
      ),
      (
        'Prix moyen',
        '${_calculateAveragePrice(provider).toStringAsFixed(0)} TND',
        Icons.attach_money_rounded,
        AppColors.info,
        null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: compact ? 132 : 124,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) {
            final card = cards[i];
            return _ModernStatCard(
              label: card.$1,
              value: card.$2,
              icon: card.$3,
              color: card.$4,
              gradient: card.$5 ?? [card.$4, card.$4],
            );
          },
        );
      },
    );
  }

  Widget _buildFreeVsPaidChart(AdminProvider provider) {
    final freeCourses = provider.courses
        .where((c) => c.price == 0 || c.price == 0.0)
        .length;
    final paidCourses = provider.courses.length - freeCourses;
    final total = provider.courses.length;

    if (total == 0) return const SizedBox.shrink();

    return _ModernChartCard(
      title: 'Gratuits vs Payants',
      icon: Icons.monetization_on_rounded,
      iconColor: AppColors.accent,
      footer: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ChartLegendChip(color: AppColors.success, label: 'Gratuits'),
          SizedBox(width: 16),
          _ChartLegendChip(color: AppColors.accent, label: 'Payants'),
        ],
      ),
      child: SizedBox(
        height: 160,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 35,
            sections: [
              PieChartSectionData(
                color: AppColors.success,
                value: freeCourses.toDouble(),
                title: '${(freeCourses / total * 100).toStringAsFixed(0)}%',
                radius: 45,
                titleStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: AppColors.accent,
                value: paidCourses.toDouble(),
                title: '${(paidCourses / total * 100).toStringAsFixed(0)}%',
                radius: 45,
                titleStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishedChart(AdminProvider provider) {
    final published = provider.publishedCourses;
    final unpublished = provider.courses.length - published;
    final total = provider.courses.length;

    if (total == 0) return const SizedBox.shrink();

    return _ModernChartCard(
      title: 'Statut',
      icon: Icons.visibility_rounded,
      iconColor: AppColors.info,
      footer: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ChartLegendChip(color: AppColors.primary, label: 'Publiés'),
          SizedBox(width: 16),
          _ChartLegendChip(color: AppColors.textHint, label: 'Brouillons'),
        ],
      ),
      child: SizedBox(
        height: 160,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 35,
            sections: [
              PieChartSectionData(
                color: AppColors.primary,
                value: published.toDouble(),
                title: '${(published / total * 100).toStringAsFixed(0)}%',
                radius: 45,
                titleStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: AppColors.textHint,
                value: unpublished.toDouble(),
                title: '${(unpublished / total * 100).toStringAsFixed(0)}%',
                radius: 45,
                titleStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesByCategoryChart(AdminProvider provider) {
    final coursesByCategory = provider.coursesByCategory;
    if (coursesByCategory.isEmpty) return const SizedBox.shrink();

    const colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.accent,
      AppColors.warning,
      AppColors.categoryPrepaIntegre,
      AppColors.categoryISET,
    ];

    return _ModernChartCard(
      title: 'Par catégorie',
      icon: Icons.category_rounded,
      iconColor: AppColors.categoryPrepaIntegre,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY:
                coursesByCategory.values
                    .reduce((a, b) => a > b ? a : b)
                    .toDouble() *
                1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.textPrimary,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} cours',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final labels = coursesByCategory.keys.toList();
                    if (value.toInt() < labels.length) {
                      final label = labels[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label.length > 8
                              ? '${label.substring(0, 8)}...'
                              : label,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: coursesByCategory.entries.toList().asMap().entries.map((
              e,
            ) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value.toDouble(),
                    gradient: LinearGradient(
                      colors: [
                        colors[e.key % colors.length],
                        colors[e.key % colors.length].withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRatedCourses(AdminProvider provider) {
    final sortedCourses = List<CourseModel>.from(provider.courses)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final topCourses = sortedCourses.take(5).toList();

    if (topCourses.isEmpty) return const SizedBox.shrink();

    return _ModernChartCard(
      title: 'Mieux notés',
      icon: Icons.star_rounded,
      iconColor: AppColors.warning,
      child: Column(
        children: topCourses.map((course) {
          final rating = course.rating;
          final ratingPercent = (rating / 5) * 100;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.backgroundLight,
                  ),
                  child: course.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Icon(
                              Icons.image_rounded,
                              color: AppColors.textHint,
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.image_rounded,
                              color: AppColors.textHint,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.image_rounded,
                          color: AppColors.textHint,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratingPercent / 100,
                                backgroundColor: AppColors.divider,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.warning,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  double _calculateAveragePrice(AdminProvider provider) {
    final paidCourses = provider.courses.where((c) => c.price > 0).toList();
    if (paidCourses.isEmpty) return 0;
    final total = paidCourses.fold<double>(0, (sum, c) => sum + c.price);
    return total / paidCourses.length;
  }
}

class _CoursesListTab extends StatelessWidget {
  const _CoursesListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (_, provider, __) {
        if (provider.coursesStatus == AdminLoadStatus.loading &&
            provider.courses.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: provider.courses.length,
          itemBuilder: (_, index) {
            final course = provider.courses[index];
            return _CourseListItem(course: course);
          },
        );
      },
    );
  }
}

class _CourseListItem extends StatelessWidget {
  final CourseModel course;

  const _CourseListItem({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: course.thumbnailUrl == null
                ? ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: Icon(
                          Icons.image_rounded,
                          color: AppColors.textHint,
                          size: 32,
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_rounded,
                          color: AppColors.textHint,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.image_rounded,
                      color: AppColors.textHint,
                      size: 32,
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (course.price == 0 || course.price == 0.0)
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (course.price == 0 || course.price == 0.0)
                              ? 'Gratuit'
                              : '${course.price.toStringAsFixed(0)} TND',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (course.price == 0 || course.price == 0.0)
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${course.studentsCount} étudiants',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
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

class _ModernStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const _ModernStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  State<_ModernStatCard> createState() => _ModernStatCardState();
}

class _ModernStatCardState extends State<_ModernStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            Text(
              widget.value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? footer;

  const _ModernChartCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

class _ChartLegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
