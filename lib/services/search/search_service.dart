import 'package:infinity_notes/services/cloud/cloud_note.dart';

class SearchService {
  static Iterable<CloudNote> filterNotes(
      Iterable<CloudNote> notes,
      String query,
      ){

    final searchTerm = query.toLowerCase();
    return notes.where((note) =>
          note.title.toLowerCase().contains(searchTerm)
      ||  note.text.toLowerCase().contains(searchTerm)
    );
  }
}