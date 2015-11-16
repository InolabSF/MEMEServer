# JINS MEME Sample


## Documents

[Registration](https://developers.jins.com/en/preregistration/)

[JINS MEME documents](https://developers.jins.com/en/resource/docs/)

[Download SDK](https://developers.jins.com/en/sdks/ios/)



## Installation

[1] Download this project

```
$ git clone https://github.com/InolabSF/MEME.git
```

[2] Install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)

[3] Input the command

```
$ pod update
```

[4] Registration

[Register your account](https://developers.jins.com/en/preregistration/)

[Create an App](https://developers.jins.com/en/apps/create/)

You will get the App ID and App Secret.

[5] Input the command

```
$ vim MEME/Classes/MMConstant-Private.swift
```

```swift
/// JINS MEME 
let kMEMEAppID =                 "YOUR_MEME_APP_ID"
let kMEMEAppSecret =             "YOUR_MEME_APP_SECRET"
```

[6] Open workspace

```
$ open MEME.xcworkspace
```

[7] Run codes


## Installation From Scratch

[1] XCode -> File -> New -> Project

[2] XCode -> Target -> General Tab -> add Embedded Binaries [MEMELib.framework](https://developers.jins.com/en/sdks/ios/)

[3] XCode -> Target -> Capabilities Tab -> swipe Background Modes ON -> check Uses Bluetooth LE accessories

[4] XCode -> Target -> Info Tab -> write settings like [Info.plist](https://github.com/InolabSF/MEME/blob/master/MEME/Resources/Plists/Info.plist)

