import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/expense_dashboard_screen.dart';
import 'expenses/expenses_list_screen.dart';
import 'reimbursement/reimbursement_screen.dart';
import 'split/split_expenses_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  static void navigateToTab(int index) {
    activeTabNotifier.value = index;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final List<Widget> _screens = const [
    ExpenseDashboardScreen(), // 0: Home (Page 4)
    ExpensesListScreen(),     // 1: Expenses (Page 7)
    ReimbursementScreen(),    // 2: Claims (Page 2)
    SplitExpensesScreen(),    // 3: Split (Page 1)
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainShell.activeTabNotifier,
      builder: (context, currentIndex, _) {
        // Clamp index to available tabs to prevent out-of-range errors
        final safeIndex = currentIndex.clamp(0, _screens.length - 1);

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
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
              currentIndex: safeIndex,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              onTap: (index) {
                MainShell.activeTabNotifier.value = index;
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
              ],
            ),
          ),
        );
      },
    );
  }
}
