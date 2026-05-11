String mapFirebaseError(Object e) {
  final error = e.toString();

  if (error.contains('permission-denied')) {
    return 'Anda tidak memiliki akses';
  } else if (error.contains('network')) {
    return 'Koneksi internet bermasalah';
  } else if (error.contains('not-found')) {
    return 'Data tidak ditemukan';
  } else if (error.contains('already-exists')) {
    return 'Data sudah ada';
  } else if (error.contains('unavailable')) {
    return 'Server sedang sibuk';
  }

  return 'Terjadi kesalahan, coba lagi';
}
