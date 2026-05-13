import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'add_to_cart_sheet.dart';
import 'product.dart';
import 'chat_screen.dart';
import 'custom_bouquet_screen.dart';
import 'services/api_service.dart';
import 'notification_screen.dart';
import 'app_language.dart';
import 'widgets/product_card.dart';

class BasBetScreen extends StatefulWidget {
  const BasBetScreen({super.key});

  @override
  State<BasBetScreen> createState() => _BasBetScreenState();
}

class _BasBetScreenState extends State<BasBetScreen>
    with SingleTickerProviderStateMixin {
  final Color darkPink = const Color(0xFFE60064);
  final Color lightPink = const Color(0xFFFFE6EB);

  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late final AnimationController _aboutUsRibbonController;

  List<Product> popularProducts = [];
  List<Product> recommendedProducts = [];
  List<Product> allProducts = [];
  bool _loadingPopular = true;
  bool _loadingRecommendations = true;
  bool _loadingAll = true;
  bool _photoSearching = false;
  bool _photoSearchActive = false;
  List<Product> _photoSearchResults = [];
  Set<String> _favoriteIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _aboutUsRibbonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _loadPopular();
    _loadRecommendations();
    _loadAllProducts();
    _loadFavorites();
  }

  @override
  void dispose() {
    _aboutUsRibbonController.dispose();
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

  Future<void> _loadRecommendations() async {
    try {
      final data = await ApiService.fetchRecommendations(limit: 8);
      if (!mounted) return;
      setState(() {
        recommendedProducts = data;
        _loadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecommendations = false);
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
    final t = context.t;
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
        SnackBar(
          content: Text(isFav ? t.removeFavoriteFailed : t.addFavoriteFailed),
        ),
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    final t = context.t;
    try {
      await ApiService.addToCart(product.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.addedToCart)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.addToCartFailed)));
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    if (_photoSearching) return;
    final t = context.t;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.choosePhotoSource,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: darkPink),
                  title: Text(t.camera),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: darkPink),
                  title: Text(t.gallery),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || source == null) return;
    await _searchByPhoto(source);
  }

  Future<void> _searchByPhoto(ImageSource source) async {
    final t = context.t;
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoSearching = true;
        _photoSearchActive = true;
        _photoSearchResults = [];
        _searchQuery = '';
        _searchController.clear();
      });

      final results = await ApiService.searchProductsByPhoto(bytes);
      if (!mounted) return;
      setState(() {
        _photoSearchResults = results;
        _photoSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoSearching = false;
        _photoSearchActive = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.photoSearchFailed)));
    }
  }

  void _clearPhotoSearch() {
    setState(() {
      _photoSearching = false;
      _photoSearchActive = false;
      _photoSearchResults = [];
    });
  }

  List<String> _tokenize(String input) {
    return input
        .toLowerCase()
        .split(RegExp(r"[\\s\\-_,.!?;:()\\[\\]{}]+"))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  bool _matchesSearch(Product product, String query, AppText t) {
    final queryWords = _tokenize(query);
    if (queryWords.isEmpty) return false;
    final normalizedName = '${product.name} ${t.productName(product)}'
        .toLowerCase();
    for (final word in queryWords) {
      if (normalizedName.contains(word)) return true;
    }
    return false;
  }

  List<Product> _searchResults(AppText t) {
    if (_searchQuery.trim().isEmpty) return [];
    return allProducts
        .where((product) => _matchesSearch(product, _searchQuery, t))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
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
          children: [
            Text(
              t.appName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_photoSearchActive || _photoSearching) ...[
              _buildPhotoSearchResults(),
            ] else if (_searchQuery.trim().isNotEmpty) ...[
              _buildSearchResults(),
            ] else ...[
              _buildRecommendationsSection(),
              if (_loadingRecommendations || recommendedProducts.isNotEmpty)
                const SizedBox(height: 25),
              _buildPopularHeader(),
              _buildPopularList(),
              const SizedBox(height: 25),
              _buildCustomBouquetCard(),
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
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: lightPink,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {
            _searchQuery = value;
            if (value.trim().isNotEmpty) {
              _photoSearchActive = false;
              _photoSearchResults = [];
            }
          }),
          decoration: InputDecoration(
            hintText: t.searchFlowers,
            prefixIcon: const Icon(Icons.search, color: Color(0xFFE60064)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_photoSearchActive)
                  IconButton(
                    tooltip: t.clearPhotoSearch,
                    onPressed: _clearPhotoSearch,
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                IconButton(
                  tooltip: t.searchByPhoto,
                  onPressed: _photoSearching ? null : _showPhotoSourceSheet,
                  icon: _photoSearching
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: darkPink,
                          ),
                        )
                      : Icon(Icons.photo_camera_outlined, color: darkPink),
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final t = context.t;
    if (_loadingAll) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE60064)),
        ),
      );
    }

    final results = _searchResults(t);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t.noSearchResults,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.searchResults,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _buildProductResultGrid(results),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoSearchResults() {
    final t = context.t;
    if (_photoSearching) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            CircularProgressIndicator(color: darkPink),
            const SizedBox(height: 12),
            Text(
              t.photoSearchLoading,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_photoSearchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t.photoSearchNoResults,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.photoSearchResults,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _buildProductResultGrid(_photoSearchResults),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductResultGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 276,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isFav = _favoriteIds.contains(product.id);
        return ProductCard(
          product: product,
          isFavorite: isFav,
          onTap: () => showAddToCartSheet(context, product),
          onAddToCartPressed: () => _addToCart(product),
          onFavoritePressed: () => _toggleFavorite(product),
          accentColor: darkPink,
          borderColor: lightPink,
        );
      },
    );
  }

  Widget _buildRecommendationsSection() {
    if (!_loadingRecommendations && recommendedProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        _buildSectionHeader(context.t.recommendedForYou),
        _buildProductRail(
          recommendedProducts,
          loading: _loadingRecommendations,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool showMore = false}) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: darkPink,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (showMore)
            Text(
              t.more,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularHeader() {
    return _buildSectionHeader(context.t.popularFlowers, showMore: true);
  }

  Widget _buildPopularList() {
    return _buildProductRail(popularProducts, loading: _loadingPopular);
  }

  Widget _buildProductRail(List<Product> products, {required bool loading}) {
    final t = context.t;
    if (loading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE60064)),
        ),
      );
    }

    if (products.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(child: Text(t.productsNotFound)),
      );
    }

    return SizedBox(
      height: 282,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isFav = _favoriteIds.contains(product.id);
          return ProductCard(
            product: product,
            isFavorite: isFav,
            width: 174,
            margin: const EdgeInsets.only(right: 14),
            onTap: () => showAddToCartSheet(context, product),
            onAddToCartPressed: () => _addToCart(product),
            onFavoritePressed: () => _toggleFavorite(product),
            accentColor: darkPink,
            borderColor: lightPink,
          );
        },
      ),
    );
  }

  Widget _buildCustomBouquetCard() {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomBouquetScreen(),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lightPink),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.local_florist, color: darkPink, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.customBouquetCtaTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.customBouquetCtaSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: darkPink, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutUsWithImages() {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Text(
            t.aboutUs,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(
          height: 140,
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const ribbonWidth = 720.0;
                final copies = (constraints.maxWidth / ribbonWidth).ceil() + 2;

                return AnimatedBuilder(
                  animation: _aboutUsRibbonController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        -ribbonWidth * _aboutUsRibbonController.value,
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: double.infinity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < copies; i++) ..._aboutUsCards(t),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _aboutUsCards(AppText t) {
    return [
      _infoCard(
        t.freshFlowers,
        'assets/us_1.png',
        alignment: const Alignment(0, -0.3),
      ),
      _infoCard(
        t.fastDelivery,
        'assets/us_2.png',
        alignment: const Alignment(0, -0.4),
      ),
      _infoCard(
        t.qualityGuarantee,
        'assets/us_3.png',
        alignment: const Alignment(0, -0.2),
      ),
    ];
  }

  Widget _infoCard(
    String title,
    String path, {
    Alignment alignment = Alignment.center,
  }) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
          alignment: alignment,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAICard() {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEE6F97), Color(0xFFE60064)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: darkPink.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.askAiAdvisor,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      t.aiAdvisorSubtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
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
