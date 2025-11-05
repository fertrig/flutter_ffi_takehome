import 'dart:ffi';
import 'dart:io';

class NativeLibraryLoadError extends Error {
  final String path;
  final Object error;
  NativeLibraryLoadError(this.path, this.error);
  @override
  String toString() =>
      'NativeLibraryLoadError: Failed to load native library $path\n$error';
}

DynamicLibrary loadNativeLibrary() {
  if (Platform.isMacOS) {
    return _loadNativeLibrary('libdittoffi.dylib');
  } else if (Platform.isLinux) {
    return _loadNativeLibrary('libdittoffi.so');
  } else if (Platform.isWindows) {
    return _loadNativeLibrary('dittoffi.dll');
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
