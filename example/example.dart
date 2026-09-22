import 'package:native_keychain/native_keychain.dart';

void saveToken(String token) {
  final keychain = NativeKeychain(service: 'com.example.myapp');
  keychain.writeString('api-token', token);
  final savedToken = keychain.readString('api-token');
  if (savedToken == null) throw StateError('Token was not saved');
  // Remove it when the user signs out:
  keychain.delete('api-token');
}
