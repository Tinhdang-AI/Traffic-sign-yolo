# 🧪 API Testing Guide - Curl & Postman

## 📋 QUICK START - GET TEST TOKEN

### 1. Register a Test Account
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@traffic.dev",
    "password": "Test123!@#",
    "displayName": "Test Driver"
  }'
```

### 2. Login & Get Token
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@traffic.dev",
    "password": "Test123!@#"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "..."
}
```

**Save token to variable:**
```bash
TOKEN="your_access_token_here"
```

---

## 🗺️ REPORTS ENDPOINTS

### Create Report
```bash
curl -X POST http://localhost:3000/api/v1/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Traffic Jam at Intersection",
    "latitude": 10.7769,
    "longitude": 106.7009,
    "violationType": "traffic",
    "description": "Heavy traffic congestion during peak hours",
    "imageUrl": null
  }'
```

### Get All Reports (Paginated)
```bash
curl -X GET "http://localhost:3000/api/v1/reports?limit=10&offset=0" \
  -H "Authorization: Bearer $TOKEN"
```

### Get Nearby Reports
```bash
curl -X GET "http://localhost:3000/api/v1/reports/nearby?latitude=10.7769&longitude=106.7009&radiusKm=5" \
  -H "Authorization: Bearer $TOKEN"
```

### Upvote Report
```bash
curl -X POST http://localhost:3000/api/v1/reports/{REPORT_ID}/upvote \
  -H "Authorization: Bearer $TOKEN"
```

### Delete Report
```bash
curl -X DELETE http://localhost:3000/api/v1/reports/{REPORT_ID} \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🎥 DETECTION HISTORY ENDPOINTS

### Record Detection (from AR Camera)
```bash
curl -X POST http://localhost:3000/api/v1/history \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "latitude": 10.7769,
    "longitude": 106.7009,
    "confidence": 0.95,
    "detectionType": "speed_limit_sign"
  }'
```

### Get Detection History
```bash
curl -X GET "http://localhost:3000/api/v1/history?limit=20&offset=0" \
  -H "Authorization: Bearer $TOKEN"
```

### Delete Detection Entry
```bash
curl -X DELETE http://localhost:3000/api/v1/history/{DETECTION_ID} \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📊 ADMIN ENDPOINTS (requires admin role)

### Dashboard Statistics
```bash
curl -X GET http://localhost:3000/api/v1/admin/dashboard/stats \
  -H "Authorization: Bearer $TOKEN"
```

### Get All Reports (Admin View)
```bash
curl -X GET "http://localhost:3000/api/v1/admin/reports?limit=50&status=pending&violationType=accident" \
  -H "Authorization: Bearer $TOKEN"
```

### Update Report Status
```bash
curl -X PATCH http://localhost:3000/api/v1/admin/reports/{REPORT_ID}/status \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "status": "resolved",
    "notes": "Issue has been addressed"
  }'
```

### Get Heatmap Data
```bash
curl -X GET "http://localhost:3000/api/v1/admin/history/heatmap?limit=1000" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📮 POSTMAN COLLECTION SETUP

### 1. Create Environment Variable
```json
{
  "name": "Traffic Detect",
  "values": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000/api/v1",
      "enabled": true
    },
    {
      "key": "token",
      "value": "",
      "enabled": true
    }
  ]
}
```

### 2. Auth Flow in Postman

**Request 1: Register**
- Method: POST
- URL: `{{baseUrl}}/auth/register`
- Body: JSON
```json
{
  "email": "test@traffic.dev",
  "password": "Test123!@#",
  "displayName": "Test Driver"
}
```

**Request 2: Login**
- Method: POST
- URL: `{{baseUrl}}/auth/login`
- Body: JSON
```json
{
  "email": "test@traffic.dev",
  "password": "Test123!@#"
}
```
- **Tests tab** (auto-save token):
```javascript
if (pm.response.code === 200) {
    pm.environment.set("token", pm.response.json().access_token);
}
```

### 3. Report Endpoints

**Create Report**
- Method: POST
- URL: `{{baseUrl}}/reports`
- Headers: `Authorization: Bearer {{token}}`
- Body: JSON
```json
{
  "name": "Traffic Jam",
  "latitude": 10.7769,
  "longitude": 106.7009,
  "violationType": "traffic",
  "description": "Heavy congestion"
}
```

**Get Nearby Reports**
- Method: GET
- URL: `{{baseUrl}}/reports/nearby?latitude=10.7769&longitude=106.7009&radiusKm=5`
- Headers: `Authorization: Bearer {{token}}`

---

## ✅ TEST WORKFLOW

1. **Health Check**
   ```bash
   curl http://localhost:3000/api/v1
   ```

2. **Register Account**
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/register ...
   ```

3. **Login**
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/login ...
   # Save token to TOKEN variable
   ```

4. **Create Report**
   ```bash
   curl -X POST http://localhost:3000/api/v1/reports \
     -H "Authorization: Bearer $TOKEN" ...
   # Save report ID
   ```

5. **Get Nearby Reports**
   ```bash
   curl -X GET http://localhost:3000/api/v1/reports/nearby \
     -H "Authorization: Bearer $TOKEN" ...
   ```

6. **Upvote Report**
   ```bash
   curl -X POST http://localhost:3000/api/v1/reports/{ID}/upvote \
     -H "Authorization: Bearer $TOKEN"
   ```

7. **Record Detection**
   ```bash
   curl -X POST http://localhost:3000/api/v1/history ...
   ```

---

## 🔍 COMMON ISSUES & SOLUTIONS

### ❌ 401 Unauthorized
- **Cause**: Missing or invalid token
- **Fix**: 
  ```bash
  # Check token is in Authorization header
  curl -H "Authorization: Bearer $TOKEN" ...
  
  # Refresh token if expired
  curl -X POST http://localhost:3000/api/v1/auth/refresh \
    -H "Content-Type: application/json" \
    -d '{"refreshToken": "your_refresh_token"}'
  ```

### ❌ 404 Not Found
- **Cause**: Endpoint doesn't exist or ID not found
- **Fix**: 
  - Check endpoint path spelling
  - Verify resource ID exists
  - Check report ID format

### ❌ CORS Error
- **Cause**: Browser blocking cross-origin request
- **Fix**: Use curl/Postman instead or check backend CORS config

### ❌ Connection Refused
- **Cause**: Backend not running
- **Fix**:
  ```bash
  # Check if backend is running
  curl http://localhost:3000/api/v1
  
  # Restart backend if needed
  npm run start:dev
  ```

---

## 📱 FLUTTER INTEGRATION TEST

Test the API service in Flutter:

```dart
import 'package:traffic_detect/services/nextjs_api_service.dart';

// In a test widget or screen
final apiService = NestJsApiService();

// Test login
final user = await apiService.login(
  email: 'test@traffic.dev',
  password: 'Test123!@#',
);

// Test create report
final report = await apiService.createReport(
  name: 'Test Report',
  latitude: 10.7769,
  longitude: 106.7009,
  violationType: 'accident',
  description: 'Test detection',
);

// Test get nearby
final nearby = await apiService.getNearbyReports(
  latitude: 10.7769,
  longitude: 106.7009,
);

print('Report ID: ${report['id']}');
print('Nearby reports: ${nearby['reports'].length}');
```

