import 'package:flutter/material.dart';

/// Micro-interacciones reutilizables (estilo "mixto": navegación sutil pero
/// acciones con feedback expresivo). Todas usan `Transform`/opacity, así que no
/// afectan el layout de grillas ni listas.

/// Feedback de **presión**: al mantener apretado, el hijo se encoge levemente y
/// vuelve al soltar. Ideal para cards y tiles tappables.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.scale = 0.93,
    this.duration = const Duration(milliseconds: 110),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Hace **rebotar** al hijo cada vez que [value] aumenta (p. ej. el badge del
/// carrito al agregar un producto). Un solo pulso con overshoot elástico.
class BounceOnChange extends StatefulWidget {
  const BounceOnChange({required this.value, required this.child, super.key});

  /// Al crecer respecto del build anterior, dispara el rebote.
  final int value;
  final Widget child;

  @override
  State<BounceOnChange> createState() => _BounceOnChangeState();
}

class _BounceOnChangeState extends State<BounceOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]).animate(_c);

  @override
  void didUpdateWidget(BounceOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > oldWidget.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Aparición **escalonada** (fade + leve deslizamiento hacia arriba) según el
/// [index] del ítem dentro de una lista/grilla. El delay se acota para que la
/// última fila no tarde demasiado.
class EntranceItem extends StatefulWidget {
  const EntranceItem({
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
    super.key,
  });

  final int index;
  final Widget child;
  final Duration duration;

  @override
  State<EntranceItem> createState() => _EntranceItemState();
}

class _EntranceItemState extends State<EntranceItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * 45).clamp(0, 400);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      // El "pop" con overshoot (easeOutBack) le da el toque divertido: el ítem
      // entra creciendo desde 0.8 y se pasa un poquito de 1.0 antes de asentar.
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.10),
            end: Offset.zero,
          ).animate(_curved),
          child: widget.child,
        ),
      ),
    );
  }
}
