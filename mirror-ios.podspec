#
# Be sure to run `pod lib lint mirror-ios.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'mirror-ios'
  s.version          = '0.0.1'
  s.summary          = 'SCMP Mirror iOS SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, do not worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  SCMP Mirror real time tracking platform sdk for iOS
                       DESC

  s.homepage         = 'https://github.com/scmp-contributor/mirror-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Terry Lee' => 'terry.lee@scmp.com' }
  s.source           = { :git => 'https://github.com/scmp-contributor/mirror-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/mirror-ios/**/*'
  
  # s.resource_bundles = {
  #   'mirror-ios' => ['mirror-ios/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
    s.dependency 'RxSwift', '~> 6.5.0'
    s.dependency 'RxAlamofire', '~> 6.1.0'
    s.dependency 'SwiftyBeaver', '~> 1.9.0'
end
