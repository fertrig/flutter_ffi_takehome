gen-bindings:
	cp ../../C/include/ditto.h ephemeral/C/ditto.h
	cp ../../C/src/ditto.c ephemeral/C/ditto.c
	fvm dart run ffigen --config ffigen.yaml

run-macos:
	cp ../../C/macos/libdittoffi.dylib  build/macos/Build/Products/Debug/ditto_ffi_app.app/Contents/MacOS/
	fvm flutter run -d macos