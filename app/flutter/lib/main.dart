// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'dart:convert';

import 'package:ditto_ffi_app/native/ditto_bindings.dart';
import 'package:ditto_ffi_app/native/ditto_db.dart';
import 'package:ditto_ffi_app/native/log.dart';

import 'native/ditto_loader.dart';

void main() {
  try {
    final library = loadNativeLibrary();
    Log.info('Native library loaded successfully');
    
    final bindings = DittoBindings(library);
    final db = DittoDb(bindings);
    db.open();
    Log.info('Database opened successfully');
    
    try {
      db.open(); // test state error
    }
    on StateError catch (e) {
      Log.warning(e);
    }

    db.put('test', Uint8List.fromList([1, 2, 3]));
    Log.info('Value "test" put successfully');

    db.put('test2', Uint8List.fromList(utf8.encode('foobar')));
    Log.info('Value "test2" put successfully');

    db.put('pi', doubleToBytes(3.141592653589793));
    Log.info('Value "pi" put successfully');

    db.put('empty', Uint8List(0));
    Log.info('Value "empty" put successfully');

    db.put('blank', Uint8List.fromList(utf8.encode('')));
    Log.info('Value "blank" put successfully');

    final value = db.get('test');
    Log.info('Value "test" retrieved successfully: ${List<int>.from(value)}');

    final value2 = db.get('test2');
    Log.info('Value "test2" retrieved successfully: ${utf8.decode(value2)}');

    final value3 = db.get('pi');
    Log.info('Value "pi" retrieved successfully: ${bytesToDouble(value3)}');

    final value4 = db.get('empty');
    Log.info('Value "empty" retrieved successfully: ${List<int>.from(value4)}');

    final value5 = db.get('blank');
    Log.info('Value "blank" retrieved successfully: ${utf8.decode(value5)}');

    db.close();
    
    Log.info('Database closed successfully');
    try {
      db.close(); // test state error
    } on StateError catch (e) {
      Log.warning(e);
    }
  } on NativeLibraryLoadError catch (e) {
    Log.error(e);
  } on UnsupportedError catch (e) {
    Log.error(e);
  } catch (e) {
    Log.error('Unexpected error: $e');
  }
}

Uint8List doubleToBytes(double v) {
  final b = ByteData(8);
  b.setFloat64(0, v, Endian.little); 
  return b.buffer.asUint8List();
}

double bytesToDouble(Uint8List u8) =>
    ByteData.sublistView(u8).getFloat64(0, Endian.little);