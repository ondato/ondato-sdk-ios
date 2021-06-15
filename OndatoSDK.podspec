Pod::Spec.new do |spec|
  spec.name         = 'OndatoSDKiOS'
  spec.version      = '1.7.2rc'
  spec.platform     = :ios
  spec.summary      = 'Ondato iOS SDK'
  spec.ios.deployment_target = '11.0'
  spec.homepage     = 'https://github.com/ondato/ondato-sdk-ios'
  spec.authors      = { 'Ondato' => 'info@ondato.com' }
  spec.source       = { :git => 'git@github.com:ondato/ondato-sdk-ios.git', :tag => spec.version }
  spec.ios.vendored_frameworks  = 'OndatoSDK.framework', 'FaceTecSDK.framework'
  spec.script_phase = { :name => 'Hello World', :script => 'bash "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/FaceTecSDK.framework/strip-unused-architectures-from-target.sh"
' }
end
