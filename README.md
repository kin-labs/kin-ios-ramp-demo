# Integrate RAMP on your KIN iOS app

Ramp iOS SDK is a library that allows you to easily integrate Ramp into your iOS app and communicate with it.

## This Demo is based off the kin-ios-starter kit.

The quickest way to get started is by following the [tutorial](https://kintegrate.dev/tutorials/getting-started-ios-sdk/) or by downloading the [starter kit](https://kintegrate.dev/starters/kin-ios-starter/).

## Test Environment

At the time of this writing the SOLANA_KIN asset is not listed on Ramp's test enviroment. This demo connects directly to the production environment in order to show KIN as an option.

To switch your demo to the test environment you need to specify a [test network](https://docs.ramp.network/testing-environments).

Example:

```
configuration.url = "https://ri-widget-staging.firebaseapp.com/"
```

## How to add Ramp

In your Podfile

```
source 'https://github.com/passbase/zoomauthentication-cocoapods-specs.git'
source 'https://github.com/passbase/cocoapods-specs.git'
source 'https://github.com/passbase/microblink-cocoapods-specs.git'

target 'kin-ios-ramp-demo' do
   use_frameworks!
   pod 'Ramp', :git => 'git@github.com:RampNetwork/ramp-sdk-ios.git', :tag => '2.0.0'
end
```

On your demo folder's root, install the pod files. This will bring the Ramp's SDK into your project

```
pod install
```

## Run the demo

Once the pods are installed, open the generated xcworkspace file.

Press the play icon to start the demo app

Press the Purchase Kin button, follow the on-screen instructions to finish up your purchase.

<img src="/media/ramp.gif" width="400" />

## How to add and customize Ramp

To start add Ramp to your ViewController, Line 11 on the Demo.
```
import Ramp
```

On the ViewController.swift file (Line23) define the information we will pass to the Ramp SDK

```
@IBAction func showRamp(_ sender: UIButton) {
       let address = kin?.address()
       var configuration = Configuration()
       configuration.userAddress = address
       configuration.selectedCountryCode = "CA"
       configuration.swapAsset = "SOLANA_KIN"
       let ramp = try! RampViewController(configuration: configuration)
       ramp.delegate = self
       present(ramp, animated: true)
    }
```

This pases the wallet address set on the Kin.swift file

```
let address = kin?.address()
```

Then we set other properties for the Ramp SDK to use. 

```
       configuration.userAddress = address
       configuration.selectedCountryCode = "CA"
       configuration.swapAsset = "SOLANA_KIN"
```

[For a comprehensive list of options check Ramp's guide](https://docs.ramp.network/mobile/ios-sdk/)

Define a button to trigger Ramp (Line 150 on the ViewController.swift file)

```
private let getRamp: UIButton = {
            let button = UIButton()
            button.backgroundColor = .black
            button.setTitleColor(
                .white,
                for: .normal
            )
            button.setTitleColor(
                .gray,
                for: .disabled
            )
            button.setTitle(
                "Purchase Kin",
                for: .normal
            )
            button.titleLabel?.textAlignment = .center
            button.addTarget(
                self,
                action: #selector(showRamp),
                for: .touchUpInside
            )
            return button
        }()
        
        private var getRampButtonFrame: CGRect {
            let width: CGFloat = 200.0
            let height: CGFloat = 50.0
            return CGRect(
                x: view.bounds.width / 2.0 - width / 2.0,
                y: addToTestBalanceButtonFrame.maxY +  80.0,
                width: width,
                height: height
            )
        }
    
```

Add the subView of our button (Line 201 in the demo)

```
        view.addSubview(getRamp)
```
Add the button to the subview layouts  (Line 209 in the demo)

```
        getRamp.frame = getRampButtonFrame
        getRamp.layer.cornerRadius = getRampButtonFrame.height / 2.0
```

Then to finish the implementation, add the RampDelegate protocol. Ramp's SDK requires three required methods to be added (Line 351)

```
extension ViewController: RampDelegate {
    func ramp(_ rampViewController: RampViewController, didCreatePurchase purchase: RampPurchase, purchaseViewToken: String, apiUrl: URL) {}
   func rampPurchaseDidFail(_ rampViewController: RampViewController) {}
   func rampDidClose(_ rampViewController: RampViewController) {}
}
```

## Additional information

[For additional implementation options and other useful information check the Ramp's SDK Integration Guides](https://docs.ramp.network/mobile/ios-sdk/)



