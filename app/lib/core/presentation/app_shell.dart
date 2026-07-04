import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/controllers/cart_controller.dart';
import '../../features/catalog/domain/entities/product.dart';
import '../../features/catalog/domain/entities/product_query.dart';
import '../../features/catalog/presentation/controllers/catalog_providers.dart';
import '../../features/catalog/presentation/widgets/product_list_args.dart';
import '../../features/notifications/presentation/controllers/notifications_providers.dart';
import '../../shared/widgets/widgets.dart';
import '../constants/app_constants.dart';
import '../responsive/breakpoints.dart';
import '../responsive/content_container.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

/// Shell principal de las 5 pestañas con estado independiente:
/// Inicio · Categorías · Carrito · Favoritos · Perfil.
///
/// Usa el `StatefulNavigationShell` de go_router (IndexedStack interno que
/// preserva el stack de cada rama). La navegación es **adaptativa** sin tocar el
/// ruteo:
///  - **mobile** (`< 700`): barra inferior `NavigationBar` (como siempre).
///  - **tablet/desktop** (`>= 700`): barra superior persistente con la marca,
///    los enlaces principales y las acciones (buscar, notificaciones, favoritos,
///    carrito, perfil). Sin barra inferior. Las páginas ocultan su propia
///    `AppBar` en anchos grandes para no duplicar cromo.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    // Barra superior de escritorio/tablet.
    if (context.isWide) {
      final unread = ref.watch(unreadNotificationsProvider);
      return Scaffold(
        appBar: _DesktopNavBar(
          currentIndex: navigationShell.currentIndex,
          onSelect: _onSelect,
          cartCount: cartCount,
          unread: unread,
        ),
        body: navigationShell,
      );
    }

    // Barra inferior de mobile.
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: BounceOnChange(
              value: cartCount,
              child: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            selectedIcon: BounceOnChange(
              value: cartCount,
              child: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart),
              ),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// Barra de navegación superior persistente para tablet/desktop.
