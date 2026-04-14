import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:doan_cuoiki/screen/user_live_chat.dart';
import 'package:doan_cuoiki/screen/deposit_screen.dart';
import 'package:doan_cuoiki/screen/mycar.dart';
import 'package:doan_cuoiki/screen/admin/admin_screen.dart';
import 'package:doan_cuoiki/firebase_options.dart';
import 'package:doan_cuoiki/models/car_detail.dart';
import 'package:doan_cuoiki/services/car_data_service.dart';
import 'package:doan_cuoiki/services/favorite_service.dart';
import 'package:doan_cuoiki/services/firebase_service.dart';
import 'package:doan_cuoiki/data/firebase_helper.dart';
import 'package:vietnam_provinces/vietnam_provinces.dart';

import 'navigation_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep only critical init on startup path.
  await Future.wait([
    dotenv.load(fileName: '.env'),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  runApp(const MyApp());

  // Warm-up non-critical services in background so first screen appears faster.
  unawaited(_warmUpBackgroundServices());
}

Future<void> _warmUpBackgroundServices() async {
  try {
    await Future.wait([
      VietnamProvinces.initialize(version: AdministrativeDivisionVersion.v1),
      initializeDateFormatting('en_US', null),
      CarDataService().initialize(),
    ]);
  } catch (_) {
    // Best-effort warmup; ignore failures.
  }

  unawaited(FavoriteService.deduplicateAndSync());

  try {
    await FirebaseService.cleanupLegacyDepositDataOnce();
  } catch (_) {
    // Không chặn app nếu cleanup không đủ quyền/không cần thiết.
  }
}

/// 🔄 Role-based Router Loader - loads role and navigates to correct route
class _RoleBasedRouterLoader extends StatefulWidget {
  final String phoneNumber;
  const _RoleBasedRouterLoader({required this.phoneNumber});

  @override
  State<_RoleBasedRouterLoader> createState() => _RoleBasedRouterLoaderState();
}

class _RoleBasedRouterLoaderState extends State<_RoleBasedRouterLoader> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _loadRoleAndNavigate();
  }

  Future<void> _loadRoleAndNavigate() async {
    if (_navigating) return; // Prevent duplicate navigation
    _navigating = true;

    try {
      final normalizedPhone = widget.phoneNumber.contains('@')
          ? widget.phoneNumber.trim().toLowerCase()
          : FirebaseHelper.normalizePhone(widget.phoneNumber);

      final usersRef = FirebaseFirestore.instance.collection('users');

      // Cache-first lookup improves perceived speed on repeat launches.
      String role = 'user';
      try {
        final cachedDoc = await usersRef
            .doc(normalizedPhone)
            .get(const GetOptions(source: Source.cache));
        final cachedRole = (cachedDoc.data()?['role'] as String?)?.trim();
        if (cachedRole != null && cachedRole.isNotEmpty) {
          role = cachedRole;
        }
      } catch (_) {
        // Ignore cache errors and fall back to server.
      }

      final remoteDoc = await usersRef.doc(normalizedPhone).get();
      final remoteRole = (remoteDoc.data()?['role'] as String?)?.trim();
      if (remoteRole != null && remoteRole.isNotEmpty) {
        role = remoteRole;
      }

      debugPrint('👤 User role: $role');

      if (!mounted) return;

      if (role == 'admin') {
        // Push /admin route for admin users
        debugPrint('👮 Routing to AdminScreen');
        Navigator.pushReplacementNamed(
          context,
          '/admin',
          arguments: normalizedPhone,
        );
      } else {
        // For users, just return HomeScreen directly (no recursive push)
        // Replace this loader with HomeScreen
        Navigator.pushReplacementNamed(
          context,
          '/homescreen',
          arguments: normalizedPhone,
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading user role: $e');
      if (!mounted) return;
      // Fallback to direct HomeScreen
      Navigator.pushReplacementNamed(
        context,
        '/homescreen',
        arguments: widget.phoneNumber.contains('@')
            ? widget.phoneNumber.trim().toLowerCase()
            : FirebaseHelper.normalizePhone(widget.phoneNumber),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Intentionally render nothing to avoid a visible "loading flash".
    // This widget should exist for only a single frame before replacement.
    return const SizedBox.shrink();
  }
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
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _AppPageTransitionsBuilder(),
                TargetPlatform.iOS: _AppPageTransitionsBuilder(),
                TargetPlatform.windows: _AppPageTransitionsBuilder(),
                TargetPlatform.macOS: _AppPageTransitionsBuilder(),
                TargetPlatform.linux: _AppPageTransitionsBuilder(),
              },
            ),
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
        '/admin': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return AdminScreen(phoneNumber: phoneNumber);
        },
        '/home': (context) {
          try {
            final args = ModalRoute.of(context)!.settings.arguments;
            String? phoneNumber;

            if (args is String) {
              phoneNumber = args;
            } else if (args is Map<String, dynamic>) {
              phoneNumber = args['phoneNumber'] as String?;
            }

            debugPrint('🏠 Home route - phoneNumber: $phoneNumber');

            if (phoneNumber == null || phoneNumber.isEmpty) {
              debugPrint('🏠 Loading HomeScreen (no phone)');
              return HomeScreen(phoneNumber: phoneNumber);
            }

            // Return placeholder, will navigate via Navigator.pushReplacementNamed in initState
            return _RoleBasedRouterLoader(phoneNumber: phoneNumber);
          } catch (e) {
            debugPrint('❌ Home route error: $e');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Lỗi tải Home Screen'),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        '/profile': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return ProfileScreen(phoneNumber: phoneNumber);
        },
        '/homescreen': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return HomeScreen(phoneNumber: phoneNumber);
        },
        '/infomation': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String?;
          return InfomationScreen(phoneNumber: phoneNumber);
        },
        '/changeinfo': (context) {
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
        '/direct_chat': (context) {
          final args =
              (ModalRoute.of(context)?.settings.arguments as Map?) ??
              const <String, dynamic>{};
          return UserLiveChatScreen(
            phoneNumber: args['phoneNumber'] as String?,
            chatId: args['chatId'] as String?,
            chatTitle: args['chatTitle'] as String?,
          );
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
        '/mycar': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final phoneNumber = args is String ? args : null;
          return MyCarScreen(phoneNumber: phoneNumber);
        },
      },
    );
  }
}

/// Global modern page transition used by Navigator.pushNamed / MaterialPageRoute.
/// Keeps motion consistent across the whole app without editing every screen.
class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Don't animate the initial route.
    if (route.isFirst) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInCubic,
    );

    // Premium iOS-like push: slide from right + subtle fade.
    final slide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(curved);
    final fade = Tween<double>(begin: 0.85, end: 1.0).animate(curved);

    // Optional: slight parallax for the outgoing page (feels more expensive).
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final outgoingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.12, 0.0),
    ).animate(secondaryCurved);

    final incoming = FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );

    // If this is a full-screen route, apply outgoing parallax. For overlays/dialog-like
    // routes, keep default behavior.
    if (route.opaque) {
      return SlideTransition(position: outgoingSlide, child: incoming);
    }

    return incoming;
  }
}
