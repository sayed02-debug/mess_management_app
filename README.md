Smart Mess Management System (SMMS) 📊



Welcome to the Smart Mess Management System (SMMS) App! This is a Flutter-based mobile application designed as a mess marketplace, where users can discover, create, and manage messes (shared living accommodations) with advanced features. Whether you're searching for a mess, setting one up, or tracking financials and member details, SMMS has you covered. Built with a modern UI, Firebase integration, and interactive graphs, it offers a seamless and user-friendly experience. 🌟
Features 🛠️

Mess Marketplace: Browse and find messes with details like name, address, and creation date. 🏠
Search Functionality: Filter messes by name or location (up to 50 km radius). 🔍
Create Mess: Register a new mess with customizable details, including location (via map or manual input). ➕
Location-Based Filtering: Use your current location or input coordinates to discover nearby messes. 📍
User Authentication: Requires login to create or manage messes, integrated with Firebase Auth. 🔐
Interactive Graphs: Visualize total cost, meal rates, and financial summaries. 📈
Financial Tracking: View total cost, meal rates, members' costs, and remaining balances. 💰
Members Management: Access members' details, profiles, and individual financial statuses. 👥
Responsive Design: Smooth animations and a clean interface using Google Fonts. 🎨



Tech Stack 💻

Flutter: For cross-platform mobile development.
Firebase: Authentication and Firestore for data storage and real-time updates.
Google Maps: For location selection and visualization.
Geolocator: To access device location services.
Google Fonts: For a polished typography experience.
Charting Library (e.g., fl_chart or similar): For interactive graphs (to be integrated).


Installation 🛠️
Prerequisites 📋

Flutter SDK.
Android Studio with Flutter and Dart plugins.
Android emulator or a physical device for testing.
Firebase project set up with Authentication and Firestore enabled.
Google Maps API key (configure in AndroidManifest.xml).



Steps 🚀

Clone the Repository
bashgit clone https://github.com/sayed02-debug/mess-management-app.git
cd mess-management-app


Set Up Firebase

Create a Firebase project at console.firebase.google.com.
Enable Authentication (Email/Password) and Firestore.
Download google-services.json (Android) and place it in the android/app/ directory.
Add your Google Maps API key to AndroidManifest.xml under <application>:
xml<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>




Install Dependencies

Add the fl_chart package (or your preferred charting library) to pubspec.yaml:
yamldependencies:
  fl_chart: ^0.67.0
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0




Run:
bashflutter pub get




Run the App

Connect a device or start an emulator.
Run the app:
bashflutter run

For APK build:
bashflutter build apk --split-per-abi




Configure Permissions

Ensure location permissions are granted in your device/emulator settings.
Update AndroidManifest.xml with:
xml<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />






Usage 🎮

Explore the Marketplace: Open the "Mess Directory" to browse messes and use the search bar or location toggle to find options. 🏠
Create a Mess: Navigate to the "Create Mess" screen (requires login), fill in details, select a location via map or manual input (e.g., "23.8103, 90.4125"), and submit. ➕
View Graphs: Access the graph section to see total costs, meal rates, and financial trends. 📈
Manage Members: Check members' profiles, their individual costs, and remaining balances under the members section. 👥
Sort: Use the dropdown in the app bar to sort messes by name or recent creation. 🔧
Financial Overview: Track overall expenses and meal rates for better management. 💰




Contributing 🤝
We’re thrilled to have you join us in enhancing SMMS! Here’s how you can contribute:

Fork the Repository: Create your own copy of the project.
Create a Feature Branch: git checkout -b feature/your-feature-name.
Commit Changes: Make your changes and commit with a clear message.
bashgit commit -m "Add feature: [description]"

Push to GitHub: git push origin feature/your-feature-name.
Open a Pull Request: Share your changes for review.
Report Issues: Found a bug or have an idea? Open an issue on GitHub! 🚩

Feel free to reach out with questions or suggestions—we’re a friendly team eager to collaborate!


A big thank you to the Flutter community for the incredible framework.
Special appreciation to the xAI team for inspiration and support.
Gratitude to all contributors who help shape SMMS into a better tool.





Support 📧💼
If you encounter issues or need assistance, don’t hesitate to:

Open an issue on GitHub. 🚩
Reach out via email at mdabusayedislam2@gmail.com 📧.

Connect on LinkedIn at https://www.linkedin.com/in/sayed02/ 💼 for discussions.

Let’s build a smarter mess management system together! 🚀
