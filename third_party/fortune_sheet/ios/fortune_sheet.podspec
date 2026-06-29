Pod::Spec.new do |s|
  s.name             = 'fortune_sheet'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter canvas port of FortuneSheet.'
  s.description      = <<-DESC
A Flutter canvas port of FortuneSheet.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Label Manager' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
