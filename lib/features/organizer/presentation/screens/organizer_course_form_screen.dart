import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/presentation/providers/course_provider.dart';
import 'package:rayen_mobile/services/supabase_storage_service.dart';

class OrganizerCourseFormScreen extends StatefulWidget {
  final String organizerId;
  final CourseModel? course;

  const OrganizerCourseFormScreen({
    super.key,
    required this.organizerId,
    this.course,
  });

  @override
  State<OrganizerCourseFormScreen> createState() =>
      _OrganizerCourseFormScreenState();
}

class _OrganizerCourseFormScreenState extends State<OrganizerCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _pdfUrlController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _durationController;
  late final TextEditingController _certificateUrlController;

  UserModel? _selectedInstructor;
  bool _isFree = true;
  bool _isPublished = false;
  bool _certificateEnabled = false;
  String? _thumbnailUrl;
  bool _saving = false;

  static const String _defaultCertificateUrl =
      'https://rykvdlhfxvqymiwwxdkx.supabase.co/storage/v1/object/public/Rayen-Bucket/course-pdfs/certificate.pdf';

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _titleController = TextEditingController(text: course?.title ?? '');
    _descController = TextEditingController(
      text: course?.shortDescription ?? '',
    );
    _pdfUrlController = TextEditingController(text: course?.pdfUrl ?? '');
    _priceController = TextEditingController(
      text: course?.price.toStringAsFixed(2) ?? '0',
    );
    _originalPriceController = TextEditingController(
      text: course?.originalPrice?.toStringAsFixed(2) ?? '',
    );
    _currencyController = TextEditingController(
      text: course?.currency ?? 'TND',
    );
    _durationController = TextEditingController(text: course?.duration ?? '');
    _certificateUrlController = TextEditingController(
      text: course?.certificatePdfUrl ?? '',
    );
    _isFree = course?.isFree ?? true;
    _isPublished = course?.isPublished ?? false;
    _certificateEnabled = course?.certificateEnabled ?? false;
    _thumbnailUrl = course?.thumbnailUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pdfUrlController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _currencyController.dispose();
    _durationController.dispose();
    _certificateUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.course != null;
    final instructors = context
        .watch<AdminProvider>()
        .users
        .where((u) => u.role.name == 'instructor')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          editing ? 'Modifier le cours' : 'Nouveau cours',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ThumbnailSection(
                  thumbnailUrl: _thumbnailUrl,
                  onPick: _pickThumbnail,
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Informations',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      _StyledField(
                        controller: _titleController,
                        label: 'Titre du cours',
                        validator: _required,
                        prefixIcon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 16),
                      _StyledField(
                        controller: _descController,
                        label: 'Description',
                        maxLines: 3,
                        prefixIcon: Icons.description_rounded,
                      ),
                      const SizedBox(height: 16),
                      _InstructorDropdown(
                        instructors: instructors,
                        selectedInstructor: _selectedInstructor,
                        onChanged: (v) =>
                            setState(() => _selectedInstructor = v),
                        initialName: widget.course?.instructorName,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StyledField(
                              controller: _durationController,
                              label: 'Durée',
                              prefixIcon: Icons.timer_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StyledField(
                              controller: _currencyController,
                              label: 'Devise',
                              prefixIcon: Icons.attach_money_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Prix & Accès',
                  icon: Icons.payments_rounded,
                  child: Column(
                    children: [
                      _ToggleOption(
                        icon: Icons.money_off_rounded,
                        title: 'Cours gratuit',
                        subtitle: 'Accessible à tous sans paiement',
                        value: _isFree,
                        onChanged: (v) => setState(() => _isFree = v),
                        activeColor: AppColors.success,
                      ),
                      if (!_isFree) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StyledField(
                                controller: _priceController,
                                label: 'Prix',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.sell_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StyledField(
                                controller: _originalPriceController,
                                label: 'Ancien prix',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.discount_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Documents',
                  icon: Icons.folder_rounded,
                  child: _StyledField(
                    controller: _pdfUrlController,
                    label: 'URL du PDF du cours',
                    hint: 'https://...',
                    validator: _required,
                    prefixIcon: Icons.picture_as_pdf_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Certificat',
                  icon: Icons.verified_rounded,
                  child: Column(
                    children: [
                      _ToggleOption(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Activer le certificat',
                        subtitle: 'Délivrer un certificat à la fin',
                        value: _certificateEnabled,
                        onChanged: (v) =>
                            setState(() => _certificateEnabled = v),
                        activeColor: AppColors.accent,
                      ),
                      if (_certificateEnabled) ...[
                        const SizedBox(height: 16),
                        _StyledField(
                          controller: _certificateUrlController,
                          label: 'Modèle de certificat (optionnel)',
                          hint: 'Laissez vide pour le modèle par défaut',
                          prefixIcon: Icons.upload_rounded,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.info,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Si aucun modèle n\'est spécifié, le certificat par défaut sera utilisé.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Publication',
                  icon: Icons.publish_rounded,
                  child: _ToggleOption(
                    icon: Icons.public_rounded,
                    title: 'Publier le cours',
                    subtitle: 'Visible par les étudiants',
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_saving) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          editing ? Icons.save_rounded : Icons.add_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        _saving
                            ? 'Enregistrement...'
                            : (editing ? 'Mettre à jour' : 'Créer le cours'),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickThumbnail() async {
    try {
      final x = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final url = await SupabaseStorageService.uploadAvatar(
        uid: 'course_${widget.course?.id ?? widget.organizerId}',
        file: File(x.path),
      );
      setState(() => _thumbnailUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      String? certUrl;
      if (_certificateEnabled) {
        certUrl = _certificateUrlController.text.trim().isNotEmpty
            ? _certificateUrlController.text.trim()
            : _defaultCertificateUrl;
      }

      final course = CourseModel(
        id: widget.course?.id ?? '',
        title: _titleController.text.trim(),
        shortDescription: _descController.text.trim(),
        thumbnailUrl: _thumbnailUrl,
        pdfUrl: _pdfUrlController.text.trim(),
        certificateEnabled: _certificateEnabled,
        certificatePdfUrl: certUrl,
        instructorId: _selectedInstructor?.uid,
        instructorName:
            _selectedInstructor?.fullName ?? widget.course?.instructorName,
        organizerId: widget.organizerId,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        originalPrice: _isFree
            ? null
            : double.tryParse(_originalPriceController.text.trim()),
        isFree: _isFree,
        currency: _currencyController.text.trim().isEmpty
            ? 'TND'
            : _currencyController.text.trim(),
        rating: widget.course?.rating ?? 0,
        reviewsCount: widget.course?.reviewsCount ?? 0,
        studentsCount: widget.course?.studentsCount ?? 0,
        level: widget.course?.level ?? CourseLevel.beginner,
        type: widget.course?.type ?? CourseType.video,
        isPublished: _isPublished,
      );

      if (widget.course == null) {
        await context.read<CourseProvider>().createCourse(course);
      } else {
        await context.read<CourseProvider>().updateCourse(course);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;
}

class _ThumbnailSection extends StatelessWidget {
  final String? thumbnailUrl;
  final VoidCallback onPick;
  const _ThumbnailSection({this.thumbnailUrl, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: thumbnailUrl == null || thumbnailUrl!.isEmpty
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Positioned(bottom: 12, right: 12, child: _EditBadge()),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ajouter une miniature',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to upload',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EditBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData? prefixIcon;

  const _StyledField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textSecondary, size: 22)
            : null,
        filled: true,
        fillColor: AppColors.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _InstructorDropdown extends StatelessWidget {
  final List<UserModel> instructors;
  final UserModel? selectedInstructor;
  final ValueChanged<UserModel?> onChanged;
  final String? initialName;

  const _InstructorDropdown({
    required this.instructors,
    required this.selectedInstructor,
    required this.onChanged,
    this.initialName,
  });

  @override
  Widget build(BuildContext context) {
    final hasInitial = initialName != null && initialName!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserModel?>(
          value: selectedInstructor,
          hint: Text(
            hasInitial ? initialName! : 'Sélectionner un instructeur',
            style: GoogleFonts.inter(
              color: hasInitial
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
          ),
          dropdownColor: Colors.white,
          items: [
            const DropdownMenuItem<UserModel?>(
              value: null,
              child: Text(
                'Aucun',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ...instructors.map(
              (i) => DropdownMenuItem<UserModel?>(
                value: i,
                child: Text(
                  i.fullName,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withValues(alpha: 0.08)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: activeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
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
          Container(
            decoration: BoxDecoration(
              color: value ? activeColor : AppColors.divider,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: activeColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}
