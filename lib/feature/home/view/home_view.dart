import 'package:flutter/material.dart';
import 'package:mavikalem_app/product/model/category_model.dart';
import 'package:mavikalem_app/product/model/product_model.dart';
import 'package:mavikalem_app/product/service/service.dart';

final class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

final class _HomeViewState extends State<HomeView> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  int? _selectedCategoryId;

  List<ProductModel>? _searchResults;
  bool _isSearching = false;
  bool _isLoadingSearch = false;

  Future<void> _onSearchSubmitted(String val) async {
    if (val.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingSearch = true;
    });

    final results = await _productService.searchSmart(val);

    setState(() {
      _isLoadingSearch = false;
      _searchResults = results;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eşleşen ürün bulunamadı!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sayfa arka planını beyaz yaptık
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar beyaz olsun ki logo şık dursun
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ), // Menü ikonu siyah olsun
        // LOGO ARTIK APPBAR'IN MERKEZİNDE
        title: Image.asset(
          'assets/logo1.webp',
          height: 40, // Yüksekliği sınırladık ki taşmasın
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // ARAMA ÇUBUĞU ARTIK SAYFANIN TEPESİNDE
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _buildSearchField(),
          ),
          // ÜRÜN LİSTESİ VEYA ARAMA SONUÇLARI (Geri kalan alanı kaplar)
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  // --- EKRAN GÖVDESİ İÇERİĞİ ---
  Widget _buildBodyContent() {
    if (_isSearching && _isLoadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSearching && _searchResults != null) {
      if (_searchResults!.isEmpty) {
        return const Center(child: Text("Aramanıza uygun ürün bulunamadı."));
      }
      return _buildProductGrid(_searchResults!);
    }

    return FutureBuilder<List<ProductModel>>(
      future: _productService.fetchProducts(categoryId: _selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Bu kategoride ürün bulunamadı.'));
        }

        return _buildProductGrid(snapshot.data!);
      },
    );
  }

  // --- ORTAK GRID YAPISI ---
  Widget _buildProductGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _ProductCard(product: products[index]),
    );
  }

  // --- ARAMA ÇUBUĞU (GÜNCELLENDİ) ---
  Widget _buildSearchField() {
    return Container(
      height: 45, // Gövdede durduğu için biraz daha kalın ve şık yaptık
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Hafif gri arka plan
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // Şık bir çerçeve
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Ürün veya SKU ara...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          prefixIcon: const Icon(Icons.search, size: 22, color: Colors.grey),
          // X BUTONU ARTIK BURADA İÇERİDE
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchSubmitted("");
                    // Klavyeyi kapat
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (val) {
          _onSearchSubmitted(val);
          // Klavyeyi kapat
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  // --- DRAWER (MENÜ) ---
  Drawer _buildDrawer() {
    return Drawer(
      child: FutureBuilder<List<CategoryModel>>(
        future: _categoryService.fetchCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rootCategories = snapshot.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Center(
                  child: Image.asset('assets/logo1.webp', fit: BoxFit.contain),
                ),
              ),
              ...rootCategories.map((cat) => _buildCategoryTile(cat)),
            ],
          );
        },
      ),
    );
  }

  // Recursive Menü
  Widget _buildCategoryTile(CategoryModel category) {
    if (category.subCategories.isEmpty) {
      return ListTile(
        title: Text(
          category.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onTap: () {
          setState(() {
            _selectedCategoryId = category.id;
            _isSearching = false;
            _searchResults = null;
            _searchController.clear();
          });
          Navigator.pop(context);
        },
      );
    }

    return ExpansionTile(
      title: Text(
        category.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      children: category.subCategories.map((subCat) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: _buildCategoryTile(subCat),
        );
      }).toList(),
    );
  }
}

// --- ÜRÜN KARTI ---
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                product.imageUrl.isEmpty
                    ? 'https://via.placeholder.com/150'
                    : product.imageUrl,
                fit: BoxFit.contain,
                headers: const {"User-Agent": "Mozilla/5.0"},
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.brandName,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "${product.price.toStringAsFixed(2)} TL",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("1"), Icon(Icons.keyboard_arrow_down)],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: const Text("SEPETE EKLE", style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
