
## 📋 Overview

Security rules bảo vệ Firestore database của bạn từ truy cập trái phép. Rules này cho phép:
- ✅ Bất kỳ ai cũng có thể **đọc** báo cáo công khai
- ✅ Chỉ người dùng **xác thực** mới có thể **tạo** báo cáo
- ✅ Chỉ tác giả mới có thể **xóa** báo cáo của họ
- ✅ Chỉ người dùng xác thực mới có thể **upvote** báo cáo
- ✅ Ngăn chặn batch delete/update trái phép

---

## 🔧 Cách Deploy Rules

### **Cách 1: Qua Firebase Console (Đơn giản nhất)**

1. Mở https://console.firebase.google.com
2. Chọn project của bạn → **Firestore Database**
3. Click tab **Rules** ở trên cùng
4. **Xóa** nội dung rules cũ
5. **Copy-paste** nội dung từ file `firestore.rules` vào editor
6. Click **Publish** (màu xanh, bên phải)
7. Chờ "Rules published successfully" ✅

### **Cách 2: Qua Firebase CLI (Nếu cài đặt)**

```bash
# Install Firebase CLI (một lần)
npm install -g firebase-tools

# Authenticate
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

---

## 🧪 Test Security Rules

Bạn có thể test rules ngay trong Firebase Console:

1. Vào **Firestore Database** → **Rules** tab
2. Click **Emulator** (nếu có)
3. Hoặc test manual bằng Firestore query tests

### **Test Cases để Kiểm tra:**

#### ✅ Test 1: Anonymous User có thể đọc reports
```
// Expected: ✅ ALLOW
- User: Anonymous
- Action: Read /community_reports/{reportId}
- Result: Success
```

#### ✅ Test 2: Authenticated user có thể tạo report
```
// Expected: ✅ ALLOW
- User: Authenticated (uid: user123)
- Action: Create /community_reports/doc1 with:
  {
    latitude: 10.7769,
    longitude: 106.6966,
    violationType: "speeding",
    description: "Radar at intersection",
    reportedBy: "user123",
    timestamp: now(),
    upvotes: 0,
    isVerified: false
  }
- Result: Success
```

#### ❌ Test 3: Authenticated user KHÔNG thể create report nếu reportedBy ≠ uid
```
// Expected: ❌ DENY
- User: Authenticated (uid: user123)
- Action: Create /community_reports/doc1 with:
  {
    ...
    reportedBy: "user456"  // ← Different user ID
    ...
  }
- Result: Permission Denied
```

#### ✅ Test 4: Authenticated user có thể upvote report
```
// Expected: ✅ ALLOW
- User: Authenticated
- Action: Update /community_reports/reportId
  {
    upvotes: 5 → 6  // ← Increment by 1
  }
- Result: Success
```

#### ❌ Test 5: Authenticated user KHÔNG thể tăng upvotes > 1
```
// Expected: ❌ DENY
- User: Authenticated
- Action: Update /community_reports/reportId
  {
    upvotes: 5 → 7  // ← Increment by 2 (not allowed)
  }
- Result: Permission Denied
```

#### ❌ Test 6: Authenticated user KHÔNG thể sửa description
```
// Expected: ❌ DENY
- User: Authenticated
- Action: Update /community_reports/reportId
  {
    description: "Old" → "New"
  }
- Result: Permission Denied
```

#### ✅ Test 7: Creator có thể xóa report của họ
```
// Expected: ✅ ALLOW
- User: Authenticated (uid: user123)
- Document owner: user123
- Action: Delete /community_reports/reportId
- Result: Success
```

#### ❌ Test 8: User KHÔNG thể xóa report của người khác
```
// Expected: ❌ DENY
- User: Authenticated (uid: user123)
- Document owner: user456
- Action: Delete /community_reports/reportId
- Result: Permission Denied
```

#### ❌ Test 9: Invalid report data (missing fields)
```
// Expected: ❌ DENY
- User: Authenticated
- Action: Create report WITHOUT required fields
- Result: Permission Denied
```

#### ❌ Test 10: Invalid violationType
```
// Expected: ❌ DENY
- User: Authenticated
- Action: Create report with violationType: "invalid_type"
- Result: Permission Denied
```

---

## 🛡️ Security Best Practices

### ✅ Điều đã làm:
1. **Read-only public** — Bất kỳ ai đọc được, nhưng không modify
2. **Auth required for write** — Chỉ user xác thực mới write
3. **Data validation** — Validate loại, kích thước, giá trị
4. **Document ownership** — User chỉ xóa của họ
5. **Prevent batch operations** — Firestore tự động block batch writes

### 🔒 Bảo vệ bổ sung (tùy chọn):
- Thêm **Rate Limiting** via Cloud Functions (nếu cần prevent spam)
- Thêm **Admin approval** flow cho verification
- Thêm **User reputation** tracking
- Implement **Content Moderation** via Cloud Functions

---

## ⚠️ Lưu ý quan trọng

1. **Authentication Setup**: Ứng dụng cần bật **Firebase Authentication**
   - Bạn có thể dùng **Anonymous Auth** (cho phép đọc nhưng không write)
   - Hoặc **Email/Phone Auth** (yêu cầu registration)

2. **Thay đổi `reportedBy`**: Nếu dùng Anonymous Auth, thay `reportedBy: request.auth.uid` bằng `reportedBy: "anonymous"` hoặc UUID unique per session

3. **Testing Rules**: Firebase Console có **Rules Playground** để test mà không public

---

## 📝 Tiếp Theo

Sau khi deploy rules:

1. ✅ **Test rules** bằng test cases trên
2. ✅ **Test app** offline → online sync
3. ✅ **Monitor** Firestore usage via Analytics
4. ✅ **Setup billing alerts** nếu chưa

---

## 🚀 Deploy Steps (Quick Summary)

```
1. Go to Firebase Console
2. Select Project → Firestore Database → Rules
3. Copy rules from firestore.rules
4. Paste vào editor
5. Click Publish
6. Wait for "Rules published successfully"
7. Test in app
```

Done! 🎉
