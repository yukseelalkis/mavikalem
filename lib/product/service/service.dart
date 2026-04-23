import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mavikalem_app/core/storage/secure_storage_service.dart';
import 'package:mavikalem_app/product/model/category_model.dart';
import 'package:mavikalem_app/product/model/product_model.dart';

Future<Map<String, String>> _authorizedJsonHeaders() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: SecureStorageService.accessTokenKey);
  if (token == null || token.isEmpty) {
    throw Exception('Oturum bulunamadi: once uygulamadan giris yapin.');
  }
  return <String, String>{
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

final class CategoryService {
  static const String _baseUrl = 'https://mavikalem.myideasoft.com/api';

  Future<List<CategoryModel>> fetchCategories() async {
    final url = Uri.parse('$_baseUrl/categories?limit=50');
    try {
      final headers = await _authorizedJsonHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final categoryMap = <int, CategoryModel>{};

        for (var item in data) {
          final id = (item['id'] as num).toInt();

          if (!categoryMap.containsKey(id)) {
            categoryMap[id] = CategoryModel.fromJson(item);
          }

          if (item['parent'] != null) {
            final pId = (item['parent']['id'] as num).toInt();
            if (!categoryMap.containsKey(pId)) {
              categoryMap[pId] = CategoryModel.fromJson(item['parent']);
            }
          }
        }

        final rootCategories = <CategoryModel>[];

        categoryMap.forEach((id, cat) {
          if (cat.parentId == null) {
            rootCategories.add(cat);
          } else {
            final parent = categoryMap[cat.parentId];
            if (parent != null) {
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
      throw Exception('Kategori hatasi');
    } catch (e) {
      debugPrint('Kategori Cekme Hatasi: $e');
      rethrow;
    }
  }
}

final class ProductService {
  static const String _baseUrl = 'https://mavikalem.myideasoft.com/api';

  Future<List<ProductModel>> fetchProducts({int? categoryId}) async {
    final endpoint = categoryId != null
        ? '$_baseUrl/products?categories=$categoryId&limit=100'
        : '$_baseUrl/products?limit=50';

    try {
      final headers = await _authorizedJsonHeaders();
      final response = await http.get(Uri.parse(endpoint), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ProductModel.fromJson(e)).toList();
      }
      throw Exception('Urunler getirilemedi');
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductModel?> fetchProductBySku(String sku) async {
    final url = Uri.parse('$_baseUrl/products?sku=$sku');

    try {
      final headers = await _authorizedJsonHeaders();
      final response = await http.get(url, headers: headers);

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

  Future<List<ProductModel>> searchSmart(String query) async {
    final encodedQuery = Uri.encodeComponent(query.trim());
    var urlString = '$_baseUrl/products?limit=50';

    if (query.contains('.')) {
      urlString += '&sku=$encodedQuery';
    } else {
      urlString += '&q[name]=$encodedQuery';
    }

    try {
      final headers = await _authorizedJsonHeaders();
      final response = await http.get(
        Uri.parse(urlString),
        headers: headers,
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
