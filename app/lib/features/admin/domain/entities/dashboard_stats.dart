/// Estadísticas del dashboard, parseadas desde `GET /api/admin/stats`.
class DashboardStats {
  const DashboardStats({
    required this.revenue,
    required this.orders,
    required this.averageTicket,
    required this.sales,
    required this.topProducts,
    required this.topCustomers,
  });

  final double revenue;
  final int orders;
  final double averageTicket;

  /// Ventas por período: claves `daily`, `weekly`, `monthly`, `yearly`.
  final Map<String, SalesBucket> sales;
  final List<TopProduct> topProducts;
  final List<TopCustomer> topCustomers;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map?) ?? const {};
    final salesJson = (json['sales'] as Map?) ?? const {};
    return DashboardStats(
      revenue: _d(totals['revenue']),
      orders: _i(totals['orders']),
      averageTicket: _d(totals['averageTicket']),
      sales: salesJson.map(
        (k, v) => MapEntry(k as String, SalesBucket.fromJson(v as Map)),
      ),
      topProducts: ((json['topProducts'] as List?) ?? const [])
          .map((e) => TopProduct.fromJson(e as Map))
          .toList(),
      topCustomers: ((json['topCustomers'] as List?) ?? const [])
          .map((e) => TopCustomer.fromJson(e as Map))
          .toList(),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
  static int _i(Object? v) => (v as num?)?.toInt() ?? 0;
}

class SalesBucket {
  const SalesBucket({required this.count, required this.amount});
  final int count;
  final double amount;
  factory SalesBucket.fromJson(Map m) => SalesBucket(
    count: (m['count'] as num?)?.toInt() ?? 0,
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
  );
}

class TopProduct {
  const TopProduct({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
  final String name;
  final int quantity;
  final double revenue;
  factory TopProduct.fromJson(Map m) => TopProduct(
    name: m['name'] as String? ?? 'Producto',
    quantity: (m['quantity'] as num?)?.toInt() ?? 0,
    revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
  );
}

class TopCustomer {
  const TopCustomer({
    required this.userId,
    required this.orders,
    required this.total,
  });
  final String userId;
  final int orders;
  final double total;
  factory TopCustomer.fromJson(Map m) => TopCustomer(
    userId: m['userId'] as String? ?? '',
    orders: (m['orders'] as num?)?.toInt() ?? 0,
    total: (m['total'] as num?)?.toDouble() ?? 0,
  );
}
