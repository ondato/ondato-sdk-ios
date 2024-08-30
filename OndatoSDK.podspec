Pod::Spec.new do |spec|
  spec.name         = 'OndatoSDK'
  spec.version      = '2.5.7'
  spec.platform     = :ios
  spec.summary      = 'Ondato iOS SDK'
  spec.ios.deployment_target = '13.0'
  spec.license  	   = 'Apache-2.0'
  spec.homepage     = 'https://github.com/ondato/ondato-sdk-ios'
  spec.authors      = { 'Ondato' => 'info@ondato.com' }
  spec.source       = { :git => 'https://github.com/ondato/ondato-sdk-ios.git', :tag => spec.version }
  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  spec.ios.vendored_frameworks  = 'OndatoSDK.xcframework', 'FaceTecSDK.xcframework', 'OpenSSL.xcframework'
end
