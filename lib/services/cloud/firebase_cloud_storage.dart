import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infinitynotes/services/cloud/cloud_note.dart';
import 'package:infinitynotes/services/cloud/cloud_storage_constants.dart';
import 'package:infinitynotes/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  // Constants and Declarations
  final notes = FirebaseFirestore.instance.collection('notes');
  static final FirebaseCloudStorage _shared = FirebaseCloudStorage._sharedInstance();

  // Singleton constructor
  FirebaseCloudStorage._sharedInstance();

  factory FirebaseCloudStorage() => _shared;
   
  // CORE CRUD OPERATIONS

  /// Creates a new note with automatic timestamps
  Future<CloudNote> createNewNote({
    required String ownerUserId,
    String title = "",
    String text = "",
    List<String>? links,
  }) async
  {
    try {
      final now = FieldValue.serverTimestamp();

      final document = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        titleFieldName: title,
        textFieldName: text,
        linksFieldName: links,
        createdAtFieldName: now,
        updatedAtFieldName: now,
      });

      final fetchedNote = await document.get();
      final data = fetchedNote.data()!;

      return CloudNote(
        documentId: fetchedNote.id,
        ownerUserId: ownerUserId,
        title: data[titleFieldName] ?? "",
        text: data[textFieldName] ?? "",
        links: data[linksFieldName] != null
            ? List<String>.from(data[linksFieldName] as List)
            : null,
        createdAt: _parseTimestamp(data[createdAtFieldName]),
        updatedAt: _parseTimestamp(data[updatedAtFieldName]),
      );
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  /// Updates an existing note with new timestamp
  Future<void> updateNote({
    required String documentId,
    required String title,
    required String text,
    List<String>? links,
  }) async
  {
    try {
      await notes.doc(documentId).update({
        titleFieldName: title,
        textFieldName: text,
        linksFieldName: links,
        updatedAtFieldName: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  /// Deletes a note by document ID
  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  // PRIMARY QUERY METHODS

  /// Get all notes for a user, sorted newest first (client-side sorting)
  Stream<Iterable<CloudNote>> allNotes({
    required String ownerUserId,
  })
  {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .limit(100)
        .snapshots()
        .map((event) {
      final notesList = event.docs
          .map((doc) => _createCloudNoteFromDoc(doc)) //  Use helper method
          .toList();

      //  CLIENT-SIDE SORT: No index required
      notesList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notesList;
    });
  }

  /// Get notes sorted by creation date (newest first)
  Stream<Iterable<CloudNote>> notesSortedByCreation({
    required String ownerUserId,
  })
  {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .limit(100)
        .snapshots()
        .map((event) {
      final notesList = event.docs
          .map((doc) => _createCloudNoteFromDoc(doc)) //  Use helper method
          .toList();

      //  CLIENT-SIDE SORT: By creation date
      notesList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notesList;
    });
  }

  /// Get recent notes from the last N days
  Stream<Iterable<CloudNote>> recentNotes({
    required String ownerUserId,
    int days = 7,
  })
  {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .limit(100)
        .snapshots()
        .map((event) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final notesList = event.docs
          .map((doc) => _createCloudNoteFromDoc(doc)) //  Use helper method
          .where((note) => note.updatedAt.isAfter(cutoffDate))
          .toList();

      //  CLIENT-SIDE SORT: Recent notes first
      notesList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notesList;
    });
  }

  // LINK MANAGEMENT METHODS

  /// Update only the links for a note
  Future<void> updateNoteLinks({
    required String documentId,
    required List<String>? links,
  }) async
  {
    try {
      await notes.doc(documentId).update({
        linksFieldName: links,
        updatedAtFieldName: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  /// Add a single link to a note
  Future<void> addLinkToNote({
    required String documentId,
    required String linkUrl,
  }) async
  {
    try {
      await notes.doc(documentId).update({
        linksFieldName: FieldValue.arrayUnion([linkUrl]),
        updatedAtFieldName: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  /// Remove a single link from a note
  Future<void> removeLinkFromNote({
    required String documentId,
    required String linkUrl,
  }) async
  {
    try {
      await notes.doc(documentId).update({
        linksFieldName: FieldValue.arrayRemove([linkUrl]),
        updatedAtFieldName: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  /// Get notes containing a specific link
  Stream<Iterable<CloudNote>> notesWithLink({
    required String ownerUserId,
    required String linkUrl,
  })
  {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .where(linksFieldName, arrayContains: linkUrl)
        .limit(50)
        .snapshots()
        .map((event) {
      final notesList = event.docs
          .map((doc) => _createCloudNoteFromDoc(doc)) //  Use helper method
          .toList();

      //  CLIENT-SIDE SORT: Latest first
      notesList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notesList;
    });
  }

  /// Get all notes that contain any links
  Stream<Iterable<CloudNote>> notesWithAnyLinks({
    required String ownerUserId,
  })
  {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .limit(100)
        .snapshots()
        .map((event) {
      final notesList = event.docs
          .map((doc) => _createCloudNoteFromDoc(doc)) //  Use helper method
          .where((note) => note.hasLinks) // Filter on client side
          .toList();

      //  CLIENT-SIDE SORT: Latest first
      notesList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notesList;
    });
  }

  // ADVANCED QUERY METHODS (Optional)

  /// Get notes with pagination support
  Stream<List<CloudNote>> getPaginatedNotes({
    required String ownerUserId,
    int limit = 20,
    CloudNote? lastNote,
  })
  {
    Query query = notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .limit(limit);

    return query.snapshots().map((event) {
      final notesList = event.docs
          .map((doc) => _createCloudNoteFromDoc(doc)) //  Use helper method
          .toList();

      //  CLIENT-SIDE SORT: Latest first
      notesList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notesList;
    });
  }

  /// Search notes by title or content (client-side search)
  Stream<Iterable<CloudNote>> searchNotes({
    required String ownerUserId,
    required String searchQuery,
  })
  {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .limit(100)
        .snapshots()
        .map((event) {
      final searchLower = searchQuery.toLowerCase();

      final filteredNotes = event.docs
          .map((doc) => _createCloudNoteFromDoc(doc)) //  Use helper method
          .where((note) =>
      note.title.toLowerCase().contains(searchLower) ||
          note.text.toLowerCase().contains(searchLower))
          .toList();

      //  CLIENT-SIDE SORT: Latest first
      filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return filteredNotes;
    });
  }

  /// Get notes count for a user
  Future<int> getNotesCount({required String ownerUserId}) async {
    try {
      final snapshot = await notes
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0; // Return 0 on error
    }
  }

  // UTILITY METHODS

  ///  HELPER: Create CloudNote from QueryDocumentSnapshot with proper type casting
  CloudNote _createCloudNoteFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>; //  Explicit cast

    return CloudNote(
      documentId: doc.id,
      ownerUserId: data[ownerUserIdFieldName] as String,
      title: data[titleFieldName] as String? ?? "",
      text: data[textFieldName] as String? ?? "",
      links: data[linksFieldName] != null
          ? List<String>.from(data[linksFieldName] as List)
          : null,
      createdAt: _parseTimestamp(data[createdAtFieldName]),
      updatedAt: _parseTimestamp(data[updatedAtFieldName]),
    );
  }

  /// Safely parse timestamp from Firestore data
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now(); // Fallback for existing notes
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.now(); // Ultimate fallback
  }
}
