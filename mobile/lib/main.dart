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
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/phone_otp_screen.dart';
import 'screens/onboarding/kyc_lite_screen.dart';
import 'screens/onboarding/employer_link_screen.dart';
import 'screens/onboarding/consent_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: AppRoutes.mainShell,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.phoneOtp: (context) => const PhoneOtpScreen(),
        AppRoutes.kycLite: (context) => const KycLiteScreen(),
        AppRoutes.employerLink: (context) => const EmployerLinkScreen(),
        AppRoutes.consent: (context) => const ConsentScreen(),
        AppRoutes.mainShell: (context) => const MainShell(),
        AppRoutes.dashboard: (context) => const ExpenseDashboardScreen(),
        AppRoutes.reimbursement: (context) => const ReimbursementScreen(),
        AppRoutes.splitExpenses: (context) => const SplitExpensesScreen(),
        AppRoutes.aiAssistant: (context) => const AiAssistantScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
      },
    );
  }
}
