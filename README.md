

# Stake Grow 🌱
![Flutter](https://img.shields.io/badge/Flutter-3.19-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-3.0-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-Cloud%20Firestore-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Riverpod](https://img.shields.io/badge/State-Riverpod-purple?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**A Professional Community Donation & Investment Platform**

Stake Grow is a comprehensive Flutter-based mobile application designed to empower communities through collective financial growth. It facilitates transparent donation management, collective investments, and community-based micro-loans. Built with a focus on scalability, security, and modern architecture, it leverages Firebase for backend services and Riverpod for state management.

---

## 🚀 Key Features

### 👥 Community Management

* **Create & Join:** Users can create communities or join existing ones via invite codes.
* **Role-Based Access:** Distinct roles for **Admins**, **Moderators**, and **Members**.
* **Subscription Tracking:** Monitors monthly subscriptions and tracks member join dates.
* **Fund Management:** Real-time tracking of total community funds.

### 💸 Donation System

* **Flexible Donations:** Support for both **Monthly** subscriptions and **Random** one-time donations.
* **Payment Gateways:** Integrated tracking for local payment methods: **Bkash, Rocket, Nagad**, and Manual entries.
* **Verification:** Robust status system (Pending, Approved, Rejected) with rejection reasons and transaction ID tracking.

### 📈 Investment Platform

* **Project Tracking:** Create and manage investment projects with details, start/end dates, and status (Active/Completed).
* **Profit/Loss Calculation:** Track invested amounts, expected profits, actual returns, and profit/loss status.
* **Share Distribution:** Automatically tracks user shares (`userShares`) to calculate individual returns based on contribution.

### 💰 Micro-Loan System

* **Borrowing:** Members can request loans with specific reasons and repayment dates.
* **Lender Tracking:** Tracks which members' funds were used for the loan (`lenderShares`) to ensure fair repayment distribution.
* **Lifecycle Management:** Manages loan status from Request -> Pending -> Approved -> Repaid.

### 👤 User Profiles

* **Professional Identity:** Users can showcase their profession alongside standard contact details.
* **History:** Tracks joined communities and account creation dates.

---

## 🛠 Tech Stack

### Frontend & Core

* **Framework:** Flutter (SDK ^3.9.2)
* **Language:** Dart
* **Routing:** `go_router` for deep linking and smart navigation.
* **UI Components:** Material 3 Design, `google_fonts`, `cupertino_icons`.

### State Management & Architecture

* **State Management:** `flutter_riverpod` & `hooks_riverpod`.
* **Pattern:** Feature-First Architecture (MVCR - Model View Controller Repository).
* **Functional Programming:** `fpdart` for error handling (`Either<Failure, Success>`).
* **Equality:** `equatable` for value comparisons.

### Backend (Firebase)

* **Core:** `firebase_core`.
* **Authentication:** `firebase_auth` for secure login/registration.
* **Database:** `cloud_firestore` (NoSQL with ACID transactions).

### Utilities

* **PDF Generation:** `pdf` & `printing` for generating reports.
* **Localization:** `intl` for date and currency formatting.
* **Code Generation:** `build_runner`, `json_serializable` for type-safe JSON serialization.

---

## 📂 Project Structure

The project follows a **Feature-First** directory structure for better scalability:

```
lib/
├── core/                   # Global utilities, common widgets, type definitions
├── features/
│   ├── auth/               # Authentication (Login, Signup, User Model)
│   ├── community/          # Community creation, dashboard, member list
│   ├── donation/           # Donation creation, history, validation
│   ├── investment/         # Investment projects, ROI tracking
│   └── loan/               # Loan requests, approvals, repayment
├── router/                 # GoRouter configuration
├── firebase_options.dart   # Firebase configuration
└── main.dart               # Entry point

```

---

## ⚡ Getting Started

### Prerequisites

* Flutter SDK installed.
* Dart SDK installed.
* A Firebase project set up.

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/your-username/stake-grow.git
cd stake-grow

```


2. **Install dependencies:**
```bash
flutter pub get

```


3. **Firebase Setup:**
* Install the FlutterFire CLI.
* Configure your app:
```bash
flutterfire configure

```


* Ensure `firebase_options.dart` is generated in `lib/`.


4. **Run Code Generation:**
   This project uses `json_serializable`. Run the builder to generate model code:
```bash
dart run build_runner build --delete-conflicting-outputs

```


5. **Run the App:**
```bash
flutter run

```



---

## 📸 Screenshots

*(Add screenshots of your Dashboard, Community View, and Investment screens here)*

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes.
4. Push to the branch.
5. Open a Pull Request.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.