import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final class KeychainException implements Exception {
  const KeychainException(this.code);
  final String code;
  @override
  String toString() => 'KeychainException($code)';
}

/// Owns the native request/response ABI; returned strings are explicitly freed.
final class KeychainBindings {
  static KeychainBindings? _instance;
  static KeychainBindings get instance => _instance ??= KeychainBindings();
  static void loadSymbols() {
    if (Platform.isIOS) {
      instance;
    }
  }

  KeychainBindings({DynamicLibrary? library}) {
    if (library == null && !Platform.isIOS) {
      throw UnsupportedError(
        'native_keychain currently supports iOS only.',
      );
    }
    final lib = library ?? DynamicLibrary.process();
    _call = lib
        .lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>)
        >('DnkeyRequest');
    _free = lib
        .lookupFunction<
          Void Function(Pointer<Utf8>),
          void Function(Pointer<Utf8>)
        >('DnkeyFree');
  }
  late final Pointer<Utf8> Function(Pointer<Utf8>) _call;
  late final void Function(Pointer<Utf8>) _free;
  Map<String, dynamic> request(Map<String, Object?> arguments) {
    final encoded = jsonEncode(arguments);
    final input = encoded.toNativeUtf8();
    Pointer<Utf8> output = nullptr;
    try {
      output = _call(input);
      if (output == nullptr) {
        throw const KeychainException('allocation_failed');
      }
      final result = jsonDecode(output.toDartString()) as Map<String, dynamic>;
      final error = result['error'];
      if (error != null) throw KeychainException(error as String);
      return result;
    } finally {
      input
          .cast<Uint8>()
          .asTypedList(utf8.encode(encoded).length)
          .fillRange(0, utf8.encode(encoded).length, 0);
      calloc.free(input);
      if (output != nullptr) _free(output);
    }
  }
}
