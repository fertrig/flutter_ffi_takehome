// ignore_for_file: avoid_print

class Log {
  static void info(Object? object) {
    print('[INFO] $object');
  }

  static void error(Object? object) {
    print('[ERROR] $object');
  }

  static void warning(Object? object) {
    print('[WARNING] $object');
  }
}