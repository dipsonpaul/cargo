# Cargo Collection Management System

A comprehensive Flutter application for managing cargo collection operations with role-based access for Admin, Driver, and Customer users.

## Features

### 🔐 Authentication System
- Secure login with role-based access
- Force password change on first login
- Admin, Driver, and Customer portals

### 👨‍💼 Admin Dashboard
- **Request Management**: View pending requests and reassign declined requests
- **Driver Management**: Add, edit, delete drivers and assign credentials
- **Customer Management**: Add, edit, delete customers and assign credentials
- **Real-time Monitoring**: Track status of all collection requests
- **Notifications**: Receive alerts for all system activities

### 🚚 Driver Interface
- **Request Management**: View assigned requests with customer details
- **Accept/Decline**: Accept or decline assigned requests with reasons
- **Status Updates**: Update collection stages:
  - "Out for Collection" → Notify customer
  - "Collected" → Notify admin & customer
  - "Customer Not Available" → Upload door photo
- **Photo Capture**: Capture cargo details and package count
- **Navigation**: Direct integration with maps for pickup locations

### 👤 Customer Interface
- **Request Creation**: Add cargo collection requests with:
  - Pickup address with location services
  - Preferred collection time
  - Special instructions
- **Request Tracking**: Real-time status updates
- **Location Sharing**: Share live location when cargo is ready
- **Communication**: Chat with admin and drivers

### 💬 Real-Time Chat System
- **Multi-User Communication**: Admin ↔ Driver, Admin ↔ Customer, Driver ↔ Customer
- **WhatsApp-like Interface**: Message bubbles with timestamps
- **Message Status**: Sent, delivered, and read indicators
- **Auto Messages**: Automatic notifications for request status changes
- **System Messages**: Automated updates for request events

### 🔔 Push Notifications
- **Firebase Cloud Messaging**: Real-time push notifications
- **Event Triggers**: Driver accepts/declines, status updates, new messages
- **Local Notifications**: In-app notification system
- **Notification Management**: Mark as read, delete, and clear all

## Technology Stack

- **Framework**: Flutter 3.7.2+
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **State Management**: Riverpod
- **UI**: Material Design 3 with custom theming
- **Location Services**: Geolocator & Geocoding
- **Image Handling**: Image Picker & Cached Network Image
- **Local Storage**: Shared Preferences
- **Notifications**: Firebase Cloud Messaging & Local Notifications

## Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd cargo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
   - Download configuration files:
     - `google-services.json` for Android (place in `android/app/`)
     - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Configure Firebase Rules**

   **Firestore Rules:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can read/write their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Requests - users can read/write their own requests
       match /requests/{requestId} {
         allow read, write: if request.auth != null;
       }
       
       // Conversations - participants can read/write
       match /conversations/{conversationId} {
         allow read, write: if request.auth != null && 
           (resource.data.participant1Id == request.auth.uid || 
            resource.data.participant2Id == request.auth.uid);
       }
       
       // Messages within conversations
       match /conversations/{conversationId}/messages/{messageId} {
         allow read, write: if request.auth != null;
       }
       
       // Notifications - users can read their own notifications
       match /notifications/{notificationId} {
         allow read, write: if request.auth != null && 
           resource.data.userId == request.auth.uid;
       }
     }
   }
   ```

   **Storage Rules:**
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

5. **Run the application**
   ```bash
   flutter run
   ```

## Demo Credentials

For testing purposes, you can use these demo credentials:

- **Admin**: `admin@cargo.com` / `admin123`
- **Driver**: `driver@cargo.com` / `driver123`
- **Customer**: `customer@cargo.com` / `customer123`

> **Note**: These are demo credentials. In production, create real user accounts through the admin panel.

## Project Structure

```
lib/
├── models/                 # Data models
│   ├── user_model.dart
│   ├── request_model.dart
│   ├── chat_model.dart
│   └── notification_model.dart
├── services/               # Business logic
│   ├── auth_service.dart
│   ├── request_service.dart
│   ├── chat_service.dart
│   └── notification_service.dart
├── screens/               # UI screens
│   ├── splash_screen.dart
│   ├── admin/             # Admin screens
│   ├── driver/            # Driver screens
│   ├── customer/          # Customer screens
│   └── auth/              # Authentication screens
├── main.dart              # App entry point
└── firebase_options.dart  # Firebase configuration
```

## Key Features Implementation

### Role-Based Access Control
- Users are assigned roles (Admin, Driver, Customer) during account creation
- Each role has access to specific features and data
- Secure authentication with Firebase Auth

### Real-Time Updates
- Firestore listeners provide real-time data synchronization
- Automatic UI updates when data changes
- Live chat functionality with message status tracking

### Location Services
- GPS-based location detection for pickup addresses
- Geocoding for address validation
- Integration with maps for navigation

### Photo Management
- Camera integration for cargo and door photos
- Firebase Storage for secure image hosting
- Image compression and optimization

### Notification System
- Firebase Cloud Messaging for push notifications
- Local notifications for in-app alerts
- Notification management and history

## Deployment

### Android
1. Generate signed APK:
   ```bash
   flutter build apk --release
   ```

2. Or build app bundle:
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. Build for iOS:
   ```bash
   flutter build ios --release
   ```

2. Open in Xcode and archive for App Store

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

## Roadmap

- [ ] Advanced analytics and reporting
- [ ] Multi-language support
- [ ] Offline mode functionality
- [ ] Advanced driver routing optimization
- [ ] Customer rating and feedback system
- [ ] Integration with third-party logistics APIs
- [ ] Advanced notification customization
- [ ] Bulk operations for admin users