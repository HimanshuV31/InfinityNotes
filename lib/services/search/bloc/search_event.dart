import 'package:infinity_notes/services/cloud/cloud_note.dart';

abstract class SearchEvent {
  const SearchEvent();
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

class SearchInitiated extends SearchEvent {
  final Iterable<CloudNote> allNotes;
  const SearchInitiated(this.allNotes);
  List<Object> get props => [allNotes];
}