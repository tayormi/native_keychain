# native_keychain

iOS Keychain generic-password items with an explicit service, optional access group, and device-bound accessibility.

```dart
final keys = NativeKeychain(
  service: 'com.example.private.v1',
  accessibility: KeychainAccessibility.whenUnlockedThisDeviceOnly,
);
keys.writeString('token', value);
final token = keys.readString('token');
```

Import `package:native_keychain/native_keychain.dart`; run `dn pub get` and initialize the generated registrant.

`read`/`write` support Uint8List; `readString`/`writeString` use UTF-8. `delete` returns whether the item existed. `accessibilityOf` returns Apple's raw accessibility identifier for an existing item. Missing items return null; all other native failures throw `KeychainException` with an OSStatus code. No reset, enumeration or bulk deletion is performed.

Supported policies are `whenUnlockedThisDeviceOnly` (default), `afterFirstUnlockThisDeviceOnly`, and `whenPasscodeSetThisDeviceOnly`. Items are always non-synchronizing. A write updates an existing item including its policy, or adds it if absent. Entitlements are required when an access group is supplied. Passcode-gated behavior requires physical-device validation.

For `flutter_secure_storage` compatibility, its `IOSOptions.accountName` becomes `service`, and its item key remains the key. Preserve the app's signing identity and Keychain access group when replacing a shipped app. The package does not decrypt Secure Enclave-wrapped formats from other plugins.

FFI request and response buffers are explicitly freed and cleared. Managed Dart/Swift strings and JSON copies cannot be guaranteed erased, so this is not a zero-copy secret container. Values never appear in errors or logs. Only iOS is declared supported.

Source: [Apple Keychain services](https://developer.apple.com/documentation/security/keychain-services).
