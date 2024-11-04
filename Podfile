# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'OneKeyBleDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks! :linkage => :static

  # Pods for OneKeyBleDemo

  pod 'Protobuf', '~> 3.21.12'

  target 'OneKeyBleDemoTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'OneKeyBleDemoUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = ''
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
