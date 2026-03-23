import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:doan_cuoiki/screen/welcome.dart';
import 'package:doan_cuoiki/screen/login.dart';
import 'package:doan_cuoiki/screen/register.dart';
import 'package:doan_cuoiki/screen/otp.dart';
import 'package:doan_cuoiki/screen/createpass.dart';
import 'package:doan_cuoiki/screen/forgotpass.dart';
import 'package:doan_cuoiki/screen/forgototp.dart';
import 'package:doan_cuoiki/screen/loginhaspass.dart';
import 'package:doan_cuoiki/screen/homescreen.dart';
import 'package:doan_cuoiki/screen/profile.dart';
import 'package:doan_cuoiki/screen/info.dart';
import 'package:doan_cuoiki/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ).copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Spartan'),
        primaryTextTheme:
            ThemeData.dark().primaryTextTheme.apply(fontFamily: 'Spartan'),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Welcome(),
        '/home': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return HomeScreen(phoneNumber: phoneNumber);
        },
        '/profile': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return ProfileScreen(phoneNumber: phoneNumber);
        },
        '/info': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return InfoScreen(phoneNumber: phoneNumber);
        },
        '/login': (context) => LoginEmail(),
        '/loginhaspass': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return LoginHasPassScreen(phoneNumber: phoneNumber);
        },
        '/register': (context) => RegisterScreen(),
        '/otp': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String;
          return OTPScreen(phoneNumber: phoneNumber);
        },
        '/createpass': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return CreatePassScreen(phoneNumber: phoneNumber);
        },
        '/forgotpass': (context) => const ForgotPassScreen(),
        '/forgototp': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String;
          return ForgotOtpScreen(phoneNumber: phoneNumber);
        },
      },
    );
  }
}
