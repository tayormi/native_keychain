library;

import 'dart:convert';
import 'dart:typed_data';
import 'src/bindings.dart';
export 'src/bindings.dart' show KeychainBindings, KeychainException;

/// Device-bound, non-synchronizing Keychain policies.
enum KeychainAccessibility {
  whenUnlockedThisDeviceOnly,
  afterFirstUnlockThisDeviceOnly,
  whenPasscodeSetThisDeviceOnly,
}

/// iOS Keychain generic-password items. [service] maps to
/// flutter_secure_storage's IOSOptions.accountName; keys map to kSecAttrAccount.
/// Missing items return null. Locked/denied items throw and are never reset.
final class NativeKeychain {
  NativeKeychain({
    required this.service,
    this.accessGroup,
    this.accessibility = KeychainAccessibility.whenUnlockedThisDeviceOnly,
    KeychainBindings? bindings,
  }) : _bindings = bindings {
    if (service.isEmpty || service.contains('\u0000')) {
      throw ArgumentError('Invalid Keychain service.');
    }
    if (accessGroup != null && accessGroup!.isEmpty) {
      throw ArgumentError('Invalid access group.');
    }
  }
  final String service;
  final String? accessGroup;
  final KeychainAccessibility accessibility;
  final KeychainBindings? _bindings;
  Map<String, dynamic> _call(
    String operation,
    String key, [
    Map<String, Object?> extra = const {},
  ]) {
    if (key.isEmpty || key.contains('\u0000')) {
      throw ArgumentError('Invalid Keychain key.');
    }
    return (_bindings ?? KeychainBindings.instance).request({
      'operation': operation,
      'service': service,
      'key': key,
      if (accessGroup != null) 'accessGroup': accessGroup,
      ...extra,
    });
  }

  Uint8List? read(String key) {
    final result = _call('read', key)['value'] as String?;
    return result == null ? null : base64Decode(result);
  }

  String? readString(String key) {
    final value = read(key);
    return value == null ? null : utf8.decode(value);
  }

  void write(String key, Uint8List value) {
    _call('write', key, {
      'value': base64Encode(value),
      'accessibility': accessibility.name,
    });
  }

  void writeString(String key, String value) =>
      write(key, Uint8List.fromList(utf8.encode(value)));
  bool delete(String key) => _call('delete', key)['deleted'] as bool;

  /// Returns Apple's raw accessibility identifier, or null when absent.
  String? accessibilityOf(String key) =>
      _call('read', key)['accessibility'] as String?;
}
