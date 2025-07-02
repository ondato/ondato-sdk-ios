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

\* Note: the SDK is only responsible for capturing and uploading photos/videos. You still need to access the [Ondato API](https://ondato.atlassian.net/wiki/spaces/PUB/pages/2334359560/Customer+onboarding+KYC+mobile+SDK+integration) to create and manage checks.

## Important note

We recommend you to lock your app to a portrait orientation.

## Getting started

- SDK supports iOS 12.0 and up

### 1. App permissions

The Ondato SDK makes use of the device Camera. You will be required to have the `NSCameraUsageDescription` key in your application's `Info.plist` file:
```
<key>NSCameraUsageDescription</key>
<string>Required for document and facial capture</string>
```

### 2. Installation 

### SPM

Add `OndatoSDK` package product to your target.

`Note`: since v2.6.0 `OndatoNFC` and `OndatoScreenRecorder` need to be added separately. Add each package product as per need to your target.

### CocoaPods

```
pod 'OndatoSDK'
```

`Note`: As off v2.6.0 `OndatoNFC` and `OndatoScreenRecorder` need to be added separately:
* If you use NFC functionality provided by `Ondato` add
```
pod 'OndatoNFC'
```
to your podfile

* If you use Screen Recorder functionality provided by `Ondato` add
```
pod `OndatoScreenRecorder`
```
to your podfile

### 3. Initializing and configuring the SDK 

#### Swift

```swift
// Use provided initializer
Ondato.sdk.setIdentityVerificationId("<Verification Id>")
```

You can change the configuration by modifying the configuration property
```swift
var configuration: OndatoServiceConfiguration = Ondato.sdk.configuration
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
    var showStartScreen: Bool // Should the start screen be shown
    var showSuccessWindow: Bool // Should the success window be shown
    var removeSelfieFrame: Bool // whether to show or to remove the selfie frame in passive liveness check mode
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
    var textColor: UIColor // Text color
    var backgroundColor: UIColor //  background color in certain situations
    var consentWindow: OndatoConsentAppearance() // appearance of header, body, acceptButton, declineButton in consent screen
```
### 4. Starting the flow

#### Swift

To instantiate sdk ViewController you should call `instantiateOndatoViewController` as in example below. Present created ViewController in your application.

```swift
let sdk = Ondato.sdk.instantiateOndatoViewController()
sdk.modalPresentationStyle = .fullScreen
present(sdk, animated: true, completion: nil) 
```

## OndatoFlowDelegate

To handle result your view controller should implement `OndatoFlowDelegate` methods `onSuccess` and `onFailure` which contains `OndatoError` {`CANCELED`, `BAD_SERVER_RESPONSE`}:

```swift
Ondato.sdk.delegate = T: OndatoFlowDelegate

func flowDidSucceed(identificationId: String?) { // provided identificationId
    
}
func flowDidFail(identificationId: String?, error: OndatoServiceError) { // provided identificationId
    
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
- Bulgarian (bg) 🇧🇬
- German (de) 🇩🇪
- Greek (el) 🇬🇷
- English (en) 🇬🇧
- Spanish (es) 🇪🇸
- Estonian (et) 🇪🇪
- French (fr) 🇫🇷
- Italian (it) 🇮🇹
- Lithuanian (lt) 🇱🇹
- Latvian (lv) 🇱🇻
- Dutch (nl) 🇳🇱
- Romanian (ro)
- Russian (ru) 🇷🇺
- Albanian (sq) 🇦🇱

```swift
OndatoLocalizeHelper.shared.language = OndatoLanguage.EN // .DE, .ET, .EN, .LT, .LV, .RU, .SQ, .BG, .ES, .FR, .EL, .IT, .NL, .RO
```

To override any localization strings, please pass a `Bundle` and a tableName within that bundle for a `.strings` file that contains the necessary translations. A example translation file with all the keys is provided next to the Framework files
```swift
let bundle = Bundle.main
/// let bundle = Bundle.main.path(forResource: "lt", ofType: "bundle")
let localizationBundle = OndatoLocalizationBundle(bundle: budle, tableName: "Localizable")
/// let localizationBundle = OndatoLocalizationBundle.bundle(with: bundle, tableName: "Localizable")
OndatoLocalizeHelper.shared.setLocalizationBundle(bundle, for: .LT)
```
