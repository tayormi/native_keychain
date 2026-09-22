Pod::Spec.new do |s|
  s.name = 'native_keychain'
  s.version = '0.1.1'
  s.summary = 'Configurable iOS Keychain access for DartNative.'
  s.description = s.summary
  s.homepage = 'https://github.com/tayormi/native_keychain'
  s.license = { :type => 'MIT', :file => '../LICENSE' }
  s.author = 'DartNative Storage contributors'
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,c,swift}'
  s.platform = :ios, '15.0'
  s.swift_version = '5.9'
  s.static_framework = true
  # FFI has no static Dart-to-C references; retain the native ABI in the app.
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -Wl,-u,_DnkeyRequest -Wl,-u,_DnkeyFree' }
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1' }
  s.frameworks = 'Foundation', 'Security'
end
