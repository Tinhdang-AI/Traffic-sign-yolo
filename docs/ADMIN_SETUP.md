# 🔐 Admin Setup Guide - Supabase

## Step 1: Run SQL Migration

1. **Go to Supabase Dashboard** → Project → SQL Editor
2. **Create new query** and paste the SQL from `supabase/migrations/profiles_table.sql`
3. **Run the query** (⚡ icon)

## Step 2: Create Admin User

You have 2 options:

### Option A: Via Supabase Auth UI (Recommended for first admin)

1. Go to **Auth** → **Users**
2. Click **"Add user"** button
3. Enter email and password
4. Copy the **User ID** (UUID)

### Option B: Via SQL (for automation)

```sql
-- Create auth user (replace email/password)
-- This won't work directly in SQL Editor - use Supabase CLI or Auth API
```

## Step 3: Seed Admin Profile

Once you have the User ID, run this SQL:

```sql
INSERT INTO profiles (id, display_name, email, is_admin, created_at, updated_at)
VALUES (
  'YOUR_USER_ID_HERE',  -- Replace with actual UUID from step 2
  'Admin',
  'admin@gmail.com',
  true,
  now(),
  now()
)
ON CONFLICT (id) DO UPDATE
SET is_admin = EXCLUDED.is_admin,
    updated_at = now();
```

**Example with real UUID:**

```sql
INSERT INTO profiles (id, display_name, email, is_admin, created_at, updated_at)
VALUES (
  '39bab503-042e-4a27-af62-2ec82e293e85',
  'Admin',
  'admin@gmail.com',
  true,
  now(),
  now()
)
ON CONFLICT (id) DO UPDATE
SET is_admin = EXCLUDED.is_admin,
    updated_at = now();
```

## Step 4: Verify in Flutter

```dart
final profileService = ProfileService();
final isAdmin = await profileService.isCurrentUserAdmin();
print('Is admin: $isAdmin');
```

## Policies Explained

| Policy                          | Effect                                     |
| ------------------------------- | ------------------------------------------ |
| **Public profiles viewable**    | Everyone can see profiles (name, avatar)   |
| **Users update own profile**    | Users can only edit their own profile data |
| **Only admins modify is_admin** | Only admins can change admin status        |

## Security Notes

- ✅ Admins are read from `profiles.is_admin` (not from claims)
- ✅ RLS prevents non-admins from modifying `is_admin` column
- ✅ `auth.uid() = id` ensures users can only update their own profiles
- ✅ Email is unique to prevent duplicates
