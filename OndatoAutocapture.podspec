Pod::Spec.new do |spec|
  spec.name         = 'OndatoAutocapture'
  spec.version      = '3.2.2'
  spec.platform     = :ios
  spec.summary      = 'Ondato iOS Autocapture'
  spec.ios.deployment_target = '13.0'
  spec.license      = 'Apache-2.0'
  spec.homepage     = 'https://github.com/ondato/ondato-sdk-ios'
  spec.authors      = { 'Ondato' => 'info@ondato.com' }
  spec.source       = { :git => 'https://github.com/ondato/ondato-sdk-ios.git', :tag => spec.version }
  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  spec.vendored_frameworks  = 'Binaries/OndatoAutocapture.xcframework'
end
