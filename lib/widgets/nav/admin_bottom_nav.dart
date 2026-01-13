import 'package:flutter/material.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _go(BuildContext context, String route) {
    // Avoid useless replacement to same route
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black12, width: 1),
          ),
        ),
        child: SizedBox(
          height: 62, // ✅ fixed height so it will not cover the body
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            currentIndex: currentIndex,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black,
            onTap: (index) {
              switch (index) {
                case 0:
                  _go(context, '/admin/admin_analytics_screen');
                  break;
                case 1:
                  // Settings screen
                  // If you're already on settings, do nothing.
                  // Otherwise navigate to settings.
                  _go(context, '/admin/admin_settings_screen');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
