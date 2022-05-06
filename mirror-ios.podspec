#
# Be sure to run `pod lib lint mirror-ios.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'mirror-ios'
  s.version          = '0.0.5'
  s.summary          = 'SCMP Mirror iOS SDK'

  s.description      = <<-DESC
  SCMP Mirror real time tracking platform sdk for iOS
                       DESC

  s.homepage         = 'https://github.com/scmp-contributor/mirror-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Terry Lee' => 'terry.lee@scmp.com' }
  s.source           = { :git => 'https://github.com/scmp-contributor/mirror-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/mirror-ios/**/*'
  
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxAlamofire'
  s.dependency 'SwiftyBeaver'
end
