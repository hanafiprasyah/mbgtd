String mapFirebaseError(Object e) {
  final error = e.toString();

  // Map common Firebase errors to user-friendly messages
  if (error.contains('permission-denied')) {
    // This error occurs when the user does not have permission to perform the requested action
    return 'You do not have permission to perform this action';
  } else if (error.contains('network')) {
    // This error occurs when there is a network issue preventing communication with Firebase
    return 'Network connection issue. Please check your internet connection';
  } else if (error.contains('not-found')) {
    // This error occurs when the requested data is not found in Firebase
    return 'Requested data was not found';
  } else if (error.contains('already-exists')) {
    // This error occurs when trying to create a document that already exists in Firebase
    return 'Data already exists';
  } else if (error.contains('unavailable')) {
    // This error occurs when the Firebase service is temporarily unavailable
    return 'The server is currently unavailable. Please try again later';
  }

  // For any other errors, return a generic message
  return 'An unexpected error occurred. Please try again';
}
