import 'package:cloud_firestore/cloud_firestore.dart';

class AppTimestamp {
  static DateTime? fromFirestore(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp toFirestore(DateTime? value) {
    if (value == null) return Timestamp.now();
    return Timestamp.fromDate(value);
  }

  static Timestamp now() => Timestamp.now();

  static int toMillis(DateTime value) => value.millisecondsSinceEpoch;

  static DateTime fromMillis(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis);
}
