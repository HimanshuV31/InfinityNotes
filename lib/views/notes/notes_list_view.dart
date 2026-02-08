import 'package:flutter/material.dart';
import 'package:infinitynotes/services/cloud/cloud_note.dart';
import 'package:infinitynotes/services/platform/platform_utils.dart';
import 'package:infinitynotes/utilities/generics/ui/linkify_text.dart';

class NotesListView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final Function(CloudNote) onTapNote;
  final Function(CloudNote) onLongPressNote;

  const NotesListView({
    super.key,
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
  });

  int _getCrossAxisCount() {
    if (PlatformUtils.isWeb ||
        PlatformUtils.isWindows ||
        PlatformUtils.isMacOS ||
        PlatformUtils.isLinux) return 3;
    return 1; // Mobile platforms
  }

  @override
  Widget build(BuildContext context) {
    final columns = _getCrossAxisCount();
    if (columns == 1) {
      return ListView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.all(10),
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final note = notes.elementAt(index);
          return NoteListTile(
            note: note,
            onTap: () => onTapNote(note),
            onLongPress: () => onLongPressNote(note),
          );
        },
      );
    } else {
      return GridView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.all(10),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.5,
        ),
        itemBuilder: (context, index) {
          final note = notes.elementAt(index);
          return NoteListTile(
            note: note,
            onTap: () => onTapNote(note),
            onLongPress: () => onLongPressNote(note),
          );
        },
      );
    }
  }
}

class SliverNotesListView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final Function(CloudNote) onTapNote;
  final Function(CloudNote) onLongPressNote;

  const SliverNotesListView({
    super.key,
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
  });

  int _getCrossAxisCount() {
    if (PlatformUtils.isWeb ||
        PlatformUtils.isWindows ||
        PlatformUtils.isMacOS ||
        PlatformUtils.isLinux) return 3;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _getCrossAxisCount();
    final notesList = notes.toList();

    if (columns == 1) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final note = notesList[index];
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 10 : 4,
                  bottom: index == notesList.length - 1 ? 10 : 4,
                ),
                child: NoteListTile(
                  note: note,
                  onTap: () => onTapNote(note),
                  onLongPress: () => onLongPressNote(note),
                ),
              );
            },
            childCount: notesList.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.all(10),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final note = notesList[index];
              return NoteListTile(
                note: note,
                onTap: () => onTapNote(note),
                onLongPress: () => onLongPressNote(note),
              );
            },
            childCount: notesList.length,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 2.5,
          ),
        ),
      );
    }
  }
}

class NoteListTile extends StatelessWidget {
  final CloudNote note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteListTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.primary;
    final cardBackground = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: backgroundColor.withAlpha(128),
            width: 0.7,
          ),
        ),
        elevation: 1,
        margin: const EdgeInsets.all(0),
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 8),
              LinkifyText(
                note.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
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
      ),
    );
  }
}
