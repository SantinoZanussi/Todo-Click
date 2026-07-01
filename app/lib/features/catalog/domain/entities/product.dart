import 'package:equatable/equatable.dart';

/// Dimensiones físicas y peso de un producto.
///
/// Son indispensables para cotizar el envío contra el proveedor de logística
/// (Correo Argentino). Peso en **gramos**, medidas en **centímetros**.
class ProductDimensions extends Equatable {
  const ProductDimensions({
    required this.weightGrams,
    required this.widthCm,
    required this.heightCm,
    required this.lengthCm,
  });

  final double weightGrams;
  final double widthCm;
  final double heightCm;
  final double lengthCm;

  /// Volumen en cm³ (útil para peso volumétrico en cotizaciones).
  double get volumeCm3 => widthCm * heightCm * lengthCm;

  ProductDimensions copyWith({
    double? weightGrams,
    double? widthCm,
    double? heightCm,
    double? lengthCm,
  }) {
    return ProductDimensions(
      weightGrams: weightGrams ?? this.weightGrams,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      lengthCm: lengthCm ?? this.lengthCm,
    );
  }

  @override
  List<Object?> get props => [weightGrams, widthCm, heightCm, lengthCm];
}

/// Entidad de dominio que representa un producto del catálogo.
///
/// Entidad **pura**: no conoce Firestore ni JSON. El mapeo desde/hacia
/// Firestore vive en `data/models/product_model.dart` (Fase 5), que extiende
/// esta entidad y agrega `fromFirestore` / `toMap`.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.subcategoryId,
    required this.brandId,
    required this.price,
    required this.stock,
    required this.dimensions,
    required this.images,
    required this.isFeatured,
    required this.isOnSale,
    required this.discountPercentage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Identificador único (id del documento Firestore).
  final String id;

  /// SKU interno / código de inventario.
  final String sku;

  final String name;
  final String description;

  /// Referencia a `categorias/{categoryId}`.
  final String categoryId;

  /// Referencia a la subcategoría dentro de la categoría.
  final String subcategoryId;

  /// Referencia a `marcas/{brandId}`.
  final String brandId;

  /// Precio de lista en ARS (sin descuento).
  final double price;

  /// Unidades disponibles en stock.
  final int stock;

  /// Peso y medidas (para cálculo de envío).
  final ProductDimensions dimensions;

  /// URLs de imágenes en Cloudinary (la primera es la principal).
  final List<String> images;

  /// Producto destacado (aparece en home / secciones promocionadas).
  final bool isFeatured;

  /// Producto en oferta.
  final bool isOnSale;

  /// Porcentaje de descuento (0-100). Solo se aplica si [isOnSale] es `true`.
  final double discountPercentage;

  /// Si está activo/visible en el catálogo (soft-delete: `false` lo oculta).
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  // --------------------------------------------------------------------------
  // Reglas de negocio derivadas
  // --------------------------------------------------------------------------

  /// Precio final a cobrar, aplicando el descuento si corresponde.
  double get finalPrice {
    if (!isOnSale || discountPercentage <= 0) return price;
    final discounted = price * (1 - (discountPercentage / 100));
    // Redondeo a 2 decimales para evitar arrastre de punto flotante.
    return double.parse(discounted.toStringAsFixed(2));
  }

  /// Monto ahorrado respecto del precio de lista.
  double get savings => price - finalPrice;

  /// `true` si hay al menos una unidad disponible.
  bool get hasStock => stock > 0;

  /// URL de la imagen principal (o `null` si no tiene imágenes).
  String? get mainImage => images.isNotEmpty ? images.first : null;

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? description,
    String? categoryId,
    String? subcategoryId,
    String? brandId,
    double? price,
    int? stock,
    ProductDimensions? dimensions,
    List<String>? images,
    bool? isFeatured,
    bool? isOnSale,
    double? discountPercentage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      brandId: brandId ?? this.brandId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      dimensions: dimensions ?? this.dimensions,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      isOnSale: isOnSale ?? this.isOnSale,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sku,
    name,
    description,
    categoryId,
    subcategoryId,
    brandId,
    price,
    stock,
    dimensions,
    images,
    isFeatured,
    isOnSale,
    discountPercentage,
    isActive,
    createdAt,
    updatedAt,
  ];
}
