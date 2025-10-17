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



## Demo Credentials

For testing purposes, you can use these demo credentials:

- **Admin**: `admin@cargo.com` / `admin123`
- **Driver**: `driver@cargo.com` / `driver123`
- **Customer**: `customer@cargo.com` / `customer123`


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


### Notification System
- Firebase Cloud Messaging for push notifications
- Local notifications for in-app alerts
- Notification management and history
