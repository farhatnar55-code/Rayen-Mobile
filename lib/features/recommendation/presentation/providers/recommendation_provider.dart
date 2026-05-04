import 'package:flutter/material.dart';
import 'package:rayen_mobile/features/recommendation/domain/entities/recommendation_item.dart';
import 'package:rayen_mobile/features/recommendation/domain/usecases/get_recommendations.dart';

enum RecommendationState { idle, loading, loaded, error }

class RecommendationProvider extends ChangeNotifier {
  final GetRecommendations _usecase;

  RecommendationProvider(this._usecase);

  RecommendationState _state = RecommendationState.idle;
  List<RecommendationItem> _items = [];
  String? _error;

  RecommendationState get state => _state;
  List<RecommendationItem> get items => _items;
  String? get error => _error;

  List<RecommendationItem> get courses => _items
      .where((i) => i.type == RecommendationItemType.course)
      .toList();

  List<RecommendationItem> get sessions => _items
      .where((i) => i.type == RecommendationItemType.session)
      .toList();

  Future<void> load({
    required String userId,
    required String fieldOfStudies,
  }) async {
    if (_state == RecommendationState.loading) return;

    _state = RecommendationState.loading;
    _error = null;
    notifyListeners();

    try {
      _items = await _usecase(
        userId: userId,
        fieldOfStudies: fieldOfStudies,
      );
      _state = RecommendationState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = RecommendationState.error;
    }

    notifyListeners();
  }
}