import 'package:famlink/features/auth/register_page.dart';
import 'package:famlink/features/connection_screen.dart';
import 'package:famlink/features/maps/map_page.dart';
import 'package:famlink/omboarding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute =
          state.uri.toString() == '/login' ||
          state.uri.toString() == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapPage()),
      GoRoute(path: '/', builder: (context, state) => const Omboarding()),
      GoRoute(
        path: '/connection',
        builder: (context, state) => const ConnectionScreen(),
      ),
    ],
  );
}
