# Ultra iOS SDK

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [Example](#example)
- [Navigation](#navigation)

----------------------

## Overview

Ultra iOS SDK supports user registration with identity proofing, and user face login, using Cryptonets fully homomorphically encrypted (FHE) for privacy and security.

Features:
- Biometric face registration and authentication compliant with IEEE 2410-2021 Standard for Biometric Privacy, and exempt from GDPR, CCPA, BIPA, and HIPPA privacy law obligations.
- Face registration and 1:n face login in 200ms constant time
- Biometric age estimation with full privacy, on-device in 20ms
- Unlimited users (unlimited gallery size)
- Fair, accurate and unbiased
- Operates online or offline, using local cache for hyper-scalability

Builds
- Verified Identity
- Identity Assurance
- Authentication Assurance
- Federation Assurance
- Face Login
- Face Unlock
- Biometric Access Control
- Account Recovery
- Face CAPTCHA

----------------------

## Installation

### Requirements
- Xcode 14.1 or later
- iOS 14.0 or later

### Steps:

1. In Xcode, with your app project open, navigate to File > Add Packages.
2. When prompted, add the `UltraPackage` SDK repository:

```swift
https://github.com/openinfer/ultra-ios-sdk
```
3. Link your Target to the SDK.

----------------------

## Example

1. Please, add requst descriptions in .plist file of root app.

**Example:**

```swift
<key>NSCameraUsageDescription</key>
<string>The camera is required to capture the user's face for secure identity verification purposes. The app compares the user's face with encrypted facial data previously stored on the device. This verification is performed entirely on the user's device, and no sensitive data is collected or stored externally.</string>
    
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID for secure authentication.</string>
    
<key>NFCReaderUsageDescription</key>
<string>We need access to NFC to scan tags for your interaction and improve service accuracy.</string>

<key>NSMotionUsageDescription</key>
<string>We use motion and fitness data to track your activity and enhance performance insights.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We require microphone access for audio input and to analyze interactions for a better experience.</string>

<key>NSCameraUsageDescription</key>
<string>We use the camera for scanning and interaction features while analyzing usage for improvements.</string>

<key>NSMotionUsageDescription</key>
<string>This app collects motion data for fitness tracking and performance optimization.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide personalized services and enhance app functionality.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Allow background location tracking for better accuracy and improved service performance.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We require location access even in the background to optimize features and collect statistics for better service.</string>

```

----------------------

2. The next step is to download the C+ library models. We implement lazy loading to ensure that the App Clip remains under 15 MB, and we use App Groups for model storage.

**Storage URL:**

```swift
https://wasm.privateid.com/Models/
```

**Model names:**

```swift
"f3ba2da6-22b3-41ae-bf35-b38d4754cdb2.data",
"a0c985f9-e37d-47a8-908c-efbd8f01cfa6.data",
"12632390-ef06-4a84-8dc4-86776152d180.data",
"6b440bf9-02eb-4fe1-ad96-f5e37a7bc2c0.data",
"8d0091b1-1848-4857-8b27-651a5095853b.data",
"7ba0db86-7ee0-4a43-bcb6-bd8e64c4917a.data",
"ef128022-c96c-4911-a243-dcb55fdf5bac.data",
"237a0839-5dce-4e87-b1eb-e77f9948c87b.data",
"ec493631-ddab-4f00-885a-dc9a4f1ac208.data",
"98b1a3b5-be51-424e-a589-cd8552f907a7.data",
"cde69dd5-8b46-49ac-a4b2-1da490f7fecd.data"
```

**Example:**

```swift
func saveModels() {
    if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: <groupId>) {
        
        let path = "https://wasm.privateid.com/Models/"
        
        let models =    ["f3ba2da6-22b3-41ae-bf35-b38d4754cdb2",
                        "a0c985f9-e37d-47a8-908c-efbd8f01cfa6",
                        "12632390-ef06-4a84-8dc4-86776152d180",
                        "6b440bf9-02eb-4fe1-ad96-f5e37a7bc2c0",
                        "8d0091b1-1848-4857-8b27-651a5095853b",
                        "7ba0db86-7ee0-4a43-bcb6-bd8e64c4917a",
                        "ef128022-c96c-4911-a243-dcb55fdf5bac",
                        "237a0839-5dce-4e87-b1eb-e77f9948c87b",
                        "ec493631-ddab-4f00-885a-dc9a4f1ac208",
                        "98b1a3b5-be51-424e-a589-cd8552f907a7",
                        "cde69dd5-8b46-49ac-a4b2-1da490f7fecd"]
            
        models.enumerated().forEach { index, item in
            self.download(from: "\(path)\(item).data") { data in
                do {
                    try data.write(to: containerURL.appendingPathComponent("\(item).data"))
                    if index == models.count - 1 {
                        // TODO: Save containerURL.absoluteString as storage URL
                     }
                } catch {
                    print("Error saving data to file: \(error)")
                }
            }
        }
    } else {
        // TODO: Add error
    }
}

private func download(from url: String, complition: @escaping (Data) -> Void) {
    guard let url = URL(string: url) else { return }
    do {
        let data = try Data(contentsOf: url)
        complition(data)
    } catch {
        print(error.localizedDescription)
    }
}
```

----------------------

3. Finally, we can lunch SDK UI.

```swift
private func runCharlie(with storageURL: String) {
    let cryptonet = UltraPackage()
    cryptonet.start(path: storageURL,
                    token: <sesionToken>,
                    publicKey: <publicKey>,
                    browser: <browserType>,
                    universalLink: <universalLink>,
                    type: <type>,
                    securityModel: SecurityModel()) { [weak self] finished in
        // TODO:
    }
}
```

    
WHERE:

- `token` - session token that may be collected from deep link. If it is nil it will be generated inside SDK.
- `publicKey` - public key that may be collected from deep link. If it is nil it will be generated inside SDK.
- `browser` - string browser type. By default, it is "chrome". Supported values: "chrome", "opera", "mozilla" or "safari".
- `universalLink` - you can redirect from your App Clip back to your full app by using a custom URL scheme or Universal Links.
- `type` - flow type as .enroll or .predict in case we don't need Welcome Page with proposed flows.

----------------------

## Navigation

### Open App Clip with Deep Link Navigation

### Example:
```swift
if let url = URL(string: "https://appclip.apple.com/id?p=com.privateid.ultra.verify.clip&universalLink=yourapp") {
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}
```
**Note:** Replace `yourapp` with your custom URL scheme from the app.

---

## How to Add a Custom URL Scheme to Your Project

### 1. Open Your Project’s Info.plist:
- In Xcode, locate and open the Info.plist file of your app.

### 2. Add a URL Types Entry:
- Right-click and choose **Add Row**.
- Select **URL Types** (if it doesn’t already exist) and set its type to **Array**.

### 3. Configure the URL Scheme:
- Expand the **URL Types** array and add a new item (**Item 0**).
- Under **Item 0**, add a key called **URL Schemes** (type: Array).
- Expand **URL Schemes** and add an item (**Item 0**) with your custom string value (e.g., **yourapp**).

Your Info.plist entry should look like this:
```
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

---

## 4. Handle the URL in Your App Delegate

Implement the following method in your **AppDelegate.swift** (or **SceneDelegate** if using scenes):

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Parse the URL and perform actions as needed
    if url.scheme == "yourapp" {
        // Handle the URL accordingly
        print("Opened via URL scheme: \(url)")
        return true
    }
    return false
}
```



