
## 🔐 Why Authentication?

Security rules require user authentication to:
- ✅ Verify report creator identity
- ✅ Prevent anonymous spam
- ✅ Allow only creator to delete their reports
- ✅ Track user contributions

---

## 🚀 Quick Setup (Firebase Anonymous Auth)

### Option 1: Anonymous Auth (Recommended for MVP)

**Advantage**: Users không cần login, nhưng mỗi session có unique ID
**Disadvantage**: User mất reports nếu uninstall app

#### Step 1: Enable in Firebase Console

1. Go to https://console.firebase.google.com
2. Select your project → **Authentication**
3. Click **Sign-in method** tab
4. Enable **Anonymous** ✅
5. Click **Save**

#### Step 2: Update `pubspec.yaml`

```yaml
dependencies:
  firebase_auth: ^5.5.0  # Already added
```

#### Step 3: Create `auth_service.dart`

Create file: `lib/services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Get current user ID (anonymous or authenticated)
  Future<String> getUserId() async {
    User? user = _auth.currentUser;
    
    // If not signed in, sign in anonymously
    if (user == null) {
      try {
        final userCredential = await _auth.signInAnonymously();
        user = userCredential.user;
        debugPrint('✅ Anonymous user signed in: ${user?.uid}');
      } catch (e) {
        debugPrint('❌ Failed to sign in anonymously: $e');
        rethrow;
      }
    }
    
    return user!.uid;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user UID
  String? get currentUid => _auth.currentUser?.uid;

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('✅ User signed out');
  }
}
```

#### Step 4: Update `community_service.dart`

Replace the `createReport` method:

```dart
import 'package:traffic_detect/services/auth_service.dart';

Future<String> createReport({
  required double latitude,
  required double longitude,
  required String violationType,
  required String description,
  required String? imageUrl,
}) async {
  try {
    final userId = await AuthService().getUserId();  // ← Get auth user ID
    final reportId = const Uuid().v4();
    final now = DateTime.now();

    // Save to local database immediately
    await _dbService.insertPendingReport(
      id: reportId,
      latitude: latitude,
      longitude: longitude,
      violationType: violationType,
      description: description,
      timestamp: now,
      reportedBy: userId,  // ← Use auth UID
      imageUrl: imageUrl,
    );

    debugPrint('✅ Report created and saved locally: $reportId');

    // Trigger sync in background
    _syncService.syncNow();

    return reportId;
  } catch (e) {
    debugPrint('❌ Error creating report: $e');
    rethrow;
  }
}
```

#### Step 5: Update UI to remove `reportedBy` parameter

In `community_report_screen.dart`, update `_submitReport`:

```dart
await _communityService.createReport(
  latitude: position.latitude,
  longitude: position.longitude,
  violationType: violationType,
  description: description.isEmpty ? 'No additional details' : description,
  imageUrl: null,
  // ← Remove reportedBy parameter
);
```

#### Step 6: Update `sync_service.dart`

Firestore sync now uses auth user instead of hardcoded ID. No changes needed - rules will verify `request.auth.uid`.

---

## 🧪 Test Authentication

### Test 1: Check user is authenticated

```dart
final userId = await AuthService().getUserId();
print('User ID: $userId');  // Should print a Firebase UID
```

### Test 2: Create report as authenticated user

```dart
await communityService.createReport(
  latitude: 10.7769,
  longitude: 106.6966,
  violationType: 'speeding',
  description: 'Test report',
  imageUrl: null,
);
// Should succeed ✅
```

### Test 3: Verify report in Firestore

1. Open Firebase Console
2. Go to **Firestore Database**
3. Check **community_reports** collection
4. Verify `reportedBy` field = user's UID (not timestamp)

---

## 🔄 Deploy Steps

1. ✅ Enable Anonymous Auth in Firebase Console
2. ✅ Add `auth_service.dart`
3. ✅ Update `community_service.dart` to use `AuthService`
4. ✅ Update UI to remove `reportedBy` parameter
5. ✅ Deploy Firestore security rules (from firestore.rules)
6. ✅ Test create → Firestore should accept

---

## 🛡️ Security Rules (Final)

After auth setup, rules will enforce:

```firestore
- Read: Anyone (anonymous OK)
- Create: Only authenticated users, reportedBy = their UID
- Update: Only for upvotes (increment by 1)
- Delete: Only creator
```

This prevents:
- ❌ Anonymous submissions
- ❌ Impersonation (reportedBy ≠ actual user)
- ❌ Batch deletes
- ❌ Unauthorized modifications

---

## 📝 Next Steps

1. Create `auth_service.dart`
2. Update `community_service.dart`
3. Update `community_report_screen.dart`
4. Deploy firestore rules
5. Test end-to-end
