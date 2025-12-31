import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/search/bloc/search_event.dart';
import 'package:infinity_notes/services/search/bloc/search_state.dart';
import 'package:infinity_notes/services/search/search_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  Iterable<CloudNote> _allNotes = [];
  Timer? _debounceTimer; // Keep this for cleanup but don't use it
  Iterable<CloudNote> get allNotes => _allNotes;

  SearchBloc() : super(const SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SearchCleared>(_onSearchCleared);
    on<SearchInitiated>(_onSearchInitiated);
  }

  void _onSearchInitiated(
      SearchInitiated event,
      Emitter<SearchState> emit,
      )
  {
    _allNotes = event.allNotes;
    emit(SearchInitial(notes: _allNotes));
    debugPrint("SearchBloc initialized with ${_allNotes.length} notes");
  }

  //  No Timer, synchronous search
  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    final query = event.query.trim();
    debugPrint("SearchBloc: Processing query '$query'");

    if (query.isEmpty) {
      emit(SearchInitial(notes: _allNotes));
      debugPrint("SearchBloc: Emitting SearchInitial with ${_allNotes.length} notes");
    } else {
      final results = SearchService.filterNotes(_allNotes, query);
      debugPrint("SearchBloc: Found ${results.length} results for '$query'");

      if (results.isEmpty) {
        emit(SearchEmpty(query: query));
        debugPrint("SearchBloc: Emitting SearchEmpty");
      } else {
        emit(SearchResults(results: results, query: query));
        debugPrint("SearchBloc: Emitting SearchResults with ${results.length} notes");
      }
    }
  }

  void _onSearchCleared(
      SearchCleared event,
      Emitter<SearchState> emit,
      )
  {
    _debounceTimer?.cancel();
    emit(SearchInitial(notes: _allNotes));
    debugPrint("🔍 SearchBloc: Search cleared, showing all ${_allNotes.length} notes");
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
