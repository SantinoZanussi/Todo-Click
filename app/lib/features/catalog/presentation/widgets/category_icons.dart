import 'package:flutter/material.dart';

/// Mapea el `iconName` (string almacenado en Firestore) a un [IconData] de
/// Material. Se usa un mapa explícito (en vez de búsqueda dinámica) para que el
/// tree-shaking de íconos de Flutter funcione correctamente.
const Map<String, IconData> _categoryIcons = {
  'checkroom': Icons.checkroom,
  'child_care': Icons.child_care,
  'ice_skating': Icons.ice_skating,
  'spa': Icons.spa,
  'home': Icons.home,
  'devices': Icons.devices,
  'smartphone': Icons.smartphone,
  'sports_soccer': Icons.sports_soccer,
  'toys': Icons.toys,
  'stroller': Icons.stroller,
  'pets': Icons.pets,
  'diamond': Icons.diamond,
  'construction': Icons.construction,
  'directions_car': Icons.directions_car,
  'edit': Icons.edit,
  'health_and_safety': Icons.health_and_safety,
  'yard': Icons.yard,
  'kitchen': Icons.kitchen,
  'celebration': Icons.celebration,
};

IconData categoryIcon(String? name) =>
    _categoryIcons[name] ?? Icons.category_outlined;
