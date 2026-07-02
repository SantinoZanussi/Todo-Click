import 'package:flutter/material.dart';

/// Microinteracción de hover reutilizable: al pasar el cursor (web/escritorio)
/// escala el hijo de forma sutil y rápida, y muestra el cursor de "click".
///
/// En mobile no hay hover, así que `MouseRegion` nunca dispara y el hijo queda
/// intacto — es seguro envolver cualquier tarjeta con esto. `AnimatedScale` usa
/// `Transform.scale`, que no afecta el layout de la grilla.
class HoverScale extends StatefulWidget {
  const HoverScale({
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 180),
    this.enabled = true,
    super.key,
  });

  final Widget child;

  /// Escala al hacer hover (1.0 = sin efecto).
  final double scale;

  final Duration duration;

  /// Permite desactivar el efecto sin cambiar el árbol.
  final bool enabled;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
