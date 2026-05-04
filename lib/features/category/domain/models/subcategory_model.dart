import 'package:equatable/equatable.dart';

class SubcategoryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String categoryId;
  final String categoryName;

  const SubcategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.categoryName,
  });

  factory SubcategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return SubcategoryModel(
      id:           id,
      name:         map['name']         as String? ?? '',
      slug:         map['slug']         as String? ?? '',
      categoryId:   map['categoryId']   as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':         name,
      'slug':         slug,
      'categoryId':   categoryId,
      'categoryName': categoryName,
    };
  }

  @override
  List<Object?> get props => [id, name, slug, categoryId, categoryName];
}
