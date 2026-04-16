import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/register_form_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/doctors/presentation/screens/doctors_screen.dart';
import '../../features/doctors/presentation/screens/doctor_detail_screen.dart';
import '../../features/clinics/presentation/screens/clinics_screen.dart';
import '../../features/clinics/presentation/screens/clinic_detail_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacies_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacy_detail_screen.dart';
import '../../features/provider/presentation/screens/doctor_setup_screen.dart';
import '../../features/provider/presentation/screens/pending_review_screen.dart';
import '../../features/provider/presentation/screens/clinic_setup_screen.dart';
import '../../features/provider/presentation/screens/pharmacy_setup_screen.dart';
import '../../features/ai/presentation/screens/ai_chat_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, s) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, s) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, s) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, s) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/register/form',
      builder: (context, state) {
        final role = state.extra as String? ?? 'patient';
        return RegisterFormScreen(role: role);
      },
    ),
    GoRoute(
      path: '/main',
      builder: (_, s) => const MainScreen(),
      routes: [
        GoRoute(
          path: 'doctors',
          builder: (_, s) => const DoctorsScreen(),
        ),
        GoRoute(
          path: 'doctors/:id',
          builder: (_, state) =>
              DoctorDetailScreen(doctorId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'clinics',
          builder: (_, s) => const ClinicsScreen(),
        ),
        GoRoute(
          path: 'clinics/:id',
          builder: (_, state) =>
              ClinicDetailScreen(clinicId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'pharmacies',
          builder: (_, s) => const PharmaciesScreen(),
        ),
        GoRoute(
          path: 'pharmacies/:id',
          builder: (_, state) =>
              PharmacyDetailScreen(pharmacyId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'search',
          builder: (_, s) => const SearchScreen(),
        ),
        GoRoute(
          path: 'favorites',
          builder: (_, s) => const FavoritesScreen(),
        ),
        GoRoute(
          path: 'ai-chat',
          builder: (_, s) => const AiChatScreen(),
        ),
      ],
    ),

    // ─── Provider routes ──────────────────────────────────────────────────
    GoRoute(
      path: '/provider/setup',
      builder: (_, s) => const DoctorSetupScreen(),
    ),
    GoRoute(
      path: '/provider/pending',
      builder: (_, s) => const PendingReviewScreen(providerType: 'doctor'),
    ),
    GoRoute(
      path: '/provider/clinic-setup',
      builder: (_, s) => const ClinicSetupScreen(),
    ),
    GoRoute(
      path: '/provider/pending-clinic',
      builder: (_, s) => const PendingReviewScreen(providerType: 'clinic'),
    ),
    GoRoute(
      path: '/provider/pharmacy-setup',
      builder: (_, s) => const PharmacySetupScreen(),
    ),
    GoRoute(
      path: '/provider/pending-pharmacy',
      builder: (_, s) =>
          const PendingReviewScreen(providerType: 'pharmacy'),
    ),
  ],
);
