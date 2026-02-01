import 'package:flutter/material.dart';
import 'product.dart';
import 'product_detail_screen.dart';
import 'chat_screen.dart';
import 'services/api_service.dart'; // Чатқа өту үшін міндетті



class BasBetScreen extends StatefulWidget {
  const BasBetScreen({super.key});

  @override
  State<BasBetScreen> createState() => _BasBetScreenState();
}

class _BasBetScreenState extends State<BasBetScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final Color lightPink = const Color(0xFFFFE6EB);

  // Танымал гүлдер тізімі (product_1-ден 3-ке дейін)
  List<Product> popularProducts = [];
  bool _loadingPopular = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icon_logo.png', // Бұлай өзгерт:
errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_florist, color: Colors.pink),),
        ),
        title: const Text("Gul alem", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // ХАБАРЛАМАЛАР БЕТІНЕ ӨТУ (Кейінірек жасаймыз)
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. ІЗДЕУ ЖОЛЫ
            _buildSearchBar(),

            // 2. ТАНЫМАЛ ГҮЛДЕР (Header + List)
            _buildPopularHeader(),
            _buildPopularList(),

            const SizedBox(height: 25),

            // 3. БІЗ ЖАЙЛЫ (Horizontal Scroll)
            _buildAboutUsWithImages(),

            const SizedBox(height: 25),

            // 4. AI КЕҢЕСШІ (Чатқа бару)
            _buildAICard(),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(color: lightPink, borderRadius: BorderRadius.circular(15)),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Гүлдерді іздеу...',
            prefixIcon: Icon(Icons.search, color: Color(0xFFE60064)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Танымал гүлдер", style: TextStyle(color: darkPink, fontWeight: FontWeight.bold, fontSize: 18)),
          GestureDetector(
            onTap: () { /* Барлық тізімге өту */ },
            child: const Text("Толығырақ", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          
        ],
      ),
    );
  }

  Widget _buildPopularList() {
    if (_loadingPopular) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator(color: Color(0xFFE60064))),
      );
    }

    if (popularProducts.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('Өнімдер табылмады')),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
        itemCount: popularProducts.length,
        itemBuilder: (context, index) {
          final product = popularProducts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ProductDetailScreen(initialProduct: product, products: popularProducts),
              ));
            },
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: lightPink),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Expanded(
                        child: Image.asset(product.imagePath, fit: BoxFit.contain, 
                          errorBuilder: (c, e, s) => Icon(Icons.image, color: lightPink, size: 50)),
                      ),
                      const SizedBox(height: 5),
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(product.formattedPrice, style: TextStyle(color: darkPink, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: () { /* Себетке қосу */ },
                        icon: Icon(Icons.shopping_cart_outlined, color: darkPink, size: 22),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Icon(Icons.favorite_border, color: darkPink, size: 20),
                  ),
                  if (!product.inStock)
                    Positioned(
                      bottom: 60,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Out of stock', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutUsWithImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, bottom: 12),
          child: Text("Біз жайлы", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 20),
            children: [
              _infoCard("Жаңа гүлдер", "assets/flower_mixed.png"),
              _infoCard("Жылдам жеткізу", "assets/flower_rose_red.png"),
              _infoCard("Сапа кепілдігі", "assets/flower_hydrangea.png"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, String path) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(path), 
          fit: BoxFit.cover, 
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)
        ),
      ),
      child: Center(
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildAICard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          // МІНЕ, ОСЫ ЖЕРДЕ ЧАТҚА ӨТЕДІ
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEE6F97), Color(0xFFE60064)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: darkPink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI Кеңесшіден сұрау", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Сізге таңдауға көмектесемін", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'catalog_screen.dart';

// class Product {
//   final String id;
//   final String name;
//   final String price;
//   final Color color;

//   Product(this.id, this.name, this.price, this.color);
// }

// class ProductDetailScreen extends StatelessWidget {
//   final Product product;
//   final List<Product> allProducts; // Навигацияға қажеттілік үшін

