import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mavikalem_app/product/model/product_model.dart';
import 'package:mavikalem_app/product/model/category_model.dart';

final class CategoryService {
  static const String _baseUrl = 'https://mavikalem.myideasoft.com/api';
  final String _token =
      'ZGM0MGY4MjEyNjNiZTM1OGE2YTg4NDYyMTc5MGFjZTRiOTcyMGRjNWE3NGFlZDM2N2QwYTA2MDQ1NmY0OGE0Yw';

  Future<List<CategoryModel>> fetchCategories() async {
    final url = Uri.parse('$_baseUrl/categories?limit=50'); // Limiti 100 tuttuk
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        Map<int, CategoryModel> categoryMap = {};

        // 1. AŞAMA: Tüm kategorileri ve EKSİK ANA KATEGORİLERİ map'e doldur
        for (var item in data) {
          int id = item['id'];

          // Kendisini ekle
          if (!categoryMap.containsKey(id)) {
            categoryMap[id] = CategoryModel.fromJson(item);
          }

          // HAYAT KURTARAN DOKUNUŞ: Eğer parent varsa ama map'te yoksa, onu parent objesinden yarat!
          if (item['parent'] != null) {
            int pId = item['parent']['id'];
            if (!categoryMap.containsKey(pId)) {
              categoryMap[pId] = CategoryModel.fromJson(item['parent']);
            }
          }
        }

        List<CategoryModel> rootCategories = [];

        // 2. AŞAMA: Ağaç (Tree) Hiyerarşisini Kur
        categoryMap.forEach((id, cat) {
          if (cat.parentId == null) {
            rootCategories.add(
              cat,
            ); // En tepedeki başlıklar (Kitap, Deneme vs.)
          } else {
            var parent = categoryMap[cat.parentId];
            if (parent != null) {
              // Aynı kategoriyi 2 kez eklememek için kontrol
              if (!parent.subCategories.any((c) => c.id == cat.id)) {
                parent.subCategories.add(cat);
              }
            } else {
              rootCategories.add(cat);
            }
          }
        });

        return rootCategories;
      }
      throw Exception('Kategori hatası');
    } catch (e) {
      debugPrint('Kategori Cekme Hatasi: $e');
      rethrow;
    }
  }
}

final class ProductService {
  static const String _baseUrl = 'https://mavikalem.myideasoft.com/api';
  final String _token =
      'ZGM0MGY4MjEyNjNiZTM1OGE2YTg4NDYyMTc5MGFjZTRiOTcyMGRjNWE3NGFlZDM2N2QwYTA2MDQ1NmY0OGE0Yw';

  /// 1. Mevcut Kategoriye Göre Listeleme Metodu
  Future<List<ProductModel>> fetchProducts({int? categoryId}) async {
    final String endpoint = categoryId != null
        ? '$_baseUrl/products?categories=$categoryId&limit=100'
        : '$_baseUrl/products?limit=50';

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ProductModel.fromJson(e)).toList();
      }
      throw Exception('Ürünler getirilemedi');
    } catch (e) {
      rethrow;
    }
  }

  /// 2. SKU İle Nokta Atışı Arama
  Future<ProductModel?> fetchProductBySku(String sku) async {
    final url = Uri.parse('$_baseUrl/products?sku=$sku');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          return ProductModel.fromJson(data[0]);
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('SKU Sorgu Hatasi: $e');
      return null;
    }
  }

  /// 3. Hem SKU hem İsim aramasına duyarlı akıllı metod
  Future<List<ProductModel>> searchSmart(String query) async {
    final encodedQuery = Uri.encodeComponent(query.trim());
    String urlString = '$_baseUrl/products?limit=50';

    if (query.contains('.')) {
      urlString += '&sku=$encodedQuery';
    } else {
      urlString += '&q[name]=$encodedQuery';
    }

    try {
      final response = await http.get(
        Uri.parse(urlString),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ProductModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Arama Hatasi: $e');
      return [];
    }
  }
}
