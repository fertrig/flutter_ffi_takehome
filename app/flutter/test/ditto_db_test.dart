// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:ditto_ffi_app/native/ditto_bindings.dart';
import 'package:ditto_ffi_app/native/ditto_db.dart';

import 'package:ditto_ffi_app/native/ditto_loader.dart';

import 'package:test/test.dart';

void main() async {
  group('DittoDb', () {
    test('open and close', () {
      final db = createDittoDb();

      db.open();
      expect(db.isOpen, isTrue);

      db.close();
      expect(db.isOpen, isFalse);
    });

    test('put and get', () {
      final db = createDittoDb();
      db.open();

      db.put('intList', Uint8List.fromList([1, 2, 3]));
      final value = db.get('intList');
      expect(List<int>.from(value), equals([1, 2, 3]));

      db.put('string', Uint8List.fromList(utf8.encode('foobar')));
      final value2 = db.get('string');
      expect(utf8.decode(value2), equals('foobar'));

      db.put('double', doubleToBytes(3.141592653589793));
      final value3 = db.get('double');
      expect(bytesToDouble(value3), equals(3.141592653589793));

      db.put('empty', Uint8List(0));
      final value4 = db.get('empty');
      expect(List<int>.from(value4), equals([]));

      db.put('blank', Uint8List.fromList(utf8.encode('')));
      final value5 = db.get('blank');
      expect(utf8.decode(value5), equals(''));

      db.close();
    });

    test('key not found', () {
      final db = createDittoDb();
      db.open();
      try {
        db.get('non-existent');
        fail('Expected KeyNotFoundError');
      } on KeyNotFoundError catch (e) {
        expect(e.key, equals('non-existent'));
      }
      db.close();
    });

    test('delete', () {
      final db = createDittoDb();
      db.open();
      db.put('test', Uint8List.fromList([1, 2, 3]));
      expect(() => db.get('test'), isNot(throwsA(isA<KeyNotFoundError>())));
      db.delete('test');
      expect(() => db.get('test'), throwsA(isA<KeyNotFoundError>()));
      db.close();
    });

    test('subscribe', () async {
      final db = createDittoDb();
      db.open();

      final stream = db.subscribe();
      expect(db.isSubscribed, isTrue);

      expectLater(stream, emitsInOrder(['test', 'test2', 'pi', 'empty', 'blank']));

      db.put('test', Uint8List.fromList([1, 2, 3]));
      db.put('test2', Uint8List.fromList(utf8.encode('foobar')));
      db.put('pi', doubleToBytes(3.141592653589793));
      db.put('empty', Uint8List(0));
      db.put('blank', Uint8List.fromList(utf8.encode('')));

      db.close();
      expect(db.isSubscribed, isFalse);
    });
  });
}

String get nativeLibraryPath => Platform.isMacOS
    ? '../../C/macos'
    : Platform.isLinux
        ? '../../C/linux'
        : '../../C/windows';

DittoDb createDittoDb() {
  final library = loadNativeLibrary(directoryPath: nativeLibraryPath);
  final bindings = DittoBindings(library);
  final db = DittoDb(bindings);
  return db;
}

Uint8List doubleToBytes(double v) {
  final b = ByteData(8);
  b.setFloat64(0, v, Endian.little); 
  return b.buffer.asUint8List();
}

double bytesToDouble(Uint8List u8) =>
    ByteData.sublistView(u8).getFloat64(0, Endian.little);