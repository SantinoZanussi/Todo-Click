import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Envuelve el contenido de la app para animar el cambio de tema con un
/// **reveal circular** (estilo Android 12): captura la pantalla actual (tema
/// viejo), cambia el tema al instante por debajo y revela el tema nuevo con un
/// círculo que se expande desde el punto de origen.
///
/// Es fluido incluso en debug porque NO usa `ThemeData.lerp` (que reconstruye
/// todo el árbol en cada frame): solo se anima el recorte de una imagen estática.
/// Requiere `themeAnimationDuration: Duration.zero` en el `MaterialApp` para que
/// el swap del tema por debajo sea instantáneo.
class ThemeSwitcherReveal extends StatefulWidget {
  const ThemeSwitcherReveal({required this.child, super.key});

  final Widget child;

  static ThemeSwitcherRevealState? of(BuildContext context) =>
      context.findAncestorStateOfType<ThemeSwitcherRevealState>();

  @override
  State<ThemeSwitcherReveal> createState() => ThemeSwitcherRevealState();
}

class ThemeSwitcherRevealState extends State<ThemeSwitcherReveal>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      _snapshot?.dispose();
      if (mounted) setState(() => _snapshot = null);
    }
  });

  ui.Image? _snapshot;
  Offset _origin = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  /// Captura la pantalla actual, ejecuta [applyChange] (que cambia el tema) y
  /// revela el resultado con un círculo que se expande desde [origin].
  Future<void> reveal(Offset origin, VoidCallback applyChange) async {
    // Si ya hay una animación en curso, cambiamos sin efecto (evita solaparse).
    if (_controller.isAnimating || _snapshot != null) {
      applyChange();
      return;
    }
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      applyChange();
      return;
    }
    ui.Image image;
    try {
      image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
    } catch (_) {
      applyChange();
      return;
    }
    applyChange();
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _snapshot = image;
      _origin = origin;
    });
    await _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (_snapshot != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => ClipPath(
                clipper: _HoleClipper(
                  fraction: Curves.easeInOut.transform(_controller.value),
                  center: _origin,
                ),
                // La captura del tema VIEJO queda arriba y se le abre un hueco
                // circular creciente que deja ver el tema nuevo por debajo.
                child: RawImage(image: _snapshot, fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }
}

/// Recorta un rectángulo completo al que se le resta un círculo creciente
/// centrado en [center] (el "hueco" por donde asoma el tema nuevo).
class _HoleClipper extends CustomClipper<Path> {
  _HoleClipper({required this.fraction, required this.center});

  final double fraction;
  final Offset center;

  @override
  Path getClip(Size size) {
    final radius = _maxDistanceToCorner(size, center) * fraction;
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  double _maxDistanceToCorner(Size size, Offset o) {
    final dx = math.max(o.dx, size.width - o.dx);
    final dy = math.max(o.dy, size.height - o.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldReclip(_HoleClipper old) =>
      old.fraction != fraction || old.center != center;
}
