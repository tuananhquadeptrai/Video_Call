# 📋 Azure Setup Guide - Video Call App

## 🎯 Tổng quan
Hướng dẫn setup Azure services cho ứng dụng Video Call với tài khoản Azure Student.

## 🔧 Azure Services cần tạo

### 1. ✅ Resource Group
- **Tên**: `rg-videocall-app`
- **Region**: `Southeast Asia`

### 2. ✅ Azure Communication Services  
- **Tên**: `acs-videocall-app`
- **Data location**: `Asia Pacific`
- **Mục đích**: Video calling, identity management

### 3. ✅ Azure Functions
- **Tên**: `func-videocall-backend` 
- **Runtime**: `Node.js 18 LTS`
- **Plan**: `Consumption (Serverless)`
- **Mục đích**: Backend API cho meeting management

### 4. ✅ Azure SignalR Service
- **Tên**: `signalr-videocall-chat`
- **Pricing tier**: `Free F1 (20 connections)`
- **Service mode**: `Default`
- **Mục đích**: Real-time chat

### 5. ✅ Storage Account
- **Tên**: `stvideocallapp` (phải unique)
- **Performance**: `Standard`
- **Replication**: `LRS (Local)`
- **Mục đích**: File storage, recordings

## 🚀 Deployment Steps

### Bước 1: Tạo Resources trên Azure Portal
1. Đăng nhập https://portal.azure.com
2. Tạo từng resource theo thứ tự trên
3. Lưu lại connection strings

### Bước 2: Deploy Azure Functions
```bash
cd azure-functions
npm install
az login
func azure functionapp publish func-videocall-backend
```

### Bước 3: Cấu hình Environment Variables
```bash
az functionapp config appsettings set \
  --name func-videocall-backend \
  --resource-group rg-videocall-app \
  --settings ACS_CONNECTION_STRING="YOUR_ACS_CONNECTION_STRING"
```

### Bước 4: Test Integration
- Test Azure Functions endpoints
- Kiểm tra kết nối từ Flutter app
- Verify video calling functionality

## 📝 Connection Strings cần lấy

### Azure Communication Services:
```
endpoint=https://acs-videocall-app.communication.azure.com/;accesskey=YOUR_KEY
```

### Azure SignalR:
```
Endpoint=https://signalr-videocall-chat.service.signalr.net;AccessKey=YOUR_KEY;Version=1.0;
```

### Storage Account:
```
DefaultEndpointsProtocol=https;AccountName=stvideocallapp;AccountKey=YOUR_KEY;EndpointSuffix=core.windows.net
```

## 🔒 Security Notes
- Sử dụng environment variables cho sensitive data
- Enable CORS cho Functions App
- Cấu hình proper access policies

## 💡 Cost Optimization (Azure Student)
- Sử dụng Free tiers khi có thể
- Monitor usage để tránh vượt credit
- Delete resources khi không dùng

## 🧪 Testing
1. **Local Testing**: Sử dụng VideoSDK fallback
2. **Azure Testing**: Test với Azure Functions
3. **Production**: Deploy hoàn chỉnh

## 🆘 Troubleshooting
- Check Azure Functions logs trong Portal
- Verify connection strings
- Test network connectivity
- Check CORS configuration
