# 🎬 CineKeep - Movie Wishlist Application

---

## 📱 Screenshots

|                          Home                         |                          Explore                         |                          Profile                         |                      Edit Profile                     |
| :---------------------------------------------------: | :------------------------------------------------------: | :------------------------------------------------------: | :---------------------------------------------------: |
| <img src="assets/screenshots/home.png" width="200" /> | <img src="assets/screenshots/explore.png" width="200" /> | <img src="assets/screenshots/profile.png" width="200" /> | <img src="assets/screenshots/edit.png" width="200" /> |

> Place screenshots inside `assets/screenshots/` to display them correctly.

---

## ✨ Key Features

### 🔐 Authentication & Profiles

* Secure **Sign Up / Login** using **Firebase Authentication**
* Persistent sessions with automatic login
* User profile management (name, avatar, banner image)
* Profile images stored efficiently in **Cloud Firestore** (Base64 format)

### 🎥 Movie Discovery

* Browse **Trending** and **New Releases** powered by the **TMDB API**
* Real-time movie search with instant results
* Detailed movie pages including overview and release date

### 🍿 Ratings & Watchlist

* Custom **Popcorn Rater** (0–10 scale) for a playful rating experience
* Personal watchlist to track movies you plan to watch
* Watched movies are automatically removed from the active watchlist

### 💾 Offline-First Experience

* Cloud synchronization using **Firestore**
* Local caching with **Hive** for offline access
* Seamless sync when the connection is restored

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **State Management:** Riverpod 2 (NotifierProvider)
* **Backend Services:** Firebase Authentication, Cloud Firestore
* **Local Storage:** Hive (NoSQL)
* **External API:** The Movie Database (TMDB)
* **Architecture:** Clean Architecture with Feature-First structure

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK installed
* TMDB API Key
* Firebase project (Android / iOS configured)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/YOUR_USERNAME/cinelist.git
   cd cinelist
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase configuration**

   * Create a project in Firebase Console
   * Android: Add `google-services.json` to `android/app/`
   * iOS: Add `GoogleService-Info.plist` to `ios/Runner/`

4. **Run the application**

   ```bash
   flutter run
   ```

---

## 👥 Team & Contributions

This is a **group project**, and responsibilities were divided as follows:

| Student ID | Name          | Role / Features                                                               |
| ---------- | ------------- | ----------------------------------------------------------------------------- |
| ID_1       | Member 1 Name | Identity & Accounts: Authentication, Profile Management, Image Sync, Settings |
| ID_2       | Member 2 Name | Discovery: Trending UI, Movie Details Screen, Popcorn Rater                   |
| ID_3       | Member 3 Name | Core Utility: Watchlist Logic, Search API Integration, CRUD Operations        |

---

## 📂 Project Structure

The project follows a **Clean Architecture + Feature-First** approach:

lib
 ┣ core
 ┃ ┣ constants
 ┃ ┃ ┗ tmdb_constants.dart
 ┃ ┣ services
 ┃ ┃ ┣ api_service.dart
 ┃ ┃ ┣ connectivity_service.dart
 ┃ ┃ ┗ local_storage_service.dart
 ┃ ┣ utils
 ┃ ┃ ┗ date_utils.dart
 ┃ ┗ widgets
 ┃ ┃ ┣ auth_wrapper.dart
 ┃ ┃ ┣ error_dialog.dart
 ┃ ┃ ┣ loading_spinner.dart
 ┃ ┃ ┗ popcorn_rater.dart
 ┣ features
 ┃ ┣ auth
 ┃ ┃ ┣ data
 ┃ ┃ ┃ ┗ auth_service.dart
 ┃ ┃ ┗ presentation
 ┃ ┃ ┃ ┣ login_screen.dart
 ┃ ┃ ┃ ┗ signup_screen.dart
 ┃ ┗ movies
 ┃ ┃ ┣ data
 ┃ ┃ ┃ ┣ datasources
 ┃ ┃ ┃ ┃ ┣ local_data_source.dart
 ┃ ┃ ┃ ┃ ┗ remote_data_source.dart
 ┃ ┃ ┃ ┣ models
 ┃ ┃ ┃ ┃ ┗ movie_model.dart
 ┃ ┃ ┃ ┗ repositories
 ┃ ┃ ┃ ┃ ┗ movie_repository.dart
 ┃ ┃ ┣ domain
 ┃ ┃ ┃ ┗ entities
 ┃ ┃ ┃ ┃ ┗ movie.dart
 ┃ ┃ ┗ presentation
 ┃ ┃ ┃ ┣ providers
 ┃ ┃ ┃ ┃ ┣ movie_providers.dart
 ┃ ┃ ┃ ┃ ┣ profile_provider.dart
 ┃ ┃ ┃ ┃ ┣ search_provider.dart
 ┃ ┃ ┃ ┃ ┗ wishlist_provider.dart
 ┃ ┃ ┃ ┣ screens
 ┃ ┃ ┃ ┃ ┣ details_screen.dart
 ┃ ┃ ┃ ┃ ┣ edit_profile_screen.dart
 ┃ ┃ ┃ ┃ ┣ home_screen.dart
 ┃ ┃ ┃ ┃ ┣ main_screen.dart
 ┃ ┃ ┃ ┃ ┣ movie_screen.dart
 ┃ ┃ ┃ ┃ ┣ profile_screen.dart
 ┃ ┃ ┃ ┃ ┣ search_screen.dart
 ┃ ┃ ┃ ┃ ┣ settings_screen.dart
 ┃ ┃ ┃ ┃ ┗ welcome_screen.dart
 ┃ ┃ ┃ ┗ widgets
 ┃ ┃ ┃ ┃ ┣ movie_card.dart
 ┃ ┃ ┃ ┃ ┣ search_bar.dart
 ┃ ┃ ┃ ┃ ┗ watchlist_card.dart
 ┣ app.dart
 ┣ firebase_options.dart
 ┗ main.dart