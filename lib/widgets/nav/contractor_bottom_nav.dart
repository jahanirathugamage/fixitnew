import 'package:flutter/material.dart';

class ContractorBottomNav extends StatelessWidget {
  final int currentIndex;

  const ContractorBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _go(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
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
              _go(context, "/dashboards/contractor/contractor_jobs");
              break;
            case 1:
              _go(context, "/dashboards/contractor/contractor_service_providers");
              break;
            case 2:
              _go(context, "/dashboards/contractor/contractor_earnings");
              break;
            case 3:
              _go(context, "/dashboards/home_contractor");
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            label: "Providers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: "Earnings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
