List of challenges I faced and how I solved them.


### Issue loading the native library

macos/README.md says "The Flutter app will automatically load this library when running on macOS. No additional configuration needed." However, that wasn't working for me. I also didn't see any script or configuration that would do that.

I considered using `Directory.current.path` to find the path to the native library in the repo. However, I didn't like that approach because that would only work in development mode. I preferred to load the native library from the same directory as the flutter app executable.

To solve that problem I tried using [dart hooks](https://dart.dev/tools/hooks), which is a nice solution, but it only works on Dart 3.10. The Dart version of the latest Flutter SDK is 3.9.2. Thus, to load the native library from the build directory, I used a Makefile to first copy the native library to the build directory and then run flutter.

I could have also open up Xcode and set up the copying of the library in the Xcode project build settings. I preferred the Makefile approach because it is programatic and it would scale well to other platforms.


### Makefile
The Makefile has tasks to run the app on macOS and to generate FFI bindings

### `ditto_open` 
- Does not use `path` parameter
- It does not do file I/O, the db is in-memory, thus ok to call synchronously from dart

### Callbacks
The approach proposed in the readme feels complex and not Dart friendly. Dart has first-class support for streams. In Dart, call sites manage their stream subscriptions and one stream can be listened to by multiple call sites. Therefore, DittoDb only needs to manage a stream controller and expose its stream, it doesn't have to manage a global registry of subscription IDs and Dart callbacks, instead I used a static map of DittoDb instances to map a subscription ID to a DittoDb instance which exposes a stream to multiple Flutter call sites.

The readme mentions "Use `scheduleMicrotask()` for thread safety". However, `StreamController.add` already delivers the event in a later microtask.

### Clear
The UI requirements mention an action "Clear". However, the API doesn't support that unless by "Clear" it means closing the db and opening a new one. I wasn't sure so I didn't implement that piece.

### FFI calls from UI thread
In my solution all FFI calls to the C library run on the UI thread which blocks the UI. This is fine because the db uses an in-memory table, it never accesses I/O. I didn't want to add extra complexity by faking async calls to the C library. 

If the db used I/O then I would have spawned a Dart isolate to make the FFI calls. I would have also made the UI responsive to async calls. 

