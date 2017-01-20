# Spider

[![CI Status](http://img.shields.io/travis/Dmitriy Shulzhenko/Spider.svg?style=flat)](https://travis-ci.org/Dmitriy Shulzhenko/Spider)
[![Version](https://img.shields.io/cocoapods/v/Spider.svg?style=flat)](http://cocoapods.org/pods/Spider)
[![License](https://img.shields.io/cocoapods/l/Spider.svg?style=flat)](http://cocoapods.org/pods/Spider)
[![Platform](https://img.shields.io/cocoapods/p/Spider.svg?style=flat)](http://cocoapods.org/pods/Spider)

## Update your model more easily. With cleaner architecture in your project.

## Example
```swift
// Swift
self.spider = Spider<T>(persistentStorageController,
                        networkController: networkController,
                        request: forecastUpdateHTTPRequest)
self.spider.delegate = self

//sends http request, handles response, deletes old data and writes a new one

self.spider.sendRequest().deleteInfo().writeInfo().execute()
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

To use Spider you have to conform these protocols

```swift
// This is your storage for any network responce
// Storage will be used to update model

@objc public protocol TempObjectStorageProtocol: class{}
```
```swift
// Entity object. Can be subclass of NSManagedObject, or smth else

@objc public protocol EntityProtocol {

@objc static var entityName: String { get }

// Entity that contains some data (NSData, Image, ets.)

@objc optional var dataRemoutePaths: [String] { get }

@objc optional var dataNames: [String] { get }

}
```
```swift
// Persistant storage controller. E.g. Core data stack controller or other.

@objc public protocol PersistentStorageControllerProtocol {

@objc optional func update(name: String, with objects: TempObjectStorageProtocol)

@objc optional func remove(name: String, new objects: TempObjectStorageProtocol)

@objc optional func fetchWithoutData(name: String) -> [EntityProtocol]?

@objc optional func write(data dataStore: [TempObjectStorageProtocol], completed:((_ error: Error?) -> Void))

//    @objc func delete(data named: String, completed:((_ error: Error?) -> Void))

@objc optional func get(data named: String) -> Data?

}
```
```swift
// Network manager

public typealias NetworkResponseBlock = (_ objects: TempObjectStorageProtocol? , _ error: Error? ) -> (Void)

@objc public protocol NetworkControllerProtocol {

@objc func executeRequest(_ request: URLRequest,
response: @escaping NetworkResponseBlock) -> URLSessionTask

}
```

## Installation

Spider is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Spider"
```

## Author

Dmitriy Shulzhenko, dmsl1805@gmail.com

## License

Spider is available under the MIT license. See the LICENSE file for more info.
