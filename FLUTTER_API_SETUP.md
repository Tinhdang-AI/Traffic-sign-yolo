# Flutter API Integration Guide

## Dependencies Required

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.0.0          # Optional: for state management
```

## Installation

1. Run `flutter pub get` to install dependencies
2. Copy the model files to `lib/models/`
3. Copy the service files to `lib/services/`

## Configuration

### Step 1: Update API Base URL

In `lib/services/api_client.dart`, change the `_baseUrl`:

```dart
// Replace with your actual backend URL
static const String _baseUrl = 'http://192.168.1.100:3000/api/v1';
```

**For different environments:**
- **Local development**: `http://192.168.x.x:3000/api/v1`
- **Production**: `https://yourdomain.com/api/v1`

### Step 2: Initialize API Client

In `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  await apiClient.init();

  // Initialize services
  final authService = AuthService(apiClient);
  final reportService = ReportService(apiClient);
  final detectionService = DetectionService(apiClient);
  final uploadService = UploadService(apiClient);

  runApp(MyApp(
    apiClient: apiClient,
    authService: authService,
    reportService: reportService,
    detectionService: detectionService,
    uploadService: uploadService,
  ));
}
```

## Usage Examples

### Authentication

#### Register
```dart
try {
  final response = await authService.register(
    email: 'user@example.com',
    password: 'securePassword123',
    displayName: 'John Doe',
  );
  print('User registered: ${response.user.displayName}');
} catch (e) {
  print('Registration error: $e');
}
```

#### Login
```dart
try {
  final response = await authService.login(
    email: 'user@example.com',
    password: 'securePassword123',
  );
  print('Logged in as: ${response.user.email}');
} catch (e) {
  print('Login error: $e');
}
```

#### Get Current User
```dart
try {
  final user = await authService.getCurrentUser();
  print('User: ${user.displayName}');
} catch (e) {
  print('Error: $e');
}
```

#### Logout
```dart
try {
  await authService.logout();
  print('Logged out');
} catch (e) {
  print('Logout error: $e');
}
```

### Reports

#### Create Report
```dart
try {
  final report = await reportService.createReport(
    name: 'Unauthorized Parking',
    latitude: 21.0285,
    longitude: 105.8542,
    violationType: 'parking',
    description: 'Double parked on main street',
    imageUrl: 'https://supabase.../image.jpg',
  );
  print('Report created: ${report.id}');
} catch (e) {
  print('Error: $e');
}
```

#### Get All Reports
```dart
try {
  final reports = await reportService.getAllReports(limit: 50, offset: 0);
  print('Reports: ${reports.length}');
} catch (e) {
  print('Error: $e');
}
```

#### Get Nearby Reports
```dart
try {
  final nearbyReports = await reportService.getNearbyReports(
    latitude: 21.0285,
    longitude: 105.8542,
    radiusKm: 5,
  );
  print('Nearby reports: ${nearbyReports.length}');
  
  // Calculate distance for each report
  for (var report in nearbyReports) {
    print('${report.name} - ${report.distance.toStringAsFixed(2)} km away');
  }
} catch (e) {
  print('Error: $e');
}
```

#### Upvote Report
```dart
try {
  await reportService.upvoteReport(reportId);
  print('Report upvoted');
} catch (e) {
  print('Error: $e');
}
```

#### Delete Report
```dart
try {
  await reportService.deleteReport(reportId);
  print('Report deleted');
} catch (e) {
  print('Error: $e');
}
```

### Detection History

#### Record Detection
```dart
try {
  final detection = await detectionService.recordDetection(
    latitude: 21.0285,
    longitude: 105.8542,
    confidence: 0.92,
    detectionType: 'speeding',
    metadata: {
      'speed': 65,
      'speedLimit': 50,
    },
  );
  print('Detection recorded: ${detection.id}');
} catch (e) {
  print('Error: $e');
}
```

#### Get Detection History
```dart
try {
  final history = await detectionService.getDetectionHistory(limit: 50, offset: 0);
  print('Detection history: ${history.length} items');
  
  for (var detection in history) {
    print('${detection.detectionType} at ${detection.latitude}, ${detection.longitude}');
  }
} catch (e) {
  print('Error: $e');
}
```

### File Upload

#### Upload Image
```dart
try {
  final upload = await uploadService.uploadImage('/path/to/image.jpg');
  print('Image uploaded: ${upload.url}');
  
  // Use the URL in your report
  final report = await reportService.createReport(
    name: 'Report with image',
    latitude: 21.0285,
    longitude: 105.8542,
    violationType: 'parking',
    imageUrl: upload.url,
  );
} catch (e) {
  print('Upload error: $e');
}
```

## Error Handling

All services throw exceptions that extend `ApiException`:

```dart
try {
  await authService.login(email: 'user@example.com', password: 'wrong');
} on UnauthorizedException catch (e) {
  print('Invalid credentials: $e');
} on ApiException catch (e) {
  print('API error: $e');
}
```

## State Management with Provider

For better state management, consider using Provider:

```dart
// lib/providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider(this._authService);

  Future<void> login(String email, String password) async {
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      _user = response.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
```

## Common Issues

### 401 Unauthorized
- Token expired: Implement token refresh logic
- Invalid token: Re-login required

### 403 Forbidden
- Admin endpoints require admin role
- Check user permissions

### 429 Too Many Requests
- Rate limit exceeded
- Implement exponential backoff

### Network Error
- Check backend URL configuration
- Ensure backend is running
- Check network connectivity

## Best Practices

1. **Always initialize ApiClient first** in main.dart
2. **Store tokens securely** using flutter_secure_storage
3. **Implement error handling** for all API calls
4. **Use try-catch blocks** for network operations
5. **Cache data locally** when possible
6. **Refresh tokens** before expiration
7. **Test with real backend** before deployment
