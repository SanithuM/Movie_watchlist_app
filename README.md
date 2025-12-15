# 🎬 CineKeep - Movie Wishlist Application

**CineKeep** is a cross-platform mobile application built with **Flutter** that allows users to discover new movies, rate them using a custom "Popcorn Rater," and manage a personal watchlist. The app features a modern dark-mode UI, real-time cloud synchronization, and robust offline capabilities.

## 📱 Screenshots

| Home Screen | Explore Movies | Profile Page | Edit Profile |
|:---:|:---:|:---:|:---:|
| <img src="assets/screenshots/home.png" width="200"> | <img src="assets/screenshots/explore.png" width="200"> | <img src="assets/screenshots/profile.png" width="200"> | <img src="assets/screenshots/edit.png" width="200"> |


## ✨ Features

### 🔐 Identity & Accounts
* **Authentication:** Secure Login and Sign Up using **Firebase Auth**.
* **Auto-Login:** `AuthWrapper` remembers users so they don't have to log in every time.
* **Profile Management:** Users can update their display name, profile picture, and banner image.
* **Cloud Storage:** Profile images are converted to Base64 and stored securely in **Firestore**.

### 🌍 Discovery & Engagement
* **Movie Discovery:** Browse "Trending Now" and "New Releases" fetched from the **TMDB API**.
* **Search System:** Real-time search functionality to find any movie.
* **Custom Rating:** A unique **Popcorn Rater** slider to rate movies on a scale of 0-10.
* **Detailed Views:** View rich movie details, release dates, and plot summaries.

### 💾 Core Utility & Persistence
* **Smart Watchlist:** Add movies to a personal list. Movies disappear from the "Home" view instantly when marked as "Watched".
* **Dual-Layer Storage:**
    * **Online:** Syncs all data (Wishlist, Ratings, Profile) to **Google Firestore**.
    * **Offline:** Uses **Hive** (NoSQL) to cache data, allowing the app to work without internet.

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** [Riverpod 2.0](https://riverpod.dev/) (NotifierProvider)
* **Backend:** [Firebase Authentication](https://firebase.google.com/docs/auth) & [Cloud Firestore](https://firebase.google.com/docs/firestore)
* **Local Database:** [Hive](https://docs.hivedb.dev/)
* **API:** [The Movie Database (TMDB)](https://www.themoviedb.org/documentation/api)
* **Architecture:** Clean Architecture + Feature-First Packaging


### Prerequisites
* Flutter SDK installed ([Guide](https://docs.flutter.dev/get-started/install))
* A TMDB API Key (Free)
* A Firebase Project


## 📂 Project Structure

The project follows a **Feature-First** architecture for better scalability:

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