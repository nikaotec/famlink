import 'dart:async';

import 'package:famlink/features/auth/register_page.dart';
import 'package:famlink/features/connection_screen.dart';
import 'package:famlink/features/maps/map_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';

class AppRouter {
  static final locationStreamController = StreamController<String>.broadcast();
  static final GoRouter router = GoRouter(
    initialLocation: '/map',
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn =
          state.uri.toString() == '/login' || state.uri.toString() == '/register';
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/map';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
     GoRoute(
        path: '/map',
        builder:
            (context, state) =>
                MapPage(locationStream: AppRouter.locationStreamController.stream),
      ),
       GoRoute(path: '/connection', builder: (context, state) => const ConnectionScreen()),
    ],
  );
}
