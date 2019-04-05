

Pod::Spec.new do |s|
    s.platform = :ios
    s.ios.deployment_target = '11.1'
  s.name             = 'PDGlobalClass'
  s.version          = '1.0'
  s.summary          = 'Class is manage Global api call with NSUrlSession and Multipart data sent to server with NSURLSession.'

s.license = { :type => "MIT", :file => "LICENSE" }

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/prashantdabhi9033/PDGlobalClass'

    s.authors          = { 'Prashant Dabhi' => 'prashantdabhi9033@gmail.com' }
    s.summary          = 'Global api call with get and post method it is use NSUrlSession and manage all use cases.'
    s.source           = { :git => 'https://github.com/prashantdabhi9033/PDGlobalClass.git', :tag => '1.0' }
    s.source_files     = 'ApiManager/*'
    s.swift_version = "4.2"
end



