import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Cliente del API de administración.
///
/// Las mutaciones van al backend (`/api/admin/*`), que valida `requireAdmin`.
/// Las imágenes se suben FIRMADAS directo a Cloudinary: el backend solo firma
/// los parámetros, los bytes no pasan por nuestra API.
class AdminApi {
  AdminApi(this._dio);

  final Dio _dio;

  // ── Estadísticas ──
  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/admin/stats');
    return res.data ?? const {};
  }

  // ── Cloudinary ──
  /// Sube una imagen y devuelve su `secure_url`.
  Future<String> uploadImage(
    Uint8List bytes, {
    String filename = 'image.jpg',
  }) async {
    // 1. Pedir firma al backend.
    final signRes = await _dio.post<Map<String, dynamic>>(
      '/api/admin/uploads/signature',
    );
    final sign = signRes.data ?? const {};

    // 2. Subir directo a Cloudinary (Dio independiente, sin baseUrl/token).
    final cloudName = sign['cloudName'] as String;
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'api_key': '${sign['apiKey']}',
      'timestamp': '${sign['timestamp']}',
      'signature': '${sign['signature']}',
      'folder': '${sign['folder']}',
    });
    final uploadRes = await Dio().post<Map<String, dynamic>>(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: form,
    );
    return uploadRes.data!['secure_url'] as String;
  }

  // ── Productos ──
  Future<void> createProduct(Map<String, dynamic> data) =>
      _dio.post('/api/admin/products', data: data);
  Future<void> updateProduct(String id, Map<String, dynamic> data) =>
      _dio.put('/api/admin/products/$id', data: data);
  Future<void> deleteProduct(String id) =>
      _dio.delete('/api/admin/products/$id');

  // ── Categorías ──
  Future<void> createCategory(Map<String, dynamic> data) =>
      _dio.post('/api/admin/categories', data: data);
  Future<void> updateCategory(String id, Map<String, dynamic> data) =>
      _dio.put('/api/admin/categories/$id', data: data);
  Future<void> deleteCategory(String id) =>
      _dio.delete('/api/admin/categories/$id');

  // ── Marcas ──
  Future<void> createBrand(Map<String, dynamic> data) =>
      _dio.post('/api/admin/brands', data: data);
  Future<void> updateBrand(String id, Map<String, dynamic> data) =>
      _dio.put('/api/admin/brands/$id', data: data);
  Future<void> deleteBrand(String id) => _dio.delete('/api/admin/brands/$id');

  // ── Cupones ──
  Future<void> createCoupon(Map<String, dynamic> data) =>
      _dio.post('/api/admin/coupons', data: data);
  Future<void> updateCoupon(String id, Map<String, dynamic> data) =>
      _dio.put('/api/admin/coupons/$id', data: data);
  Future<void> deleteCoupon(String id) => _dio.delete('/api/admin/coupons/$id');

  // ── Promociones ──
  Future<void> createPromotion(Map<String, dynamic> data) =>
      _dio.post('/api/admin/promotions', data: data);
  Future<void> updatePromotion(String id, Map<String, dynamic> data) =>
      _dio.put('/api/admin/promotions/$id', data: data);
  Future<void> deletePromotion(String id) =>
      _dio.delete('/api/admin/promotions/$id');

  // ── Pedidos ──
  Future<void> updateOrderStatus(String id, String status, {String? note}) =>
      _dio.patch(
        '/api/admin/orders/$id/status',
        data: {'status': status, 'note': ?note},
      );

  Future<void> setOrderTracking(String id, String trackingCode) => _dio.patch(
    '/api/admin/orders/$id/tracking',
    data: {'trackingCode': trackingCode},
  );

  // ── Usuarios ──
  Future<void> setUserRole(String uid, String role) =>
      _dio.patch('/api/admin/users/$uid/role', data: {'role': role});

  // ── Notificaciones ──
  /// Envía una promoción push a todos los suscriptos (tópico `promos`).
  Future<void> broadcastPromo(String title, String body) => _dio.post(
    '/api/admin/notifications/broadcast',
    data: {'title': title, 'body': body},
  );
}
