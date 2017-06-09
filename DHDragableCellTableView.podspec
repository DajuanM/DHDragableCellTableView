#
#  Be sure to run `pod spec lint DHDragableCellTableView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "DHDragableCellTableView"
  s.version      = "1.0.3"
  s.summary      = "dragable UITableView"
  s.description  = <<-DESC
                    easy to implement dragable UITableView
                   DESC
  s.homepage     = "https://github.com/DajuanM/DHDragableCellTableView"
  s.license      = "MIT"
  s.author             = { "Aiden" => "252289287@qq.com" }
  s.source       = { :git => "https://github.com/DajuanM/DHDragableCellTableView.git", :tag => "#{s.version}" }
  s.source_files  = "DHDragableCellTableView", "DHDragableCellTableView/**/*.{h,m}"
  s.requires_arc = true
  s.ios.deployment_target = '7.0'
end
