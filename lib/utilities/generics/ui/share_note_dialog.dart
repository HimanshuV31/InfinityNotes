import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';

Future<void> showShareNoteDialog({
  required BuildContext context,
  required CloudNote note,
}) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Note',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Option 1: Share Link (Deep Link)
          ListTile(
            leading: Icon(
              Icons.link,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Share Link'),
            subtitle: const Text('Opens in Infinity Notes app'),
            onTap: () {
              Navigator.of(context).pop();
              _shareWithDeepLink(note);
            },
          ),

          const Divider(),

          // Option 2: Share Content (Plain Text)
          ListTile(
            leading: Icon(
              Icons.text_fields,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Share Content'),
            subtitle: const Text('Share as plain text'),
            onTap: () {
              Navigator.of(context).pop();
              _shareNoteContent(note);
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

// Share with deep link (correct SharePlus API)
Future<void> _shareWithDeepLink(CloudNote note) async {
  final noteId = note.documentId;
  final deepLink = 'infinitynotes://note/$noteId';

  final shareText = note.title.isNotEmpty
      ? '📝 ${note.title}\n\n$deepLink\n\n🚀 Shared via Infinity Notes\n\n📲 Download: https://play.google.com/store/apps/details?id=com.ehv.infinitynotes'
      : '📝 Check out my note!\n\n$deepLink\n\n🚀 Shared via Infinity Notes\n\n📲 Download: https://play.google.com/store/apps/details?id=com.ehv.infinitynotes';

  // Correct API: SharePlus.instance.share with ShareParams
  await SharePlus.instance.share(
    ShareParams(
      text: shareText,
      subject: note.title.isNotEmpty ? note.title : 'Shared Note',
    ),
  );
}

// Share note content (correct SharePlus API)
Future<void> _shareNoteContent(CloudNote note) async {
  final noteTitle = note.title.isNotEmpty ? note.title : 'Untitled Note';
  final noteContent = note.text.isNotEmpty ? note.text : '(Empty note)';

  final shareText = '''📝 $noteTitle

$noteContent

━━━━━━━━━━━━━━━━━━
🚀 Shared via Infinity Notes
📲 https://play.google.com/store/apps/details?id=com.ehv.infinitynotes''';

  // Correct API: SharePlus.instance.share with ShareParams
  await SharePlus.instance.share(
    ShareParams(
      text: shareText,
      subject: noteTitle,
    ),
  );
}
