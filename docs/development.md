# Development

Run `dart pub get` and `dart analyze` from this directory.

Build the iOS and Android artifacts supported by this package on a Mac with Xcode, CocoaPods, Android build tools, and DartNative installed:

```sh
python3 tools/build_release.py --dn /path/to/dn
```

The script builds with the DartNative CLI, applies this package's MIT metadata to the generated podspec, includes documentation and license notices, and writes archives and checksums to `dist/`.

Native behavior needs an app test. Keychain accessibility and file protection need a physical iOS device; simulators cannot reproduce all lock and protection behavior.
