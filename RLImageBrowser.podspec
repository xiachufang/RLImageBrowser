
Pod::Spec.new do |s|
    s.name             = 'RLImageBrowser'
    s.version          = '1.0.0'
    s.summary          = 'A simple image browser.'
    s.description      = 'A simple image browser...'
    
    s.homepage         = 'https://github.com/kinarob/RLImageBrowser'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'kinarobin@outlook.com' => 'kinarobin@outlook.com' }
    s.source           = { :git => 'https://github.com/kinarob/RLImageBrowser.git', :tag => s.version.to_s }
    s.ios.deployment_target = '8.0'
    
    s.resources    = 'RLImageBrowser/RLPhotoBrowser.bundle', 'RLImageBrowser/RLLocalizations.bundle'
    s.source_files = 'RLImageBrowser/**/*'
    s.dependency 'SDWebImage', '~> 5.0.0-beta4'
    s.dependency 'SDWebImageWebPCoder', '~> 0.1.1'
    s.dependency 'DACircularProgress'
    
end
