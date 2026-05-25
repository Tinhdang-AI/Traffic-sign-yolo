# Supabase Integration Guide

## Overview
This project uses Supabase for authentication and backend services. Supabase is an open-source Firebase alternative built on PostgreSQL.

## Configuration

### Credentials
- **Supabase URL**: `https://aeigibdspuzwcwsthfhg.supabase.co`
- **Anon Key**: Stored in `lib/core/config/supabase_config.dart`

The credentials are initialized in `main.dart` when the app starts.

## Services

### AuthService (`lib/services/auth_service.dart`)
Handles all authentication-related operations:

```dart
// Sign in with email and password
await authService.signInWithEmailPassword(email, password);

// Register new user
await authService.registerWithEmailPassword(email, password);

// Update user profile
await authService.updateUserProfile(
  displayName: 'User Name',
  phoneNumber: '+84912345678',
);

// Sign out
await authService.signOut();

// Reset password
await authService.resetPassword(email);

// Get current user
final user = authService.currentUser;

// Get access token
final token = authService.accessToken;

// Listen to auth state changes
authService.authStateChanges.listen((authState) {
  final user = authState.session?.user;
});
```

### ApiService (`lib/services/api_service.dart`)
Handles API requests with automatic JWT token attachment:

```dart
final apiService = ApiService();

// GET request
final data = await apiService.get('/endpoint');

// POST request
final response = await apiService.post('/endpoint', {'key': 'value'});

// PUT request
await apiService.put('/endpoint', {'key': 'value'});

// DELETE request
await apiService.delete('/endpoint');

// Token management
await apiService.saveToken(token);
final token = await apiService.getToken();
await apiService.clearToken();
```

## Authentication Flow

### Login
1. User enters email and password on `LoginScreen`
2. `_handleLogin()` calls `AuthService.signInWithEmailPassword()`
3. On success: navigate to `MainShell`
4. On error: display error message with specific reason

### Registration
1. User fills form on `RegisterScreen`
2. `_handleRegister()` calls `AuthService.registerWithEmailPassword()`
3. Update user profile with display name
4. On success: navigate to `MainShell`
5. On error: display error message

### Auth State Management
- `AuthProvider` listens to auth state changes via `authStateChanges` stream
- Updates `_user` property when authentication state changes
- Notifies listeners for UI updates

## Error Handling

Common Supabase Auth Errors:
- **Invalid login credentials**: Email or password is incorrect
- **Email not confirmed**: User needs to verify their email
- **User already exists**: Email is already registered
- **Password too weak**: Password doesn't meet requirements

All errors are caught and user-friendly messages are displayed via `SnackBar`.

## Security Notes

1. **Never commit credentials** - Keep `supabase_config.dart` private
2. **Secure storage** - Tokens are stored using `flutter_secure_storage`
3. **JWT handling** - Tokens are automatically attached to API requests
4. **Token refresh** - Automatic refresh on 401 responses
5. **Sign out** - Always sign out when user logs out to clear tokens

## Supabase Console

Access Supabase management:
1. Go to https://supabase.com
2. Sign in with your account
3. Select the project
4. Manage users, database, and settings

## Dependencies

Add to `pubspec.yaml`:
```yaml
supabase_flutter: ^2.3.0
flutter_secure_storage: ^10.2.0
dio: ^5.9.2
```

## Environment Setup

For local development:
1. Install Flutter SDK
2. Get dependencies: `flutter pub get`
3. Run: `flutter run`

For production:
- Use environment-specific Supabase projects
- Update credentials in `supabase_config.dart`
- Ensure RLS (Row Level Security) policies are configured

## Troubleshooting

**Issue**: "Invalid Supabase URL"
- Solution: Check URL in `supabase_config.dart`

**Issue**: "Unauthorized" errors on API calls
- Solution: Ensure user is authenticated and token is valid

**Issue**: Tokens not persisting across app restart
- Solution: Check `flutter_secure_storage` platform setup (iOS/Android)

## Next Steps

1. Set up RLS (Row Level Security) in Supabase for database access
2. Create database tables for user profiles
3. Implement password reset email confirmation
4. Add email verification on registration
5. Set up OAuth providers (Google, Apple) for social auth