//   const ProductDetailScreen({super.key, required this.product, required this.allProducts});
  
//   // Түстер
//   final Color darkPink = const Color.fromARGB(255, 230, 0, 100);

//   // Өнім атауына сәйкес үлкен суретті көрсететін виджет
//   Widget _buildMainProductImage(Size screenSize) {
//     return Container(
//       height: screenSize.height * 0.6,
//       alignment: Alignment.center,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // 🖼️ Негізгі сурет
//           Image.asset(
//             // Ескерту: Сурет жолы 'assets/product_1.png' форматында болуы керек
//             'assets/product_${product.id}.png', 
//             height: screenSize.height * 0.5,
//             fit: BoxFit.contain,
//             errorBuilder: (context, error, stackTrace) {
//               return Icon(Icons.local_florist, size: 150, color: darkPink.withOpacity(0.7));
//             },
//           ),
//           // 👈 Сол жақ стрелка
//           const Positioned(
//             left: 5,
//             child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 35),
//           ),
//           // 👉 Оң жақ стрелка
//           const Positioned(
//             right: 5,
//             child: Icon(Icons.arrow_forward_ios, color: Colors.black, size: 35),
//           ),
//           // 🏷️ Баға тегі (Сұр түсті стиль)
//           Positioned(
//             bottom: 30,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.withOpacity(0.8), 
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               child: Text(
//                 product.price.replaceAll(' тг', ''), 
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Size screenSize = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.favorite_border, color: Colors.black, size: 28),
//             onPressed: () {},
//           ),
//           const SizedBox(width: 10),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // 1. Үлкен сурет, баға, стрелкалар
//             _buildMainProductImage(screenSize),

//             // 2. Өнім атауы
//             Padding(
//               padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
//               child: Text(
//                 product.name.replaceAll('"', ''), 
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontStyle: FontStyle.italic,
//                   color: Colors.grey.shade700,
//                 ),
//               ),
//             ),
            
//             // 3. Себетке қосу батырмасы
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('${product.name} себетке қосылды!')),
//                   );
//                 },
//                 icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                 label: const Text(
//                   'Себетке қосу',
//                   style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: darkPink, 
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//                   minimumSize: Size(screenSize.width * 0.9, 50),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//           ],
//         ),
//       ),
//       // Төменгі навигацияны бұл бетте көрсетпейміз
//     );
//   }
// }
// // -------------------------------------------------------------
// // 👆 ProductDetailScreen
// // -------------------------------------------------------------


// // -------------------------------------------------------------
// // 👇 BasBetScreen (onTap логикасы өзгертілген)
// // -------------------------------------------------------------
// class BasBetScreen extends StatefulWidget {
//   const BasBetScreen({super.key});

//   @override
//   State<BasBetScreen> createState() => _BasBetScreenState();
// }

// class _BasBetScreenState extends State<BasBetScreen> {
//   // 🎨 Түстер
//   final Color softPink = Colors.white;
//   final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
//   final Color accentPink = const Color.fromARGB(255, 238, 111, 151);
//   final Color navBarPink = const Color.fromARGB(255, 255, 230, 235);

//   final String logoPath = 'assets/icon_logo.png';
//   final String aboutUsImagePath = 'assets/team_photo.png';

//   bool _showWelcome = false;

//   // 🛍️ Өнімдер тізімі
//   final List<Product> popularProducts = [
//     Product('1', '"Ақ раушан"', '16 990 тг', Colors.white),
//     Product('2', '"Тосынсый"', '31 990 тг', const Color.fromARGB(255, 255, 255, 255)),
//     Product('3', '"Себеп-сіз"', '13 990 тг', const Color.fromARGB(255, 252, 252, 252)),
//     Product('4', '"Доллар букеті"', '85 000 тг', const Color.fromARGB(255, 255, 255, 255)),
//     Product('5', '"Тәтті букеті"', '28 500 тг', const Color.fromARGB(255, 255, 255, 255)), 
//     Product('6', '"Себеп-сіз"', '18 990 тг', const Color.fromARGB(255, 255, 255, 255)),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) setState(() => _showWelcome = true);
//       Future.delayed(const Duration(seconds: 3), () {
//         if (mounted) setState(() => _showWelcome = false);
//       });
//     });
//   }

