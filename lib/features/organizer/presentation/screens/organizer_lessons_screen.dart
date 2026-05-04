import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/course/domain/models/course_lesson_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/presentation/providers/course_provider.dart';

class OrganizerLessonsScreen extends StatefulWidget {
  final CourseModel course;

  const OrganizerLessonsScreen({super.key, required this.course});

  @override
  State<OrganizerLessonsScreen> createState() => _OrganizerLessonsScreenState();
}

class _OrganizerLessonsScreenState extends State<OrganizerLessonsScreen> {
  static const String _defaultVideoUrl = 'https://youtu.be/niWpfRyvs2U';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadLessons(widget.course.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Leçons: ${widget.course.title}',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary),
            ),
            onPressed: () => _showLessonEditor(context),
          ),
        ],
      ),
      body: Consumer<CourseProvider>(
        builder: (_, provider, __) {
          final lessons =
              provider.lessons
                  .where((l) => l.courseId == widget.course.id)
                  .toList()
                ..sort((a, b) => a.order.compareTo(b.order));

          if (lessons.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _LessonCard(
              lesson: lessons[i],
              onEdit: () => _showLessonEditor(context, lesson: lessons[i]),
              onDelete: () => _showDeleteDialog(context, lessons[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_lesson_rounded,
                size: 48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune leçon',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des leçons à ce cours',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showLessonEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter une leçon'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLessonEditor(
    BuildContext context, {
    CourseLessonModel? lesson,
  }) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: lesson?.title ?? '');
    final descController = TextEditingController(
      text: lesson?.description ?? '',
    );
    final videoController = TextEditingController(text: lesson?.videoUrl ?? '');
    final orderController = TextEditingController(
      text: lesson?.order.toString() ?? '1',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    lesson == null ? 'Nouvelle leçon' : 'Modifier la leçon',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    _buildField(
                      titleController,
                      'Titre de la leçon',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                      prefix: Icons.title_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      descController,
                      'Description',
                      maxLines: 3,
                      prefix: Icons.description_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      videoController,
                      'URL vidéo (Supabase)',
                      hint: 'https://...',
                      prefix: Icons.play_circle_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      orderController,
                      'Ordre',
                      keyboardType: TextInputType.number,
                      prefix: Icons.format_list_numbered_rounded,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final videoUrl = videoController.text.trim().isEmpty
                            ? _defaultVideoUrl
                            : videoController.text.trim();
                        final provider = context.read<CourseProvider>();
                        if (lesson == null) {
                          await provider.addLesson(
                            CourseLessonModel(
                              id: '',
                              courseId: widget.course.id,
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              videoUrl: videoUrl,
                              order:
                                  int.tryParse(orderController.text.trim()) ??
                                  1,
                            ),
                          );
                        } else {
                          await provider.updateLesson(
                            lesson.copyWith(
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              videoUrl: videoUrl,
                              order:
                                  int.tryParse(orderController.text.trim()) ??
                                  lesson.order,
                            ),
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        lesson == null ? 'Ajouter' : 'Mettre à jour',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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

  Widget _buildField(
    TextEditingController controller,
    String label, {
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? prefix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix != null
            ? Icon(prefix, color: AppColors.textSecondary)
            : null,
        filled: true,
        fillColor: AppColors.backgroundLight,
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
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    CourseLessonModel lesson,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la leçon'),
        content: Text('Voulez-vous supprimer "${lesson.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<CourseProvider>().deleteLesson(
        widget.course.id,
        lesson.id,
      );
    }
  }
}

class _LessonCard extends StatelessWidget {
  final CourseLessonModel lesson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LessonCard({
    required this.lesson,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 70,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${lesson.order}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lesson.videoUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Vidéo',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.error,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
