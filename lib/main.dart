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
import 'package:doan_cuoiki/screen/infomation.dart';
import 'package:doan_cuoiki/screen/info.dart';
import 'package:doan_cuoiki/screen/changepass.dart';
import 'package:doan_cuoiki/screen/newcar.dart';
import 'package:doan_cuoiki/screen/favorite.dart';
import 'package:doan_cuoiki/screen/detailcar.dart';
import 'package:doan_cuoiki/screen/bookcar.dart';
import 'package:doan_cuoiki/screen/logocar/mercedes_screen.dart';
import 'package:doan_cuoiki/screen/logocar/bmw_screen.dart';
import 'package:doan_cuoiki/screen/logocar/volvo_screen.dart';
import 'package:doan_cuoiki/screen/logocar/tesla_screen.dart';
import 'package:doan_cuoiki/screen/logocar/toyota_screen.dart';
import 'package:doan_cuoiki/screen/logocar/mazda_screen.dart';
import 'package:doan_cuoiki/screen/logocar/hyundai_screen.dart';
import 'package:doan_cuoiki/screen/endow.dart';
import 'package:doan_cuoiki/screen/notification.dart';
import 'package:doan_cuoiki/screen/app_info.dart';
import 'package:doan_cuoiki/firebase_options.dart';
import 'package:vietnam_provinces/vietnam_provinces.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await VietnamProvinces.initialize(version: AdministrativeDivisionVersion.v1);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark()
          .copyWith(
            scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
          )
          .copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Spartan'),
            primaryTextTheme: ThemeData.dark().primaryTextTheme.apply(
              fontFamily: 'Spartan',
            ),
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
        '/infomation': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return InfomationScreen(phoneNumber: phoneNumber);
        },
        '/info': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return InfoScreen(phoneNumber: phoneNumber);
        },
        '/changepass': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return ChangePassScreen(phoneNumber: phoneNumber);
        },
        '/login': (context) => LoginEmail(),
        '/loginhaspass': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return LoginHasPassScreen(phoneNumber: phoneNumber);
        },
        '/register': (context) => RegisterScreen(),
        '/otp': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          String phoneNumber;

          if (args is Map) {
            phoneNumber = args['phoneNumber'] as String;
          } else {
            phoneNumber = args as String;
          }

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
        '/newcar': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return NewCarScreen(phoneNumber: phoneNumber);
        },
        '/favorite': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return FavoriteScreen(phoneNumber: phoneNumber);
        },
        '/detailcar': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return DetailCarScreen(
            carName: args['carName'] as String,
            carBrand: args['carBrand'] as String,
            carImage: args['carImage'] as String,
            carPrice: args['carPrice'] as String,
            carDescription: args['carDescription'] as String,
            carImages: args['carImages'] as List<String>,
            rating: args['rating'] as double,
            reviewCount: args['reviewCount'] as int,
            isNew: args['isNew'] as bool,
            phoneNumber: args['phoneNumber'] as String?,
          );
        },
        '/bookcar': (context) {
          final args =
              (ModalRoute.of(context)!.settings.arguments as Map?) ??
              const <String, dynamic>{};
          return BookCarScreen(
            carData: {
              'name': args['carName'] ?? '',
              'brand': args['carBrand'] ?? '',
              'image': args['carImage'] ?? '',
              'phoneNumber': args['phoneNumber'],
            },
          );
        },
        '/mercedes': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return MercedesScreen(phoneNumber: phoneNumber);
        },
        '/bmw': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return BMWScreen(phoneNumber: phoneNumber);
        },
        '/volvo': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return VolvoScreen(phoneNumber: phoneNumber);
        },
        '/tesla': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return TeslaScreen(phoneNumber: phoneNumber);
        },
        '/toyota': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return ToyotaScreen(phoneNumber: phoneNumber);
        },
        '/mazda': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return MazdaScreen(phoneNumber: phoneNumber);
        },
        '/hyundai': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return HyundaiScreen(phoneNumber: phoneNumber);
        },
        '/endow': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return EndowScreen(phoneNumber: phoneNumber);
        },
        '/notification': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return NotificationScreen(phoneNumber: phoneNumber);
        },
        '/appinfo': (context) => const AppInfoScreen(),
      },
    );
  }
}
