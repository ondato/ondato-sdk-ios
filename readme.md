# Ondato iOS SDK

## Table of contents

* [Overview](#overview)
* [Getting started](#getting-started)
* [Configuration](#configuration)
* [JSON Configuration](#json-configuration)
* [Starting the flow](#starting-the-flow)
* [Closing the flow](#closing-the-flow)
* [OndatoSDK delegate](#ondatoflowdelegate)
* [Customising SDK](#customising-sdk)
* [Localization](#localization)
* [Logs](#logs)
* [Old version V2](#old-version-v2)


## Overview

This SDK provides a drop-in set of screens and tools for iOS applications to allow capturing of identity documents and face photos/live videos for the purpose of identity verification. The SDK offers a number of benefits to help you create the best onboarding/identity verification experience for your customers:

- Carefully designed UI to guide your customers through the entire photo/video-capturing process
- Modular design to help you seamlessly integrate the photo/video-capturing process into your application flow
- Advanced image quality detection technology to ensure the quality of the captured images meets the requirement of the Ondato identity verification process, guaranteeing the best success rate
- Direct image upload to the Ondato service, to simplify integration\*

\* Note: the SDK is only responsible for capturing and uploading photos/videos. You still need to access the [Ondato API](https://ondato.atlassian.net/wiki/spaces/PUB/pages/2334359560/Customer+onboarding+KYC+mobile+SDK+integration) to create and manage checks.

## Important notes

- We recommend you to lock your app to a portrait orientation.
- **All SDK APIs must be called on the main thread.** This includes configuring the SDK (`setIdentityVerificationId`, `configuration`, `setWhitelabel`, localization and log settings), instantiating and presenting the SDK view controller, and calling `closeSDK()`. `OndatoFlowDelegate` methods are also called on the main thread.
- Only one SDK flow can run at a time. See [Starting the flow](#starting-the-flow).
- **Since 3.6.0, the bundled FaceTec SDK terminates the app when the Xcode debugger is attached.** This is a FaceTec security feature. See [Debugging your app](#debugging-your-app).

## Getting started

- SDK supports iOS 15.0 and up
- The SDK binaries are built with Xcode 26 (Swift 6.x). Simulator slices are arm64 only, so Intel-based simulators are not supported.

### 1. App permissions

The Ondato SDK makes use of the device Camera. You will be required to have the `NSCameraUsageDescription` key in your application's `Info.plist` file:
```
<key>NSCameraUsageDescription</key>
<string>Required for document and facial capture</string>
```

#### NFC

If you use `OndatoNFC`, your app also needs:

1. The `NFCReaderUsageDescription` key in `Info.plist`:
```
<key>NFCReaderUsageDescription</key>
<string>Required to read passport and ID card chips</string>
```
2. The ISO 7816 application identifier used by e-passports and eID cards in `Info.plist`:
```
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
</array>
```
3. The **Near Field Communication Tag Reading** capability, which adds the following to your app's entitlements:
```
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
</array>
```

### 2. Installation 

> [!IMPORTANT]
> Most, if not all configurations have automatic document capture (`OndatoAutocapture`) enabled for identity verification flows inside internal systems **by default**. If your flow uses automatic document capture and `OndatoAutocapture` is not integrated, you will get missing module errors.

### SPM

Add the `OndatoSDK` package product to your target.

The following package products need to be added separately, as per need:
* `OndatoAutocapture` - automatic document capture. **With SPM, `OndatoSDK` does not include `OndatoAutocapture`**, so add it if your flows use automatic document capture.
* `OndatoNFC` - NFC chip reading
* `OndatoScreenRecorder` - screen recording

### CocoaPods

There are two ways to integrate the SDK with CocoaPods:
1. `OndatoSDK`, which already contains `OndatoAutocapture`:
```
pod 'OndatoSDK'
```
2. `OndatoSDK-Core`, which does not contain `OndatoAutocapture`. Use it if your flows do not use automatic document capture, or add `OndatoAutocapture` alongside it:
```
pod 'OndatoSDK-Core'
pod 'OndatoAutocapture'
```

**You do not need to add either `OndatoSDK-Core` or `OndatoAutocapture` if `OndatoSDK` is used.**

`OndatoNFC` and `OndatoScreenRecorder` need to be added separately:
* If you use NFC functionality provided by `Ondato` add
```
pod 'OndatoNFC'
```
to your podfile

* If you use Screen Recorder functionality provided by `Ondato` add
```
pod 'OndatoScreenRecorder'
```
to your podfile

### Debugging your app

Starting with **3.6.0**, the SDK bundles FaceTec SDK 9.7.137. The production FaceTec framework terminates the app when a debugger (e.g. Xcode) is attached. Release builds, TestFlight and launching the app without Xcode are not affected.

To debug the face capture step, replace the FaceTec framework with FaceTec's development framework in **Debug** builds:

1. Download [`FaceTecSDKForDevelopment-9.7.137.zip`](https://github.com/ondato/ondato-sdk-ios/releases/download/3.6.2/FaceTecSDKForDevelopment-9.7.137.zip) (works with SDK 3.6.0, 3.6.1 and 3.6.2), unzip it and place `FaceTecSDKForDevelopment.xcframework` in the same folder as your `.xcodeproj`.
   * Do **not** add it to your target or link it — the script below handles it.
2. In your app target, go to **Build Phases**, add **New Run Script Phase** and move it to the **very end** (after `Embed Frameworks` / `[CP] Embed Pods Frameworks`). Untick **Based on dependency analysis** and paste:
```sh
# Ondato SDK: use the FaceTec development framework for Debug device builds,
# so the app can be debugged. Release builds and archives keep the production framework.
set -euo pipefail

FACETEC_DEV_XCFRAMEWORK="${PROJECT_DIR}/FaceTecSDKForDevelopment.xcframework"

if [ "${CONFIGURATION}" != "Debug" ] || [ "${PLATFORM_NAME}" != "iphoneos" ] || [ "${ACTION}" = "install" ]; then
    echo "FaceTecSDK: skipping development framework swap"
    exit 0
fi

SLICE="${FACETEC_DEV_XCFRAMEWORK}/ios-arm64/FaceTecSDK.framework"
EMBEDDED_FRAMEWORK="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FaceTecSDK.framework"

[ -d "${SLICE}" ] || { echo "error: ${SLICE} not found"; exit 1; }
[ -d "${EMBEDDED_FRAMEWORK}" ] || { echo "error: FaceTecSDK.framework is not embedded yet - move this phase to the end"; exit 1; }

rsync -a --delete "${SLICE}/" "${EMBEDDED_FRAMEWORK}/"
codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:-${CODE_SIGN_IDENTITY:--}}" \
    --preserve-metadata=identifier,entitlements,flags "${EMBEDDED_FRAMEWORK}"

echo "FaceTecSDK: framework replaced with FaceTecSDKForDevelopment"
```
3. In your app target's **Build Settings**, set **User Script Sandboxing** (`ENABLE_USER_SCRIPT_SANDBOXING`) to **No**.
4. Clean and build for a device. The build log should contain `FaceTecSDK: framework replaced with FaceTecSDKForDevelopment`.

> [!NOTE]
> If you use CocoaPods, check the phase is still the last one after `pod install`.

> [!WARNING]
> Never ship the development framework. The script only runs for the `Debug` configuration on devices and is skipped when archiving.

If you don't need to debug the face capture step, you can instead disable **Debug executable** in your scheme (**Edit Scheme → Run → Info**), or launch the app from the device home screen.

### 3. Initializing and configuring the SDK 

#### Swift

```swift
// Use provided initializer
Ondato.sdk.setIdentityVerificationId("<Verification Id>")
```
## Configuration
You can change the configuration by modifying the configuration property
```swift
var configuration: OndatoServiceConfiguration = Ondato.sdk.configuration
```

The configuration option has 3 properties
```swift
class OndatoServiceConfiguration {
    var resources: OndatoResources()
    var flowConfiguration: OndatoFlowConfiguration()
    var mode: OndatoEnvironment
}
```

`mode` can be set to either test or live (default is `test`)
```swift
enum OndatoEnvironment {
    case test
    case live
}
```

`flowConfiguration` holds several flow configuration options
```swift
class OndatoFlowConfiguration {
    var skipRegistrationIfDriverLicense: Bool = false
    var showTranslationKeys: Bool = false
    var showNoInternetConnectionView: Bool = true
    var disablePdfFileUpload: Bool = false
    var switchPrimaryButtons: Bool = false
    var showComplianceTextDocSelect: Bool = false
    var enableAgreeButtonAfterScrolling: Bool = true
    var termsAgreementButtonTimeout: Double = 0
}
```

* `enableAgreeButtonAfterScrolling` - the consent screen's agree button stays disabled until the user has scrolled through the terms. A tooltip explains why the button is disabled.
* `termsAgreementButtonTimeout` - time in seconds before the consent screen's agree button becomes enabled. `0` means no timeout.

If both are set, the agree button is enabled only after the user has scrolled to the end **and** the timeout has passed.

To provide custom resources configure corresponding property of `OndatoResources`
```swift
class OndatoResources {
    var animations: OndatoAnimations
    var fonts: OndatoFonts
    var images: OndatoImages
}
```
For custom `animations`:
```swift
class OndatoAnimations {
    var waitingScreenAnimationFilePath: String?
}
```

For custom `fonts` (`Note`: if you provide custom font via `OndatoResources.fonts`, JSON configurations related to `fontSize`, `fontWeight` are ignored):
```swift
class OndatoFonts {
    var heading1: UIFont?
    var heading2: UIFont?
    var normal: UIFont?
    var list: UIFont?
    var button: UIFont?
}
```

For custom 'images':
```swift
class OndatoImages {
    public var documentCaptureInstructions: [OndatoDocumentType: [OndatoDocumentPart: UIImage]]?
    public var additionalDocumentCaptureInstructions: [OndatoAdditionalDocumentType: UIImage]?
    public var faceCaptureInstructions: [OndatoFaceCaptureType: UIImage]?
    public var nfcCaptureInstructions: [OndatoDocumentType: [OndatoNFCCaptureComponent: UIImage]]?
    
    public var warning: UIImage?
    public var backButton: UIImage?
    public var closeButton: UIImage?
    public var documentImages: OndatoDocumentImages
}
```
`note` Ondato document types and parts listed here: [Ondato document types](#ondato-document-types)

## JSON configuration
To configure UI provide a JSON object via public `setWhitelabel(_ data: Data) throws` method. Ondato SDK supports the following values inside the whitelabel JSON file (A more detailed customization document can be found [here](https://ondato.atlassian.net/wiki/spaces/PUB/pages/3092938754/Mobile+SDK+Whitelabeling)
):

```json
{
  "brand": {
    "colors": {
      "primaryColor": "#64749c", // Primary brand color - used in illustration and primary button
      "textColor": "#000000", // Text color for content
      "backgroundColor": "#FFFFFF", // Base background color for screens
      "danger": "#D04555", // Color for error states and messages
      "warning": "#F9BB42", // Color for warning elements
      "success": "#28865A", // Color for success elements
      "grey100": "", // Currently not used
      "grey200": "#F2F5F8", //Button Disabled state background, Text input readonly background
      "grey300": "", // Currently not used
      "grey400": "#BEC6D0", //Color for input element border color, also used in Text input
      "grey500": "#96A0AE", //Color for "Select card" icon, Proof of Adress upload element border, Text input disabled state text color
      "grey600": "#6D7580", //Color for Proof of Adress icon color, Text input Active state border
      "grey700": "#282B2F", //Color for feedback bar background color
      "certificateColor": "#6D7580", //Color for Document selection certificate icons
      //Android specific
      "statusBarColor": "#64749c" //Default: brand.colors.primaryColor
    },
    "baseComponentStyling": {
      "cornerRadius": 6, //Used for all input components (Buttons, Text inputs and other elements)
      "buttonPadding": { "top": 14, "bottom": 14, "left": 24, "right": 24 }, //Used for Primary and Secondary button paddings
      "borderWidth": 1.0 //Used for Secondary button, Text input, Selection button border
    },
    // IMPORTANT! For iOS the font size, weight is taken from Font file.
    "typography": {
      "heading1": { "fontSize": 24, "fontWeight": 500, "lineHeight": 32, "alignment": "center" },
      "heading2": { "fontSize": 16, "fontWeight": 500, "lineHeight": 18, "alignment": "center" },
      "body": { "fontSize": 16, "fontWeight": 400, "lineHeight": 18, "alignment": "center" },
      "list": { "fontSize": 16, "fontWeight": 400, "lineHeight": 18 },
      "inputLabel": { "fontSize": 16, "fontWeight": 400, "lineHeight": 18 },
      "button": { "fontSize": 16, "fontWeight": 500, "lineHeight": 18 }
    }
  },
  // COMPONENTS
  "buttons": {
    "primary": {
      "base": {
        "cornerRadius": 6, //Default: brand.baseComponentStyling.cornerRadius
        "padding": { "top": 14, "bottom": 14, "left": 24, "right": 24 }, //Default: brand.baseComponentStyling.buttonPadding
        "fontSize": 16, //Type: Number  |   Default: typography.button.fontSize
        "fontWeight": 500, //Type: Number  |   Default: typography.button.fontWeight
        "lineHeight": 18, //Type: Number  |   Default: typography.button.lineHeight
        "showIcon": false //Type: Boolean
      },
      "normal": {
        "textColor": "#000", //Type: String  |  Default: brand.colors.textColor
        "backgroundColor": "#64749c", //Type: String  |  Default: brand.colors.primaryColor
        "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
        "borderColor": "#64749c", //Type: String  |  Default: colors.primaryColor
        "iconColor": "#000", //Type: String  |  Default: colors.textColor
        "opacity": 1.0 //Type: Float
      },
      "pressed": {
        "textColor": "#000", //Type: String  |  Default: brand.colors.textColor
        "backgroundColor": "#64749c", //Type: String  |  Default: brand.colors.primaryColor
        "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
        "borderColor": "#64749c", //Type: String  |  Default: colors.primaryColor
        "iconColor": "#000", //Type: String  |  Default: colors.textColor
        "opacity": 0.8 //Type: Float
      },
      "disabled": {
        "textColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
        "backgroundColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
        "borderWidth": 1, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
        "borderColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
        "iconColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
        "opacity": 1.0 //Type: Float
      }
    },
    "secondary": {
      "base": {
        "cornerRadius": 6, //Default: brand.baseComponentStyling.cornerRadius
        "padding": { "top": 14, "bottom": 14, "left": 24, "right": 24 }, //Default: brand.baseComponentStyling.buttonPadding
        "fontSize": 16, //Type: Number  |   Default: typography.button.fontSize
        "fontWeight": 500, //Type: Number  |   Default: typography.button.fontWeight
        "lineHeight": 18, //Type: Number  |   Default: typography.button.lineHeight
        "showIcon": false //Type: Boolean
      },
      "normal": {
        "textColor": "#000", //Type: String  |  Default: brand.colors.textColor
        "backgroundColor": "#FFFFFF", //Default -  colors.backgroundColor
        "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
        "borderColor": "#BEC6D0", //Type: String  |  Default: brand.colors.grey400
        "iconColor": "#000", //Type: String  |  Default: brand.colors.textColor
        "opacity": 1.0 //Type: Float
      },
      "pressed": {
        "textColor": "#000", //Type: String  |  Default: brand.colors.textColor
        "backgroundColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
        "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
        "borderColor": "#6D7580", //Type: String  |  Default: brand.colors.grey600
        "iconColor": "#000", //Type: String  |  Default: brand.colors.textColor
        "opacity": 1.0 //Type: Float
      },
      "disabled": {
        "textColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
        "backgroundColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
        "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
        "borderColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
        "iconColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
        "opacity": 1.0 //Type: Float
      }
    },
    "iconButton": {  // delete document button
        "base": {
                "cornerRadius": 10  //Default: brand.baseComponentStyling.cornerRadius
        },
        "normal": {
                "iconColor": "#000000",        //Type: String  |  Default: brand.colors.textColor
                "backgroundColor": "#FFFFFF",  //Type: String  |  Default: brand.colors.backgroundColor
                "borderColor": "#FF66FF",      //Type: String  |  Default: brand.colors.backgroundColor
                "borderWidth": 0               //Type: Float
        },
        "pressed": {
                "iconColor": "#000000",        //Type: String  |  Default: brand.colors.textColor
                "backgroundColor": "#F2F5F8",  //Type: String  |  Default: brand.colors.grey200
                "borderColor": "#F266F8",      //Type: String  |  Default: brand.colors.grey200
                "borderWidth": 0               //Type: Float
        },
        "disabled": {
                "iconColor": "#96A0AE",        //Type: String  |  Default: brand.colors.grey500
                "backgroundColor": "#F2F5F8",  //Type: String  |  Default: brand.colors.grey200
                "borderColor": "#F266F8",      //Type: String  |  Default: brand.colors.grey200
                "borderWidth": 0               //Type: Float
        }
    },
    "navigationButton": {
      "base": {
        "cornerRadius": 6     //Default: brand.baseComponentStyling.cornerRadius
      },
      "normal": {
        "iconColor": "#000000",       //Type: String  |  Default: brand.colors.textColor
        "backgroundColor": "#FFFFFF", //Type: String  |  Default: brand.colors.backgroundColor
        "borderColor": "#FFFFFF",     //Type: String  |  Default: brand.colors.backgroundColor
        "borderWidth": 0              //Type: Float
      },
      "pressed": {
        "iconColor": "#000000",        //Type: String  |  Default: brand.colors.textColor
        "backgroundColor": "#F2F5F8",  //Type: String  |  Default: brand.colors.grey200
        "borderColor": "#F2F5F8",      //Type: String  |  Default: brand.colors.grey200
        "borderWidth": 0               //Type: Float
      },
      "disabled": {
        "iconColor": "#96A0AE",        //Type: String  |  Default: brand.colors.grey500
        "backgroundColor": "#F2F5F8",  //Type: String  |  Default: brand.colors.grey200
        "borderColor": "#F2F5F8",      //Type: String  |  Default: brand.colors.grey200
        "borderWidth": 0               //Type: Float
      }
    }
  },
  "textInput": {
    "base": {
      "cornerRadius": 6,   //Type: Float  |   Default: brand.baseComponentStyling.cornerRadius
      "padding": { "top": 14, "bottom": 14, "left": 24, "right": 24 },  //Default: brand.baseComponentStyling.buttonPadding
      "fontSize": 16,     //Type: Number  |   Default: typography.body.fontSize
      "fontWeight": 500,  //Type: Number  |   Default: typography.body.fontWeight
      "lineHeight": 22    //Type: Number  |   Default: typography.body.lineHeight
    },
    "normal": {
      "textColor": "#000000",        //Type: String  |  Default: brand.colors.textColor
      "backgroundColor": "#FFFFFF",  //Type: String  |   Default: brand.colors.backgroundColor
      "borderColor": "#96A0AE",      //Type: String  |  Default: brand.colors.grey500
      "borderWidth": 1.0             //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
    },
    "focused": {
      "textColor": "#000000", //Type: String  |  Default: brand.colors.textColor
      "backgroundColor": "#FFFFFF", //Type: String  |   Default: brand.colors.backgroundColor
      "borderColor": "#6D7580", //Type: String  |  Default: brand.colors.grey600
      "borderWidth": 1.0 //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
    },
    "disabled": {
      "textColor": "#BEC6D0", //Type: String  |  Default: brand.colors.grey400
      "backgroundColor": "#FFFFFF", //Type: String  |  Default: brand.colors.backgroundColor
      "borderColor": "#BEC6D0", //Type: String  |  Default: brand.colors.grey400
      "borderWidth": 1.0 //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
    },
    "readOnly": {
      "textColor": "#6D7580", //Type: String  |  Default: brand.colors.grey600
      "backgroundColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
      "borderColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
      "borderWidth": 1.0 //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
    },
    "error": {
      "textColor": "#D04555", //Type: String  |  Default: brand.colors.danger
      "borderColor": "#D04555", //Type: String  |  Default: brand.colors.danger
      "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
      "backgroundColor": "#FFFFFF" //Type: String  |   Default: brand.colors.backgroundColor
    }
  },
  "selectionCard": {
    "base": {
      "cornerRadius": 6, //Type: Float  |   Default: brand.baseComponentStyling.cornerRadius
      "fontSize": 16, //Type: Number  |   Default: typography.body.fontSize
      "fontWeight": 500, //Type: Number  |   Default: typography.body.fontWeight
      "lineHeight": 22 //Type: Number  |   Default: typography.body.lineHeight
    },
    "normal": {
      "textColor": "#000000", //Type: String  |  Default: brand.colors.textColor
      "backgroundColor": "#FFFFFF", //Type: String  |  Default: brand.colors.backgroundColor
      "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
      "borderColor": "#BEC6D0", //Type: String  |  Default: brand.colors.grey400
      "leftIconColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
      "rightIconColor": "#000000" //Type: String  |  Default: brand.colors.textColor
    },
    "pressed": {
      "textColor": "#000000", //Type: String  |  Default: brand.colors.textColor
      "backgroundColor": "#F2F5F8", //Type: String  |   Default: brand.colors.grey200
      "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
      "borderColor": "#BEC6D0", //Type: String  |  Default: brand.colors.grey400
      "leftIconColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
      "rightIconColor": "#000000" //Type: String  |  Default: brand.colors.textColor
    },
    "disabled": {
      "textColor": "#BEC6D0", //Type: String  |  Default: brand.colors.grey400
      "backgroundColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
      "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
      "borderColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
      "leftIconColor": "#BEC6D0", //Type: String  |  Default: brand.colors.grey400
      "rightIconColor": "#BEC6D0" //Type: String  |  Default: brand.colors.grey400
    }
  },
  "activityIndicator": {
    "color": "#64749c" //Type: String  |  Default: brand.colors.primaryColor
  },
  "faceScanUI": {
    "frame": {
      "borderColor": "#282B2F", //Type: String  |  Default: brand.colors.grey700
      "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
      "progressColor": "#64749c" //Type: String  |  Default: brand.colors.primaryColor
    },
    "feedbackBar": {
      "backgroundColor": "#282B2F", //Type: String  |  Default: brand.colors.grey700
      "textColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
      "cornerRadius": 6 //Type: Float  |   Default: brand.baseComponentStyling.cornerRadius
    }
  },
  // Used for customizing the proof-of-address document upload screen
  "documentUploadConfiguration": {
    "borderColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
    "borderWidth": 1.0, //Type: Float   |  Default: brand.baseComponentStyling.borderWidth
    "borderRadius": 6.0, //Type: Float  |   Default: brand.baseComponentStyling.cornerRadius
    "fileDescriptionTextColor": "#96A0AE", //Type: String  |  Default: brand.colors.grey500
    "fileIconColor": "#6D7580", //Type: String  |  Default: brand.colors.grey600
    "uploadAreaBackgroundOpacity": 0,
    "uploadAreaBackgroundColor": "#FFFFFF" //Type: String  |  Default: brand.colors.backgroundColor
  },
  "cameraScreenConfiguration": {
    "backgroundColor": "#282B2F", //Type: String  |  Default: brand.colors.grey700
    "opacity": 0.5, // Type: Float
    "cornerRadius": 6.0 //Type: Float  |   Default: brand.baseComponentStyling.cornerRadius
  },
  // Used for all pop-ups, including the document and face capture guideline pop-ups
  "modalConfiguration": {
    "backgroundColor": "#FFFFFF", // Type: String | Default: brand.colors.background
    "textColor": "#000000", // Type: String | Default: brand.colors.text
    "cornerRadius": 6.0, // Type: Float
    "backdropColor": "#282B2F", // Type: String | Default: brand.colors.grey700
    "backdropOpacity": 0.5 // Type: Float
  },
  // Used for the consent screen tooltip explaining why the agree button is disabled
  "tooltip": {
    "textColor": "#F2F5F8", //Type: String  |  Default: brand.colors.grey200
    "backgroundColor": "#282B2F", //Type: String  |  Default: brand.colors.grey700
    "cornerRadius": 6, //Type: Float  |   Default: brand.baseComponentStyling.cornerRadius
    "fontSize": 16, //Type: Number  |   Default: typography.body.fontSize
    "fontWeight": 400, //Type: Number  |   Default: typography.body.fontWeight
    "lineHeight": 18 //Type: Number  |   Default: typography.body.lineHeight
  }
}
```
Note that all these values are optional - if any of the parameters mentioned in the whitelabel JSON file are not included inside it, then the SDK will use the default values for these UI components. The comments in the example above are for documentation only; JSON passed to `setWhitelabel` must not contain comments.

## Starting the flow


To instantiate sdk ViewController you should call `instantiateOndatoViewController` as in example below. Present created ViewController in your application.

```swift
let sdk = Ondato.sdk.instantiateOndatoViewController()
sdk.modalPresentationStyle = .fullScreen
present(sdk, animated: true, completion: nil) 
```

The verification session starts when the SDK view controller is first shown, not when it is instantiated.

Only one SDK flow can run at a time. If you present another SDK view controller while a flow is already running, the new one is dismissed immediately and the running flow continues. To start a new flow, wait for the current one to finish (see [OndatoFlowDelegate](#ondatoflowdelegate)) or close it with `closeSDK()`.

## Closing the flow

To close a running flow from your app, call:

```swift
Ondato.sdk.closeSDK()
```

This dismisses the SDK screens and calls `flowDidFail(identificationId:error:)` with the `aborted` error.

## OndatoFlowDelegate

To handle the result, set `Ondato.sdk.delegate` and implement the required `OndatoFlowDelegate` methods `flowDidSucceed` and `flowDidFail`. The failure method contains an `OndatoServiceError`. Both methods are called on the main thread.

```swift
Ondato.sdk.delegate = self // an object conforming to OndatoFlowDelegate

func flowDidSucceed(identificationId: String?) { // provided identificationId
    
}
func flowDidFail(identificationId: String?, error: OndatoServiceError) { // provided identificationId
    
}
```

`delegate` is a `weak` property, so keep a strong reference to your delegate object for the duration of the flow.
## Customising SDK
You might want to replace some default OndatoSDK screens with your custom ViewControllers. To do that implement OndatoFlowDelegate protocol functions that you need. These functions have to return specified types of view controllers. Your custom view controllers should subclass these types [provided below](#provided-classes-for-custom-viewcontrollers)

The OndatoFlowDelegate also has optional methods to replace Ondato windows/views with custom ones:

```swift
    @objc optional func viewControllerForLoading() -> OndatoLoadingViewControllerType?
    @objc optional func viewForScanProcessing() -> UIView?
    @objc optional func viewForLoading() -> UIView?
    @objc optional func documentCapture(instructionsViewControllerFor documentType: OndatoDocumentType, documentPart: OndatoDocumentPart) -> OndatoInstructionViewControllerType?
    @objc optional func additionalDocumentCapture(instructionsViewControllerFor additionalDocumentType: OndatoAdditionalDocumentType) -> OndatoInstructionViewControllerType?
    @objc optional func nfcCapture(instructionsViewControllerFor documentType: OndatoDocumentType, documentComponent: OndatoNFCCaptureComponent) -> OndatoInstructionViewControllerType?
    @objc optional func faceCapture(instructionsViewControllerFor faceCaptureType: OndatoFaceCaptureType) -> OndatoInstructionViewControllerType?
    
    @objc optional func completionViewController() -> OndatoCompletionViewControllerType?
    
    @objc optional func chooseDocumentViewController(documentTypes: OndatoDocumentTypes) -> OndatoChooseDocumentViewControllerType?
```
## provided classes for custom ViewControllers

```swift
class OndatoLoadingViewControllerType: UIViewController {
    var closeButtonPressed: (() -> Void)?
}

class OndatoCompletionViewControllerType: UIViewController {
    var closeButtonPressed: (() -> Void)?
    var restartButtonPressed: (() -> Void)?
}

class OndatoInstructionViewControllerType: UIViewController {
    var closeButtonPressed: (() -> Void)?
    var backButtonPressed: (() -> Void)?
    var continuePressed: (() -> Void)?
}

class OndatoChooseDocumentViewControllerType: UIViewController {
    var closeButtonPressed: (() -> Void)?
    var backButtonPressed: (() -> Void)?
    var documentSelected: ((OndatoDocumentType) -> Void)?
}
```
Depending on your account configuration settings you will use some of document types and parts listed here:
## Ondato document types
```swift
    enum OndatoDocumentType: {
        case passport 
        case idCard 
        case drivingLicence 
        case residencePermit 
        case internalPassport 
        case socialIdentityCard 
}
```
```swift
    enum OndatoDocumentPart: {
        case front 
        case back 
        case frontCover 
        case dataPage 
        case blankPages 
}
```
```swift
    enum OndatoAdditionalDocumentType: {
        case proofOfAddress
        case selfieWithDocument
}
```
```swift
     enum OndatoFaceCaptureType: {
        case activeLiveness 
        case passiveLiveness 
        case faceAuth 
}
```
For example, if you want to implement your custom view controller for instruction screen (screen before actual capturing):
```swift
        func documentCapture(instructionsViewControllerFor documentType: OndatoDocumentType, documentPart: OndatoDocumentPart) -> OndatoInstructionViewControllerType? {
         // OndatoSDK will pass document type and document part (for example documentType: .idCard, documentPart: .front), according to those parameters you should return view controller for idCard front side instructions. Same goes for other types of documents that you need in your flow
        }
```
`Note` - dont forget to call `OndatoInstructionViewControllerType.continuePressed` closure in your button action handler
```swift
class CustomInstructionsViewController: OndatoInstructionViewControllerType {
        @IBAction func continueButtonPressed(_ sender: Any) {
            continuePressed?()
        }
    }
```
## Localization

Ondato iOS SDK comes with out-of-the-box translations for the following languages:

| Language | `OndatoSupportedLanguage` | Language code | Example translation file |
|---|---|---|---|
| Albanian | `.SQ` | `sq` | `ondato_sq-AL.strings` |
| Bulgarian | `.BG` | `bg` | `ondato_bg-BG.strings` |
| Catalan | `.CA` | `ca` | `ondato_ca-ES.strings` |
| Chinese (Simplified) | `.CN` | `cn` | `ondato_zh-CN.strings` |
| Czech | `.CS` | `cs` | `ondato_cs-CZ.strings` |
| Danish | `.DK` | `dk` | `ondato_da-DK.strings` |
| Dutch | `.NL` | `nl` | `ondato_nl-NL.strings` |
| English | `.EN` | `en` | `ondato_en-GB.strings` |
| Estonian | `.ET` | `et` | `ondato_et-EE.strings` |
| Finnish | `.FI` | `fi` | `ondato_fi-FI.strings` |
| French | `.FR` | `fr` | `ondato_fr-FR.strings` |
| German | `.DE` | `de` | `ondato_de-DE.strings` |
| Greek | `.EL` | `el` | `ondato_el-GR.strings` |
| Hungarian | `.HU` | `hu` | `ondato_hu-HU.strings` |
| Italian | `.IT` | `it` | `ondato_it-IT.strings` |
| Korean | `.KR` | `kr` | `ondato_ko-KR.strings` |
| Latvian | `.LV` | `lv` | `ondato_lv-LV.strings` |
| Lithuanian | `.LT` | `lt` | `ondato_lt-LT.strings` |
| Polish | `.PL` | `pl` | `ondato_pl-PL.strings` |
| Portuguese (Brazil) | `.PT` | `pt` | `ondato_pt-BR.strings` |
| Romanian | `.RO` | `ro` | `ondato_ro-RO.strings` |
| Russian | `.RU` | `ru` | `ondato_ru-RU.strings` |
| Slovak | `.SK` | `sk` | `ondato_sk-SK.strings` |
| Spanish | `.ES` | `es` | `ondato_es-ES.strings` |
| Swedish | `.SV` | `sv` | `ondato_sv-SE.strings` |
| Thai | `.TH` | `th` | `ondato_th-TH.strings` |
| Ukrainian | `.UA` | `uk` | `ondato_uk-UA.strings` |
| Vietnamese | `.VI` | `vi` | `ondato_vi-VN.strings` |

`Note`: the language code is what `setLanguage(code:)`, `setLocalizationBundle(_:languageCode:)` and `setLocalization(table:languageCode:)` expect, and what `OndatoLocalizeHelper.shared.language` returns. For some languages it differs from the ISO code, e.g. Ukrainian is `uk` (`.UA`), Chinese is `cn`, Danish is `dk` and Korean is `kr`.

To set the SDK language, use either the enum or a language code:

```swift
OndatoLocalizeHelper.shared.setLangauge(.EN)
// or
OndatoLocalizeHelper.shared.setLanguage(code: "en")
```

The currently selected language can be read from `OndatoLocalizeHelper.shared.language`.

To override any localization strings, pass a `Bundle` and a table name within that bundle for a `.strings` file that contains the necessary translations. Example translation files with all the keys for every supported language are provided in the [Localizations](Localizations) folder.
```swift
let bundle = Bundle.main
let localizationBundle = OndatoLocalizationBundle(bundle: bundle, tableName: "Localizable")
OndatoLocalizeHelper.shared.setLocalizationBundle(localizationBundle, for: .LT)
// or
OndatoLocalizeHelper.shared.setLocalizationBundle(localizationBundle, languageCode: "lt")
```

You can also override strings with a dictionary:
```swift
OndatoLocalizeHelper.shared.setLocalization(table: ["<key>": "<translation>"], for: .LT)
// or
OndatoLocalizeHelper.shared.setLocalization(table: ["<key>": "<translation>"], languageCode: "lt")
```
## Logs
There are three levels of logs, which can be set by calling 
```swift 
OndatoLog.shared.setLogLevel(level: OndatoLogLevel)
```
```swift
enum OndatoLogLevel {
    case info
    case debug
    case error
}
```
Default log level is info.
* info: log level gives info about: OndatoSDK build version; Device os, brand, model; Session ID;
`OndatoFlowConfiguration` settings;
* debug: info + debug levels. 
Debug log level gives info about: Api requests and responses, flow steps, device state (moved to background)
* error: info + debug + error.
Error log level gives info about screen recording problems, unsuccessful api calls and other errors
### To get log strings:
```swift
OndatoLog.shared.logs // returns [String]
```

## Available failure statuses

| Status name                 | Status message                                                    |
|-----------------------------|-------------------------------------------------------------------|
| badFlowSetup                | “The setup has no steps or is misconfigured“                      |
| consentDeclined             | “User has declined consent”                                       |
| failureExit                 | “Process failed by rejection, cancelled by user”                  |
| invalidID                   | “Invalid session ID or access token provided”                     |
| unauthorized                | “Session ID does not have access to this resource”                |
| internalServerError         | “Internal server error”                                           |
| aborted                     | “User has aborted the process”                                    |
| nfcNotSupported             | “NFC is not supported in NFC mandatory or optional mode”          |
| recorderFailure             | “Screen recorder cannot be started on the device”                 |
| tooManyAttempts             | “Number of max attempts reached when trying to authenticate face” |
| noAvailableDocumentTypes    | “The setup has no available document types”                       |
| generic                     | “Unknown error”                                                   |

---
## Old version V2
Link to deprecated version of SDK [README](https://github.com/ondato/ondato-sdk-ios/blob/release/2.6.9/readme.md)
