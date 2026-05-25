# Flutter API Integration - Quick Reference

## 📋 Files Structure

```
lib/
├── models/
│   ├── user_model.dart              # User & Auth models
│   ├── report_model.dart            # Report models
│   ├── detection_model.dart         # Detection models (traffic_detect only)
│   └── api_response_model.dart      # Response wrappers
├── services/
│   ├── api_client.dart              # Base HTTP client
│   ├── auth_service.dart            # Authentication
│   ├── report_service.dart          # Reports
│   ├── detection_service.dart       # Detections (traffic_detect only)
│   └── upload_service.dart          # File uploads (traffic_detect only)
└── main.dart                        # Initialization
```

## 🔑 Setup Steps

1. **Add Dependencies**
   ```bash
   flutter pub add http flutter_secure_storage provider
   ```

2. **Update API URL** in `lib/services/api_client.dart`
   ```dart
   static const String _baseUrl = 'http://192.168.x.x:3000/api/v1';
   ```

3. **Initialize in main.dart**
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     final apiClient = ApiClient();
     await apiClient.init();
     runApp(MyApp());
   }
   ```

## 🔐 Authentication

```dart
// Register
final response = await authService.register(
  email: 'user@example.com',
  password: 'pass123',
  displayName: 'John Doe',
);

// Login
final response = await authService.login(
  email: 'user@example.com',
  password: 'pass123',
);

// Get Current User
final user = await authService.getCurrentUser();

// Logout
await authService.logout();
```

## 📍 Reports

```dart
// Create
await reportService.createReport(
  name: 'Name',
  latitude: 21.0285,
  longitude: 105.8542,
  violationType: 'parking',
  description: 'Desc',
  imageUrl: 'https://...',
);

// Get All
final reports = await reportService.getAllReports(
  limit: 50,
  offset: 0,
);

// Get Nearby
final nearby = await reportService.getNearbyReports(
  latitude: 21.0285,
  longitude: 105.8542,
  radiusKm: 5,
);

// Upvote
await reportService.upvoteReport(reportId);

// Delete
await reportService.deleteReport(reportId);
```

## 📊 Detection History (traffic_detect only)

```dart
// Record Detection
await detectionService.recordDetection(
  latitude: 21.0285,
  longitude: 105.8542,
  confidence: 0.92,
  detectionType: 'speeding',
  metadata: {'speed': 65, 'speedLimit': 50},
);

// Get History
final history = await detectionService.getDetectionHistory(
  limit: 50,
  offset: 0,
);
```

## 📤 Upload (traffic_detect only)

```dart
final upload = await uploadService.uploadImage('/path/to/image.jpg');
print(upload.url); // Use in reports
```

## ⚠️ Error Handling

```dart
try {
  await authService.login(email: 'user@example.com', password: 'wrong');
} on UnauthorizedException {
  print('Invalid credentials');
} on ForbiddenException {
  print('No permission');
} on NotFoundException {
  print('Not found');
} on RateLimitException {
  print('Too many requests');
} on ApiException catch (e) {
  print('Error: $e');
}
```

## 🔄 Token Management

Tokens are automatically stored in secure storage:
- Access token: `access_token`
- Refresh token: `refresh_token`

Tokens are cleared on logout or 401 error.

## 🌐 API Endpoints

| Endpoint | Method | Auth |
|----------|--------|------|
| `/auth/register` | POST | No |
| `/auth/login` | POST | No |
| `/auth/me` | GET | Yes |
| `/auth/logout` | POST | Yes |
| `/reports` | POST/GET | Yes/No |
| `/reports/nearby` | GET | No |
| `/reports/{id}/upvote` | POST | Yes |
| `/reports/{id}` | DELETE | Yes |
| `/detections/history` | POST/GET | Yes |
| `/upload/image` | POST | Yes |

## 💡 Best Practices

✅ **Do:**
- Initialize ApiClient once in main.dart
- Use try-catch for all API calls
- Store tokens securely
- Validate input before API calls
- Implement token refresh logic

❌ **Don't:**
- Hardcode tokens in code
- Make multiple ApiClient instances
- Ignore 401 responses
- Trust all error messages
- Share tokens in logs

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| 404 API Not Found | Check backend is running |
| 401 Unauthorized | Re-login, tokens may be expired |
| Network Error | Check internet, backend URL |
| 429 Too Many Requests | Implement backoff strategy |
| Certificate Error | Disable HTTPS validation (dev only) |

## 📚 Documentation

- Backend API: See `API_DOCUMENTATION.md` in backend
- Database Schema: See `SUPABASE_SETUP.md` in backend
- Setup Guide: See `FLUTTER_API_SETUP.md`
