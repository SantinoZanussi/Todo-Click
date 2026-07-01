import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/features/catalog/domain/entities/product.dart';

Product buildProduct({
  double price = 1000,
  int stock = 5,
  bool isOnSale = false,
  double discount = 0,
  List<String> images = const [],
}) {
  return Product(
    id: 'p1',
    sku: 'SKU1',
    name: 'Producto',
    description: 'desc',
    categoryId: 'c',
    subcategoryId: 's',
    brandId: 'b',
    price: price,
    stock: stock,
    dimensions: const ProductDimensions(
      weightGrams: 100,
      widthCm: 1,
      heightCm: 1,
      lengthCm: 1,
    ),
    images: images,
    isFeatured: false,
    isOnSale: isOnSale,
    discountPercentage: discount,
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('Product.finalPrice', () {
    test('sin oferta = precio de lista', () {
      expect(buildProduct(price: 1000).finalPrice, 1000);
    });

    test('con oferta aplica el descuento', () {
      final p = buildProduct(price: 1000, isOnSale: true, discount: 20);
      expect(p.finalPrice, 800);
      expect(p.savings, 200);
    });

    test('oferta sin porcentaje no descuenta', () {
      expect(
        buildProduct(price: 1000, isOnSale: true, discount: 0).finalPrice,
        1000,
      );
    });
  });

  test('hasStock refleja el stock', () {
    expect(buildProduct(stock: 0).hasStock, isFalse);
    expect(buildProduct(stock: 3).hasStock, isTrue);
  });

  test('mainImage devuelve la primera o null', () {
    expect(buildProduct(images: const []).mainImage, isNull);
    expect(buildProduct(images: const ['a.jpg', 'b.jpg']).mainImage, 'a.jpg');
  });
}
