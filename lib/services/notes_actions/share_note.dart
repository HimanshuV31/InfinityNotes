import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';

Future<void> shareNote({
  required CloudNote note,
  required BuildContext context,
}) async {
  final noteId = note.documentId;
  final deepLink = 'https://himanshuv31.github.io/InfinityNotes/note/$noteId';

  final shareText = note.title.isNotEmpty
      ? '${note.title}\n\n$deepLink\n\nShared via Infinity Notes'
      : 'Check out my note: $deepLink\n\nShared via Infinity Notes';

  await SharePlus.instance.share(
    ShareParams(
      text: shareText,
      title: 'Share Note',
      subject: note.title.isNotEmpty ? note.title : 'Shared Note from Infinity Notes',
    ),
  );
}
