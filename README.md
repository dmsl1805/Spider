# Spider

[![CI Status](http://img.shields.io/travis/Dmitriy Shulzhenko/Spider.svg?style=flat)](https://travis-ci.org/Dmitriy Shulzhenko/Spider)
[![Version](https://img.shields.io/cocoapods/v/Spider.svg?style=flat)](http://cocoapods.org/pods/Spider)
[![License](https://img.shields.io/cocoapods/l/Spider.svg?style=flat)](http://cocoapods.org/pods/Spider)
[![Platform](https://img.shields.io/cocoapods/p/Spider.svg?style=flat)](http://cocoapods.org/pods/Spider)

## Example
// Update your model more easily. Clean architecture.

self.spider = Spider<Forecast>(persistentStorageController,
networkController: networkController,
request: forecastUpdateHTTPRequest)
self.spider.delegate = self

//sends http request, handles response, deletes old data and writes a new one
self.spider.sendRequest().deleteInfo().writeInfo().execute()

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

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
