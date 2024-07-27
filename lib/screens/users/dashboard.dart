import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth_provider.dart';
import 'home.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Home(),
    const Center(child: Text('Cart Screen')),
    const Center(child: Text('Transaction Screen')),
    const Center(child: Text('Profile Screen')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.userId == null) {
          Future.microtask(
              () => Navigator.pushReplacementNamed(context, '/login'));
          return SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Dashboard'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            items: <BottomNavigationBarItem>[
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.shopping_cart, 'Cart', 1),
              _buildNavItem(Icons.receipt_long, 'Transaksi', 2),
              _buildNavItem(Icons.person, 'Profile', 3),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(8),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