//   // 🛍️ Өнім карточкасы
//   Widget _buildProductCard(Product product, Size screenSize) {
//     final double cardWidth = screenSize.width * 0.45; 
//     final Color priceTagColor = darkPink.withOpacity(0.9); 

//     return GestureDetector(
//       // 👇 ОСЫ ЖЕРДЕГІ НАВИГАЦИЯ ӨЗГЕРТІЛДІ/ҚОСЫЛДЫ
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ProductDetailScreen(
//               product: product, // Таңдалған өнім
//               allProducts: popularProducts, // Өнімдер тізімі
//             ),
//           ),
//         );
//       },
//       // 👆
//       child: Container(
//         margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10), 
//         width: cardWidth,
//         child: Column(
//           children: [
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: product.color,
//                   borderRadius: BorderRadius.circular(25),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.3),
//                       blurRadius: 7,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Stack(
//                   children: [
//                     const Positioned(
//                       top: 10,
//                       right: 10,
//                       child: Icon(Icons.favorite_border, color: Colors.black54, size: 24), 
//                     ),
//                     Center(
//                       child: Image.asset(
//                         'assets/product_${product.id}.png', 
//                         width: cardWidth * 6, 
//                         height: cardWidth * 6,
//                         fit: BoxFit.contain,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Icon(Icons.local_florist, size: 60, color: darkPink.withOpacity(0.7));
//                         },
//                       ),
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       left: 0,
//                       right: 0,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: priceTagColor,
//                           borderRadius: const BorderRadius.only(
//                             bottomLeft: Radius.circular(25),
//                             bottomRight: Radius.circular(25),
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20), 
//                             Text(
//                               product.price,
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5),
//             Text(product.name,
//                 style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey.shade600,
//                     fontWeight: FontWeight.w500)),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🌷 Танымал гүлдер бөлімі (өзгеріссіз)
//   Widget _buildPopularCollection(Size screenSize) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0), 
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//             decoration: BoxDecoration(
//               color: navBarPink,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               'Танымал гүлдер топтамасы: ',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkPink),
//             ),
//           ),
//         ),
//         SizedBox(
//           height: screenSize.height * 0.35, 
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: Row(
//               children: popularProducts
//                   .map((product) => _buildProductCard(product, screenSize))
//                   .toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // 💐 Біз жайлы бөлімі (өзгеріссіз)
//   Widget _buildAboutUsSection(Size screenSize) {
//     final Widget aboutUsCard = Container(
//       width: screenSize.width * 0.8,
//       margin: const EdgeInsets.symmetric(horizontal: 10),
//       padding: const EdgeInsets.all(25),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 7, offset: const Offset(0, 3)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Біз жайлы',
//               style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w900,
//                   color: darkPink,
//                   fontStyle: FontStyle.italic)),
//           const SizedBox(height: 15),
//           const Text(
//             '«Gul alem» — Қазақстан бойынша онлайн гүл жеткізу қызметі. Біз сапалы және жаңа гүлдерді уақтылы жеткіземіз. Біздің мақсатымыз — әрбір клиентке ерекше көңіл бөлу және олардың қуанышына себепші болу.',
//             style: TextStyle(fontSize: 14, color: Colors.black87),
//           ),
//         ],
//       ),
//     );

//     return Container(
//       color: navBarPink.withOpacity(0.7),
//       padding: const EdgeInsets.symmetric(vertical: 15), 
//       child: SizedBox(
//         height: screenSize.height * 0.25,
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           child: Row(
//             children: [
//               aboutUsCard,
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(30),
//                 child: Image.asset(
//                   aboutUsImagePath,
//                   width: screenSize.width * 0.5,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container( 
//                       color: accentPink.withOpacity(0.2),
//                       width: screenSize.width * 0.5,
//                       child: Center(child: Icon(Icons.local_florist, size: 50, color: darkPink)),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(width: 10), 
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // 🔘 Төменгі навигация (өзгеріссіз)
//   Widget _buildBottomNavBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: navBarPink,
//         boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, offset: const Offset(0, 3))],
//       ),
//       height: 80,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           IconButton(icon: Icon(Icons.home, color: darkPink, size: 30), onPressed: () {}),
//           IconButton(icon: Icon(Icons.favorite_border, color: darkPink, size: 30), onPressed: () {}),
//           IconButton(icon: Icon(Icons.shopping_cart_outlined, color: darkPink, size: 30), onPressed: () {}),
//           IconButton(icon: Icon(Icons.person_outline, color: darkPink, size: 30), onPressed: () {}),
//         ],
//       ),
//     );
//   }

//   // 🎉 Қош келдіңіз анимациясы (өзгеріссіз)
//   Widget _buildWelcomeOverlay(Size screenSize) {
//     if (!_showWelcome) return const SizedBox.shrink();
//     return AnimatedOpacity(
//       opacity: _showWelcome ? 1.0 : 0.0,
//       duration: const Duration(milliseconds: 500),
//       child: Container(
//         width: screenSize.width,
//         height: screenSize.height,
//         color: const Color.fromARGB(255, 255, 255, 255),
//         child: Center(
//           child: Container(
//             padding: const EdgeInsets.all(30),
//             decoration: BoxDecoration(
//               color: darkPink,
//               borderRadius: BorderRadius.circular(25),
//               boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
//             ),
//             child: const Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.thumb_up_alt_outlined, color: Colors.white, size: 50),
//                 SizedBox(height: 15),
//                 Text('Қош келдіңіз!',
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 🏡 Негізгі экран
//   @override
//   Widget build(BuildContext context) {
//     final Size screenSize = MediaQuery.of(context).size;

//     return Stack(
//       children: [
//         Scaffold(
//           backgroundColor: softPink,
//           appBar: AppBar(
//             backgroundColor: softPink,
//             elevation: 0,
//             toolbarHeight: 70,
//             title: Row(
//               children: [
//                 Image.asset(
//                   logoPath,
//                   width: 40,
//                   height: 40,
//                   errorBuilder: (context, error, stackTrace) =>
//                       Icon(Icons.local_florist, color: darkPink, size: 30),
//                 ),
//                 const SizedBox(width: 8),
//                 const Text('Gul alem',
//                     style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
//                 onPressed: () {
//                   // Хабарландырулар бетіне өту логикасы
//                 },
//               ),
//               const SizedBox(width: 10),
//             ],
//           ),
//           body: SingleChildScrollView(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 15),
//                     decoration:
//                         BoxDecoration(color: navBarPink, borderRadius: BorderRadius.circular(15)),
//                     child: const TextField(
//                       decoration: InputDecoration(
//                           hintText: 'Іздеу...',
//                           border: InputBorder.none,
//                           icon: Icon(Icons.search, color: Color.fromARGB(255, 230, 0, 100))),
//                     ),
//                   ),
//                 ),
//                 _buildPopularCollection(screenSize),
//                 const SizedBox(height: 15), 
//                 _buildAboutUsSection(screenSize),
//                 const SizedBox(height: 15), 
//      ElevatedButton(
//   onPressed: () {
//     // Ешқандай route-сыз, тікелей ауысу:
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const CatalogScreen()),
//     );
//   },
//   style: ElevatedButton.styleFrom(
//     backgroundColor: const Color.fromARGB(255, 238, 111, 151).withOpacity(0.8),
//     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//   ),
//   child: const Text('Каталогқа өту',
//       style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
// ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//           bottomNavigationBar: _buildBottomNavBar(),
//         ),
//         _buildWelcomeOverlay(screenSize),
//       ],
//     );
//   }
// }


