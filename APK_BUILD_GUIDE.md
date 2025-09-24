# 📱 Hướng dẫn Build APK cho Android

## 🚀 Cách build APK để cài lên điện thoại

### **Phương pháp 1: Build thông qua Flutter CLI**

```bash
# Bước 1: Chuẩn bị
flutter clean
flutter pub get

# Bước 2: Build APK release
flutter build apk --release

# Bước 3: Tìm file APK
# APK sẽ được tạo tại: build/app/outputs/flutter-apk/app-release.apk
```

### **Phương pháp 2: Build APK với size nhỏ hơn**

```bash
# Build APK cho từng kiến trúc CPU riêng biệt (giảm 70% size)
flutter build apk --release --split-per-abi

# Sẽ tạo ra 3 file APK:
# - app-arm64-v8a-release.apk (cho hầu hết điện thoại hiện đại)
# - app-armeabi-v7a-release.apk (cho điện thoại cũ)
# - app-x86_64-release.apk (cho emulator)
```

### **Phương pháp 3: Sử dụng Android Studio**

1. Mở Android Studio
2. File → Open → Chọn thư mục `android/`
3. Build → Generate Signed Bundle / APK
4. Chọn APK → Next
5. Create new keystore hoặc dùng existing
6. Build

## 📁 **Vị trí file APK sau khi build:**

```
project_root/
├── build/
│   └── app/
│       └── outputs/
│           └── flutter-apk/
│               ├── app-release.apk          (Universal APK - ~50MB)
│               ├── app-arm64-v8a-release.apk     (~15MB - Recommended)
│               ├── app-armeabi-v7a-release.apk   (~15MB)
│               └── app-x86_64-release.apk        (~15MB)
```

## 📲 **Cách cài APK lên điện thoại:**

### **Option 1: USB Transfer**
1. Copy file APK vào điện thoại qua USB
2. Mở File Manager trên điện thoại
3. Tap vào file APK
4. Allow "Install from unknown sources" nếu được hỏi
5. Install

### **Option 2: ADB Install**
```bash
# Kết nối điện thoại qua USB với USB Debugging enabled
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### **Option 3: Google Drive/Cloud**
1. Upload APK lên Google Drive
2. Download về điện thoại
3. Install như Option 1

## 🔧 **Troubleshooting**

### **Lỗi "App not installed"**
- Enable "Unknown sources" trong Settings → Security
- Hoặc Settings → Apps → Special access → Install unknown apps

### **APK quá lớn**
- Dùng `--split-per-abi` để tạo APK riêng cho từng architecture
- Chọn file APK phù hợp với điện thoại:
  - **ARM64** (arm64-v8a): Điện thoại hiện đại (2017+)
  - **ARM32** (armeabi-v7a): Điện thoại cũ hơn

### **App crash khi mở**
- Kiểm tra permissions trong Settings → Apps → [App name] → Permissions
- Enable Camera và Microphone permissions

## 📋 **App đã được config:**

✅ **Permissions**: Camera, Microphone, Internet
✅ **App Name**: "Azure Video Call"  
✅ **VideoSDK**: Ready for video calling
✅ **UI**: Modern gradient design
✅ **Features**: Create meeting, Join meeting, Multi-user support

## 🎯 **Expected APK Info:**

- **Size**: 15-50MB (tùy theo build method)
- **Min Android**: API 21 (Android 5.0)
- **Permissions**: Camera, Microphone required
- **Internet**: Required for VideoSDK API

---

**📱 Sau khi cài APK, test bằng cách:**
1. Mở app trên 2 điện thoại
2. Điện thoại 1: Tạo meeting → Copy ID
3. Điện thoại 2: Join với meeting ID đó
4. Kiểm tra video/audio connection!
