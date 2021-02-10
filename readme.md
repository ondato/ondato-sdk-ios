# Ondato iOS SDK

## Table of contents

* [Overview](#overview)
* [Getting started](#getting-started)
* [Handling callbacks](#handling-callbacks)
* [Customising SDK](#customising-sdk)


## Overview

This SDK provides a drop-in set of screens and tools for iOS applications to allow capturing of identity documents and face photos/live videos for the purpose of identity verification. The SDK offers a number of benefits to help you create the best onboarding/identity verification experience for your customers:

- Carefully designed UI to guide your customers through the entire photo/video-capturing process
- Modular design to help you seamlessly integrate the photo/video-capturing process into your application flow
- Advanced image quality detection technology to ensure the quality of the captured images meets the requirement of the Ondato identity verification process, guaranteeing the best success rate
- Direct image upload to the Ondato service, to simplify integration\*

\* Note: the SDK is only responsible for capturing and uploading photos/videos. You still need to access the [Ondato API](https://documenter.getpostman.com/view/6997242/S1TZwaZe?version=latest) to create and manage checks.

## Important note

We recommend you to lock your app to a portrait orientation.

## Getting started

- SDK supports iOS 10.0
- SDK supports Swift 5
- SDK Xcode Version 12.1

### 1. App permissions

The Ondato SDK makes use of the device Camera. You will be required to have the `NSCameraUsageDescription` key in your application's `Info.plist` file:
```
<key>NSCameraUsageDescription</key>
<string>Required for document and facial capture</string>
```
### 2. Installation 

### Manually
Download `OndatoSDK.framework` from latest sdk release. Add it to your project and select `Embed & Sign`

#### Add the following Run Script phases to your Build Phases

Remove unnecessary architectures, needed for release.
```
# skip if we run in debug
if [ "$CONFIGURATION" == "Debug" ]; then
echo "Skip frameworks cleaning in debug version"
exit 0
fi

APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

# This script loops through the frameworks embedded in the application and
# removes unused architectures.
find "$APP_PATH" -name '*.framework' -type d | while read -r FRAMEWORK
do
FRAMEWORK_EXECUTABLE_NAME=$(defaults read "$FRAMEWORK/Info.plist" CFBundleExecutable)
FRAMEWORK_EXECUTABLE_PATH="$FRAMEWORK/$FRAMEWORK_EXECUTABLE_NAME"
echo "Executable is $FRAMEWORK_EXECUTABLE_PATH"

EXTRACTED_ARCHS=()

for ARCH in $ARCHS
do
echo "Extracting $ARCH from $FRAMEWORK_EXECUTABLE_NAME"
lipo -extract "$ARCH" "$FRAMEWORK_EXECUTABLE_PATH" -o "$FRAMEWORK_EXECUTABLE_PATH-$ARCH"
EXTRACTED_ARCHS+=("$FRAMEWORK_EXECUTABLE_PATH-$ARCH")
done

echo "Merging extracted architectures: ${ARCHS}"
lipo -o "$FRAMEWORK_EXECUTABLE_PATH-merged" -create "${EXTRACTED_ARCHS[@]}"
rm "${EXTRACTED_ARCHS[@]}"

echo "Replacing original executable with thinned version"
rm "$FRAMEWORK_EXECUTABLE_PATH"
mv "$FRAMEWORK_EXECUTABLE_PATH-merged" "$FRAMEWORK_EXECUTABLE_PATH"

done
```

Codesign framework
```
pushd "${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app/Frameworks/OndatoSDK.framework/Frameworks"
for EACH in *.framework; do
    echo "-- signing ${EACH}"
    /usr/bin/codesign --force --deep --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --entitlements "${TARGET_TEMP_DIR}/${PRODUCT_NAME}.app.xcent" --timestamp=none $EACH
done
popd
```


### 3. Initializing and configuring the SDK 

#### Swift

```swift
// Use one of the provided initializers
OndatoService.shared.initialize(username: "username", password: "password")
OndatoService.shared.initialize(accessToken: "accessToken")
```

You can change the configuration by modifying the configuration property
```swift
var configuration: OndatoServiceConfiguration = OndatoService.shared.configuration
```

The configuration option has 3 properties
```swift
class OndatoServiceConfiguration {
	var appearance: OndatoAppearance
    var flowConfiguration: OndatoFlowConfiguration()
    var mode: OndatoEnvironment
}
```

`mode`  can be set to either test or live
```swift
enum OndatoEnvironment {
	case test
	case live
}
```

`flowConfiguration` holds several flow configuration options
```swift
class OndatoFlowConfiguration {
    var showSplashScreen: Bool // Should the splash screen be shown
    var showStartScreen: Bool // Should the start screen be shown
    var showConsentScreen: Bool // Should the consent screen be shown
    var showSelfieAndDocumentScreen // Should a selfie with document be requested when taking document pictures
    var showSuccessWindow: Bool // Should the success window be shown
    var ignoreLivenessErrors: Bool // Allows user to skip liveness check in case of failure
    var ignoreVerificationErrors: Bool // Allows user to skip document verification error result checks
    var recordProcess: Bool // Should the verification process be recorded
}
```

`appearance` holds the appearance configuration options
```swift
class OndatoAppearance {
    
    var logoImage: UIImage // Logo image that can be shown in the splash screen
    var progressColor: UIColor // background color of the `ProgressBarView` which guides the user through the flow
    var buttonColor: UIColor // background color of the primary action buttons
    var buttonTextColor: UIColor // background color of the primary action buttons text
    var errorColor: UIColor // background color of the error message background
    var errorTextColor: UIColor // background color of the error message text color
    var regularFontName: String // regular text font 
    var mediumFontName: String // medium text font
    var consentWindow: OndatoConsentAppearance() // appearance of header, body, acceptButton, declineButton in consent screen
```

### 4. Starting the flow

#### Swift


```swift
let sdk = OndatoService.shared.instantiateOndatoViewController()
sdk.modalPresentationStyle = .fullScreen
present(sdk, animated: true, completion: nil) 
```

## OndatoFlowDelegate

To handle result your view controller should implement `OndatoFlowDelegate` methods `onSuccess` and `onFailure` which contains `OndatoError` {`CANCELED`, `BAD_SERVER_RESPONSE`}:

```swift
OndatoService.shared.flowDelegate = T: OndatoFlowDelegate

func onSuccess(identificationId: String?) { // provided identificationId
    
}
func onFailure(identificationId: String?, error: OndatoError) { // provided identificationId
    
}
```

The delegate also has optional methods to replace Ondato windows/views with custom ones:

```swift
optional func viewControllerForStart(startPressed: @escaping () -> Void) -> UIViewController
optional func viewForSuccess(continue: @escaping () -> Void) -> UIView
optional func viewForLoading(progress: Float) -> UIView
```

### 4. Localization

Ondato iOS SDK already comes with out-of-the-box translations for the following locales:
- English (en) :uk:
- Lithuanian (lt) :lt:
- German (de) :de:

```swift
OndatoLocalizeHelper.language = OndatoLanguage.EN // OndatoLanguage.LT, OndatoLanguage.DE
```

To override liveness check strings, add a `.bundle` file which contains `Zoom.strings` table to your project and pass that bundle to the SDK
```swift
class OndatoService {
	var livenessLocalizationLT: Bundle?
	var livenessLocalizationEN: Bundle?
	var livenessLocalizationDE: Bundle?
}

if let bundleURL = Bundle.main.url(forResource: "LivenessLT", withExtension: "bundle"), let bundle = Bundle(url: bundleURL) {
    OndatoService.shared.zoomLocalizationBundleLT = bundle
}
```

To override Ondato strings, add a `.strings` file to the project directory and pass the URL to that file to the SDK
```swift
class OndatoService {
	var ondatoLocalizationFileLT: URL?
	var ondatoLocalizationFileEN: URL?
	var ondatoLocalizationFileDE: URL?
}

if let fileURL = Bundle.main.url(forResource: "OndatoLT", withExtension: "strings") {
    OndatoService.shared.ondatoLocalizationFileLT = fileURL
}
```