import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.order,
    this.iconUrl,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id:      id,
      name:    map['name']    as String? ?? '',
      slug:    map['slug']    as String? ?? '',
      iconUrl: map['iconUrl'] as String?,
      order:   map['order']   as int?    ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':    name,
      'slug':    slug,
      'iconUrl': iconUrl,
      'order':   order,
    };
  }

  @override
  List<Object?> get props => [id, name, slug, iconUrl, order];
}
