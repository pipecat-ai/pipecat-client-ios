Pod::Spec.new do |s|
  s.name         = 'PipecatClientIOS'
  s.version      = '0.3.4'
  s.summary      = 'Pipecat iOS client library.'
  s.description  = <<-DESC
                    Pipecat iOS client library that implements the RTVI-AI standard.
                   DESC
  s.homepage     = 'https://github.com/pipecat-ai/pipecat-client-ios'
  s.documentation_url  = "https://docs.pipecat.ai/client/ios/introduction"
  s.license      = { :type => 'BSD-2', :file => 'LICENSE' }
  s.author             = { "Daily.co" => "help@daily.co" }
  s.source       = { :git => 'https://github.com/pipecat-ai/pipecat-client-ios.git', :tag => "0.3.2" }
  s.ios.deployment_target = '13.0'
  s.source_files = 'Sources/**/*.{swift,h,m}'
  s.exclude_files = 'Sources/Exclude'
  s.swift_version = '5.5'
end

