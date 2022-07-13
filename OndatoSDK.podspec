Pod::Spec.new do |spec|
  spec.name         = 'OndatoSDK'
  spec.version      = '1.8.20'
  spec.platform     = :ios
  spec.summary      = 'Ondato iOS SDK'
  spec.ios.deployment_target = '12.0'
  spec.license  	   = 'Apache-2.0'
  spec.homepage     = 'https://github.com/ondato/ondato-sdk-ios'
  spec.authors      = { 'Ondato' => 'info@ondato.com' }
  spec.source       = { :git => 'git@github.com:ondato/ondato-sdk-ios.git', :tag => spec.version }
  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  spec.ios.vendored_frameworks  = 'OndatoSDK.framework', 'FaceTecSDK.framework', 'SwiftyTesseract.framework', 'libtesseract.xcframework'
  spec.dependency "OpenSSL-Universal", '1.1.180'
  spec.weak_frameworks = 'CoreNFC'
  spec.script_phase = { :name => 'Strip unused architectures', :script => 'bash "${PODS_ROOT}/OndatoSDK/FaceTecSDK.framework/strip-unused-architectures-from-target.sh"
' }
end
