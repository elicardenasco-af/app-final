import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/promo_banner.dart';
import '../../services/shop_service.dart';
import '../../widgets/error_view.dart';
import '../product/product_detail_screen.dart';
import 'banner_carousel.dart';
import 'product_card.dart';

/// 03 — Pantalla Home: carrusel, buscador, filtro por categorías y grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();

  List<PromoBanner> _banners = [];
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _selectedCategoryId; // null = Todos
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final shop = context.read<ShopService>();
    setState(() {
      _loading = _products.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([shop.banners(), shop.categories(), shop.products()]);
      if (!mounted) return;
      setState(() {
        _banners = results[0] as List<PromoBanner>;
        _categories = results[1] as List<Category>;
        _products = results[2] as List<Product>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Filtra por nombre (en tiempo real) y por categoría.
  List<Product> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _products.where((p) {
      final matchesCategory = _selectedCategoryId == null || p.category.id == _selectedCategoryId;
      final matchesQuery = query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _products.isEmpty) return ErrorView(message: _error!, onRetry: _load);

    final products = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: BannerCarousel(banners: _banners)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _chip(null, 'Todos'),
                  for (final c in _categories) _chip(c.id, c.name),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No encontramos productos con ese criterio'),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductCard(
                    product: products[i],
                    onTap: () => _openProduct(products[i]),
                  ),
                  childCount: products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(int? id, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedCategoryId == id,
        onSelected: (_) => setState(() => _selectedCategoryId = id),
      ),
    );
  }
}
