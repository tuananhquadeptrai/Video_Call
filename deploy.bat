@echo off
echo 🚀 Building Flutter Web App for Netlify...
echo.

echo 📦 Cleaning previous build...
flutter clean

echo 📥 Getting dependencies...
flutter pub get

echo 🔨 Building for web production...
flutter build web --release

echo ✅ Build completed!
echo.
echo 📁 Deploy folder: build/web
echo 🌐 Manual deploy: Drag build/web folder to netlify.com
echo 📋 Or check DEPLOYMENT.md for Git-based deployment
echo.
pause
