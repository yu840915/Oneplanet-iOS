# Oneplanet-iOS

## 必備條件
* 需安裝 Xcode
* 需安裝 [Cocoapods](https://guides.cocoapods.org/using/getting-started.html)
* 需安裝 [Carthage](https://github.com/Carthage/Carthage)

開啟專案前，先由終端機前往專案目錄，分別執行：

```
pod install
```

```
carthage update --platform iOS
```

完成後開啟 `Oneplanet.xcworkspace`

## 簡述

此專案使用Swift 5語言。

為物件導向設計，大量的使用物件聚合與委派(delegation)，故必須對此有深入的暸解。

畫面實作上，採用了 **Interface Builder** 。排版實作上，採用 **Auto Layout** 與 `UIStackView`。畫面流程上，深度依賴 **View Controller Hierarchy** 技術。要了解這些技術可以參考 [Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html) 與 [View Controller Programming Guide for iOS](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/) ，並觀看各年WWDC關於UIKit相關的主題影片。

另外，還依賴 [ModelBlocks](https://github.com/yu840915/ModelBlocks) 提供基礎任務類別(Operation)建構框架。網路存取使用 [AlamoFire](https://github.com/Alamofire/Alamofire) 並搭配 [AlamofireAPIAccessOperation](https://github.com/yu840915/AlamofireAPIAccessOperation) 處理重複的流程。請參考各個頁面的說明。

### Logging
使用 [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver)，將事件分級印出。

### 本地化
這裡以原生的方式提供本地化服務，並集中管理在 `Localized.swift` 中。依照內容特性分類。這是要避免字串散佈在各個檔案。

許多經常使用字串查詢的服務也都有包覆在物件當中，例如 `PreferencesItem` 包覆 `UserDefaults`，`AppConfigurationItem` 包覆 `RemoteConfig` 項目。

### 共享資源

這裡有些沒有狀態的工具類、資源類物件，且可能有創建成本的，有集中管理，像是文字格式化工具(formatter)，文字驗證(input validator)，顏色與UI物件工廠等。