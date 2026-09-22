# native_keychain

Store tokens, passwords, and small secrets in the iOS Keychain from DartNative.

## Install

Add to your DartNative app's `pubspec.yaml`:

```yaml
dependencies:
  native_keychain:
    hosted: https://dartpub.dev
    version: ^0.1.1
```

Run `dn pub get`, then rebuild the app to link the native plugin. Use the generated plugin registrant provided by your DartNative app template.

## Use

```dart
import 'package:native_keychain/native_keychain.dart';

void saveToken(String token) {
  final keychain = NativeKeychain(service: 'com.example.myapp');
  keychain.writeString('api-token', token);
  final savedToken = keychain.readString('api-token');
  if (savedToken == null) throw StateError('Token was not saved');
  // Remove it when the user signs out:
  keychain.delete('api-token');
}
```

## Notes

- iOS only, with a native deployment target of iOS 15+. Your DartNative SDK may require a newer OS.
- Items default to `whenUnlockedThisDeviceOnly`: available while unlocked and bound to the device. Other supported accessibility policies are documented in [API notes](https://github.com/tayormi/native_keychain/blob/main/docs/api-notes.md).
- Missing keys return `null`. Other native failures throw `KeychainException`.
- Use a stable service name. Sharing items through an access group requires matching Keychain entitlements.

Supports strings and bytes. Items do not sync through iCloud. See [API notes](https://github.com/tayormi/native_keychain/blob/main/docs/api-notes.md) for migration and accessibility details.

MIT license.
