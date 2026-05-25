# Hướng Dẫn Kết Nối Next.js Backend

## 📋 Cấu Hình

### 1. Cập nhật URL Next.js
**File**: `lib/services/api_service.dart`

```dart
static const String nextjsApiUrl = 'http://your-nextjs-api.com'; // Thay URL của bạn
// Hoặc local: 'http://192.168.1.x:3000'
```

### 2. Supabase Token tự động được gửi lên
Mỗi request sẽ tự động kèm theo Supabase token:
```
Authorization: Bearer <supabase_token>
```

---

## 🔌 Cách Sử Dụng

### Import service
```dart
import 'package:traffic_detect/services/nextjs_api_service.dart';

final apiService = NextjsApiService();
```

### Gọi API từ một màn hình
```dart
class ExampleScreen extends StatefulWidget {
  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _apiService = NextjsApiService();
  bool _isLoading = false;

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Gọi API Next.js
      final reports = await _apiService.getReports(
        latitude: 10.7769,
        longitude: 106.7009,
        radiusKm: 5,
      );
      print('Reports: $reports');
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: _fetchData,
        child: _isLoading ? CircularProgressIndicator() : Text('Fetch Data'),
      ),
    );
  }
}
```

---

## 📡 Các Endpoint Có Sẵn

### 1. Tạo báo cáo giao thông
```dart
await apiService.createTrafficReport(
  latitude: 10.7769,
  longitude: 106.7009,
  reportType: 'accident', // 'accident', 'traffic', 'construction'
  description: 'Xe máy va chạm tại ngã tư',
  imageUrls: ['url1', 'url2'],
);
```

### 2. Lấy danh sách báo cáo gần đó
```dart
final reports = await apiService.getReports(
  latitude: 10.7769,
  longitude: 106.7009,
  radiusKm: 5,
);
```

### 3. Lấy thống kê giao thông
```dart
final stats = await apiService.getTrafficStats(
  latitude: 10.7769,
  longitude: 106.7009,
);
```

### 4. Cập nhật vị trí người dùng
```dart
await apiService.updateUserLocation(
  latitude: 10.7769,
  longitude: 106.7009,
);
```

### 5. Gọi API custom
```dart
final result = await apiService.callApi(
  '/api/your-endpoint',
  method: 'POST',
  data: {'key': 'value'},
);
```

---

## 🔐 Xác Thực từ Next.js Backend

### Next.js cần verify Supabase token
```javascript
// pages/api/reports.js
import { createClient } from '@supabase/supabase-js';

export default async function handler(req, res) {
  const token = req.headers.authorization?.split('Bearer ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Verify token với Supabase
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );

  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  // User đã được xác thực
  console.log('User:', user.id);

  // Xử lý request...
  return res.status(200).json({ success: true });
}
```

---

## 🌐 Cấu Hình CORS (Next.js)

**next.config.js**
```javascript
module.exports = {
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Credentials', value: 'true' },
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,POST,PUT,DELETE' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type,Authorization' },
        ],
      },
    ];
  },
};
```

---

## 📍 Ví Dụ: Gửi báo cáo từ AR Detection Screen

```dart
class ARDetectionScreen extends StatefulWidget {
  @override
  State<ARDetectionScreen> createState() => _ARDetectionScreenState();
}

class _ARDetectionScreenState extends State<ARDetectionScreen> {
  final _apiService = NextjsApiService();

  Future<void> _reportTraffic(String type) async {
    try {
      final response = await _apiService.createTrafficReport(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        reportType: type,
        description: 'Phát hiện từ AR',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Báo cáo đã gửi: $response')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _reportTraffic('accident'),
          child: Text('Báo cáo tai nạn'),
        ),
      ),
    );
  }
}
```

---

## 🐛 Troubleshooting

### Lỗi: "Unauthorized"
- ✅ Kiểm tra Supabase token có hợp lệ
- ✅ Kiểm tra token không hết hạn
- ✅ Refresh token: `await _supabase.auth.refreshSession()`

### Lỗi: "Connection refused"
- ✅ Kiểm tra URL Next.js đúng
- ✅ Kiểm tra Next.js server đang chạy
- ✅ Kiểm tra firewall cho phép kết nối

### Lỗi: CORS
- ✅ Cấu hình CORS đúng trong Next.js
- ✅ Kiểm tra headers `Authorization`

---

## 📝 Bước Tiếp Theo

1. Cung cấp URL Next.js backend
2. Cấu hình API endpoints trong Next.js
3. Test kết nối với curl hoặc Postman
4. Integrate vào các screens (Login, AR Detection, Map, etc)
5. Xử lý lỗi và loading states
