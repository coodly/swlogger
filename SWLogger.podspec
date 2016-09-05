Pod::Spec.new do |s|
  s.name = 'SWLogger'
  s.version = '0.3.0'
  s.license = 'Apache 2'
  s.summary = 'Logging in Swift'
  s.homepage = 'https://github.com/coodly/swlogger'
  s.authors = { 'Jaanus Siim' => 'jaanus@coodly.com' }
  s.source = { :git => 'git@github.com:coodly/swlogger.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'

  s.source_files = 'Sources/*.swift'
  s.tvos.exclude_files = ['Sources/ShakeWindow.swift']
  s.osx.exclude_files = ['Sources/ShakeWindow.swift']

  s.requires_arc = true
end
