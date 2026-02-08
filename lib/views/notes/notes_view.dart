import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'
    show ReadContext, BlocListener, BlocProvider, BlocBuilder;
import 'package:infinitynotes/constants/routes.dart';
import 'package:infinitynotes/enums/menu_actions.dart';
import 'package:infinitynotes/services/auth/auth_exception.dart';
import 'package:infinitynotes/services/auth/auth_service.dart';
import 'package:infinitynotes/services/auth/bloc/auth_bloc.dart';
import 'package:infinitynotes/services/auth/bloc/auth_event.dart';
import 'package:infinitynotes/services/auth/bloc/auth_state.dart';
import 'package:infinitynotes/services/cloud/cloud_note.dart';
import 'package:infinitynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinitynotes/services/notes_actions/handle_long_press_note.dart';
import 'package:infinitynotes/services/search/bloc/search_bloc.dart';
import 'package:infinitynotes/services/search/bloc/search_event.dart';
import 'package:infinitynotes/services/search/bloc/search_state.dart';
import 'package:infinitynotes/utilities/generics/ui/animation/animation_controller.dart';
import 'package:infinitynotes/utilities/generics/ui/custom_sliver_app_bar.dart';
import 'package:infinitynotes/utilities/generics/ui/custom_toast.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';
import 'package:infinitynotes/utilities/generics/ui/feedback_dialog.dart';
import 'package:infinitynotes/utilities/generics/ui/ui_constants.dart';
import 'package:infinitynotes/views/menu/settings/settings_view.dart';
import 'package:infinitynotes/views/notes/notes_list_view.dart';
import 'package:infinitynotes/views/notes/notes_tile_view.dart';
import 'package:infinitynotes/utilities/generics/ui/whats_new_dialog.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  String get userEmail => AuthService.firebase().currentUser!.email;
  late final FirebaseCloudStorage _notesService;
  String get userId => AuthService.firebase().currentUser!.id;
  CloseDialog? _closeDialogHandle;
  late SearchBloc _searchBloc;

  final ValueNotifier<bool> _showListViewNotifier = ValueNotifier<bool>(false);

  Future<void> newNote() async {
    await Navigator.of(context).pushNamed(CreateUpdateNoteRoute);
  }

  Future<void> openNote(CloudNote note) async {
    await Navigator.of(
      context,
    ).pushNamed(CreateUpdateNoteRoute, arguments: note);
  }

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
    _searchBloc = SearchBloc();
    GlobalAnimationController.triggerTitleAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showWhatsNewIfNeeded(context);
    });
  }

  void _toggleView() {
    _showListViewNotifier.value = !_showListViewNotifier.value;
  }

  @override
  void dispose() {
    _showListViewNotifier.dispose();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthStateLoggedOut && state.exception != null) {
            final closeDialog = _closeDialogHandle;
            if (!state.isLoading && closeDialog != null) {
              closeDialog();
              _closeDialogHandle = null;
            } else if (state.isLoading && closeDialog == null) {
              _closeDialogHandle = showLoadingDialog(
                context: context,
                text: "Loading... .. .",
              );
            }

            final e = state.exception;
            if (e is AuthException) {
              showWarningDialog(
                context: context,
                title: e.title,
                message: e.message,
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: StreamBuilder<Iterable<CloudNote>>(
              stream: _notesService.allNotes(ownerUserId: userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }
                final allNotes = snapshot.data ?? <CloudNote>[];
                final hasNotes = allNotes.isNotEmpty;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (hasNotes && _searchBloc.state is SearchInitial) {
                    _searchBloc.add(SearchInitiated(allNotes));
                    debugPrint(
                      "🔍 Post-frame: Initialized SearchBloc with ${allNotes.length} notes",
                    );
                  }
                });

                return ValueListenableBuilder<bool>(
                  valueListenable: _showListViewNotifier,
                  builder: (context, showListView, _) {
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        CustomSliverAppBar(
                          title: "Infinity Notes",
                          userEmail: userEmail,
                          hasNotes: hasNotes,
                          autoShowSearch: hasNotes,
                          backgroundColor:
                          Theme.of(context).appBarTheme.backgroundColor!,
                          foregroundColor:
                          Theme.of(context).appBarTheme.foregroundColor!,
                          onToggleView: _toggleView,
                          isListView: showListView,
                          onLogout: () => _handleMenuAction(MenuAction.logout),
                          onSearchChanged: (query) =>
                              _searchBloc.add(SearchQueryChanged(query)),
                          onReportBug: _handleReportBug,
                          onFeedback: _handleFeedback,
                          onSettings: _handleSettings,
                        ),
                        BlocBuilder<SearchBloc, SearchState>(
                          builder: (context, searchState) {
                            return _buildNotesContent(
                              allNotes,
                              searchState,
                              showListView,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          floatingActionButton: Container(
            margin: const EdgeInsets.only(bottom: 36, right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: UIConstants.strongShadow,
            ),
            child: FloatingActionButton(
              onPressed: newNote,
              backgroundColor: const Color(0xFF3993ad),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                size: 28,
                shadows: UIConstants.iconShadow,
              ),
            ),
          ),

        ),
      ),
    );
  }

  void _handleMenuAction(MenuAction action) async {
    switch (action) {
      case MenuAction.logout:
        final shouldLogout = await showLogoutDialog(context: context);
        if (!mounted) return;
        if (!shouldLogout) return;
        context.read<AuthBloc>().add(const AuthEventLogOut());
        if (!mounted) return;
        showCustomToast(context, "Logout Successful");
        break;
      case MenuAction.profile:
        throw UnimplementedError();
      case MenuAction.settings:
        throw UnimplementedError();
    }
  }

  Future<void> _handleReportBug() async {
    await showFeedbackDialog(
      context: context,
      type: FeedbackType.bugReport,
      userEmail: userEmail,
    );
  }

  Future<void> _handleFeedback() async {
    await showFeedbackDialog(
      context: context,
      type: FeedbackType.generalFeedback,
      userEmail: userEmail,
    );
  }
  Future<void> _handleSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsView(
          userEmail: userEmail,
        ),
      ),
    );
  }
  Widget _buildNotesContent(
      Iterable<CloudNote> allNotes,
      SearchState searchState,
      bool showListView,
      ) {
    debugPrint("🔍 _buildNotesContent: searchState = $searchState");
    debugPrint("🔍 searchState type: ${searchState.runtimeType}");

    Iterable<CloudNote> notesToShow;

    if (searchState is SearchResults) {
      debugPrint("🔍 ENTERING SearchResults branch");

      final state = searchState;
      final liveNoteIds = allNotes.map((n) => n.documentId).toSet();
      notesToShow = state.results.where(
            (note) => liveNoteIds.contains(note.documentId),
      );

      debugPrint(
        "🔍 Showing ${notesToShow.length} search results for '${state.query}'",
      );

      if (notesToShow.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(height: 16),
                Text(
                  "No results found for: ${state.query}",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else if (searchState is SearchEmpty) {
      debugPrint("🔍 ENTERING SearchEmpty branch");

      final state = searchState;
      debugPrint("🔍 No results found for '${state.query}'");

      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 16),
              Text(
                "No results found for: ${state.query}",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (searchState is SearchInitial) {
      debugPrint("🔍 ENTERING SearchInitial branch");

      final state = searchState;
      notesToShow = state.notes.isNotEmpty ? state.notes : allNotes;

      debugPrint(
        "🔍 Showing all ${notesToShow.length} notes (initial state)",
      );
    } else {
      debugPrint("🔍 ENTERING default branch");

      notesToShow = allNotes;
      debugPrint("🔍 Showing all ${notesToShow.length} notes (default)");
    }

    // Empty notes check
    if (notesToShow.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_add,
                size: 64,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 16),
              Text(
                "No notes found. Create one!",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Render list or tile view
    if (showListView) {
      debugPrint("🔍 Rendering ListView with ${notesToShow.length} notes");

      return SliverNotesListView(
        key: const ValueKey('list_view'),
        notes: notesToShow,
        onTapNote: (note) => openNote(note),
        onLongPressNote: (note) => handleLongPressNote(
          context: context,
          note: note,
          notesService: _notesService,
        ),
      );
    } else {
      debugPrint("🔍 Rendering TileView with ${notesToShow.length} notes");

      return SliverNotesTileView(
        key: const ValueKey('tile_view'),
        notes: notesToShow,
        onTapNote: (note) => openNote(note),
        onLongPressNote: (note) => handleLongPressNote(
          context: context,
          note: note,
          notesService: _notesService,
        ),
      );
    }
  }
}
