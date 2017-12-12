Closure-Notifier

Closure-Notifier (App), is an iOS app to manage a subscription list of cities of interest to receive notifications from U.S. Department of Labor Emergency Management Center.

Features:
* The App is written in Swift 3
* Fast and lightweight
* Can search by: city name, state code (VA, etc), or region name

Requirements:
* iOS 10.0+
* Swift 3
* Alamofire

Installation
CocoaPods

To install, simply add 
pod 'Alamofire'
and
use_frameworks!

to your podfile. Final podfle looks like:

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'Closure' do
  pod 'Alamofire', '~> 4.5'
  pod 'MBProgressHUD', '~> 1.0'
end

Once the podfile is created run

pod install

with CocoaPods 1.0 or newer.


Using XCode on the Closure source
Ensure Alamofire is installed
Use Closure.xcworkspace to launch XCode project.
