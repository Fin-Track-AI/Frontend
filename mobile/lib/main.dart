import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/main_shell.dart';
import 'screens/dashboard/expense_dashboard_screen.dart';
import 'screens/expenses/expenses_list_screen.dart';
import 'screens/reimbursement/reimbursement_screen.dart';
import 'screens/split/split_expenses_screen.dart';
import 'screens/assistant/ai_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/app_landing_screen.dart';
import 'screens/onboarding/phone_otp_screen.dart';
import 'screens/onboarding/kyc_lite_screen.dart';
import 'screens/onboarding/employer_link_screen.dart';
import 'screens/onboarding/company_selection_screen.dart';
import 'screens/onboarding/consent_screen.dart';
import 'screens/onboarding/financial_setup_screen.dart';
import 'services/session_service.dart';
import 'services/user_financial_service.dart';
import 'core/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve backend API URL (Primary Cloud Run with Localhost fallback)
  await ApiConfig.getActiveBaseUrl();

  // Restore persisted session (JWT + user) before any screen renders
  await SessionService().init();

  // Restore local financial data (salary, expenses stored on device)
  await UserFinancialService().init();

  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.welcome: (context) => const AppLandingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignUpScreen(),
        AppRoutes.phoneOtp: (context) => const PhoneOtpScreen(),
        AppRoutes.kycLite: (context) => const KycLiteScreen(),
        AppRoutes.employerLink: (context) => const EmployerLinkScreen(),
        AppRoutes.companySelection: (context) => const CompanySelectionScreen(),
        AppRoutes.consent: (context) => const ConsentScreen(),
        AppRoutes.financialSetup: (context) => const FinancialSetupScreen(),
        AppRoutes.mainShell: (context) => const MainShell(),
        AppRoutes.dashboard: (context) => const ExpenseDashboardScreen(),
        AppRoutes.expenses: (context) => const ExpensesListScreen(),
        AppRoutes.reimbursement: (context) => const ReimbursementScreen(),
        AppRoutes.splitExpenses: (context) => const SplitExpensesScreen(),
        AppRoutes.aiAssistant: (context) => const AiAssistantScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
      },
    );
  }
}
