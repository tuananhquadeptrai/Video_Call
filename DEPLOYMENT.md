# 🚀 Deploy Video Call App lên Netlify

## 📋 Prerequisites
- Tài khoản Netlify (free): https://netlify.com
- Git repository (GitHub/GitLab) hoặc manual deploy

## 🔧 Cách 1: Deploy từ Git Repository (Recommended)

### 1. Push code lên GitHub
```bash
git add .
git commit -m "Ready for Netlify deployment"
git push origin main
```

### 2. Connect với Netlify
1. Đăng nhập vào https://netlify.com
2. Click "New site from Git"
3. Chọn GitHub/GitLab và authorize
4. Chọn repository `video_call_app`

### 3. Configure Build Settings
- **Build command**: `flutter build web --release`
- **Publish directory**: `build/web`
- **Base directory**: (để trống)

### 4. Environment Variables (nếu cần)
Trong Netlify dashboard → Site settings → Environment variables:
```
FLUTTER_WEB=true
```

### 5. Deploy!
Click "Deploy site" → Netlify sẽ auto build và deploy

## 🔧 Cách 2: Manual Deploy

### 1. Build local
```bash
flutter build web --release
```

### 2. Drag & Drop Deploy
1. Vào https://netlify.com
2. Kéo thả folder `build/web` vào Netlify dashboard
3. Wait for deployment

## 🌐 Sau khi Deploy

### URL Example:
- Netlify sẽ tạo URL dạng: `https://amazing-app-name-123456.netlify.app`
- Có thể custom domain trong Settings

### 📱 Test Multi-User
1. Mở URL trên 2 browser/device khác nhau
2. Device 1: Tạo meeting → note meeting ID
3. Device 2: Join với meeting ID đó
4. Kiểm tra video/audio connection

## 🔧 Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
flutter build web --release --verbose
```

### CORS Issues
VideoSDK API đã support web, không cần config thêm

### Camera/Mic Permissions
- Cần HTTPS để access camera/mic trên production
- Netlify auto provide HTTPS

## 📊 Performance Tips

### 1. Enable Gzip trong netlify.toml
```toml
[[headers]]
  for = "*.js"
  [headers.values]
    Content-Encoding = "gzip"
```

### 2. PWA Support (optional)
Thêm vào `web/manifest.json` để support PWA

## 🔒 Security Notes

- VideoSDK token đã được include trong build
- Không expose sensitive Azure keys (chưa active)
- HTTPS required cho WebRTC

## 📈 Analytics & Monitoring

Netlify cung cấp:
- Build logs
- Function logs (nếu dùng)
- Performance analytics
- Form submissions

---

**🎯 Expected Result**: 
App sẽ chạy trên web với full video calling functionality!
