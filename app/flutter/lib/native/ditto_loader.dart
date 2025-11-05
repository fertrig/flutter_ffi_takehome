import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as p;

class NativeLibraryLoadError extends Error {
  final String path;
  final Object error;
  NativeLibraryLoadError(this.path, this.error);
  @override
  String toString() =>
      'NativeLibraryLoadError: Failed to load native library $path\n$error';
}

/// Loads the native library from the specified directory path.
/// If no directory path is specified, the library is loaded from the current directory.
DynamicLibrary loadNativeLibrary({String directoryPath = ''}) {
  if (Platform.isMacOS) {
    return _loadNativeLibrary(p.join(directoryPath, 'libdittoffi.dylib'));
  } else if (Platform.isLinux) {
    return _loadNativeLibrary(p.join(directoryPath, 'libdittoffi.so'));
  } else if (Platform.isWindows) {
    return _loadNativeLibrary(p.join(directoryPath, 'dittoffi.dll'));
  } else {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}

DynamicLibrary _loadNativeLibrary(String path) {
  try {
    return DynamicLibrary.open(path);
  } catch (e) {
    throw NativeLibraryLoadError(path, e);
  }
}
