import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/imagekit_uploader.dart';
import '../domain/catalog_models.dart';

/// إدارة الكتالوج (قراءة/كتابة) ورفع الصور إلى ImageKit.
class CatalogRepository {
  const CatalogRepository(this._client);

  final SupabaseClient _client;

  // ---------- التصنيفات ----------
  Future<List<CatalogCategory>> fetchCategories() async {
    final dynamic rows = await _client.from('categories').select().order('display_order', ascending: true);
    return (rows as List)
        .map((dynamic row) => CatalogCategory.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> createCategory({required String id, required Map<String, dynamic> values}) async {
    await _client.from('categories').insert(<String, dynamic>{'id': id, ...values});
  }

  Future<void> updateCategory(String id, Map<String, dynamic> values) async {
    await _client.from('categories').update(values).eq('id', id);
  }

  /// حذف تصنيف نهائياً. المنتجات المرتبطة تبقى مع `category_id = null`
  /// (قيد المفتاح الأجنبي `on delete set null`).
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  // ---------- المنتجات ----------
  Future<List<CatalogProduct>> fetchProducts() async {
    final dynamic rows = await _client.from('products').select().order('created_at', ascending: false);
    return (rows as List)
        .map((dynamic row) => CatalogProduct.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> createProduct(Map<String, dynamic> values) async {
    await _client.from('products').insert(values);
  }

  Future<void> setProductActive(String id, bool active) async {
    await _client.from('products').update(<String, dynamic>{'is_active': active}).eq('id', id);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> values) async {
    await _client.from('products').update(values).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // ---------- الصور ----------
  /// يرفع الصورة إلى ImageKit (مجلد باسم [bucket]) ويعيد رابط CDN مع التحويلات.
  Future<String> uploadImage({
    required XFile file,
    required String bucket,
    required String path,
  }) {
    return ImageKitUploader(_client).upload(file: file, folder: '/$bucket', fileNameBase: path);
  }
}
