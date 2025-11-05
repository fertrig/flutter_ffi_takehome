import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  // @gotcha: hooks only work on Dart 3.10, the Dart version of the latest Flutter SDK is 3.9.2
  await build(args, (input, output) async {
    if (input.config.buildCodeAssets && Platform.isMacOS) {
      output.dependencies.add(Uri.file('../../C/macos/libdittoffi.dylib'));
    }
  });
}