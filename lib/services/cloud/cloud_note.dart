import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infinity_notes/services/cloud/cloud_storage_constants.dart';

class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String title;
  final String text;
  final List<String>? links;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.title,
    required this.text,
    this.links,
    required this.createdAt,
    required this.updatedAt,
  });

  //Accept QueryDocumentSnapshot<Object?> and cast internally
  CloudNote.fromSnapshot(QueryDocumentSnapshot snapshot)
      : documentId = snapshot.id,
        ownerUserId = (snapshot.data() as Map<String, dynamic>)[ownerUserIdFieldName] as String,
        title = (snapshot.data() as Map<String, dynamic>)[titleFieldName] as String? ?? "",
        text = (snapshot.data() as Map<String, dynamic>)[textFieldName] as String? ?? "",
        links = (snapshot.data() as Map<String, dynamic>)[linksFieldName] != null
            ? List<String>.from((snapshot.data() as Map<String, dynamic>)[linksFieldName] as List)
            : null,
        createdAt = _parseTimestamp((snapshot.data() as Map<String, dynamic>)[createdAtFieldName]),
        updatedAt = _parseTimestamp((snapshot.data() as Map<String, dynamic>)[updatedAtFieldName]);

  //  Helper method to parse timestamps safely
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.now();
  }

  // Your existing helper methods...
  bool get hasLinks => links != null && links!.isNotEmpty;
  int get linkCount => links?.length ?? 0;
  List<String> get safeLinks => links ?? [];

  String get formattedCreatedAt => _formatDate(createdAt);
  String get formattedUpdatedAt => _formatDate(updatedAt);
  String get timeAgo => _getTimeAgo(updatedAt);

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today ${_formatTime(date)}';
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
    }
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDate(date);
    }
  }
}
