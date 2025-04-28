# Finance App

A personal finance management application built with Flutter to help users track expenses, manage budgets, visualize spending patterns, and make informed financial decisions.

## Features

- **User Authentication**
  - Email and password authentication
  - Social logins (Google, Facebook)
  - Biometric authentication for secure access

- **Financial Management**
  - Expense tracking and categorization
  - Budget creation and monitoring
  - Income tracking
  - Financial goal setting

- **Receipt Scanning**
  - OCR-powered receipt scanning using Google ML Kit
  - Automatic expense entry from scanned receipts

- **Data Visualization**
  - Interactive charts and graphs for expense analysis
  - Budget progress visualization
  - Spending patterns and trends

- **Data Management**
  - Cloud synchronization with Firebase
  - Local data storage for offline access
  - CSV export/import functionality

- **Notifications**
  - Budget alerts
  - Bill payment reminders
  - Financial goal progress updates

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Flutter Bloc
- **Backend**: Firebase (Authentication, Cloud Firestore)
- **Local Storage**: Shared Preferences
- **Navigation**: Go Router
- **Data Visualization**: FL Chart
- **ML & Text Recognition**: Google ML Kit

## Getting Started

### Prerequisites

- Flutter SDK (version 3.7.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase account

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/DOAN-K16-FIT-HAUI/TranDucLuong.git
   cd finance_app
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Set up Firebase
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)
   - Enable Authentication methods in Firebase Console
   - Set up Cloud Firestore database

4. Run the app
   ```bash
   flutter run
   ```

## Project Structure

```
finance_app/
├── lib/
│   ├── config/                   # App configuration
│   ├── core/                     # Core functionality
│   ├── data/                     # Data layer
│   │   ├── models/               # Data models
│   │   ├── repositories/         # Repositories
│   │   └── sources/              # Data sources
│   ├── domain/                   # Business logic
│   │   ├── entities/             # Business entities
│   │   ├── repositories/         # Repository interfaces
│   │   └── usecases/             # Use cases
│   ├── presentation/             # UI layer
│   │   ├── blocs/                # BLoC state management
│   │   ├── pages/                # App pages
│   │   └── widgets/              # Reusable widgets
│   └── main.dart                 # Entry point
├── assets/                       # App assets
└── test/                         # Tests
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- All the package maintainers for their contributions
