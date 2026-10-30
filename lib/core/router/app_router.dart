
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/landing_screen.dart';
import '../../features/notes/presentation/screens/notes_home_dashboard.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const NotesHomeDashboard(),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) {
          final noteId = state.uri.queryParameters['id'];
          return NoteEditorScreen(noteId: noteId);
        },
      ),
    ],
  );
}
