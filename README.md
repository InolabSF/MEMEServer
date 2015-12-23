# JINS MEME iOS API Server


## Installation

[1] Download this project

```
$ git clone https://github.com/InolabSF/MEMEServer.git
$ cd MEMEServer
```

[2] Install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)

[3] Input the command

```
$ pod update
```

[4] Registration

[Register your account](https://developers.jins.com/en/preregistration/)

[Create an App](https://developers.jins.com/en/apps/create/)

[5] Open workspace

```
$ open MEME.xcworkspace
```

[6] Run codes


### MEMELib

It's implemented by HTTP Server.

```
API: /isConnected

API: /isDataReceiving

API: /isCalibrated

API: /set?appClientId=YOUR_MEME_SDK_APP_CLIENT_ID&clientSecret=YOUR_MEME_SDK_CLIENT_SECRET

API: /startScanningPeripherals

API: /connect?peripheral=YOUR_PERIPHERAL_UUID_STRING

API: /disconnectPeripheral

API: /getConnectedByOthers

API: /startDataReport

API: /stopDataReport

API: /getSDKVersion

API: /getFWVersion

API: /getHWVersion

API: /getConnectedDeviceType

API: /getConnectedDeviceSubType
```
