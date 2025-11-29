import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/platform/platform_utils.dart';
import 'package:infinity_notes/utilities/generics/ui/linkify_text.dart';

class NotesTileView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final Function(CloudNote) onTapNote;
  final Function(CloudNote) onLongPressNote;

  const NotesTileView({
    super.key,
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
  });

  int _getCrossAxisCount() {
    if (PlatformUtils.isWeb ||
        PlatformUtils.isWindows ||
        PlatformUtils.isMacOS ||
        PlatformUtils.isLinux) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: _getCrossAxisCount(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      itemCount: notes.length,
      padding: const EdgeInsets.all(10),
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final note = notes.elementAt(index);
        return _NoteTile(
          note: note,
          onTap: () => onTapNote(note),
          onLongPress: () => onLongPressNote(note),
        );
      },
    );
  }
}

class SliverNotesTileView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final Function(CloudNote) onTapNote;
  final Function(CloudNote) onLongPressNote;

  const SliverNotesTileView({
    super.key,
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
  });

  int _getCrossAxisCount() {
    if (PlatformUtils.isWeb ||
        PlatformUtils.isWindows ||
        PlatformUtils.isMacOS ||
        PlatformUtils.isLinux) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final notesList = notes.toList();

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: _getCrossAxisCount(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childCount: notesList.length,
        itemBuilder: (context, index) {
          final note = notesList[index];
          return _NoteTile(
            note: note,
            onTap: () => onTapNote(note),
            onLongPress: () => onLongPressNote(note),
          );
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, this.onTap, this.onLongPress});

  final CloudNote note;
  static const maxTextLines = 10;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.primary;
    final tileBackground = Theme.of(context).cardColor;
    final hasText = note.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tileBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: backgroundColor.withAlpha(128),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              note.title.isEmpty ? "Untitled" : note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (hasText) ...[
              const SizedBox(height: 8),
              LinkifyText(
                note.text,
                maxLines: maxTextLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
            ],
            if (note.timeAgo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
