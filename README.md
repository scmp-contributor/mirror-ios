# mirror-ios

SCMP Mirror real time tracking platform sdk for iOS

## Table of Contents
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Check Result](#check-result)

## Requirements
- iOS 10.0+
- Swift 5

## Installation

### CocoaPods

To integrate mirror-ios into your Xcode project using CocoaPods, specify it in your Podfile:

```ruby
pod 'Mirror'
```

### Swift Package Manager

Project -> Package Dependencies -> Add Package

![SPM tutorial](../main/Sources/Resources/spm_tutorial.png)

Once you have your Swift package set up, adding mirror-ios as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```swift
dependencies: [
    .package(url: "https://github.com/scmp-contributor/mirror-ios", .upToNextMajor(from: "0.0.23"))
]
```

## Usage

### Initialize Mirror:

```swift
let mirror = Mirror(environment: "YOUR_ENVIRONMENT",
                    organizationID: "YOUR_ORGANIZATION_ID",
                    domain: "YOUR_DOMAIN",
                    visitorType: "YOUR_VISITOR_TYPE", 
                    window: "AppDelegate or SceneDelegate window", 
                    scheduler: "YOUR_SCHEDULER_TYPE")
```

### Send Data:

**Send Ping Event:**

```swift
let trackData = TrackData(path: "CURRENT_PAGE_PATH",
                          section: "ARTICLE_SECTION",
                          authors: "ARTICLE_AUTHOR",
                          pageTitle: "PAGE_TITLE")

mirror.ping(data: trackData)
```

**Send Click Event:**

```swift
let trackData = TrackData(path: "CURRENT_PAGE_PATH",
                          clickInfo: "FULL_DESTINATION_URL")

mirror.click(data: trackData)
```

### Update Environment:

```swift
mirror.updateEnvironment("YOUR_ENVIRONMENT")
```

### Update Domain:

```swift
mirror.updateDomain("YOUR_DOMAIN")
```

### Update Visitor Type:

```swift
mirror.updateVisitorType("YOUR_VISITOR_TYPE")
```

## Check Result
There will be print logs for variety mirror events. By filtering `Mirror` to check the print logs to validate the result.

**Ping log sample**

```
[Track-Mirror]
mirror -> ping success, response: 200,
mirror -> state: active,
mirror -> ping interval: 15,
mirror -> next ping interval: 15
====== Mirror Request Body Start ======
mirror parameter ff: 45
mirror parameter u: FeSjWW93~RtVA2kSs_3t5
mirror parameter eg: 0
mirror parameter ir: %2Fhk
mirror parameter v: mi-0.0.20
mirror parameter p: %2Fnews%2Fasia
mirror parameter et: ping
mirror parameter vt: gst
mirror parameter s: articles only, News, Hong Kong, Health & Environment
mirror parameter sq: 1
mirror parameter pt: HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post
mirror parameter nc: false
mirror parameter pi: YCnPyuzyxWBZxkXz42JiU
mirror parameter k: 1
mirror parameter a: Keung To, Anson Lo
mirror parameter d: scmp.com
====== Mirror Request Body End ======
```

**Click log sample**

```
[Track-Mirror]
mirror -> click success, response: 200
====== Mirror Request Body Start ======
mirror parameter ci: https%3A%2F%2Fscmp.com%2Fnews%2Fhong-kong%2Fhealth-environment%2Farticle%2F3179276%2Fcoronavirus-hong-kong-prepared-rebound-infections
mirror parameter k: 1
mirror parameter sq: 2
mirror parameter pi: g8NYy~bCNg6WtnF_bUH7L
mirror parameter v: mi-0.0.20
mirror parameter eg: 2
mirror parameter vt: gst
mirror parameter et: click
mirror parameter s: articles only, News, Hong Kong, Health & Environment
mirror parameter u: FeSjWW93~RtVA2kSs_3t5
mirror parameter a: Keung To, Anson Lo
mirror parameter nc: false
mirror parameter d: scmp.com
mirror parameter p: %2Fnews%2Fasia
====== Mirror Request Body End ======
```
