import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'ditto_bindings.dart';

class DittoDb {
  final DittoBindings bindings;
  DittoDb(this.bindings);

  Pointer<ditto_db_t>? _dbPtr;

  bool get isOpen => _dbPtr != null;

  /// `path` is optional because it is not used, but is required by the C API signature.
  void open({String path = 'ditto.default.db'}) {
    if (isOpen) {
      throw StateError('Database already open.');
    }
    final dbPtrPtr = calloc<Pointer<ditto_db_t>>();
    final pathPtr = path.toNativeUtf8();

    try {
      final rc = bindings.ditto_open(pathPtr, dbPtrPtr);
      if (rc != 0) {
        throw Exception('Failed to open database, error code: $rc');
      }
      _dbPtr = dbPtrPtr.value;
    } finally {
      malloc.free(pathPtr);
      calloc.free(dbPtrPtr);
    }
  }

  void close() {
    if (!isOpen) {
      throw StateError('Database not open.');
    }
    bindings.ditto_close(_dbPtr!);
    _dbPtr = null;
  }

  void put(String key, Uint8List value) {
    if (!isOpen) {
      throw StateError('Database not open.');
    }
    final keyPtr = key.toNativeUtf8();
    final valuePtr = malloc.allocate<Uint8>(value.length);
    valuePtr.asTypedList(value.length).setAll(0, value);
    try {
      final rc = bindings.ditto_put(_dbPtr!, keyPtr, valuePtr, value.length);
      if (rc != 0) {
        throw Exception('Failed to put value, error code: $rc');
      }
    } finally {
      malloc.free(keyPtr);
      malloc.free(valuePtr);
    }
  }

  Uint8List get(String key) {
    if (!isOpen) {
      throw StateError('Database not open.');
    }
    final keyPtr = key.toNativeUtf8();
    final lengthPtr = calloc<Size>();

    try {
      final rc =
          bindings.ditto_get(_dbPtr!, keyPtr, nullptr.cast<Uint8>(), lengthPtr);
      final len = lengthPtr.value;
      if (rc == 0 || len == 0) {
        return Uint8List(0);
      }
      if (rc == 1) {
        final dataPtr = malloc.allocate<Uint8>(len);
        try {
          final rc2 = bindings.ditto_get(_dbPtr!, keyPtr, dataPtr, lengthPtr);
          if (rc2 != 0) {
            throw Exception(
                'Failed to get value after resizing buffer, error code: $rc2');
          }
          final out = Uint8List(len);
          out.setAll(0, dataPtr.asTypedList(len));
          return out;
        } finally {
          malloc.free(dataPtr);
        }
      }
      if (rc == 2) {
        throw Exception('Key not found.');
      }
      throw Exception('Failed to get value, error code: $rc');
    } finally {
      malloc.free(keyPtr);
      calloc.free(lengthPtr);
    }
  }
}
