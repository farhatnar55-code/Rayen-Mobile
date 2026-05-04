import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_role.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              tabs: const [Tab(text: 'Analyse'), Tab(text: 'Utilisateurs')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_UsersAnalyticsTab(), _UsersListTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersAnalyticsTab extends StatelessWidget {
  const _UsersAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (_, provider, __) {
        if (provider.usersStatus == AdminLoadStatus.loading &&
            provider.users.isEmpty) {
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
              _buildUsersByRoleChart(provider),
              const SizedBox(height: 24),
              _buildSubscriptionChart(provider),
              const SizedBox(height: 24),
              _buildActivityChart(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(AdminProvider provider) {
    final cards = [
      (
        'Total',
        '${provider.users.length}',
        Icons.people_rounded,
        AppColors.primary,
        const [AppColors.primary, AppColors.primaryLight],
      ),
      (
        'Actifs',
        '${provider.activeUsers}',
        Icons.check_circle_rounded,
        AppColors.success,
        const [AppColors.success, AppColors.success],
      ),
      (
        'Abonnés',
        '${provider.subscribedUsers}',
        Icons.card_membership_rounded,
        AppColors.accent,
        const [AppColors.accent, AppColors.accentLight],
      ),
      (
        'Taux',
        '${_calculateSubscriptionRate(provider)}%',
        Icons.trending_up_rounded,
        AppColors.info,
        const [AppColors.info, AppColors.info],
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
              gradient: card.$5,
            );
          },
        );
      },
    );
  }

  Widget _buildUsersByRoleChart(AdminProvider provider) {
    final usersByRole = provider.usersByRole;
    final total = usersByRole.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    const colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.accent,
      AppColors.categoryPrepaIntegre,
      AppColors.error,
    ];

    return _ModernChartCard(
      title: 'Par rôle',
      icon: Icons.pie_chart_rounded,
      iconColor: AppColors.primary,
      legend: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: usersByRole.entries.toList().asMap().entries.map((e) {
          final index = e.key;
          final entry = e.value;
          return _ChartLegendChip(
            color: colors[index % colors.length],
            label: entry.key.value,
          );
        }).toList(),
      ),
      child: SizedBox(
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
                radius: 45,
                titleStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionChart(AdminProvider provider) {
    if (provider.users.isEmpty) return const SizedBox.shrink();

    final subscribed = provider.subscribedUsers;
    final unsubscribed = provider.users.length - subscribed;

    return _ModernChartCard(
      title: 'Abonnements',
      icon: Icons.subscriptions_rounded,
      iconColor: AppColors.accent,
      legend: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ChartLegendChip(color: AppColors.success, label: 'Abonnés'),
          SizedBox(width: 16),
          _ChartLegendChip(color: AppColors.textHint, label: 'Gratuit'),
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
                value: subscribed.toDouble(),
                title:
                    '${(subscribed / provider.users.length * 100).toStringAsFixed(0)}%',
                radius: 45,
                titleStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: AppColors.textHint,
                value: unsubscribed.toDouble(),
                title:
                    '${(unsubscribed / provider.users.length * 100).toStringAsFixed(0)}%',
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

  Widget _buildActivityChart(AdminProvider provider) {
    return _ModernChartCard(
      title: 'Activité récente',
      icon: Icons.insights_rounded,
      iconColor: AppColors.info,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.divider.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final days = [
                      'Lun',
                      'Mar',
                      'Mer',
                      'Jeu',
                      'Ven',
                      'Sam',
                      'Dim',
                    ];
                    if (value.toInt() < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[value.toInt()],
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
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 3),
                  FlSpot(1, 5),
                  FlSpot(2, 4),
                  FlSpot(3, 7),
                  FlSpot(4, 6),
                  FlSpot(5, 8),
                  FlSpot(6, 5),
                ],
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateSubscriptionRate(AdminProvider provider) {
    if (provider.users.isEmpty) return 0;
    return ((provider.subscribedUsers / provider.users.length) * 100).round();
  }
}

class _UsersListTab extends StatelessWidget {
  const _UsersListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (_, provider, __) {
        if (provider.usersStatus == AdminLoadStatus.loading &&
            provider.users.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final users = provider.filteredUsers;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: context.read<AdminProvider>().setUserSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: provider.userSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                context
                                    .read<AdminProvider>()
                                    .setUserSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _RoleFilterChip(
                          label: 'Tous',
                          selected: provider.selectedRoleFilter == null,
                          onSelected: (_) =>
                              context.read<AdminProvider>().setRoleFilter(null),
                        ),
                        const SizedBox(width: 8),
                        ...UserRole.values.map(
                          (role) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _RoleFilterChip(
                              label: _roleLabel(role),
                              selected: provider.selectedRoleFilter == role,
                              onSelected: (_) => context
                                  .read<AdminProvider>()
                                  .setRoleFilter(role),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<AdminUserSortOption>(
                          initialValue: provider.userSortOption,
                          decoration: const InputDecoration(
                            labelText: 'Tri des utilisateurs',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: AdminUserSortOption.newest,
                              child: Text('Plus récents'),
                            ),
                            DropdownMenuItem(
                              value: AdminUserSortOption.oldest,
                              child: Text('Plus anciens'),
                            ),
                            DropdownMenuItem(
                              value: AdminUserSortOption.roleAsc,
                              child: Text('Rôle (A → Z)'),
                            ),
                            DropdownMenuItem(
                              value: AdminUserSortOption.roleDesc,
                              child: Text('Rôle (Z → A)'),
                            ),
                            DropdownMenuItem(
                              value: AdminUserSortOption.nameAsc,
                              child: Text('Nom (A → Z)'),
                            ),
                            DropdownMenuItem(
                              value: AdminUserSortOption.nameDesc,
                              child: Text('Nom (Z → A)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              context
                                  .read<AdminProvider>()
                                  .setUserSortOption(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => _showCreateUserDialog(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const _UsersEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: users.length,
                      itemBuilder: (_, index) {
                        final user = users[index];
                        return _UserListItem(user: user);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final UserModel user;

  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRoleColor(user.role).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildAvatarPlaceholder(),
                      errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.value,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getRoleColor(user.role),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (user.isSubscribed)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Abonné',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final admin = context.read<AdminProvider>();
              if (value == 'edit') {
                await _showEditUserDialog(context, user);
              } else if (value == 'toggle') {
                await admin.toggleUserActive(user.uid, !user.isActive);
              } else if (value == 'delete') {
                final confirmed = await _confirmUserDeletion(context, user);
                if (confirmed == true) {
                  await admin.deleteUser(user.uid);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Modifier'),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Text(user.isActive ? 'Bannir' : 'Réactiver'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.backgroundLight,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return AppColors.primary;
      case UserRole.instructor:
        return AppColors.info;
      case UserRole.organizer:
        return AppColors.accent;
      case UserRole.trainer:
        return AppColors.categoryPrepaIntegre;
      case UserRole.admin:
        return AppColors.error;
    }
  }
}

Future<void> _showCreateUserDialog(
  BuildContext context,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  UserRole selectedRole = UserRole.instructor;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ajouter un compte'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? '6 caractères minimum'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.instructor,
                          child: Text('Instructeur'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.trainer,
                          child: Text('Formateur'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedRole = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final ok = await context.read<AdminProvider>().createUser(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    fullName: nameController.text.trim(),
                    role: selectedRole,
                  );
                  if (ok && context.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Créer'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showEditUserDialog(BuildContext context, UserModel user) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: user.fullName);
  UserRole selectedRole = user.role;
  bool isActive = user.isActive;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Modifier le compte'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: user.email,
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      items: UserRole.values
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(_roleLabel(role)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      title: const Text('Compte actif'),
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final ok = await context.read<AdminProvider>().updateUser(
                    uid: user.uid,
                    fullName: nameController.text.trim(),
                    role: selectedRole,
                    isActive: isActive,
                  );
                  if (ok && context.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _roleLabel(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Étudiant';
    case UserRole.instructor:
      return 'Instructeur';
    case UserRole.organizer:
      return 'Organisateur';
    case UserRole.admin:
      return 'Administrateur';
    case UserRole.trainer:
      return 'Formateur';
  }
}

Future<bool?> _confirmUserDeletion(BuildContext context, UserModel user) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: Text(
          'Le compte de ${user.fullName} sera masqué de l\'administration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      );
    },
  );
}

class _RoleFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.3)
            : AppColors.divider,
      ),
      backgroundColor: AppColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _UsersEmptyState extends StatelessWidget {
  const _UsersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aucun utilisateur trouvé',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Ajustez vos filtres ou créez un nouveau compte.',
              style: GoogleFonts.inter(
                fontSize: 12,
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
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
  final Widget? legend;

  const _ModernChartCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.legend,
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
          if (legend != null) ...[const SizedBox(height: 16), legend!],
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
