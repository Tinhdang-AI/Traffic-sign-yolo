# Required packages for pubspec.yaml

Add these to your pubspec.yaml file:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP & Networking
  http: ^1.1.0

  # Secure Storage for tokens
  flutter_secure_storage: ^9.0.0

  # State Management (optional but recommended)
  provider: ^6.0.0

  # UI Components
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^3.0.0
```

## Installation Steps

1. Add the above packages to your `pubspec.yaml`
2. Run `flutter pub get`
3. Follow the platform-specific setup for flutter_secure_storage:

### Android Setup (flutter_secure_storage)

In `android/app/build.gradle`, add:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS Setup (flutter_secure_storage)

In `ios/Podfile`, ensure platform version is at least 11.0:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```
