import 'package:flutter/material.dart';
import 'category_detail_screen.dart'; // Келесі бетті тану үшін керек

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
    final Color navBarPink = const Color.fromARGB(255, 255, 230, 235);

    final List<String> catalogImages = [
      "assets/cat_1.png",
      "assets/cat_2.png",
      "assets/cat_3.png",
      "assets/cat_4.png",
      "assets/cat_5.png",
      "assets/cat_6.png",
      "assets/cat_7.png",
      "assets/cat_8.png",
      "assets/cat_9.png",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Каталог",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0,
          ),
          itemCount: catalogImages.length,
          itemBuilder: (context, index) {
            // GestureDetector қосылды - басуды сезу үшін
            return GestureDetector(
              onTap: () {
                // Карточканы басқанда осы функция орындалады
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailScreen(
                      categoryIndex: index + 1, // Қай карточка басылғанын жібереміз
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: navBarPink, width: 2),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    catalogImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.local_florist, size: 50, color: darkPink),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// class CatalogScreen extends StatelessWidget {
//   const CatalogScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
//     final Color navBarPink = const Color.fromARGB(255, 255, 230, 235);

//     // 9 фотодан тұратын тізім
//     final List<String> catalogImages = [
//       "assets/cat_1.png",
//       "assets/cat_2.png",
//       "assets/cat_3.png",
//       "assets/cat_4.png",
//       "assets/cat_5.png",
//       "assets/cat_6.png",
//       "assets/cat_7.png", // Жаңа фотолар
//       "assets/cat_8.png",
//       "assets/cat_9.png",
//     ];

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "Каталог",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: GridView.builder(
//           // GridView баптаулары
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2, // 2 баған
//             crossAxisSpacing: 15,
//             mainAxisSpacing: 15,
//             childAspectRatio: 1.0, // Карточкалар квадратты болуы үшін
//           ),
//           itemCount: catalogImages.length, // Барлығы 9
//           itemBuilder: (context, index) {
//             return Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: navBarPink, width: 2),
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(18), // Жиегін дөңгелету
//                 child: Image.asset(
//                   catalogImages[index],
//                   fit: BoxFit.cover, // Фото бүкіл жерді толтырып тұрады
//                   errorBuilder: (context, error, stackTrace) => 
//                       Icon(Icons.local_florist, size: 50, color: darkPink),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
