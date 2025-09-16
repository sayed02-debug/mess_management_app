import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:mess_management_app/screens/admin_screen.dart';
import 'package:mess_management_app/screens/create_mess_screen.dart';
import 'package:mess_management_app/screens/forgot_password_screen.dart';
import 'package:mess_management_app/screens/home_screen.dart';
import 'package:mess_management_app/screens/login_screen.dart';
import 'package:mess_management_app/screens/mess_list_screen.dart';
import 'package:mess_management_app/screens/signup_screen.dart';
import 'package:mess_management_app/screens/splash_screen.dart';
import 'package:mess_management_app/screens/your_mess_screen.dart';
import 'package:mess_management_app/screens/mess_features/mess_details_screen.dart';
import 'package:mess_management_app/screens/mess_features/mess_stats_screen.dart';
import 'package:mess_management_app/screens/mess_features/quick_options_screen.dart';
import 'package:mess_management_app/screens/mess_features/shopping_record_screen.dart';
import 'package:mess_management_app/screens/mess_features/shopping_summary_screen.dart';
import 'package:mess_management_app/screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mess Management App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/adminScreen':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('messId')) {
              return MaterialPageRoute(
                builder: (context) => AdminScreen(messId: args['messId']),
              );
            }
            return _errorRoute('Mess ID not provided');

          case '/shopping_record':
            final args = settings.arguments as Map<String, dynamic>;
            if (args.containsKey('messId')) {
              return MaterialPageRoute(
                builder: (context) => ShoppingRecordScreen(messId: args['messId']),
              );
            }
            return _errorRoute('Mess ID not provided');

          case '/shopping_summary':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('messId') && args.containsKey('shoppingRecords')) {
              return MaterialPageRoute(
                builder: (context) => ShoppingSummaryScreen(
                  messId: args['messId'],
                  shoppingRecords: args['shoppingRecords'],
                ),
              );
            }
            return _errorRoute('Mess ID or Shopping Records not provided');

          case '/mess_details':
            final args = settings.arguments as Map<String, dynamic>;
            if (args.containsKey('mess')) {
              return MaterialPageRoute(
                builder: (context) => MessDetailsScreen(mess: args['mess']),
              );
            }
            return _errorRoute('Mess data not provided');

          case '/mess_stats':
            final args = settings.arguments as Map<String, dynamic>;
            if (args.containsKey('messId')) {
              return MaterialPageRoute(
                builder: (context) => MessStatsScreen(messId: args['messId']),
              );
            }
            return _errorRoute('Mess ID not provided');

          case '/quick_options':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('messId')) {
              return MaterialPageRoute(
                builder: (context) => QuickOptionsScreen(messId: args['messId']),
              );
            }
            return _errorRoute('Mess ID not provided');

          case '/yourMess':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('messId')) {
              return MaterialPageRoute(
                builder: (context) => YourMessScreen(messId: args['messId']),
              );
            }
            return _errorRoute('Mess ID not provided');

          case '/userProfile':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('userId') && args.containsKey('messId')) {
              return MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: args['userId'],
                  messId: args['messId'],
                ),
              );
            }
            return _errorRoute('User ID or Mess ID not provided');

          default:
            return null;
        }
      },
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/forget_password': (context) => ForgotPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/messList': (context) => MessListScreen(),
        '/create_mess': (context) => CreateMessScreen(),
      },
    );
  }

  MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(child: Text('Error: $message')),
      ),
    );
  }
}
