# Expense Tracker

A simple and clean Expense Tracker mobile application built with Flutter, Dart, Firebase, and Cloud Firestore.

The application allows users to add, edit, delete, view, and filter expenses while automatically calculating the total expenses for the current month.

This project was developed as part of a Flutter practical assessment.

---

## Features Implemented

### Expense Management

- Add new expenses
- Edit existing expenses
- Delete expenses
- Delete confirmation before removing an expense
- View expense history
- Real-time expense updates using Cloud Firestore

### Expense Details

Each expense contains:

- Title
- Amount
- Category
- Date
- Optional note/description

### Expense Categories

The following categories are available:

- Food
- Transport
- Shopping
- Bills
- Entertainment
- Health
- Education
- Other

### Expense Summary

- Displays the total expenses for the current month
- Automatically recalculates the monthly total when expenses are added, edited, or deleted
- Expenses from other months are excluded from the current-month total

### Filtering

Expenses can be filtered by:

- Category
- Date range

Users can also clear the active filters to return to the currently selected
month's expense history.

### Form Validation

The expense form includes validation for:

- Required title
- Required amount
- Valid numeric amount
- Amount greater than zero
- Category selection
- Date selection

The note/description field is optional.

### Application States

The application handles:

- Loading state while retrieving Firebase data
- Empty state when no expenses exist
- No-results state when filters return no matching expenses
- Error state when expense data cannot be retrieved
- Saving state while an expense is being stored
- User feedback when delete/save operations fail

---

## Technologies Used

- Flutter
- Dart
- Firebase
- Cloud Firestore
- Material 3

---

## Packages Used

The main Flutter packages used in the project are:

### firebase_core

Used to initialize and connect the Flutter application with Firebase.

### cloud_firestore

Used to store, retrieve, update, delete, and listen to expense data in Cloud Firestore.

### cupertino_icons

Provides additional icon support for Flutter.

The exact package versions used by the project are available in `pubspec.yaml`.

---

## Firebase Implementation

Cloud Firestore is used as the application's persistent database.

Expense information is stored inside an `expenses` collection.

Example structure:

```text
expenses
│
├── documentId
│   ├── title
│   ├── amount
│   ├── category
│   ├── date
│   ├── note
│   └── createdAt
```

The application supports the four main CRUD operations:

| Operation | Implementation |
|---|---|
| Create | Add a new expense |
| Read | Retrieve and display expenses |
| Update | Edit an existing expense |
| Delete | Delete an existing expense |

Firestore real-time snapshots are used so that changes to expense data are automatically reflected in the application UI.

---

## Project Structure

```text
lib/
├── models/
│   ├── expense.dart
│   └── expense_category.dart
│
├── screens/
│   ├── add_edit_expense_screen.dart
│   └── home_screen.dart
│
├── services/
│   └── expense_service.dart
│
├── firebase_options.dart
└── main.dart
```

### `models`

Contains the application's data models.

`expense.dart` defines the structure of an expense and handles conversion between Dart objects and Firestore data.

`expense_category.dart` defines the supported expense categories.

### `screens`

Contains the main application screens.

`home_screen.dart` displays the monthly total, filters, and expense history.

`add_edit_expense_screen.dart` handles adding and editing expenses.

### `services`

Contains the application's Firebase data operations.

`expense_service.dart` handles Firestore Create, Read, Update, and Delete operations.

---

## Getting Started

### Prerequisites

Before running the project, ensure the following are installed:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android SDK
- Firebase CLI
- FlutterFire CLI

Verify your Flutter installation:

```bash
flutter doctor
```

Resolve any reported Flutter or Android configuration problems before continuing.

---

## Clone the Repository

Clone this repository:

```bash
git clone https://github.com/methma490/expense-tracker-flutter.git
```

Move into the project directory:

```bash
cd expense-tracker-flutter
```

Install the Flutter dependencies:

```bash
flutter pub get
```

---

## Firebase Setup

### 1. Create a Firebase Project

Create a Firebase project from the Firebase Console.

### 2. Enable Cloud Firestore

Inside the Firebase project:

```text
Build
→ Firestore Database
→ Create database
```

Configure the appropriate Firestore security rules for the environment.

### 3. Install Firebase CLI

If Firebase CLI is not already installed:

```bash
npm install -g firebase-tools
```

Sign in:

```bash
firebase login
```

### 4. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 5. Configure Firebase

From the project root directory run:

```bash
flutterfire configure
```

Select the Firebase project and required platforms.

FlutterFire generates the Firebase configuration required by the application.

---

## Run the Application

Check the available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

For development using Chrome:

```bash
flutter run -d chrome
```

For the final mobile version, run the application on an Android emulator or physical Android device.

---

## Code Analysis

The project can be checked using Flutter's static analyzer:

```bash
flutter analyze
```

Dependencies can be refreshed using:

```bash
flutter pub get
```

---

## Build Release APK

To generate an Android release APK:

```bash
flutter build apk --release
```

The generated APK can be found at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## How the Application Works

### Adding an Expense

1. Tap **Add Expense**.
2. Enter the expense title.
3. Enter the amount.
4. Select a category.
5. Select the expense date.
6. Optionally enter a note.
7. Tap **Save Expense**.

The expense is stored in Cloud Firestore and automatically appears in the expense history.

### Editing an Expense

1. Open the menu for an existing expense.
2. Select **Edit**.
3. Modify the required information.
4. Tap **Update Expense**.

The corresponding Firestore document is updated.

### Deleting an Expense

1. Open the menu for an expense.
2. Select **Delete**.
3. Confirm the deletion.

The expense is removed from Cloud Firestore and the expense history.

### Filtering Expenses

Expenses can be filtered using:

- Expense category
- An explicit start and end date selected with the **Date range** button

When a date range is selected, matching expenses are shown from the full
expense history. Otherwise, the list follows the month selected in the summary
card. Filters can be cleared to return to that selected month.

### Monthly Total

The application checks the year and month of each expense.

Only expenses belonging to the current month are included in the displayed monthly total.

---

## AI Tools Used

### ChatGPT

ChatGPT was used as an AI-assisted development tool during this project.

It assisted with:

- Planning the Flutter project structure
- Explaining Flutter and Dart concepts
- Guidance for Firebase and Cloud Firestore integration
- Reviewing implementation approaches
- Assisting with Firestore CRUD operations
- Form validation guidance
- Debugging assistance
- Reviewing loading, empty, and error-state handling
- UI and usability suggestions
- Reviewing the practical-task requirements
- Documentation and README preparation

AI-generated suggestions were reviewed and adapted during development. I verified the implementation and made sure I understood the code and development decisions used in the submitted project.

---

## Key Development Concepts

The project demonstrates:

- Flutter widget-based UI development
- Stateful UI management
- Form handling and validation
- Dart models and enums
- Asynchronous programming
- Firebase initialization
- Cloud Firestore integration
- Firestore CRUD operations
- Real-time Firestore streams
- `StreamBuilder`
- Date handling
- Expense filtering
- Monthly total calculation
- Loading, empty, and error-state handling
- Responsive Flutter layouts

---

## Possible Future Improvements

The application can be extended with:

- Expense charts
- Dark mode
- Search functionality
- Monthly and category-wise reports
- Firebase Authentication
- User-specific expense storage
- Budget limits
- Exportable expense reports

These features were kept outside the core implementation to maintain a simple and focused solution for the practical task.

---

## Submission Assets

A demo video and downloadable release APK are not included in this repository.
Generate a release APK with the command above before distributing it.

Developed as part of a Flutter Expense Tracker practical assessment.
