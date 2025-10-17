# Demo Users Setup

Since this is for demo purposes, you need to create demo users in your Firebase Console first.

## Steps to Create Demo Users:

### 1. Go to Firebase Console
- Visit: https://console.firebase.google.com/
- Select your project: `cargo58`

### 2. Enable Authentication
- Go to **Authentication** → **Sign-in method**
- Enable **Email/Password** provider
- Click **Save**

### 3. Create Demo Users
Go to **Authentication** → **Users** → **Add user**

Create these users:

#### Admin User:
- **Email**: `admin@cargo.com`
- **Password**: `admin123`

#### Driver User:
- **Email**: `driver@cargo.com`
- **Password**: `driver123`

#### Customer User:
- **Email**: `customer@cargo.com`
- **Password**: `customer123`

### 4. Create User Documents in Firestore
Go to **Firestore Database** → **Start collection**

Create a collection called `users` with these documents:

#### Admin Document:
- **Document ID**: `[Admin's UID from Authentication]`
- **Fields**:
  - `email`: `admin@cargo.com`
  - `name`: `Admin User`
  - `phone`: `+1234567890`
  - `role`: `admin`
  - `isActive`: `true`
  - `createdAt`: `[Current timestamp]`
  - `isFirstLogin`: `false`

#### Driver Document:
- **Document ID**: `[Driver's UID from Authentication]`
- **Fields**:
  - `email`: `driver@cargo.com`
  - `name`: `Driver User`
  - `phone`: `+1234567891`
  - `role`: `driver`
  - `isActive`: `true`
  - `createdAt`: `[Current timestamp]`
  - `isFirstLogin`: `false`

#### Customer Document:
- **Document ID**: `[Customer's UID from Authentication]`
- **Fields**:
  - `email`: `customer@cargo.com`
  - `name`: `Customer User`
  - `phone`: `+1234567892`
  - `role`: `customer`
  - `isActive`: `true`
  - `createdAt`: `[Current timestamp]`
  - `isFirstLogin`: `false`

### 5. Firestore Rules (for demo)
Go to **Firestore Database** → **Rules** and use these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents for demo
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 6. Storage Rules (for demo)
Go to **Storage** → **Rules** and use these rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## After Setup:
1. Run `flutter pub get`
2. Run `flutter run`
3. Use the demo credentials to login:
   - **Admin**: `admin@cargo.com` / `admin123`
   - **Driver**: `driver@cargo.com` / `driver123`
   - **Customer**: `customer@cargo.com` / `customer123`

## Troubleshooting:
- If login fails, check that the user exists in both Authentication and Firestore
- Make sure the UID in Firestore matches the Authentication UID exactly
- Ensure all required fields are present in the Firestore documents
