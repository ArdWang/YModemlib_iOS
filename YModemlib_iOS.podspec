#
#  Be sure to run `pod spec lint YModemlib_iOS.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "YModemlib_iOS"
  spec.version      = "1.0.1"
  spec.summary      = "A short description of YModemlib_iOS."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
  This is quickly Bluetooth help connect, it is help quick more device connect. so you use very smart!
                   DESC
  




  spec.homepage     = "https://github.com/ArdWang/YModemlib_iOS"

  spec.license      = { :type => "MIT", :file => "LICENSE" }
                 
                 
  spec.author       = { "ArdWang" => "278161009@qq.com" }
                 
  spec.platform     = :ios, "9.0"
                 
  spec.ios.deployment_target = "9.0"
                 
                 
  spec.source    = { :git => "https://github.com/ArdWang/YModemlib_iOS.git", :tag => "#{spec.version}" }
                 
  spec.swift_version = '5.0'
                 
                 
                 
  spec.source_files  = "YModemlib_iOS", "YModemCs/Class/YModem/*.{h,m}"
                 
  spec.frameworks = "Foundation","UIKit","CoreBluetooth","Masonry"
                 
                  
                 
  end                 
  