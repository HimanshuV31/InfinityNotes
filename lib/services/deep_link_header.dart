import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class DeepLinkHandler {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  Future<void> init(BuildContext context) async {
    _appLinks = AppLinks();

    // Handle initial link (app was closed)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(context, initialLink);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }

    // Handle links while app is running
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(context, uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  void _handleDeepLink(BuildContext context, Uri uri) {
    debugPrint('Deep link received: $uri');

    // Extract note ID from path
    // Format: infinitynotes://note/NOTE_ID or https://himanshuv31.github.io/InfinityNotes/note/NOTE_ID
    final segments = uri.pathSegments;

    // Handle both URL formats
    // GitHub Pages: /InfinityNotes/note/abc123 → segments = ['InfinityNotes', 'note', 'abc123']
    // Custom scheme: /note/abc123 → segments = ['note', 'abc123']

    String? noteId;
    if (segments.length >= 2) {
      // Find 'note' segment
      final noteIndex = segments.indexOf('note');
      if (noteIndex != -1 && noteIndex < segments.length - 1) {
        noteId = segments[noteIndex + 1];
      }
    }

    if (noteId != null && noteId.isNotEmpty) {
      // Navigate to note view
      Navigator.pushNamed(
        context,
        '/create-update-note',
        arguments: noteId,
      );
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
