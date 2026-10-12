Pod::Spec.new do |spec|
  spec.name         = "OndatoNFC"
  spec.version      = "3.6.1"
  spec.platform     = :ios
  spec.summary      = "Ondato iOS NFC"
  spec.ios.deployment_target = "15.0"
  spec.license      = 'Apache-2.0'
  spec.homepage     = "https://gitlab.com/ondato/ondato-sdk-ios"
  spec.authors      = { "Ondato" => "info@ondato.com" }
  spec.source       = { :git => 'https://gitlab.com/ondato/ondato-sdk-ios.git', :tag => spec.version }
  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  spec.vendored_frameworks  = 'Binaries/OndatoNFC.xcframework', 'Binaries/OpenSSL.xcframework'
end
