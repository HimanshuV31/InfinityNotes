import 'package:infinity_notes/services/cloud/cloud_note.dart';

abstract class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {
  final Iterable<CloudNote> notes;
  const SearchInitial({this.notes = const <CloudNote>[]});
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchResults extends SearchState {
  final Iterable<CloudNote> results;
  final String query;

  const SearchResults({
    required this.results,
    required this.query,
  });
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
}

class SearchEmpty extends SearchState {
  final String query;
  const SearchEmpty({required this.query});
}
