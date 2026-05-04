import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/core/constants/app_dimensions.dart';
import 'package:rayen_mobile/core/utils/validators.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/training/domain/models/session_enrollment_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';
import 'package:rayen_mobile/features/training/presentation/providers/training_provider.dart';

class OrganizerSessionsScreen extends StatefulWidget {
  final String organizerId;

  const OrganizerSessionsScreen({super.key, required this.organizerId});

  @override
  State<OrganizerSessionsScreen> createState() =>
      _OrganizerSessionsScreenState();
}

class _OrganizerSessionsScreenState extends State<OrganizerSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainingProvider>().loadSessionsByOrganizer(
        widget.organizerId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('sessions_fab'),
        onPressed: () => _showCreateSessionSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Nouvelle session',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer<TrainingProvider>(
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
                      Icons.event_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune session créée',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre première session de formation.',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: provider.sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _OrganizerSessionCard(
              session: provider.sessions[i],
              organizerId: widget.organizerId,
            ),
          );
        },
      ),
    );
  }

  void _showCreateSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSessionSheet(
        organizerId: widget.organizerId,
        organizerName: context.read<AuthProvider>().user?.fullName ?? '',
      ),
    );
  }
}

class _OrganizerSessionCard extends StatelessWidget {
  final TrainingSessionModel session;
  final String organizerId;

