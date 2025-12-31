//
// abstract class CrudException implements Exception {
//   final String code;
//   String get message;
//   const CrudException(this.code);
//
//   @override
//   String toString() {
//     return "CrudException($code): $message";
//   }
//
//   factory CrudException.fromCode(String code) {
//     switch (code) {
//       case 'document-dir-not-found'
//         : return UnableToGetDocumentsDirectoryException();
//       case 'database-already-open'
//         : return  DatabaseAlreadyOpenException();
//       case 'database-not-open'
//         : return  DatabaseNotOpenException();
//       case 'could-not-delete-user'
//         : return  CouldNotDeleteUser();
//       case 'user-already-exists'
//         : return  UserAlreadyExistsException();
//       case 'could-not-find-user'
//         : return  CouldNotFindUserException();
//       case 'could-not-delete-note'
//         : return  CouldNotDeleteNote();
//       case 'could-not-find-note'
//         : return  CouldNotFindNoteException();
//       case 'could-not-update-note'
//         : return  CouldNotUpdateNote();
//       case 'missing-platform-directory'
//         : return  MissingPlatformDirectoryException();
//       default
//           : return  GenericCRUDException();
//
//     }
//   }
// }
//
//
//
// class UnableToGetDocumentsDirectoryException extends CrudException {//
//   const UnableToGetDocumentsDirectoryException()
//       :super('document-dir-not-found');
//   @override
//   String get message => "Unable to get documents directory.";
// }
//
// class DatabaseAlreadyOpenException extends CrudException{//
//   const DatabaseAlreadyOpenException()
//       :super('database-already-open');
//   @override
//   String get message => "Database is already Open.";
// }
//
// class DatabaseNotOpenException extends CrudException{//
//   const DatabaseNotOpenException()
//       :super('database-not-open');
//   @override
//   String get message => "Database is not Open.";
// }
//
// class CouldNotDeleteUser extends CrudException{ //
//   const CouldNotDeleteUser()
//       :super('could-not-delete-user');
//   @override
//   String get message => "Could not delete user.";
// }
//
// class UserAlreadyExistsException extends CrudException{//
//   const UserAlreadyExistsException()
//       :super('user-already-exists');
//   @override
//   String get message => "User already exists.";
// }
//
// class CouldNotFindUserException extends CrudException{//
//   const CouldNotFindUserException()
//       :super('could-not-find-user');
//   @override
//   String get message => "Could not find User.";
// }
//
// class CouldNotDeleteNote extends CrudException{//
//   const CouldNotDeleteNote()
//       :super('could-not-delete-note');
//   @override
//   String get message => "Could not delete Note.";
// }
//
// class CouldNotFindNoteException extends CrudException{//
//   const CouldNotFindNoteException()
//       :super('could-not-find-note');
//   @override
//   String get message => "Could not find Note.";
// }
//
// class CouldNotUpdateNote extends CrudException{//
//   const CouldNotUpdateNote()
//       :super('could-not-update-note');
//   @override
//   String get message => "Could not update Note.";
// }
//
// class MissingPlatformDirectoryException extends CrudException{
//   const MissingPlatformDirectoryException()
//       :super('missing-platform-directory');
//   @override
//   String get message => "Platform directory not found.";
// }
//
// class GenericCRUDException extends CrudException{//
//   const GenericCRUDException()
//       :super('generic-crud-exception');
//   @override
//   String get message => "Something went wrong.";
// }