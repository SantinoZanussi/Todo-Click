import 'package:flutter/widgets.dart';

/// Breakpoints y utilidades responsive de TodoClick.
///
/// Un único lugar define los cortes; el resto de la app decide su layout a
/// partir de [DeviceType] en vez de repartir números mágicos de `MediaQuery`
/// por todos lados. Esto es lo que evita el efecto "app móvil estirada": cada
/// pantalla puede pedir un árbol de widgets distinto según el ancho real.
///
///  - `mobile`   `< 700`      → una columna, navegación inferior
///  - `tablet`   `700 – 1100` → layout intermedio
///  - `desktop`  `>= 1100`    → tienda de escritorio (nav superior, grillas amplias)
abstract final class Breakpoints {
  /// A partir de acá dejamos de ser mobile.
  static const double tablet = 700;

  /// A partir de acá activamos el layout de escritorio.
  static const double desktop = 1100;

  /// Ancho máximo del contenido centrado en pantallas anchas. Más allá de esto
  /// el contenido se centra y aparecen márgenes laterales (como en una tienda
  /// real), en vez de estirarse de borde a borde en un monitor.
  static const double maxContentWidth = 1280;
}

/// Categoría de tamaño de la ventana actual.
enum DeviceType { mobile, tablet, desktop }

/// Deriva el [DeviceType] a partir de un ancho en píxeles lógicos.
DeviceType deviceTypeForWidth(double width) {
  if (width >= Breakpoints.desktop) return DeviceType.desktop;
  if (width >= Breakpoints.tablet) return DeviceType.tablet;
  return DeviceType.mobile;
}

/// Azúcar sintáctico para consultar el breakpoint desde cualquier `context`.
extension ResponsiveContext on BuildContext {
  /// Tipo de dispositivo según el ancho de la ventana.
  DeviceType get deviceType =>
      deviceTypeForWidth(MediaQuery.sizeOf(this).width);

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// `true` para tablet y desktop: donde usamos navegación superior en vez de
  /// la barra inferior y el contenido se centra con ancho máximo.
  bool get isWide => deviceType != DeviceType.mobile;

  /// Elige un valor según el breakpoint (mobile-first): si no se especifica
  /// `tablet`/`desktop`, cae al valor anterior disponible.
  ///
  /// ```dart
  /// final columns = context.responsive(mobile: 2, tablet: 3, desktop: 5);
  /// ```
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// Construye un árbol de widgets distinto por breakpoint usando el ancho real
/// del **contenedor** (vía `LayoutBuilder`), no el de la pantalla completa.
///
/// Es la forma correcta cuando un panel lateral (p. ej. filtros) reduce el
/// espacio disponible: el contenido reacciona al lugar que realmente tiene,
/// no al tamaño de la ventana.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (deviceTypeForWidth(constraints.maxWidth)) {
          case DeviceType.desktop:
            return (desktop ?? tablet ?? mobile)(context);
          case DeviceType.tablet:
            return (tablet ?? mobile)(context);
          case DeviceType.mobile:
            return mobile(context);
        }
      },
    );
  }
}
