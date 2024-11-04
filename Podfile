# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'OneKeyBleDemo' do
  # Change to static linking
  use_frameworks! :linkage => :static

  # Pods for OneKeyBleDemo

  pod 'Protobuf', '3.23.4'


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
      # Add these specific settings for Protobuf
      if target.name == 'Protobuf'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GPBOBJC_SKIP_MESSAGE_IMPL=1'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GPB_STATIC_LIBRARY=1'
        config.build_settings['CLANG_ENABLE_OBJC_WEAK'] = 'YES'
        config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
        config.build_settings['CLANG_WARN_DIRECT_OBJC_ISA_USAGE'] = 'YES_ERROR'
      else
        config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
      end
      
      # Other necessary settings
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['SKIP_INSTALL'] = 'YES'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      
      # Protobuf specific settings
      config.build_settings['HEADER_SEARCH_PATHS'] = '$(inherited) "${PODS_ROOT}/Headers/Public/Protobuf"'
    end
  end
end

