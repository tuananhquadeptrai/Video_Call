@echo off
echo 📱 Building Android APK for Video Call App...
echo.

echo 🧹 Cleaning previous build...
flutter clean

echo 📦 Getting dependencies...
flutter pub get

echo 🔨 Building APK...
flutter build apk --release

echo.
echo ✅ APK build completed!
echo 📍 APK location: build\app\outputs\flutter-apk\app-release.apk
echo 📱 You can install this APK on your Android device
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ✅ APK file found at:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Size:
    dir "build\app\outputs\flutter-apk\app-release.apk" | findstr app-release.apk
) else (
    echo ❌ APK file not found. Check errors above.
)

echo.
pause
