import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'ditto_bindings.dart';

class DittoDb {
  final DittoBindings bindings;

  DittoDb(this.bindings);

  static final _instances = <int, DittoDb>{};
  static int _nextInstanceId = 1;
  late final int _instanceId;
  late final Pointer<Int32> _instanceIdPtr;

  Pointer<ditto_db_t>? _dbPtr;
  bool get isOpen => _dbPtr != null;
  Pointer<ditto_db_t> get _handle => _dbPtr!;

  int? _subId;
  bool get isSubscribed => _subId != null;
  final _changeController = StreamController<String>.broadcast();

  /// `path` is optional because it is not used, but is required by the C API signature.
  void open({String path = 'ditto.default.db'}) {
    if (isOpen) {
      throw StateError('Database already open.');
    }

    _instanceId = _nextInstanceId++;
    _instanceIdPtr = calloc<Int32>();
    _instanceIdPtr.value = _instanceId;
    _instances[_instanceId] = this;

    final dbPtrPtr = calloc<Pointer<ditto_db_t>>();
    final pathPtr = path.toNativeUtf8();
    final subIdPtr = calloc<Int32>();

    try {
      final rc = bindings.ditto_open(pathPtr, dbPtrPtr);
      if (rc != 0) {
        throw Exception('Failed to open database, error code: $rc');
      }
      _dbPtr = dbPtrPtr.value;
    } finally {
      malloc.free(pathPtr);
      calloc.free(dbPtrPtr);
      calloc.free(subIdPtr);
    }
  }

  Stream<String> subscribe() {
    if (isSubscribed) {
      throw StateError('Already subscribed.');
    }
    final subIdPtr = calloc<Int32>();

    try {
      final callbackPtr = Pointer.fromFunction<ditto_on_change_cbFunction>(
          _nativeChangeCallback);
      final rc = bindings.ditto_subscribe(
          _handle, callbackPtr, _instanceIdPtr.cast<Void>(), subIdPtr);
      if (rc != 0) {
        throw Exception('Failed to subscribe to db changes, error code: $rc');
      }
      _subId = subIdPtr.value;
      return _changeController.stream;
    } finally {
      calloc.free(subIdPtr);
    }
  }

  static void _nativeChangeCallback(
      Pointer<Void> userData, Pointer<Utf8> keyPtr) {
    final instanceId = userData.cast<IntPtr>().value;
    final instance = _instances[instanceId];

    if (instance != null) {
      final key = keyPtr.toDartString();
      instance._changeController.add(key);
    }
  }

  void close() {
    if (!isOpen) {
      throw StateError('Database not open.');
    }
    if (isSubscribed) {
      bindings.ditto_unsubscribe(_handle, _subId!);
    }
    bindings.ditto_close(_handle);
    _changeController.close();
    _instances.remove(_instanceId);
    calloc.free(_instanceIdPtr);
    _dbPtr = null;
    _subId = null;
  }

  void put(String key, Uint8List value) {
    if (!isOpen) {
      throw StateError('Database not open.');
    }
    final keyPtr = key.toNativeUtf8();
    final valuePtr = malloc.allocate<Uint8>(value.length);
    valuePtr.asTypedList(value.length).setAll(0, value);
    try {
      final rc = bindings.ditto_put(_handle, keyPtr, valuePtr, value.length);
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
          bindings.ditto_get(_handle, keyPtr, nullptr.cast<Uint8>(), lengthPtr);
      final len = lengthPtr.value;

      if (rc == 0) {
        return Uint8List(0);
      } else if (rc == 1) {
        final dataPtr = malloc.allocate<Uint8>(len);
        try {
          final rc2 = bindings.ditto_get(_handle, keyPtr, dataPtr, lengthPtr);
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
      } else if (rc == 2) {
        throw KeyNotFoundError(key);
      } else {
        throw Exception('Failed to get value, error code: $rc');
      }
    } finally {
      malloc.free(keyPtr);
      calloc.free(lengthPtr);
    }
  }

  void delete(String key) {
    if (!isOpen) {
      throw StateError('Database not open.');
    }
    final keyPtr = key.toNativeUtf8();
    try {
      final rc = bindings.ditto_delete(_handle, keyPtr);
      if (rc == 0) {
        return;
      } else if (rc == 2) {
        throw KeyNotFoundError(key);
      } else {
        throw Exception('Failed to delete value, error code: $rc');
      }
    } finally {
      malloc.free(keyPtr);
    }
  }
}

class KeyNotFoundError extends Error {
  final String key;
  KeyNotFoundError(this.key);
  @override
  String toString() => 'Key not found: $key';
}
