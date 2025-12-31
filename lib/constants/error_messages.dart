
class ErrorMessages {
  /// Maps FirebaseAuth error codes to user-friendly messages.
  /// Add more cases here as you discover them.
  static String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address format is incorrect.';
      case 'user-disabled':
        return 'Your account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'invalid-credential':
        return 'The email or password you entered is incorrect.';
      case 'wrong-password':
        return 'The password you entered is incorrect.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'weak-password':
        return 'Your password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'cancelled-popup-request':
        return 'Popup request cancelled by user.';
      case 'popup-blocked':
        return 'Popup blocked by browser.';
      case 'popup-closed-by-user':
        return 'Popup closed by user.';
      case 'popup-timeout':
        return 'Popup timed out.';
      default:
        return "An unexpected error occurred.: '$errorCode'.";
    }
  }

  static String getAuthErrorTitle(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Invalid Email';
      case 'user-disabled':
        return 'Account Disabled';
      case 'user-not-found':
        return 'Account Not Found';
      case 'invalid-credential':
        return 'Invalid Credentials';
      case 'wrong-password':
        return 'Incorrect Password';
      case 'email-already-in-use':
        return 'Email Already Registered';
      case 'weak-password':
        return 'Weak Password';
      case 'network-request-failed':
        return 'No Internet Connection';
      case 'too-many-requests':
        return 'Too Many Attempts';
      case 'cancelled-popup-request':
        return 'Popup Request Cancelled';
      case 'popup-blocked':
        return 'Popup Blocked';
      case 'popup-closed-by-user':
        return 'Popup Closed by User';
      case 'popup-timeout':
        return 'Popup Timeout';
      default:
        return 'Unexpected Error';
    }
  }

  /// Maps general app errors (non-auth) to user-friendly messages.
  /// You can use this for other views like NotesView, SettingsView, etc.
  static String getGeneralErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'network-error':
        return 'Unable to connect to the server. Please try again.';
      case 'timeout':
        return 'The request timed out. Please try again.';
      case 'unknown':
        return 'Something went wrong. Please try again later.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}/*Class ErrorMessages*/