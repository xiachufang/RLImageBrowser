
Pod::Spec.new do |s|
    s.name             = 'RLImageBrowser'
    s.version          = '1.1.0'
    s.summary          = 'A simple image browser with webp/gif support and gesture to dismiss.'
    s.description      = 'A simple image browser with webp/gif support and gesture to dismiss...'
    
    s.homepage         = 'https://github.com/kinarob/RLImageBrowser'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'kinarobin@outlook.com' => 'kinarobin@outlook.com' }
    s.source           = { :git => 'https://github.com/kinarob/RLImageBrowser.git', :tag => s.version.to_s }
    s.ios.deployment_target = '8.0'
    
    s.resources    = 'RLImageBrowser/RLImageBrowser.bundle'
    s.source_files = 'RLImageBrowser/**/*.{h,m}'
    s.dependency 'SDWebImage', '~> 5.0.2'
    s.dependency 'SDWebImageWebPCoder', '~> 0.2.1'
    
end
