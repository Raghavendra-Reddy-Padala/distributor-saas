import 'package:flutter/material.dart';
import 'package:priyanakaenterprises/screens/tabs/bills_tab.dart';
import 'package:priyanakaenterprises/screens/tabs/clients_tab.dart';
import 'package:priyanakaenterprises/screens/tabs/dashboard_tab.dart';
import 'package:priyanakaenterprises/screens/tabs/reminders_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // CORPORATE THEME COLORS
  final Color _navyPrimary = const Color(0xFF0D47A1);
  final Color _goldAccent = const Color(0xFFFFA000);

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    ClientsTab(),
    BillsTab(),
    RemindersTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Sharper, subtler shadow for a "floating card" feel
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard, // Removed "_rounded" for sharper look
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.groups,
                  label: 'Clients',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long,
                  label: 'Bills',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.notifications_active, // More urgent icon for reminders
                  label: 'Reminders',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  // Solid Navy Background when selected
                  color: isSelected ? _navyPrimary : Colors.transparent,
                  // Sharper corners (8) to match the finance aesthetic
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  // Gold Icon when selected (Premium), Grey when inactive
                  color: isSelected ? _goldAccent : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, // Slightly smaller, more professional font size
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  // Navy Text when selected, Grey when inactive
                  color: isSelected ? _navyPrimary : Colors.grey[500],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}