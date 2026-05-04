import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rayen_mobile/core/constants/app_colors.dart';
import 'package:rayen_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:rayen_mobile/features/category/domain/models/category_model.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (_, provider, __) {
        if (provider.categoriesStatus == AdminLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.categories.isEmpty) {
          return Center(
            child: Text(
              'Aucune catégorie trouvée.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _CategoryTile(
            category: provider.categories[i],
            subcategories: provider.subcategories
                .where((s) => s.categoryId == provider.categories[i].id)
                .toList(),
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final List subcategories;

  const _CategoryTile({required this.category, required this.subcategories});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.category_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${subcategories.length} sous-catégories',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        children: subcategories.map((sub) {
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            leading: const Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 18,
              color: AppColors.textHint,
            ),
            title: Text(
              sub.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
