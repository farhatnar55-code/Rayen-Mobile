import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/core/constants/app_dimensions.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';
import 'package:rayen_mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:rayen_mobile/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:rayen_mobile/services/supabase_storage_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _gradeController = TextEditingController();
  final _fieldController = TextEditingController();

  File? _imageFile;
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  int _currentStep = 0;

  List<Map<String, String>> _fieldsOfStudies = [];
  Map<String, List<Map<String, String>>> _groupedFields = {};
  bool _fieldsLoaded = false;
  String? _selectedFieldId;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFieldsOfStudies();
  }

  Future<void> _loadFieldsOfStudies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fields_of_studies')
          .orderBy('order')
          .get();

      final fields = snapshot.docs
          .map(
            (doc) => <String, String>{
              'id': doc.id,
              'name': doc.data()['name'] as String? ?? '',
              'category': doc.data()['category'] as String? ?? '',
              'icon': doc.data()['icon'] as String? ?? 'category',
            },
          )
          .toList();

      final grouped = <String, List<Map<String, String>>>{};
      for (final field in fields) {
        final category = field['category']!;
        grouped.putIfAbsent(category, () => []).add(field);
      }

      if (mounted) {
        setState(() {
          _fieldsOfStudies = fields;
          _groupedFields = grouped;
          _fieldsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _fieldsLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _gradeController.dispose();
    _fieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: _currentStep == 0
                      ? _buildPhotoStep()
                      : _buildInfoStep(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientDarkGreen, AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compléter le profil',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quelques informations pour personnaliser votre expérience.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          _stepDot(0, 'Photo'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 0 ? AppColors.primary : AppColors.divider,
            ),
          ),
          _stepDot(1, 'Infos'),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? AppColors.primary
                : AppColors.backgroundLight,
            border: Border.all(
              color: isActive || isCompleted
                  ? AppColors.primary
                  : AppColors.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySurface,
                    border: Border.all(
                      color: _imageFile != null
                          ? AppColors.primary
                          : AppColors.divider,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Ajouter une photo de profil',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Optionnel — vous pouvez la modifier à tout moment.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library_rounded, size: 18),
          label: Text(
            'Choisir une photo',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_imageFile != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _imageFile = null),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: AppColors.error,
            ),
            label: Text(
              'Supprimer la photo',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          controller: _phoneController,
          label: 'Numéro de téléphone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Le numéro de téléphone est obligatoire.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _sectionLabel('Date de naissance'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cake_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  _dateOfBirth != null
                      ? DateFormat('dd MMMM yyyy', 'fr').format(_dateOfBirth!)
                      : 'Sélectionner une date',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _dateOfBirth != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_dateOfBirth == null && _formKey.currentState != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              'La date de naissance est obligatoire.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
            ),
          ),
        const SizedBox(height: 14),
        _field(
          controller: _gradeController,
          label: 'Niveau / Classe',
          icon: Icons.school_outlined,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Le niveau est obligatoire.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _sectionLabel('Filière / Spécialité'),
        const SizedBox(height: 8),
        _buildFieldDropdown(),
        if (_selectedFieldId == null && _formKey.currentState != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              'La filière est obligatoire.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
            ),
          ),
        const SizedBox(height: 14),
        _field(
          controller: _cityController,
          label: 'Ville (optionnel)',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _bioController,
          label: 'Bio (optionnel)',
          icon: Icons.info_outline_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFieldDropdown() {
    if (!_fieldsLoaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement des filières...',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _showFieldPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedFieldId != null
                ? AppColors.primary
                : AppColors.inputBorder,
            width: _selectedFieldId != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.category_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedFieldId != null
                    ? (_fieldsOfStudies
                              .cast<Map<String, String>>()
                              .where((f) => f['id'] == _selectedFieldId)
                              .firstOrNull?['name'] ??
                          'Sélectionner une filière')
                    : 'Sélectionner une filière',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _selectedFieldId != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFieldPicker() async {
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FieldPickerSheet(
        groupedFields: _groupedFields,
        selectedId: _selectedFieldId,
      ),
    );

    if (selected != null && mounted && selected['id'] != null) {
      setState(() {
        _selectedFieldId = selected['id'];
        _fieldController.text = selected['name'] ?? '';
      });
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, AppDimensions.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.buttonRadius,
                    ),
                  ),
                ),
                child: Text(
                  'Retour',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(
                  double.infinity,
                  AppDimensions.buttonHeight,
                ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 0 ? 'Suivant' : 'Terminer',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() {});
      return;
    }
    if (_selectedFieldId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner une filière.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      String? photoUrl;

      if (_imageFile != null) {
        photoUrl = await SupabaseStorageService.uploadAvatar(
          uid: uid,
          file: _imageFile!,
        );
      }

      final selectedField =
          _fieldsOfStudies
              .where((f) => f['id'] == _selectedFieldId)
              .firstOrNull ??
          {'id': '', 'name': _fieldController.text};

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'phone': _phoneController.text.trim(),
        'dateOfBirth': AppTimestamp.toFirestore(_dateOfBirth),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        'grade': _gradeController.text.trim(),
        'fieldOfStudies': selectedField['name'],
        'fieldOfStudiesId': _selectedFieldId,
        'photoUrl': photoUrl,
        'profileCompleted': true,
      });

      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const SubscriptionScreen(showSkip: true),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _FieldPickerSheet extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> groupedFields;
  final String? selectedId;

  const _FieldPickerSheet({required this.groupedFields, this.selectedId});

  @override
  State<_FieldPickerSheet> createState() => _FieldPickerSheetState();
}

class _FieldPickerSheetState extends State<_FieldPickerSheet> {
  String? _selectedId;
  String? _selectedName;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    if (_selectedId != null) {
      for (final fields in widget.groupedFields.values) {
        final match = fields.where((f) => f['id'] == _selectedId).firstOrNull;
        if (match != null) {
          _selectedName = match['name'] as String;
          break;
        }
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> get _filteredGroups {
    if (_searchQuery.isEmpty) return widget.groupedFields;

    final filtered = <String, List<Map<String, dynamic>>>{};
    for (final entry in widget.groupedFields.entries) {
      final matching = entry.value
          .where(
            (f) => (f['name'] as String).toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
      if (matching.isNotEmpty) {
        filtered[entry.key] = matching;
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Rechercher une filière...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _filteredGroups.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        top: 8,
                        bottom: 4,
                      ),
                      child: Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...entry.value.map(
                      (field) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        selected: _selectedId == field['id'],
                        selectedTileColor: AppColors.primarySurface,
                        leading: Icon(
                          _iconFromName(field['icon'] as String),
                          size: 20,
                          color: _selectedId == field['id']
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          field['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: _selectedId == field['id']
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedId == field['id']
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        trailing: _selectedId == field['id']
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () => setState(() {
                          _selectedId = field['id'] as String;
                          _selectedName = field['name'] as String;
                        }),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedId != null
                    ? () => Navigator.of(
                        context,
                      ).pop({'id': _selectedId!, 'name': _selectedName ?? ''})
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirmer',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFromName(String name) {
    final map = <String, IconData>{
      'science': Icons.science_rounded,
      'experiment': Icons.biotech_rounded,
      'engineering': Icons.engineering_rounded,
      'build': Icons.build_rounded,
      'calculate': Icons.calculate_rounded,
      'design_services': Icons.design_services_rounded,
      'biotech': Icons.biotech_rounded,
      'computer': Icons.computer_rounded,
      'memory': Icons.memory_rounded,
      'translate': Icons.translate_rounded,
      'language': Icons.language_rounded,
      'functions': Icons.functions_rounded,
      'bolt': Icons.bolt_rounded,
      'school': Icons.school_rounded,
      'developer_board': Icons.developer_board_rounded,
      'code': Icons.code_rounded,
      'electrical_services': Icons.electrical_services_rounded,
      'apartment': Icons.apartment_rounded,
      'factory': Icons.factory_rounded,
      'cable': Icons.cable_rounded,
      'cell_tower': Icons.cell_tower_rounded,
      'hub': Icons.hub_rounded,
      'monitor_heart': Icons.monitor_heart_rounded,
      'diamond': Icons.diamond_rounded,
      'eco': Icons.eco_rounded,
      'solar_power': Icons.solar_power_rounded,
      'water_drop': Icons.water_drop_rounded,
      'checkroom': Icons.checkroom_rounded,
      'analytics': Icons.analytics_rounded,
      'smart_toy': Icons.smart_toy_rounded,
      'shield': Icons.shield_rounded,
      'web': Icons.web_rounded,
      'phone_android': Icons.phone_android_rounded,
      'lan': Icons.lan_rounded,
      'brush': Icons.brush_rounded,
      'trending_up': Icons.trending_up_rounded,
      'account_balance': Icons.account_balance_rounded,
      'business_center': Icons.business_center_rounded,
      'rocket_launch': Icons.rocket_launch_rounded,
      'lightbulb': Icons.lightbulb_rounded,
      'groups': Icons.groups_rounded,
      'receipt_long': Icons.receipt_long_rounded,
      'menu_book': Icons.menu_book_rounded,
      'self_improvement': Icons.self_improvement_rounded,
      'gavel': Icons.gavel_rounded,
      'model_training': Icons.model_training_rounded,
      'business': Icons.business_rounded,
      'medical_services': Icons.medical_services_rounded,
      'medication': Icons.medication_rounded,
      'dentistry': Icons.medical_services_rounded,
      'payments': Icons.payments_rounded,
      'handyman': Icons.handyman_rounded,
      'precision_manufacturing': Icons.precision_manufacturing_rounded,
      'more_horiz': Icons.more_horiz_rounded,
    };
    return map[name] ?? Icons.category_rounded;
  }
}
