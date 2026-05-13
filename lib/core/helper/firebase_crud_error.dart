String mapFirebaseError(Object e) {
  final error = e.toString();

  if (error.contains('permission-denied')) {
    return 'You do not have permission to perform this action';
  } else if (error.contains('network')) {
    return 'Network connection issue. Please check your internet connection';
  } else if (error.contains('not-found')) {
    return 'Requested data was not found';
  } else if (error.contains('already-exists')) {
    return 'Data already exists';
  } else if (error.contains('unavailable')) {
    return 'The server is currently unavailable. Please try again later';
  }

  return 'An unexpected error occurred. Please try again';
}
