import 'package:flutter/material.dart';
import 'bas_bet_screen.dart';
import 'catalog_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Беттер тізімі (5 бет)
    final List<Widget> _screens = [
      const BasBetScreen(), // 0
      const CatalogScreen(), // 1
      const Center(child: Text("Избранное беті")), // 2
      const Center(child: Text("Себет беті")),    // 3
      const Center(child: Text("Профиль беті")),  // 4
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFE6EB),
        selectedItemColor: const Color(0xFFE60064),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false, // Жазуларды өшірдік
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ""),
        ],
      ),
    );
  }
}

// class MainWrapper extends StatefulWidget {
//   const MainWrapper({super.key});

//   @override
//   State<MainWrapper> createState() => _MainWrapperState();
// }

// class _MainWrapperState extends State<MainWrapper> {
//   int _currentIndex = 0; // Қазіргі индекс
//   final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
//   final Color navBarPink = const Color.fromARGB(255, 255, 230, 235);

//   // Беттерді ауыстыру функциясы
//   void _changePage(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Беттер тізімі
//     final List<Widget> _pages = [
//       BasBetScreen(onCatalogTap: () => _changePage(1)), // 0 индекс
//       const CatalogScreen(), // 1 индекс
//       const Center(child: Text("Себет")), // 2 индекс
//       const Center(child: Text("Профиль")), // 3 индекс
//     ];

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         toolbarHeight: 70,
//         title: Row(
//           children: [
//             Icon(Icons.local_florist, color: darkPink, size: 30),
//             const SizedBox(width: 8),
//             const Text('Gul alem',
//                 style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
//           ],
//         ),
//         actions: [
//           IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28), onPressed: () {}),
//         ],
//       ),
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _pages,
//       ),
//       bottomNavigationBar: Container(
//         height: 80,
//         decoration: BoxDecoration(
//           color: navBarPink,
//           boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, offset: const Offset(0, 3))],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _currentIndex,
//           onTap: _changePage,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: darkPink,
//           unselectedItemColor: darkPink.withOpacity(0.5),
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//             BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Catalog'),
//             BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
//             BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
//           ],
//         ),
//       ),
//     );
//   }
// }