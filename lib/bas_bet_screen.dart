import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'product.dart';
import 'chat_screen.dart';
import 'services/api_service.dart';
import 'notification_screen.dart';

class BasBetScreen extends StatefulWidget {
  const BasBetScreen({super.key});

  @override
  State<BasBetScreen> createState() => _BasBetScreenState();
}

class _BasBetScreenState extends State<BasBetScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final Color lightPink = const Color(0xFFFFE6EB);

  final TextEditingController _searchController = TextEditingController();

  List<Product> popularProducts = [];
  List<Product> allProducts = [];
  bool _loadingPopular = true;
  bool _loadingAll = true;
  Set<String> _favoriteIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPopular();
    _loadAllProducts();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopular() async {
    try {
      final data = await ApiService.fetchProducts(popularOnly: true);
      if (!mounted) return;
      setState(() {
        popularProducts = data;
        _loadingPopular = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPopular = false);
    }
  }

  Future<void> _loadAllProducts() async {
    try {
      final data = await ApiService.fetchProducts();
      if (!mounted) return;
      setState(() {
        allProducts = data;
        _loadingAll = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAll = false);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteIds = favorites.map((item) => item.id).toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite(Product product) async {
    final isFav = _favoriteIds.contains(product.id);
    try {
      if (isFav) {
        await ApiService.removeFavorite(product.id);
      } else {
        await ApiService.addFavorite(product.id);
      }
      if (!mounted) return;
      setState(() {
        if (isFav) {
          _favoriteIds.remove(product.id);
        } else {
          _favoriteIds.add(product.id);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFav ? 'Таңдаулыдан өшіру сәтсіз' : 'Таңдаулыға қосу сәтсіз')),
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      await ApiService.addToCart(product.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Себетке қосылды')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Себетке қосу сәтсіз')),
      );
    }
  }

  List<String> _tokenize(String input) {
    return input
        .toLowerCase()
        .split(RegExp(r"[\\s\\-_,.!?;:()\\[\\]{}]+"))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  bool _matchesSearch(Product product, String query) {
    final queryWords = _tokenize(query);
    if (queryWords.isEmpty) return false;
    final normalizedName = product.name.toLowerCase();
    for (final word in queryWords) {
      if (normalizedName.contains(word)) return true;
    }
    return false;
  }

  List<Product> get _searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    return allProducts.where((product) => _matchesSearch(product, _searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icon_logo.png',
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.local_florist, color: Colors.pink),
          ),
        ),
        title: Row(
          children: const [
            Text('Gul alem', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_searchQuery.trim().isNotEmpty) ...[
              _buildSearchResults(),
            ] else ...[
              _buildPopularHeader(),
              _buildPopularList(),
              const SizedBox(height: 25),
              _buildAboutUsWithImages(),
              const SizedBox(height: 25),
              _buildAICard(),
              const SizedBox(height: 30),
            ],
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
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            hintText: '\u0413\u04af\u043b\u0434\u0435\u0440\u0434\u0456 \u0456\u0437\u0434\u0435\u0443...',
            prefixIcon: Icon(Icons.search, color: Color(0xFFE60064)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_loadingAll) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFE60064))),
      );
    }

    final results = _searchResults;
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Іздеу нәтижесі табылмады', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Іздеу нәтижелері',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final product = results[index];
              return GestureDetector(
                onTap: () => showAddToCartSheet(context, product),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: lightPink),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child: Image.asset(
                              product.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) =>
                                  Icon(Icons.image, color: lightPink, size: 50),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.formattedPrice,
                            style: TextStyle(color: darkPink, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            onPressed: () => _addToCart(product),
                            icon: Icon(Icons.add_circle, color: darkPink, size: 22),
                          ),
                        ],
                      ),
                      if (!product.inStock)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Қоймада жоқ',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPopularHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Танымал гүлдер',
            style: TextStyle(color: darkPink, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text('Толығырақ', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
          final isFav = _favoriteIds.contains(product.id);
          return GestureDetector(
            onTap: () => showAddToCartSheet(context, product),
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
                        child: Image.asset(
                          product.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) =>
                              Icon(Icons.image, color: lightPink, size: 50),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(product.formattedPrice,
                          style: TextStyle(color: darkPink, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: () => _addToCart(product),
                        icon: Icon(Icons.add_circle, color: darkPink, size: 22),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      onPressed: () => _toggleFavorite(product),
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: darkPink, size: 20),
                    ),
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
                        child: const Text('Қоймада жоқ',
                            style: TextStyle(color: Colors.white, fontSize: 10)),
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
          child: Text('Біз жайлы', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 20),
            children: [
              _infoCard(
                'Жаңа гүлдер',
                'assets/us_1.png',
                alignment: const Alignment(0, -0.3),
              ),
              _infoCard(
                'Жылдам жеткізу',
                'assets/us_2.png',
                alignment: const Alignment(0, -0.4),
              ),
              _infoCard(
                'Сапа кепілдігі',
                'assets/us_3.png',
                alignment: const Alignment(0, -0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, String path, {Alignment alignment = Alignment.center}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
          alignment: alignment,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ),
      ),
      child: Center(
        child: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildAICard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
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
                    Text('ЖИ кеңесшіден сұрау',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Сізге таңдауға көмектесемін',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
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

