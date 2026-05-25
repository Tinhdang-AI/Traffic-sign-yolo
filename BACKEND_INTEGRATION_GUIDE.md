# 🚀 Backend Integration Guide - NestJS + Flutter

**Backend URL**: `http://localhost:3000/api/v1`

---

## 1️⃣ TEST BACKEND WITH CURL/POSTMAN

### ✅ Health Check
```bash
curl -X GET http://localhost:3000/api/v1
```

### 🔐 Authentication Endpoints

#### Register
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "displayName": "Test User"
  }'
```

#### Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```
**Response**: `{ "access_token": "...", "refresh_token": "..." }`

#### Get Current User
```bash
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <access_token>"
```

### 📍 Reports Endpoints

#### Create Report
```bash
curl -X POST http://localhost:3000/api/v1/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access_token>" \
  -d '{
    "name": "Traffic Report",
    "latitude": 10.7769,
    "longitude": 106.7009,
    "violationType": "accident",
    "description": "Motorcycle crash at intersection"
  }'
```

#### Get Nearby Reports
```bash
curl -X GET "http://localhost:3000/api/v1/reports/nearby?latitude=10.7769&longitude=106.7009&radiusKm=5" \
  -H "Authorization: Bearer <access_token>"
```

#### Upvote Report
```bash
curl -X POST http://localhost:3000/api/v1/reports/:id/upvote \
  -H "Authorization: Bearer <access_token>"
```

### 🔍 Detection Endpoints

#### Record Detection
```bash
curl -X POST http://localhost:3000/api/v1/history \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access_token>" \
  -d '{
    "latitude": 10.7769,
    "longitude": 106.7009,
    "confidence": 0.95,
    "detectionType": "accident"
  }'
```

#### Get Detection History
```bash
curl -X GET "http://localhost:3000/api/v1/history?limit=10&offset=0" \
  -H "Authorization: Bearer <access_token>"
```

---

## 2️⃣ POSTMAN COLLECTION

**Import in Postman:**

1. Create new Collection: `Traffic Detect Backend`
2. Add requests with Bearer token auth
3. Use `{{baseUrl}}` = `http://localhost:3000/api/v1`

---

## 3️⃣ ERROR HANDLING IMPLEMENTATION

Create error helper (`lib/core/errors/api_error_handler.dart`):

```dart
class ApiErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return 'Invalid request';
        case 401:
          return 'Unauthorized - Please login again';
        case 403:
          return 'Forbidden';
        case 404:
          return 'Resource not found';
        case 500:
          return 'Server error - Please try again later';
        default:
          return error.message;
      }
    }
    return 'Unknown error occurred';
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
```

---

## 4️⃣ LOADING STATES WIDGET

Create reusable loading widget (`lib/widgets/loading_overlay.dart`):

```dart
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  if (message != null) ...[
                    SizedBox(height: 16),
                    Text(
                      message!,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

---

## 5️⃣ SCREEN INTEGRATION EXAMPLES

### Login Screen Integration

```dart
import 'package:traffic_detect/services/nextjs_api_service.dart';
import 'package:traffic_detect/core/errors/api_error_handler.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = NestJsApiService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ApiErrorHandler.showErrorSnackBar(context, 'Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ApiErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Logging in...',
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleLogin,
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### AR Detection Screen Integration

```dart
class ARDetectionScreen extends StatefulWidget {
  @override
  State<ARDetectionScreen> createState() => _ARDetectionScreenState();
}

class _ARDetectionScreenState extends State<ARDetectionScreen> {
  final _apiService = NestJsApiService();
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  Future<void> _reportTraffic(String violationType) async {
    if (_latitude == null || _longitude == null) {
      ApiErrorHandler.showErrorSnackBar(context, 'Location not available');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.createReport(
        name: 'AR Detection Report',
        latitude: _latitude!,
        longitude: _longitude!,
        violationType: violationType,
        description: 'Detected via AR Camera',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Sending report...',
      child: Scaffold(
        appBar: AppBar(title: Text('AR Detection')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _reportTraffic('accident'),
                icon: Icon(Icons.warning),
                label: Text('Report Accident'),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _reportTraffic('traffic'),
                icon: Icon(Icons.directions_car),
                label: Text('Report Traffic'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## ✅ Checklist

- [ ] Test all curl commands
- [ ] Verify NestJS backend responses
- [ ] Integrate login/register screens
- [ ] Integrate AR detection reports
- [ ] Integrate map with nearby reports
- [ ] Add error handling to all screens
- [ ] Test loading states
- [ ] Test error messages

