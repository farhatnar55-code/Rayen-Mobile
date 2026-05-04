import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:rayen_mobile/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:rayen_mobile/features/admin/presentation/screens/admin_courses_screen.dart';
import 'package:rayen_mobile/features/admin/presentation/screens/admin_sessions_screen.dart';
import 'package:rayen_mobile/features/admin/presentation/screens/admin_categories_screen.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_role.dart';
import 'package:rayen_mobile/features/notifications/presentation/providers/notification_provider.dart';
import 'package:rayen_mobile/features/notifications/presentation/screens/notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _menuController;
  late Animation<double> _menuAnimation;

  final List<_DrawerItem> _items = const [
    _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _DrawerItem(icon: Icons.people_rounded, label: 'Utilisateurs'),
    _DrawerItem(icon: Icons.library_books_rounded, label: 'Cours'),
    _DrawerItem(icon: Icons.event_rounded, label: 'Sessions'),
    _DrawerItem(icon: Icons.category_rounded, label: 'Catégories'),
  ];

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAllData();
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<NotificationProvider>().loadNotifications(uid);
      }
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBodyBehindAppBar: false,
      appBar: _buildModernAppBar(),
      drawer: _buildModernDrawer(user?.fullName ?? 'Admin', user?.photoUrl),
      body: Stack(children: [const _BackgroundDecorations(), _buildBody()]),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Builder(
                  builder: (context) => _AnimatedIconButton(
                    icon: Icons.menu_rounded,
                    onTap: () => Scaffold.of(context).openDrawer(),
                    controller: _menuAnimation,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _items[_selectedIndex].label,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildHeaderActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        Consumer<NotificationProvider>(
          builder: (_, notifications, __) => Stack(
            clipBehavior: Clip.none,
            children: [
              _GlassIconButton(
                icon: Icons.notifications_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (notifications.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      notifications.unreadCount > 9
                          ? '9+'
                          : '${notifications.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _GlassIconButton(icon: Icons.settings_outlined, onTap: () {}),
      ],
    );
  }


  Widget _buildModernDrawer(String name, String? avatarUrl) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Column(
          children: [
            _buildDrawerHeader(name, avatarUrl),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _items.length,
                itemBuilder: (_, i) => _buildDrawerTile(i),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildSignOutTile(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String name, String? avatarUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Administrateur',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(int index) {
    final item = _items[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.3))
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(item.icon, color: Colors.white, size: 24),
          title: Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: Colors.white,
            ),
          ),
          trailing: isSelected
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                )
              : null,
          onTap: () {
            setState(() => _selectedIndex = index);
            Navigator.of(context).pop();

            final provider = context.read<AdminProvider>();
            switch (index) {
              case 1:
                if (provider.usersStatus == AdminLoadStatus.initial) {
                  provider.loadUsers();
                }
                break;
              case 2:
                if (provider.coursesStatus == AdminLoadStatus.initial) {
                  provider.loadCourses();
                }
                break;
              case 3:
                if (provider.sessionsStatus == AdminLoadStatus.initial) {
                  provider.loadSessions();
                }
                break;
              case 4:
                if (provider.categoriesStatus == AdminLoadStatus.initial) {
                  provider.loadCategories();
                }
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildSignOutTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(
          Icons.logout_rounded,
          color: Colors.white70,
          size: 24,
        ),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
        onTap: () async {
          Navigator.of(context).pop();
          await context.read<AuthProvider>().signOut();
        },
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _buildScreenContent(),
    );
  }

  Widget _buildScreenContent() {
    switch (_selectedIndex) {
      case 0:
        return const _DashboardOverview(key: ValueKey('dashboard'));
      case 1:
        return const AdminUsersScreen(key: ValueKey('users'));
      case 2:
        return const AdminCoursesScreen(key: ValueKey('courses'));
      case 3:
        return const AdminSessionsScreen(key: ValueKey('sessions'));
      case 4:
        return const AdminCategoriesScreen(key: ValueKey('categories'));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  const _DrawerItem({required this.icon, required this.label});
}

class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: _FloatingCircle(
            size: 300,
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -150,
          child: _FloatingCircle(
            size: 250,
            color: AppColors.accent.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          top: 400,
          right: -50,
          child: _FloatingCircle(
            size: 150,
            color: AppColors.info.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _FloatingCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Animation<double> controller;

  const _AnimatedIconButton({
    required this.icon,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * math.pi,
          child: child,
        );
      },
      child: _GlassIconButton(icon: icon, onTap: onTap),
    );
  }
}

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (_, provider, __) {
        if (provider.statsStatus == AdminLoadStatus.loading &&
            provider.users.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => provider.loadAllData(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeBanner(provider),
                const SizedBox(height: 24),
                _buildStatCards(provider),
                const SizedBox(height: 32),
                _buildUsersChart(provider),
                const SizedBox(height: 24),
                _buildCoursesByCategory(provider),
                const SizedBox(height: 24),
                _buildSessionsOverview(provider),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeBanner(AdminProvider provider) {
    return _ModernCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryLight],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue Admin !',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voici un aperçu de votre plateforme',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 116,
                      child: _BannerStat(
                        value: '${provider.users.length}',
                        label: 'Utilisateurs',
                        icon: Icons.people_rounded,
                      ),
                    ),
                    SizedBox(
                      width: 116,
                      child: _BannerStat(
                        value: '${provider.courses.length}',
                        label: 'Cours',
                        icon: Icons.library_books_rounded,
                      ),
                    ),
                    SizedBox(
                      width: 116,
                      child: _BannerStat(
                        value: '${provider.totalPublishedSessions}',
                        label: 'Sessions',
                        icon: Icons.event_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(AdminProvider provider) {
    final cards = <_StatCardData>[
      _StatCardData(
        label: 'Utilisateurs',
        value: '${provider.stats['totalUsers'] ?? provider.users.length}',
        icon: Icons.people_rounded,
        color: AppColors.primary,
        gradient: const [AppColors.primary, AppColors.primaryLight],
      ),
      _StatCardData(
        label: 'Étudiants',
        value: '${provider.totalStudents}',
        icon: Icons.school_rounded,
        color: AppColors.info,
        gradient: [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
      ),
      _StatCardData(
        label: 'Instructeurs',
        value: '${provider.totalInstructors}',
        icon: Icons.person_rounded,
        color: AppColors.accent,
        gradient: const [AppColors.accent, AppColors.accentLight],
      ),
      _StatCardData(
        label: 'Cours',
        value: '${provider.stats['totalCourses'] ?? provider.courses.length}',
        icon: Icons.library_books_rounded,
        color: AppColors.warning,
        gradient: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
      ),
      _StatCardData(
        label: 'Gratuits',
        value: '${provider.freeCourses}',
        icon: Icons.card_giftcard_rounded,
        color: AppColors.success,
        gradient: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
      ),
      _StatCardData(
        label: 'Sessions',
        value: '${provider.totalPublishedSessions}',
        icon: Icons.event_rounded,
        color: AppColors.categoryPrepaIntegre,
        gradient: [
          AppColors.categoryPrepaIntegre,
          AppColors.categoryPrepaIntegre.withValues(alpha: 0.7),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isCompact ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: isCompact ? 132 : 122,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => _AnimatedStatCard(data: cards[i]),
        );
      },
    );
  }

  Widget _buildUsersChart(AdminProvider provider) {
    final usersByRole = provider.usersByRole;
    final total = usersByRole.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.accent,
      AppColors.categoryPrepaIntegre,
      AppColors.error,
    ];

    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Utilisateurs par rôle',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 35,
                sections: usersByRole.entries.toList().asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  final percentage = (entry.value / total * 100);
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: entry.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: usersByRole.entries.toList().asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              return _ChartLegendItem(
                color: colors[index % colors.length],
                label: entry.key.value,
                value: entry.value,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesByCategory(AdminProvider provider) {
    final coursesByCategory = provider.coursesByCategory;
    if (coursesByCategory.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.accent,
      AppColors.warning,
      AppColors.categoryPrepaIntegre,
      AppColors.categoryISET,
    ];

    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cours par catégorie',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
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
                        '${rod.toY.toInt()}',
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
                      getTitlesWidget: (value, meta) {
                        final labels = coursesByCategory.keys.toList();
                        if (value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()].substring(0, 3),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
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
                barGroups: coursesByCategory.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.value.toDouble(),
                            color: colors[e.key % colors.length],
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsOverview(AdminProvider provider) {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.categoryPrepaIntegre.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  size: 20,
                  color: AppColors.categoryPrepaIntegre,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Aperçu des Sessions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SessionStatItem(
                  label: 'Publiées',
                  value: '${provider.totalPublishedSessions}',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SessionStatItem(
                  label: 'Brouillons',
                  value: '${provider.totalDraftSessions}',
                  color: AppColors.warning,
                  icon: Icons.edit_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SessionStatItem(
                  label: 'Participants',
                  value: '${provider.totalEnrolledParticipants}',
                  color: AppColors.info,
                  icon: Icons.people_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _BannerStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _ModernCard extends StatefulWidget {
  final Widget child;
  final Gradient? gradient;

  const _ModernCard({required this.child, this.gradient});

  @override
  State<_ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<_ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (widget.gradient?.colors.first ?? AppColors.primary)
                  .withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.gradient == null
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [widget.child],
                ),
              )
            : widget.child,
      ),
    );
  }
}

class _AnimatedStatCard extends StatefulWidget {
  final _StatCardData data;

  const _AnimatedStatCard({required this.data});

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _countAnimation;
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _countAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();

    _countAnimation.addListener(() {
      final targetValue = int.tryParse(widget.data.value) ?? 0;
      setState(() {
        _displayValue = (targetValue * _countAnimation.value).round();
      });
    });
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.data.gradient[0], widget.data.gradient[1]],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.data.color.withValues(alpha: 0.3),
              blurRadius: 11,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.data.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              '$_displayValue',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              widget.data.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label ($value)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SessionStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SessionStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
