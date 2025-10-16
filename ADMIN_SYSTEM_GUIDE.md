# Admin System Setup Guide

## 🔐 Admin Login System

### Default Admin Credentials

```
Username: admin
Password: adminpassword!
```

### Access Points

#### 1. **Teacher Login Page** (Landing Page)

- Regular teachers login here with their Supabase credentials
- Has a link at the bottom to access Admin Login

#### 2. **Admin Login Page** (`/admin-login`)

- Dedicated admin portal
- Accepts default credentials (admin/adminpassword!)
- Also accepts database admin users with role='admin'

#### 3. **Admin Dashboard** (`/admin-dashboard`)

- User management interface
- View all users (teachers and admins)
- Add new users
- Delete users
- See statistics

---

## 🎯 Features

### Admin Dashboard Features:

1. **User Statistics**

   - Total users count
   - Total teachers count
   - Total admins count

2. **User Management**

   - View all users in a list
   - Each user shows:
     - Name
     - Email
     - Role (Teacher/Admin)
   - Add new users with form
   - Delete users with confirmation

3. **Add User Dialog**
   - Name field
   - Email field (with validation)
   - Password field (minimum 6 characters)
   - Role dropdown (Teacher/Admin)
   - Creates user in Supabase Auth
   - Adds user record to 'users' table

---

## 🗄️ Database Setup

### Required Table: `users`

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  role TEXT NOT NULL CHECK (role IN ('teacher', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read
CREATE POLICY "Users can view all users"
ON users FOR SELECT
TO authenticated
USING (true);

-- Policy: Allow admins to insert
CREATE POLICY "Admins can insert users"
ON users FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- Policy: Allow admins to delete
CREATE POLICY "Admins can delete users"
ON users FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);
```

---

## 🚀 Usage

### For Default Admin:

1. Navigate to the landing page
2. Click "Admin Login" at the bottom
3. Enter credentials:
   - Username: `admin`
   - Password: `adminpassword!`
4. Access the admin dashboard

### For Database Admin Users:

1. First, an existing admin must create an admin user through the dashboard
2. New admin can then login with their email and password
3. Access the same admin dashboard

### Teacher Login Flow:

1. Teachers use the main landing page
2. Login with their Supabase credentials
3. Must have role='teacher' in the database
4. Redirected to `/homepage`

---

## 🔒 Security Notes

1. **Default Credentials**: The hardcoded admin credentials bypass database checks
2. **Role Verification**: All other logins check the user's role in the database
3. **Access Control**: Only users with role='admin' can access admin features
4. **Teacher Isolation**: Teachers cannot access admin dashboard

---

## 📱 Navigation Routes

- `/` - Teacher Login (Landing Page)
- `/homepage` - Teacher Dashboard
- `/enrollment` - Student Enrollment
- `/admin-login` - Admin Login Portal
- `/admin-dashboard` - Admin User Management

---

## 🎨 UI Features

- Modern design using Tulai Design System
- Responsive layout
- Loading states
- Error handling
- Success/error notifications
- Confirmation dialogs for destructive actions
- Role badges (color-coded)
- Statistics cards

---

## 📝 TODO / Future Enhancements

- [ ] Add user edit functionality
- [ ] Add password reset for users
- [ ] Add user search/filter
- [ ] Add pagination for large user lists
- [ ] Add audit log for admin actions
- [ ] Add ability to disable users instead of deleting
- [ ] Add bulk user import (CSV)
- [ ] Add email notifications for new users
- [ ] Change default admin password
- [ ] Add two-factor authentication
