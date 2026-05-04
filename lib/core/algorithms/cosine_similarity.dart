import 'dart:math';

class CosineSimilarity {
  static double compute(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Vectors must have equal dimensions');

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0.0) return 0.0;
    return dot / denominator;
  }

  static List<double> centroid(List<List<double>> vectors) {
    assert(vectors.isNotEmpty, 'Cannot compute centroid of empty list');

    final int dims = vectors.first.length;
    final result = List<double>.filled(dims, 0.0);

    for (final vec in vectors) {
      for (int i = 0; i < dims; i++) {
        result[i] += vec[i];
      }
    }

    for (int i = 0; i < dims; i++) {
      result[i] /= vectors.length;
    }

    return result;
  }
}