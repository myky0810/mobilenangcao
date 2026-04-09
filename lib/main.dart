import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:doan_cuoiki/screen/changeinfo.dart';
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
import 'package:doan_cuoiki/screen/warranty.dart';
import 'package:doan_cuoiki/screen/app_info.dart';
import 'package:doan_cuoiki/screen/calendar_drive.dart';
import 'package:doan_cuoiki/screen/AIChat.dart';
import 'package:doan_cuoiki/screen/deposit_screen.dart';
import 'package:doan_cuoiki/firebase_options.dart';
import 'package:doan_cuoiki/models/car_detail.dart';
import 'package:doan_cuoiki/services/car_data_service.dart';
import 'package:doan_cuoiki/services/favorite_service.dart';
import 'package:doan_cuoiki/services/firebase_service.dart';
import 'package:vietnam_provinces/vietnam_provinces.dart';

import 'navigation_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await VietnamProvinces.initialize(version: AdministrativeDivisionVersion.v1);
  await initializeDateFormatting('en_US', null);
  await CarDataService().initialize();

  // Làm sạch dữ liệu yêu thích trùng lặp khi ứng dụng khởi động
  await FavoriteService.deduplicateAndSync();

  // Chạy dọn dữ liệu đặt cọc cũ một lần (nếu có).
  try {
    await FirebaseService.cleanupLegacyDepositDataOnce();
  } catch (_) {
    // Không chặn app startup nếu cleanup không đủ quyền/không cần thiết.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData.dark()
          .copyWith(
            scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
          )
          .copyWith(
            textTheme: GoogleFonts.leagueSpartanTextTheme(
              ThemeData.dark().textTheme,
            ),
            primaryTextTheme: GoogleFonts.leagueSpartanTextTheme(
              ThemeData.dark().primaryTextTheme,
            ),
          ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Welcome(),
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          String? phoneNumber;

          if (args is String) {
            phoneNumber = args;
          } else if (args is Map<String, dynamic>) {
            phoneNumber = args['phoneNumber'] as String?;
          }

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
          final args = ModalRoute.of(context)!.settings.arguments;
          String? phoneNumber;
          bool isResetPassword = false;

          if (args is String) {
            // Legacy format for registration
            phoneNumber = args;
          } else if (args is Map) {
            // New format with reset password flag
            phoneNumber = args['phoneNumber'] as String?;
            isResetPassword = args['isResetPassword'] == true;
          }

          return CreatePassScreen(
            phoneNumber: phoneNumber,
            isResetPassword: isResetPassword,
          );
        },
        '/forgotpass': (context) => const ForgotPassScreen(),
        '/forgototp': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String;
          return ForgotOtpScreen(phoneNumber: phoneNumber);
        },
        '/newcar': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final phoneNumber = args is String ? args : null;
          return NewCarScreen(phoneNumber: phoneNumber);
        },
        '/favorite': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return FavoriteScreen(phoneNumber: phoneNumber);
        },
        '/detailcar': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return DetailCarScreen(car: CarDetailData.fromRouteArguments(args));
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
        '/warranty': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return WarrantyScreen(phoneNumber: phoneNumber);
        },
        '/appinfo': (context) => const AppInfoScreen(),
        '/date_drive': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return TestDriveScreen(phoneNumber: phoneNumber);
        },
        '/aichat': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return AIChatScreen(phoneNumber: phoneNumber);
        },
        '/deposit': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return DepositScreen(
            carName: args['carName'],
            carBrand: args['carBrand'],
            carImage: args['carImage'],
            carPrice: args['carPrice'],
            phoneNumber: args['phoneNumber'],
          );
        },
      },
    );
  }
}
