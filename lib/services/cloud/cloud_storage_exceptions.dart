abstract class CloudStorageException implements Exception {
  final String code;

  const CloudStorageException(this.code);

  String get message;

  String get title;

  @override
  String toString() => "CloudStorageException($code): $message";

  factory CloudStorageException.fromCode(String code) {
    switch (code) {
      case "CouldNotCreateNote":
        return CouldNotCreateNoteException(code);
      case "CouldNotGetAllNotes":
        return CouldNotGetAllNotesException(code);
      case "CouldNotDeleteNote":
        return CouldNotDeleteNoteException(code);
      case "CouldNotUpdateNote":
        return CouldNotUpdateNoteException(code);
      case "CouldNotReadNote":
        return CouldNotReadNoteException(code);
      case "CouldNotFindNote":
        return CouldNotFindNoteException(code);
      case "CouldNotSaveNote":
        return CouldNotSaveNoteException(code);
      case "CouldNotLoadNote":
        return CouldNotLoadNoteException(code);
      default:
        return UnknownCloudStorageException(code);
    }
  }
}

class CouldNotCreateNoteException extends CloudStorageException {
  const CouldNotCreateNoteException(super.code);

  @override
  // TODO: implement message
  String get message => "Could not Create the Note. Please try again later.";

  @override
  // TODO: implement title
  String get title => "New Note Failed";
}

class CouldNotGetAllNotesException extends CloudStorageException {
  const CouldNotGetAllNotesException(super.code);

  @override
  // TODO: implement message
  String get message => "Could not Get All Notes. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Get All Notes Failed";
}

class CouldNotDeleteNoteException extends CloudStorageException {
  const CouldNotDeleteNoteException(super.code);

  @override
  // TODO: implement message
  String get message => "Could not Delete the Note. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Delete Note Failed";
}

class CouldNotUpdateNoteException extends CloudStorageException {
  const CouldNotUpdateNoteException(super.code);

  @override
  // TODO: implement message
  String get message => "Could not Update the Note. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Update Note Failed";
}

class CouldNotReadNoteException extends CloudStorageException {
  const CouldNotReadNoteException(super.code);

  @override
  // TODO: implement message
  String get message => "Could not Read the Note. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Read Note Failed";
}

class CouldNotFindNoteException extends CloudStorageException {
  const CouldNotFindNoteException(super.code);

  @override
  // TODO: implement message
  String get message =>
      "Could not Find the Note from the database. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Find Note Failed";
}

class CouldNotSaveNoteException extends CloudStorageException {
  const CouldNotSaveNoteException(super.code);

  @override
  // TODO: implement message
  String get message => "Could not Save the Note. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Save Note Failed";
}

class CouldNotLoadNoteException extends CloudStorageException {
  const CouldNotLoadNoteException(super.code);

  @override
  // TODO: implement message
  String get message => "Could not Load the Note. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Load Note Failed";
}

class UnknownCloudStorageException extends CloudStorageException {
  const UnknownCloudStorageException(super.code);

  @override
  // TODO: implement message
  String get message =>
      "An Unknown Cloud Storage Exception Occurred. Please try again later.";

  @override
  // TODO: implement title
  String get title => "Unknown DB Exception";
}
