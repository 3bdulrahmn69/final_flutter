# Social Connect - Flutter + Firebase Social App

A complete social media app built with Flutter and Firebase, featuring user authentication, posts, comments, likes, and real-time updates.

## Features

### ✅ Authentication System

- Email/Password registration with 5+ input fields
- Google Sign-In integration
- Facebook Sign-In integration
- Secure user management with Firebase Auth

### ✅ User Interface

- Beautiful splash screen with animations
- Modern, responsive design
- Dark/Light mode toggle
- Smooth transitions and animations

### ✅ Social Features

- Create posts with text and images
- Real-time feed with all users' posts
- Like/Unlike posts with instant updates
- Comment system with nested conversations
- User profiles with post history
- Search functionality for posts and users

### ✅ Data Management

- Real-time updates using Firestore streams
- Image upload to Firebase Storage
- Optimized data loading and caching
- Offline support

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (latest stable version)
- Firebase account
- Android Studio / VS Code
- Git

### 2. Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - Authentication (Email/Password, Google, Facebook)
   - Cloud Firestore
   - Storage
3. Add your app to the Firebase project:
   - For Android: Add `android/app/google-services.json`
   - For iOS: Add `ios/Runner/GoogleService-Info.plist`
   - For Web: Update Firebase configuration in `lib/firebase_options.dart`

### 3. Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd flutter_application_5

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 4. Configuration

1. Update `lib/firebase_options.dart` with your Firebase project configuration
2. For Google Sign-In:
   - Add your SHA-1 fingerprint to Firebase project
   - Update `android/app/build.gradle` with your application ID
3. For Facebook Sign-In:
   - Create Facebook App at [Facebook Developers](https://developers.facebook.com/)
   - Add Facebook App ID to your project configuration

### 5. Test Data

The app includes sample data seeding functionality:

- 5 test users will be created
- Each user will have 3 posts
- Posts include various content types and timestamps

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user_model.dart
│   └── post_model.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   └── database_service.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── search_screen.dart
│   ├── comments_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── widgets/
│       ├── post_card.dart
│       └── create_post_widget.dart
└── utils/
    └── data_seeder.dart      # Test data generation
```

## Security Features

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Posts are readable by all authenticated users
    // Only the author can update/delete their posts
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
                   request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null &&
                            request.auth.uid == resource.data.userId;

      // Comments subcollection
      match /comments/{commentId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null &&
                     request.auth.uid == request.resource.data.userId;
        allow update, delete: if request.auth != null &&
                              request.auth.uid == resource.data.userId;
      }
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /posts/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                   request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
  }
}
```

## App Screenshots

The app includes:

- **Splash Screen**: Animated loading screen with app branding
- **Authentication**: Clean login/register forms with social sign-in options
- **Home Feed**: Real-time posts feed with like/comment functionality
- **Profile**: User profile with personal posts and comments
- **Search**: Powerful search functionality across posts and users
- **Comments**: Nested comment system with real-time updates

## Technologies Used

- **Flutter**: Cross-platform mobile development
- **Firebase Auth**: User authentication and management
- **Cloud Firestore**: NoSQL database with real-time updates
- **Firebase Storage**: File and image storage
- **Google Sign-In**: OAuth integration
- **Facebook Auth**: Social media authentication
- **Image Picker**: Photo selection and upload
- **Cached Network Image**: Optimized image loading

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is created for educational purposes as part of the ITI 4-month Flutter course.

---

**Note**: Remember to configure your Firebase project and update the configuration files with your actual Firebase credentials before running the app.
