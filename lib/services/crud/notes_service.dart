// import 'dart:async';
//
// import 'package:flutter/cupertino.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:infinitynotes/services/crud/crud_exception.dart';
//
// //Constants for Database
// const dbName = "notes.db";
// const noteTable = "note";
// const userTable = "user";
// const idColumn = "id";
// const emailColumn = "email";
// const userIdColumn = "user_id";
// const titleColumn = "title";
// const textColumn = "text";
// const isSyncedWithCloudColumn = "is_synced_with_cloud";
// const createdColumn = "created_at";
// const updatedColumn = "updated_at";
//
// //Database Queries
// //User Table
// const String createUserTable =
//     '''
//         CREATE TABLE IF NOT EXISTS $userTable (
//           $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
//           $emailColumn TEXT UNIQUE NOT NULL
//         )''';
// //Note Table
// const String createNoteTable =
//     '''
//       CREATE TABLE IF NOT EXISTS $noteTable (
//         $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
//         $userIdColumn INTEGER NOT NULL,
//         $titleColumn TEXT NOT NULL,
//         $textColumn TEXT NOT NULL,
//         $isSyncedWithCloudColumn INTEGER NOT NULL DEFAULT 0,
//         $createdColumn TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
//         $updatedColumn TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
//         FOREIGN KEY($userIdColumn) REFERENCES $userTable($idColumn) ON DELETE CASCADE
//         )''';
//
// const String createUpdateTrigger =
//     '''
//   CREATE TRIGGER IF NOT EXISTS update_note_timestamp
//   AFTER UPDATE ON $noteTable
//   BEGIN
//     UPDATE $noteTable SET $updatedColumn = CURRENT_TIMESTAMP WHERE $idColumn = NEW.$idColumn;
//   END;
// ''';
//
// /*Database Structure*/
// class NotesService {
//   Database? _db;
//   List<DatabaseNote> _notes = [];
//   static final NotesService _shared = NotesService._sharedInstance();
//   late final StreamController<List<DatabaseNote>> _notesStreamController;
//
//   NotesService._sharedInstance(){
//     _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
//     onListen: () {
//         _notesStreamController.sink.add(_notes);
//     },
//     );
//   }
//   factory NotesService() => _shared;
//
//   //Public Stream for UI to listen to
//   Stream<List<DatabaseNote>> get allNotes =>
//       _notesStreamController.stream;
//   //Filter by UserID
//   Stream<List<DatabaseNote>> notesForUser(int userId) {
//     return _notesStreamController.stream.map((_){
//       final allNotes = _notes.where((note) => note.userId == userId).toList();
//       return allNotes;
//     });
//   }
//
//   Future<void> _cacheNotes({required int userId}) async {
//     final allNotes = await getAllNotes(userId: userId);
//     _notes = allNotes.toList();
//     _notesStreamController.add(_notes);
//   } //Future<void> _cacheNotes()
//
//   Future<DatabaseNote> updateNote({
//     required DatabaseNote note,
//     required String title,
//     required String text,
//   }) async
//   {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     await getNote(id: note.id); //check if note exists
//     final updatesCount = await db.update(
//         noteTable, {
//       titleColumn: title,
//       textColumn: text,
//       isSyncedWithCloudColumn: 0,
//     }, where: '$idColumn = ?',
//       whereArgs: [note.id],
//     );
//     if (updatesCount == 0) {
//       throw CrudException.fromCode('could-not-update-note');
//     } else {
//       final updatedNote = await getNote(id: note.id);
//       _notes.removeWhere((note) => note.id == updatedNote.id);
//       _notes.add(updatedNote);
//       _notesStreamController.add(_notes);
//       return updatedNote;
//     }
//   } //Future<DatabaseNote> updateNote()
//
//   Future<Iterable<DatabaseNote>> getAllNotes({required int userId}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final notes = await db.query(
//         noteTable,
//       where: '$userIdColumn = ?',
//       whereArgs: [userId],
//     );
//     final result = notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
//     return result;
//   } //Future<Iterable<DatabaseNote>> getAllNotes()
//
//   Future<DatabaseNote> getNote({required int id}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final notes = await db.query(
//       noteTable,
//       limit: 1,
//       where: '$idColumn = ?',
//       whereArgs: [id],
//     );
//     if (notes.isEmpty) {
//       throw CrudException.fromCode('could-not-find-note');
//     } else {
//       final note = DatabaseNote.fromRow(notes.first);
//       _notes.removeWhere((note) => note.id == id);
//       _notes.add(note);
//       _notesStreamController.add(_notes);
//       return note;
//     }
//   } //Future<DatabaseNote> getNote()
//
//   Future<int> deleteAllNotes() async {
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(noteTable);
//
//     _notes = []; //empties the notes list
//     _notesStreamController.add(_notes); //adds an empty list to the stream
//     return deletedCount;
//   } //Future<int> deleteAllNotes()
//
//   Future<DatabaseNote> createNote({
//     required DatabaseUser owner,
//     required String title,
//     required String text,
//   }) async
//   {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final dbUser = await getUser(email: owner.email);
//     if (dbUser != owner) {
//       throw CrudException.fromCode('could-not-find-user');
//     }
//     final noteId = await db.insert(noteTable, {
//       userIdColumn: owner.id,
//       titleColumn: title,
//       textColumn: text,
//       isSyncedWithCloudColumn: 1,
//     });
//     final note = DatabaseNote(
//       id: noteId,
//       userId: owner.id,
//       title: title,
//       text: text,
//       isSyncedWithCloud: true,
//       createdAt: DateTime.now().toString(),
//       updatedAt: DateTime.now().toString(),
//     );
//
//     _notes.add(note);
//     _notesStreamController.add(_notes);
//     return note;
//   } //Future<DatabaseNote> createNote()
//
//   Future<void> deleteNote({required int id}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       noteTable,
//       where: '$idColumn = ?',
//       whereArgs: [id],
//     );
//     if (deletedCount != 1) {
//       throw CrudException.fromCode('could-not-delete-note');
//     } else {
//       _notes.removeWhere((note) => note.id == id);
//       _notesStreamController.add(_notes);
//     }
//   } //Future<void> deleteNote()
//
//   //User Functions
//   Future<DatabaseUser> getOrCreateUser({required String email}) async {
//     try {
//       final user = await getUser(email: email);
//       await _cacheNotes(userId: user.id);
//       return user;
//       /* } on CouldNotFindUserException {*/
//     } on CrudException catch (e) {
//       if (e.code != 'could-not-find-user') {
//         rethrow;
//       }
//       final createdUser = await createUser(email: email);
//       await _cacheNotes(userId: createdUser.id);
//       return createdUser;
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<DatabaseUser> getUser({required String email}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: '$emailColumn = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (results.isEmpty) {
//       throw CrudException.fromCode('could-not-find-user');
//     } else {
//       return DatabaseUser.fromMap(results.first);
//     }
//   } //Future<DatabaseUser> getUser()
//
//   Future<DatabaseUser> createUser({required String email}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: '$emailColumn = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (results.isNotEmpty) {
//       throw CrudException.fromCode('user-already-exists');
//     }
//     final userId = await db.insert(userTable, {
//       emailColumn: email.toLowerCase(),
//     });
//     return DatabaseUser(id: userId, email: email);
//   } //Future<DatabaseUser> createUser()
//
//   Future<void> deleteUser({required String email}) async {
//     await _ensureDBIsOpen();
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       userTable,
//       where: '$emailColumn = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (deletedCount != 1) {
//       throw CrudException.fromCode('could-not-delete-user');
//     }
//   } //Future<void> deleteUser()
//
//   // Database Functions
//   Future<void> _ensureDBIsOpen() async {
//     try {
//       await open();
//     } on CrudException catch (e) {
//       if (e.code != 'database-already-open') {
//         rethrow;
//       } //empty
//     }
//   } //Future<void> _ensureDBIsOpen()
//
//   Database _getDatabaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw CrudException.fromCode('database-not-open');
//     } else {
//       return db;
//     }
//   } // Database _getDatabaseOrThrow()
//
//   Future<void> close() async {
//     final db = _db;
//     if (db == null) {
//       throw CrudException.fromCode('database-not-open');
//     } else {
//       await db.close();
//       _db = null;
//     }
//   } // Future<void> close()
//
//   Future<void> open() async {
//     if (_db != null) {
//       throw CrudException.fromCode('database-already-open');
//     }
//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//         _db = await openDatabase(
//           dbPath,
//           version: 1,
//       onCreate: (db, version) async {
//         await db.execute(createUserTable);
//         await db.execute(createNoteTable);
//         await db.execute(createUpdateTrigger);
//       },
//
//       );
//       //Enable Foreign Keys first
//       await _db?.execute("PRAGMA foreign_keys = ON");
//     } on CrudException catch (e) {
//       if (e.code != 'missing-platform-directory') {
//         rethrow;
//       } else {
//         throw CrudException.fromCode('document-dir-not-found');
//       }
//     }
//   } // Future<void> open()
// } // class NotesService. Should be the end of the block every time.
//
// @immutable
// class DatabaseUser {
//   final int id;
//   final String email;
//
//   const DatabaseUser({required this.id, required this.email});
//
//   DatabaseUser.fromMap(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         email = (map[emailColumn] ?? '') as String;
//
//
//   @override
//   String toString() => "User(id: $id, email: $email)";
//
//   @override
//   bool operator ==(covariant DatabaseUser other) => id == other.id;
//
//   @override
//   int get hashCode => id.hashCode;
// } //class DatabaseUser
//
// class DatabaseNote {
//   final int id;
//   final int userId;
//   final String title;
//   final String text;
//   final bool isSyncedWithCloud;
//   final String createdAt;
//   final String updatedAt;
//
//   DatabaseNote({
//     required this.id,
//     required this.userId,
//     required this.title,
//     required this.text,
//     required this.isSyncedWithCloud,
//     required this.createdAt,
//     required this.updatedAt,
//   }); //DatabaseNote Constructor
//
//   DatabaseNote.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         userId = map[userIdColumn] as int,
//         title = (map[titleColumn] ?? '') as String, // fallback empty string
//         text = (map[textColumn] ?? '') as String,
//         isSyncedWithCloud = (map[isSyncedWithCloudColumn] as int? ?? 0) == 1,
//         createdAt = (map['created_at'] ?? DateTime.now().toIso8601String()) as String,
//         updatedAt = (map['updated_at'] ?? DateTime.now().toIso8601String()) as String;
//
//
//   @override
//   String toString() {
//     return "Note("
//         "id: $id, "
//         "userId: $userId, "
//         "title: $title, "
//         "text: $text, "
//         "isSyncedWithCloud: $isSyncedWithCloud,"
//         "createdAt: $createdAt, "
//         "updatedAt: $updatedAt)";
//   }
//
//   @override
//   bool operator ==(covariant DatabaseNote other) => id == other.id;
//
//   @override
//   int get hashCode => id.hashCode;
// } //class DatabaseNote
