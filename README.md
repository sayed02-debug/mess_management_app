Smart Mess Management System (SMMS) 📊

Welcome to the Smart Mess Management System (SMMS) app! 🎉

SMMS is a Flutter-based mobile application designed as a mess marketplace, where users can discover, create, and manage messes (shared living accommodations) with ease.

Whether you’re looking for a mess to join, setting one up, or managing finances and member details, SMMS has you covered. Built with a modern UI, Firebase integration, and interactive graphs, it delivers a seamless and user-friendly experience. 🌟

✨ Features

Mess Marketplace – Browse and explore messes with details like name, address, and creation date. 🏠

Search Functionality – Filter messes by name or location (within a 50 km radius). 🔍

Create Mess – Register a new mess with customizable details, including location (via map or manual input). ➕

Location-Based Filtering – Discover nearby messes using GPS or custom coordinates. 📍

User Authentication – Secure login via Firebase Auth to create or manage messes. 🔐

Interactive Graphs – Visualize costs, meal rates, and financial summaries. 📈

Financial Tracking – Monitor total costs, meal rates, member expenses, and remaining balances. 💰

Members Management – Access members’ profiles, financial details, and status. 👥

Responsive Design – Smooth animations and clean UI powered by Google Fonts. 🎨

💻 Tech Stack

Flutter – Cross-platform mobile development

Firebase – Authentication & Firestore (real-time database)

Google Maps – Location selection & visualization

Geolocator – Access device location services

Google Fonts – Modern typography

Charting Library (fl_chart or similar) – For interactive data visualization

🛠️ Installation
Prerequisites 📋

Flutter SDK

Android Studio with Flutter & Dart plugins

Android emulator or physical device

Firebase project with Authentication + Firestore enabled

Google Maps API key (configured in AndroidManifest.xml)

Steps 🚀

1. Clone the Repository

git clone https://github.com/sayed02-debug/mess-management-app.git
cd mess-management-app


2. Set Up Firebase

Create a Firebase project → console.firebase.google.com

Enable Authentication (Email/Password) + Firestore

Download google-services.json → place inside android/app/

Add your Google Maps API key in AndroidManifest.xml:

<meta-data 
    android:name="com.google.android.geo.API_KEY" 
    android:value="YOUR_API_KEY"/>


3. Install Dependencies
Add these packages in pubspec.yaml:

dependencies:
  fl_chart: ^0.67.0
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0


Run:

flutter pub get


4. Run the App

flutter run


For APK build:

flutter build apk --split-per-abi


5. Configure Permissions
Add location permissions to AndroidManifest.xml:

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

🎮 Usage

Explore Marketplace – Browse messes, use search or location toggle. 🏠

Create Mess – Login → add mess details → select location (map or coordinates e.g., 23.8103, 90.4125) → submit. ➕

View Graphs – Check cost breakdowns, meal rates, and financial insights. 📈

Manage Members – View profiles, individual expenses, and balances. 👥

Sort Messes – Sort by name or recent creation. 🔧

Track Finances – Monitor expenses & meal rates for better management. 💰

🤝 Contributing

We’d love your contributions to SMMS! Here’s how you can get started:

Fork the repository

Create a feature branch

git checkout -b feature/your-feature-name


Commit your changes

git commit -m "Add feature: [description]"


Push to GitHub

git push origin feature/your-feature-name


Open a Pull Request – Share your changes for review.

👉 Found a bug or have an idea? Open an issue
 

📧 Support

Need help or have feedback? Reach out anytime:

Open a GitHub issue 🚩

Email: mdabusayedislam2@gmail.com
 📧

Connect on LinkedIn: linkedin.com/in/sayed02
 💼

Let’s build a smarter mess management system together! 🚀