///
/// Dos niveles estilo tienda: una **barra de anuncio** slate full-bleed arriba
/// (identidad de marca) y, debajo, la barra principal con marca + enlaces de
/// sección + acciones. Todos los colores salen del `ColorScheme` para que la
/// marca no se apague en modo oscuro. Reusa el índice/branches del
/// `navigationShell`.
class _DesktopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const _DesktopNavBar({
    required this.currentIndex,
    required this.onSelect,
    required this.cartCount,
    required this.unread,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final int cartCount;
  final int unread;

  static const double _announcementHeight = 36;
  static const double _barHeight = 76;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_announcementHeight + _barHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Column(
        children: [
          const _AnnouncementBar(height: _announcementHeight),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outline)),
            ),
            child: SizedBox(
              height: _barHeight,
              child: ContentContainer(
                maxWidth: 1440,
                child: Row(
                  children: [
                    _BrandMark(onTap: () => onSelect(0)),
                    const SizedBox(width: AppSpacing.xxl),
                    _NavLink(
                      label: 'INICIO',
                      selected: currentIndex == 0,
                      onTap: () => onSelect(0),
                    ),
                    _NavLink(
                      label: 'CATEGORÍAS',
                      selected: currentIndex == 1,
                      onTap: () => onSelect(1),
                    ),
                    const Spacer(),
                    const _NavSearch(),
                    IconButton(
                      tooltip: 'Notificaciones',
                      color: scheme.onSurface,
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        child: const Icon(Icons.notifications_none),
                      ),
                      onPressed: () => context.push(AppRoutes.notifications),
                    ),
                    _NavIcon(
                      tooltip: 'Favoritos',
                      icon: Icons.favorite_border,
                      selectedIcon: Icons.favorite,
                      selected: currentIndex == 3,
                      onTap: () => onSelect(3),
                    ),
                    _NavIcon(
                      tooltip: 'Carrito',
                      icon: Icons.shopping_cart_outlined,
                      selectedIcon: Icons.shopping_cart,
                      selected: currentIndex == 2,
                      badgeCount: cartCount,
                      onTap: () => onSelect(2),
                    ),
                    _NavIcon(
                      tooltip: 'Perfil',
                      icon: Icons.person_outline,
                      selectedIcon: Icons.person,
                      selected: currentIndex == 4,
                      onTap: () => onSelect(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de anuncio full-bleed (slate) con mensajes de marca. Fija en ambos
/// modos: es un bloque oscuro intencional con texto claro.
class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar({required this.height});

  final double height;

  static const _messages = [
    'ENVÍO A TODO EL PAÍS',
    'CAMBIOS FÁCILES HASTA 30 DÍAS',
    'PAGÁ CON MERCADO PAGO',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.charcoal,
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        children: [
          for (var i = 0; i < _messages.length; i++) ...[
            if (i > 0)
              Text(
                '·',
                style: TextStyle(
                  color: AppColors.sage.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            Text(
              _messages[i],
              style: const TextStyle(
                color: AppColors.cream,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Marca (wordmark) en mayúsculas con tracking, clickeable → Inicio.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          AppConstants.appName.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            fontSize: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Enlace de sección de la barra superior: mayúsculas + subrayado que se revela
/// en hover o cuando está activo.
class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.selected || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 13,
                  color: active ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                height: 2,
                width: active ? 18 : 0,
                color: scheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Acción con ícono de la barra superior, con estado activo y badge opcional.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
      icon: BounceOnChange(
        value: badgeCount,
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text('$badgeCount'),
          child: Icon(selected ? selectedIcon : icon),
        ),
      ),
      onPressed: onTap,
    );
  }
}

/// Buscador **inline** de la barra superior: el ícono se despliega en un campo
/// de texto dentro de la misma barra y muestra los resultados en un panel
/// anclado debajo (sin abrir un popup ni llevar a otra sección). Reusa
/// `productsQueryProvider` — no toca lógica.
class _NavSearch extends ConsumerStatefulWidget {
  const _NavSearch();

  @override
  ConsumerState<_NavSearch> createState() => _NavSearchState();
}

class _NavSearchState extends ConsumerState<_NavSearch> {
  static const _groupId = 'nav-search';

  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  Timer? _debounce;
  String _text = '';
  bool _open = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _open = true);
    _portal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _close() {
    _debounce?.cancel();
    _portal.hide();
    _controller.clear();
    _focus.unfocus();
    setState(() {
      _open = false;
      _text = '';
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _text = value.trim());
    });
  }

  void _seeAll() {
    final q = _controller.text.trim();
    _close();
    if (q.isEmpty) return;
    context.push(
      AppRoutes.productList,
      extra: ProductListArgs(
        title: 'Resultados: $q',
        query: ProductQuery(searchText: q),
      ),
    );
  }

  void _openProduct(String id) {
    _close();
    context.push(AppRoutes.productDetailOf(id));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (_) => _overlay(scheme),
        child: _open ? _field(scheme) : _iconButton(scheme),
      ),
    );
  }

  Widget _iconButton(ColorScheme scheme) {
    return IconButton(
      tooltip: 'Buscar',
      color: scheme.onSurface,
      icon: const Icon(Icons.search),
      onPressed: _openSearch,
    );
  }

  Widget _field(ColorScheme scheme) {
    return TapRegion(
      groupId: _groupId,
      onTapOutside: (_) => _close(),
      child: SizedBox(
        width: 300,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          onSubmitted: (_) => _seeAll(),
          onTapOutside: (_) {},
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Buscar productos…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Cerrar',
              onPressed: _close,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _overlay(ColorScheme scheme) {
    // El `Align` externo afloja las restricciones "tight" a pantalla completa
    // que el Overlay le pasa al hijo: sin él, el `SizedBox(440)` se estira y el
    // panel ocupa casi toda la ventana. El `Follower` reposiciona el paint.
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 10),
        child: TapRegion(
          groupId: _groupId,
          child: Material(
            color: scheme.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(width: 440, child: _results(scheme)),
          ),
        ),
      ),
    );
  }

  Widget _results(ColorScheme scheme) {
    if (_text.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Escribí para buscar productos…',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    final async = ref.watch(
      productsQueryProvider(ProductQuery(searchText: _text)),
    );
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No se pudo buscar.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Sin resultados para "$_text".',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in products.take(6)) _resultTile(p, scheme),
            Divider(height: 1, color: scheme.outline),
            InkWell(
              onTap: _seeAll,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'VER TODOS LOS RESULTADOS',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _resultTile(Product p, ColorScheme scheme) {
    return InkWell(
      onTap: () => _openProduct(p.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 44,
                height: 44,
                child: p.mainImage == null
                    ? const BrandPlaceholder(compact: true)
                    : CachedNetworkImage(
                        imageUrl: p.mainImage!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const BrandPlaceholder(compact: true),
                        errorWidget: (_, _, _) =>
                            const BrandPlaceholder(compact: true),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              Formatters.currency(p.finalPrice),
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
