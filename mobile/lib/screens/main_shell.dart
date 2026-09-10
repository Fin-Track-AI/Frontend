import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/expense_dashboard_screen.dart';
import 'expenses/expenses_list_screen.dart';
import 'reimbursement/reimbursement_screen.dart';
import 'split/split_expenses_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExpenseDashboardScreen(), // Home (Page 4)
    ExpensesListScreen(),     // Expenses (Page 7)
    ReimbursementScreen(),    // Claims (Page 2)
    SplitExpensesScreen(),    // Split (Page 1)
    ProfileScreen(),          // Profile (Page 6)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined, size: 22),
              activeIcon: Icon(Icons.receipt_long_rounded, size: 22),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined, size: 22),
              activeIcon: Icon(Icons.description_rounded, size: 22),
              label: 'Claims',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.incomplete_circle_outlined, size: 22),
              activeIcon: Icon(Icons.incomplete_circle_rounded, size: 22),
              label: 'Split',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 22),
              activeIcon: Icon(Icons.person_rounded, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
