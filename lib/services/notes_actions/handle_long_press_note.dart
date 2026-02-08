import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinitynotes/services/cloud/cloud_note.dart';
import 'package:infinitynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinitynotes/services/search/bloc/search_bloc.dart';
import 'package:infinitynotes/services/search/bloc/search_event.dart';
import 'package:infinitynotes/services/search/bloc/search_state.dart';
import 'package:infinitynotes/utilities/ai/ai_helper.dart';
import 'package:infinitynotes/utilities/generics/ui/custom_toast.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';
import 'package:infinitynotes/utilities/generics/ui/share_note_dialog.dart';

Future<String?> showNoteActionsDialog({
  required BuildContext context,
  required FirebaseCloudStorage notesService,
  required CloudNote note,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    note.title.isNotEmpty ? note.title : 'Select Action',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Divider(
                height: 20,
                thickness: 1,
                color: Theme.of(context).dividerColor,
              ),

              // AI Summary option
              InkWell(
                onTap: () => Navigator.pop(context, 'ai_summary'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AIHelper.canSummarizeContent(note.text)
                            ? Colors.blue
                            : Theme.of(context).disabledColor,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'AI Summary',
                        style: TextStyle(
                          fontSize: 16,
                          color: AIHelper.canSummarizeContent(note.text)
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(
                height: 20,
                thickness: 1,
                color: Theme.of(context).dividerColor,
              ),

              // Share option
              InkWell(
                onTap: () => Navigator.pop(context, 'share'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.share, color: Colors.green),
                      const SizedBox(width: 16),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(
                color: Theme.of(context).dividerColor,
              ),

              // Delete option
              InkWell(
                onTap: () => Navigator.pop(context, 'delete'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever, color: Colors.red),
                      const SizedBox(width: 16),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).dividerColor,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> handleLongPressNote({
  required BuildContext context,
  required CloudNote note,
  required FirebaseCloudStorage notesService,
}) async {
  final action = await showNoteActionsDialog(
    context: context,
    notesService: notesService,
    note: note,
  );

  if (action == null) return;

  switch (action) {
    case 'ai_summary':
      if (AIHelper.canSummarizeContent(note.text)) {
        AIHelper.handleSummarizeAction(
          context: context,
          content: note.text,
          title: note.title,
          onComplete: () {
            showCustomToast(context, "AI Summary created successfully!");
          },
        );
      } else {
        showCustomToast(
          context,
          "Note content is empty or too short to summarize",
        );
      }
      break;

    case 'share':
    // Updated: Call new dual-share dialog
      await showShareNoteDialog(
        context: context,
        note: note,
      );
      break;

    case 'delete':
      final confirm = await showDeleteDialog(context: context);
      if (confirm) {
        await notesService.deleteNote(documentId: note.documentId);
        if (context.mounted) {
          final searchBloc = BlocProvider.of<SearchBloc>(context);
          final currentState = searchBloc.state;
          final updatedNotes = List<CloudNote>.from(searchBloc.allNotes)
            ..removeWhere((n) => n.documentId == note.documentId);
          searchBloc.add(SearchInitiated(updatedNotes));
          if (currentState is SearchResults) {
            searchBloc.add(SearchQueryChanged(currentState.query));
          }

          showCustomToast(context, "Note Deleted Successfully");
        }
      }
      break;
  }
}
