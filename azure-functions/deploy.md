# 🚀 Hướng dẫn Deploy Azure Functions

## Bước 1: Cài đặt Azure Functions Core Tools

```bash
# Windows (PowerShell as Administrator)
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Hoặc sử dụng Chocolatey
choco install azure-functions-core-tools
```

## Bước 2: Login và Deploy

```bash
# Di chuyển vào thư mục azure-functions
cd azure-functions

# Login vào Azure
az login

# Deploy Functions lên Azure
func azure functionapp publish func-videocall-backend

# Cài đặt environment variables
az functionapp config appsettings set --name func-videocall-backend --resource-group rg-videocall-app --settings ACS_CONNECTION_STRING="YOUR_ACS_CONNECTION_STRING"
```

## Bước 3: Lấy Connection Strings

### Azure Communication Services:
1. Vào Azure Portal → Communication Services → acs-videocall-app
2. Keys → Copy "Primary connection string"
3. Dán vào lệnh trên thay cho "YOUR_ACS_CONNECTION_STRING"

### Azure SignalR:
1. Vào Azure Portal → SignalR Service → signalr-videocall-chat  
2. Keys → Copy "Primary connection string"

## Bước 4: Test Functions

Sau khi deploy, test các endpoints:

```bash
# Test Create Meeting
curl -X POST https://func-videocall-backend.azurewebsites.net/api/meetings/create \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Meeting", "maxParticipants": 10}'

# Test Join Meeting  
curl -X POST https://func-videocall-backend.azurewebsites.net/api/meetings/join \
  -H "Content-Type: application/json" \
  -d '{"meetingId": "1234-5678-9012", "userName": "Test User"}'
```

## Bước 5: Cập nhật Flutter App

Trong Flutter app, cập nhật file `env.example` thành `.env`:

```
ACS_CONNECTION_STRING=endpoint=https://acs-videocall-app.communication.azure.com/;accesskey=YOUR_ACTUAL_KEY
AZURE_FUNCTIONS_URL=https://func-videocall-backend.azurewebsites.net
SIGNALR_CONNECTION_STRING=Endpoint=https://signalr-videocall-chat.service.signalr.net;AccessKey=YOUR_ACTUAL_KEY;Version=1.0;
```