  const _OrganizerSessionCard({
    required this.session,
    required this.organizerId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TrainingProvider>();
    final pending = provider.enrollments
        .where(
          (e) =>
              e.sessionId == session.id &&
              e.status == EnrollmentRequestStatus.pending,
        )
        .length;

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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (pending > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pending en attente',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    _StatusChip(status: session.status),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (_) => [
                        if (session.status == SessionStatus.draft)
                          PopupMenuItem(
                            value: 'publish',
                            child: _menuItem(
                              Icons.publish_rounded,
                              'Publier',
                              AppColors.success,
                            ),
                          ),
                        if (session.status == SessionStatus.published)
                          PopupMenuItem(
                            value: 'cancel',
                            child: _menuItem(
                              Icons.cancel_outlined,
                              'Annuler',
                              AppColors.error,
                            ),
                          ),
                        PopupMenuItem(
                          value: 'enrollments',
                          child: _menuItem(
                            Icons.people_rounded,
                            'Inscriptions',
                            AppColors.info,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: _menuItem(
                            Icons.delete_outline_rounded,
                            'Supprimer',
                            AppColors.error,
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        switch (value) {
                          case 'publish':
                            await provider.updateSessionStatus(
                              session.id,
                              SessionStatus.published,
                            );
                            break;
                          case 'cancel':
                            await provider.cancelSessionWithNotification(
                              session.id,
                            );
                            break;
                          case 'enrollments':
                            _showEnrollments(context, provider);
                            break;
                          case 'delete':
                            await provider.deleteSession(session.id);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  session.domain,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      session.trainerName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(
                      Icons.calendar_today_rounded,
                      DateFormat(
                        'dd MMM yyyy',
                        'fr',
                      ).format(session.sessionDate),
                    ),
                    const SizedBox(width: 12),
                    _chip(
                      Icons.people_rounded,
                      '${session.enrolledCount}/${session.maxParticipants}',
                    ),
                    const SizedBox(width: 12),
                    _chip(
                      Icons.attach_money_rounded,
                      session.isFree
                          ? 'Gratuit'
                          : '${session.price.toStringAsFixed(0)} TND',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: color)),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
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

  void _showEnrollments(BuildContext context, TrainingProvider provider) {
    provider.loadEnrollmentsBySession(session.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _EnrollmentsSheet(session: session),
      ),
    );
  }
}

class _EnrollmentsSheet extends StatelessWidget {
  final TrainingSessionModel session;

  const _EnrollmentsSheet({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Demandes d\'inscription',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<TrainingProvider>(
              builder: (_, provider, __) {
                if (provider.enrollmentsStatus == TrainingLoadStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final enrollments = provider.enrollments
                    .where((e) => e.sessionId == session.id)
                    .toList();

                if (enrollments.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune demande pour cette session.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: enrollments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _EnrollmentTile(enrollment: enrollments[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentTile extends StatelessWidget {
  final SessionEnrollmentModel enrollment;

  const _EnrollmentTile({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TrainingProvider>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 20,
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
                    fontSize: 13,
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
          if (enrollment.isPending)
            Row(
              children: [
                _actionButton(
                  icon: Icons.check_rounded,
                  color: AppColors.success,
                  onTap: () => provider.respondToEnrollment(
                    enrollment.id,
                    EnrollmentRequestStatus.approved,
                  ),
                ),
                const SizedBox(width: 8),
                _actionButton(
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  onTap: () => provider.respondToEnrollment(
                    enrollment.id,
                    EnrollmentRequestStatus.rejected,
                  ),
                ),
              ],
            )
          else
            _StatusPill(status: enrollment.status),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
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

class _StatusChip extends StatelessWidget {
  final SessionStatus status;
  const _StatusChip({required this.status});

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

class _CreateSessionSheet extends StatefulWidget {
  final String organizerId;
  final String organizerName;

  const _CreateSessionSheet({
    required this.organizerId,
    required this.organizerName,
  });

  @override
  State<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<_CreateSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _domainController = TextEditingController();
  final _linkController = TextEditingController();
  final _maxController = TextEditingController(text: '20');
  final _durationController = TextEditingController(text: '60');
  final _priceController = TextEditingController(text: '0');

  UserModel? _selectedTrainer;
  List<UserModel> _trainers = [];
  bool _loadingTrainers = true;
  DateTime _sessionDate = DateTime.now().add(const Duration(days: 7));
  bool _isFree = true;
  bool _certificateEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _domainController.dispose();
    _linkController.dispose();
    _maxController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .get();
      setState(() {
        _trainers = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();
        _loadingTrainers = false;
      });
    } catch (e) {
      setState(() => _loadingTrainers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nouvelle session',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      _titleController,
                      'Titre',
                      Icons.title_rounded,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      _descController,
                      'Description',
                      Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      _domainController,
                      'Domaine',
                      Icons.category_outlined,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 12),
                    _sectionLabel('Formateur'),
                    const SizedBox(height: 8),
                    _buildTrainerPicker(),
                    const SizedBox(height: 12),
                    _field(
                      _linkController,
                      'Lien de la session',
                      Icons.link_rounded,
                    ),
                    const SizedBox(height: 12),
                    _sectionLabel('Date de la session'),
                    const SizedBox(height: 8),
                    _buildDatePicker(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _durationController,
                            'Durée (min)',
                            Icons.access_time_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _maxController,
                            'Max participants',
                            Icons.people_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sectionLabel('Prix'),
                    Row(
                      children: [
                        Switch(
                          value: _isFree,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isFree = v),
                        ),
                        Text(
                          'Gratuit',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (!_isFree) ...[
                      const SizedBox(height: 8),
                      _field(
                        _priceController,
                        'Prix (TND)',
                        Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: _certificateEnabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _certificateEnabled = v),
                        ),
                        Text(
                          'Certificat à l\'issue',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.buttonRadius,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Créer la session',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  Widget _buildTrainerPicker() {
    if (_loadingTrainers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trainers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aucun formateur disponible. Créez d\'abord un compte formateur.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<UserModel>(
      initialValue: _selectedTrainer,
      hint: Text(
        'Sélectionner un formateur',
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint),
      ),
      validator: (_) => _selectedTrainer == null
          ? 'Veuillez sélectionner un formateur.'
          : null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.fitness_center_rounded, size: 18),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _trainers
          .map(
            (t) => DropdownMenuItem<UserModel>(
              value: t,
              child: Text(t.fullName, style: GoogleFonts.inter(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (t) => setState(() => _selectedTrainer = t),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMMM yyyy', 'fr').format(_sessionDate),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _sessionDate = picked);
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrainer == null) return;
    setState(() => _isLoading = true);

    final session = TrainingSessionModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      domain: _domainController.text.trim(),
      trainerId: _selectedTrainer!.uid,
      trainerName: _selectedTrainer!.fullName,
      organizerId: widget.organizerId,
      organizerName: widget.organizerName,
      sessionDate: _sessionDate,
      durationMinutes: int.tryParse(_durationController.text) ?? 60,
      maxParticipants: int.tryParse(_maxController.text) ?? 20,
      enrolledCount: 0,
      price: _isFree ? 0 : double.tryParse(_priceController.text) ?? 0,
      isFree: _isFree,
      currency: 'TND',
      meetingLink: _linkController.text.trim().isEmpty
          ? null
          : _linkController.text.trim(),
      status: SessionStatus.draft,
      certificateEnabled: _certificateEnabled,
      createdAt: DateTime.now(),
    );

    final success = await context.read<TrainingProvider>().createSession(
      session,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session créée avec succès.',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<TrainingProvider>().errorMessage ?? 'Erreur.',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
