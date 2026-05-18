import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/register_form_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/doctors/presentation/screens/doctors_screen.dart';
import '../../features/doctors/presentation/screens/doctor_detail_screen.dart';
import '../../features/clinics/presentation/screens/clinics_screen.dart';
import '../../features/clinics/presentation/screens/clinic_detail_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacies_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacy_detail_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacy_company_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/provider/presentation/screens/doctor_setup_screen.dart';
import '../../features/provider/presentation/screens/pending_review_screen.dart';
import '../../features/provider/presentation/screens/clinic_setup_screen.dart';
import '../../features/provider/presentation/screens/clinic_intro_screen.dart';
import '../../features/provider/presentation/screens/clinic_created_screen.dart';
import '../../features/provider/presentation/screens/pharmacy_setup_screen.dart';
import '../../features/clinics/presentation/screens/doctor_requests_screen.dart';
import '../../features/clinics/presentation/screens/clinic_doctors_screen.dart';
import '../../features/ai/presentation/screens/ai_chat_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacy_manage_screen.dart';
import '../../features/doctors/presentation/screens/doctors_by_symptom_screen.dart';
import '../../features/doctors/presentation/screens/specializations_screen.dart';
import '../../features/doctors/presentation/screens/symptoms_screen.dart';
import '../../features/doctors/presentation/screens/doctors_by_specialization_screen.dart';
import '../../features/clinics/presentation/screens/clinic_photos_screen.dart';
import '../../features/health/presentation/screens/first_aid_detail_screen.dart';
import '../../features/clinics/presentation/screens/clinic_edit_screen.dart';
import '../../features/pharmacies/presentation/screens/branch_photos_screen.dart';
import '../../features/pharmacies/presentation/screens/add_branch_screen.dart';
import '../../features/pharmacies/presentation/screens/edit_pharmacy_company_screen.dart';
import '../../features/pharmacies/presentation/screens/edit_branch_screen.dart';
import '../../features/provider/presentation/screens/doctor_edit_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/analytics/presentation/screens/clinic_analytics_screen.dart';
import '../../features/analytics/presentation/screens/pharmacy_branch_analytics_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    if (state.uri.toString() == '/') return '/splash';
    return null;
  },
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
      path: '/forgot-password',
      builder: (_, s) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ResetPasswordScreen(
          phone: extra['phone'] as String? ?? '',
          devCode: extra['devCode'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpScreen(
          phone: extra['phone'] as String? ?? '',
          devCode: extra['devCode'] as String?,
          fullName: extra['fullName'] as String?,
          role: extra['role'] as String? ?? 'patient',
        );
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
          path: 'doctors/by-symptom/:symptomId',
          builder: (_, state) => DoctorsBySymptomScreen(
            symptomId: int.parse(state.pathParameters['symptomId']!),
            symptomName: state.extra as String? ?? 'Симптом',
          ),
        ),
        GoRoute(
          path: 'doctors/by-specialization',
          builder: (_, state) => DoctorsBySpecializationScreen(
            specialization: state.extra as String? ?? '',
          ),
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
          path: 'pharmacies/branch/:id',
          builder: (_, state) =>
              PharmacyDetailScreen(pharmacyId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'pharmacies/company/:id',
          builder: (_, state) =>
              PharmacyCompanyScreen(companyId: state.pathParameters['id']!),
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
          path: 'notifications',
          builder: (_, s) => const NotificationsScreen(),
        ),
        GoRoute(
          path: 'edit-profile',
          builder: (_, s) => const EditProfileScreen(),
        ),
        GoRoute(
          path: 'ai-chat',
          builder: (_, s) => const AiChatScreen(),
        ),
        GoRoute(
          path: 'specializations',
          builder: (_, s) => const SpecializationsScreen(),
        ),
        GoRoute(
          path: 'symptoms',
          builder: (_, s) => const SymptomsScreen(),
        ),
        GoRoute(
          path: 'health/first-aid/:id',
          builder: (_, state) => FirstAidDetailScreen(
            categoryId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),

    // ─── Clinic management routes ─────────────────────────────────────────
    GoRoute(
      path: '/clinic/:id/doctor-requests',
      builder: (_, state) => DoctorRequestsScreen(
        clinicId: int.parse(state.pathParameters['id']!),
        initialTab: state.uri.queryParameters['tab'] == 'updates' ? 4 : 0,
      ),
    ),
    GoRoute(
      path: '/clinic/:id/photos',
      builder: (_, state) => ClinicPhotosScreen(
        clinicId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/clinic/:id/doctors',
      builder: (_, state) => ClinicDoctorsScreen(
        clinicId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/clinic/:id/edit',
      builder: (_, state) => ClinicEditScreen(
        clinicId: int.parse(state.pathParameters['id']!),
      ),
    ),

    // ─── Provider routes ──────────────────────────────────────────────────
    GoRoute(
      path: '/provider/setup',
      builder: (_, s) => const DoctorSetupScreen(),
    ),
    GoRoute(
      path: '/provider/doctor-edit',
      builder: (_, s) => const DoctorEditScreen(),
    ),
    GoRoute(
      path: '/provider/pending',
      builder: (_, s) => const PendingReviewScreen(providerType: 'doctor'),
    ),
    GoRoute(
      path: '/provider/clinic-intro',
      builder: (_, s) => const ClinicIntroScreen(),
    ),
    GoRoute(
      path: '/provider/clinic-setup',
      builder: (_, s) => const ClinicSetupScreen(),
    ),
    GoRoute(
      path: '/provider/clinic-created',
      builder: (_, s) => const ClinicCreatedScreen(),
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
      path: '/provider/pharmacy/manage',
      builder: (_, s) => const PharmacyManageScreen(),
    ),
    GoRoute(
      path: '/provider/pending-pharmacy',
      builder: (_, s) =>
          const PendingReviewScreen(providerType: 'pharmacy'),
    ),
    GoRoute(
      path: '/pharmacy/branch/:id/photos',
      builder: (_, state) => BranchPhotosScreen(
        branchId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/provider/pharmacy/branch/add',
      builder: (_, s) => const AddBranchScreen(),
    ),
    GoRoute(
      path: '/provider/pharmacy/edit',
      builder: (_, s) => const EditPharmacyCompanyScreen(),
    ),
    GoRoute(
      path: '/provider/pharmacy/branch/:id/edit',
      builder: (_, state) => EditBranchScreen(
        branchId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/clinic/analytics',
      builder: (_, s) => const ClinicAnalyticsScreen(),
    ),
    GoRoute(
      path: '/pharmacy/analytics',
      builder: (_, s) => const PharmacyBranchAnalyticsScreen(),
    ),
  ],
);
