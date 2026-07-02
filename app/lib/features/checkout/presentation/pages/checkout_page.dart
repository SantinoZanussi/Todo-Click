import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/argentina.dart';
import '../../../../core/enums/shipping_method.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/content_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../shipping/domain/entities/shipping_agency.dart';
import '../../../shipping/domain/entities/shipping_option.dart';
import '../../../shipping/presentation/controllers/shipping_providers.dart';
import '../controllers/checkout_controller.dart';

/// Pantalla de checkout: datos de contacto + dirección, cotización de envío
/// (Correo Argentino), cupón, resumen y pago con Mercado Pago (Checkout Pro).
///
/// Responsive:
///  - **mobile**: una columna (formulario, resumen y pago apilados).
///  - **desktop/tablet**: dos columnas — formulario a la izquierda y resumen +
///    pago (sticky) a la derecha.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _street = TextEditingController();
  final _apartment = TextEditingController();
  final _postalCode = TextEditingController();
  final _couponCtrl = TextEditingController();
  String? _province;
  bool _prefilled = false;
  bool _paying = false;
  bool _loadingShipping = false;
  List<ShippingOption> _shippingOptions = [];
  ShippingOption? _selectedShipping;
  List<ShippingAgency> _agencies = [];
  ShippingAgency? _selectedAgency;
  bool _loadingAgencies = false;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _city,
      _street,
      _apartment,
      _postalCode,
      _couponCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefillFromUser() {
    if (_prefilled) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      _email.text = user.email;
      final parts = (user.displayName ?? '').split(' ');
      if (parts.isNotEmpty) _firstName.text = parts.first;
      if (parts.length > 1) _lastName.text = parts.sublist(1).join(' ');
      if (user.phone != null) _phone.text = user.phone!;
    }
    _prefilled = true;
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(checkoutControllerProvider.notifier).applyCoupon(code);
  }

  Future<void> _calculateShipping() async {
    if (_province == null || _postalCode.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá provincia y código postal.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final cart = ref.read(cartControllerProvider);
    setState(() => _loadingShipping = true);
    final result = await ref
        .read(shippingRepositoryProvider)
        .quote(
          province: _province!,
          postalCode: _postalCode.text.trim().toUpperCase(),
          items: cart.items
              .map((i) => {'productId': i.productId, 'quantity': i.quantity})
              .toList(),
        );
    if (!mounted) return;
    setState(() {
      _loadingShipping = false;
      result.fold(
        (failure) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message))),
        (options) {
          _shippingOptions = options;
          _selectedShipping = options.isNotEmpty ? options.first : null;
          _agencies = [];
          _selectedAgency = null;
        },
      );
    });
  }

  /// Selecciona una opción de envío; si es retiro en sucursal, carga las
  /// sucursales de correo de la provincia elegida.
  void _selectOption(ShippingOption option) {
    setState(() => _selectedShipping = option);
    if (option.method == ShippingMethod.branchPickup && _agencies.isEmpty) {
      _loadAgencies();
    }
  }

  Future<void> _loadAgencies() async {
    if (_province == null) return;
    setState(() => _loadingAgencies = true);
    final result = await ref
        .read(shippingRepositoryProvider)
        .agencies(province: _province!);
    if (!mounted) return;
    setState(() {
      _loadingAgencies = false;
      result.fold(
        (failure) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message))),
        (list) => _agencies = list,
      );
    });
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    if (_province == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Elegí una provincia.')));
      return;
    }
    if (_selectedShipping == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calculá y elegí una opción de envío.')),
      );
      return;
    }
    if (_selectedShipping!.method == ShippingMethod.branchPickup &&
        _selectedAgency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí una sucursal de correo.')),
      );
      return;
    }

    final cart = ref.read(cartControllerProvider);
    final coupon = ref.read(checkoutControllerProvider).coupon;
    final body = <String, dynamic>{
      'items': cart.items
          .map((i) => {'productId': i.productId, 'quantity': i.quantity})
          .toList(),
      'shipping': {
        'method': _selectedShipping!.method.key,
        'cost': _selectedShipping!.cost,
        'estimatedDays': _selectedShipping!.estimatedDays,
        'carrier': _selectedShipping!.carrier,
        'branchId': ?_selectedAgency?.code,
        'address': {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'province': _province,
          'city': _city.text.trim(),
          'street': _street.text.trim(),
          'apartment': _apartment.text.trim(),
          'postalCode': _postalCode.text.trim().toUpperCase(),
        },
      },
      'couponCode': ?coupon?.code,
    };

    setState(() => _paying = true);
    final result = await ref
        .read(paymentRepositoryProvider)
        .createCheckout(body);
    if (!mounted) return;
    setState(() => _paying = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.coral,
        ),
      ),
      (checkout) async {
        // Abre Mercado Pago Checkout Pro.
        if (checkout.initPoint.isNotEmpty) {
          await launchUrl(
            Uri.parse(checkout.initPoint),
            mode: LaunchMode.externalApplication,
          );
        }
        if (mounted) {
          context.go(AppRoutes.paymentResultOf(checkout.orderId));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromUser();
    final cart = ref.watch(cartControllerProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final wide = context.isWide;

    final subtotal = cart.subtotal;
    final discount = checkout.discount.clamp(0, subtotal).toDouble();
    final shippingCost = _selectedShipping?.cost ?? 0;
    final total = subtotal - discount + shippingCost;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const EmptyStateView(
          icon: Icons.shopping_cart_outlined,
          title: 'Tu carrito está vacío',
          message: 'Agregá productos antes de continuar.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar compra')),
      body: Form(
        key: _formKey,
        child: wide
            ? _wideBody(checkout, subtotal, discount, shippingCost, total)
            : _mobileBody(checkout, subtotal, discount, shippingCost, total),
      ),
    );
  }

  // ------------------------------- Layouts ----------------------------------

  Widget _mobileBody(
    CheckoutState checkout,
    double subtotal,
    double discount,
    double shippingCost,
    double total,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _contactSection(),
        const SizedBox(height: AppSpacing.xl),
        _addressSection(),
        const SizedBox(height: AppSpacing.xl),
        _shippingBlock(),
        const SizedBox(height: AppSpacing.xl),
        _couponSection(checkout),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(context, 'Resumen'),
        _summary(context, subtotal, discount, shippingCost, total),
        const SizedBox(height: AppSpacing.xl),
        _payButton(),
        const SizedBox(height: AppSpacing.sm),
        _secureNote(context),
      ],
    );
  }

  Widget _wideBody(
    CheckoutState checkout,
    double subtotal,
    double discount,
    double shippingCost,
    double total,
  ) {
    return ContentContainer(
      maxWidth: 1120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulario (columna izquierda, scrollea).
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _contactSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _addressSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _shippingBlock(),
                  const SizedBox(height: AppSpacing.xl),
                  _couponSection(checkout),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxxl),
          // Resumen + pago (columna derecha, sticky).
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(context, 'Resumen'),
                  _summary(context, subtotal, discount, shippingCost, total),
                  const SizedBox(height: AppSpacing.lg),
                  _payButton(),
                  const SizedBox(height: AppSpacing.sm),
                  _secureNote(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------ Secciones ---------------------------------

  Widget _contactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Datos de contacto'),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => Validators.required(v, field: 'El nombre'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (v) => Validators.required(v, field: 'El apellido'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: Validators.email,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          validator: Validators.phone,
        ),
      ],
    );
  }

  Widget _addressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Dirección de envío'),
        DropdownButtonFormField<String>(
          initialValue: _province,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Provincia'),
          items: Argentina.provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _province = v),
          validator: (v) => v == null ? 'Elegí una provincia' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _city,
          decoration: const InputDecoration(labelText: 'Localidad'),
          validator: (v) => Validators.required(v, field: 'La localidad'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _street,
          decoration: const InputDecoration(labelText: 'Calle y altura'),
          validator: (v) => Validators.required(v, field: 'La dirección'),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _apartment,
                decoration: const InputDecoration(
                  labelText: 'Piso/Depto (opcional)',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _postalCode,
                decoration: const InputDecoration(labelText: 'Código postal'),
                validator: Validators.postalCode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shippingBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Envío'),
        _shippingSection(),
      ],
    );
  }

  Widget _couponSection(CheckoutState checkout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Cupón de descuento'),
        _couponField(checkout),
      ],
    );
  }

  Widget _payButton() => AppButton(
    label: 'Continuar al pago',
    icon: Icons.lock_outline,
    isLoading: _paying,
    onPressed: _pay,
  );

  Widget _secureNote(BuildContext context) => Text(
    'Pagás de forma segura con Mercado Pago. El envío lo realiza '
    'Correo Argentino.',
    textAlign: TextAlign.center,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
  );

  Widget _shippingSection() {
    if (_shippingOptions.isEmpty) {
      return OutlinedButton.icon(
        onPressed: _loadingShipping ? null : _calculateShipping,
        icon: _loadingShipping
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.local_shipping_outlined),
        label: const Text('Calcular envío'),
      );
    }
    return Column(
      children: [
        ..._shippingOptions.map((o) {
          final selected = _selectedShipping == o;
          final scheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: selected ? scheme.surfaceContainerHighest : scheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: selected ? scheme.onSurface : scheme.outline,
                  width: selected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                title: Text(
                  o.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  o.estimatedDays == 0
                      ? 'Retiro inmediato'
                      : 'Llega en ~${o.estimatedDays} días hábiles',
                ),
                trailing: Text(
                  o.cost == 0 ? 'Gratis' : Formatters.currency(o.cost),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => _selectOption(o),
              ),
            ),
          );
        }),
        if (_selectedShipping?.method == ShippingMethod.branchPickup)
          _branchSelector(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _calculateShipping,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Recalcular'),
          ),
        ),
      ],
    );
  }

  /// Selector de sucursal de correo (solo para retiro en sucursal).
  Widget _branchSelector() {
    if (_loadingAgencies) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: LinearProgressIndicator(),
      );
    }
    if (_agencies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OutlinedButton.icon(
          onPressed: _loadAgencies,
          icon: const Icon(Icons.store_mall_directory_outlined),
          label: const Text('Ver sucursales'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DropdownButtonFormField<ShippingAgency>(
        initialValue: _selectedAgency,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Elegí una sucursal',
          prefixIcon: Icon(Icons.store_mall_directory_outlined),
        ),
        items: _agencies
            .map(
              (a) => DropdownMenuItem(
                value: a,
                child: Text(a.shortLabel, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (a) => setState(() => _selectedAgency = a),
      ),
    );
  }

  Widget _couponField(CheckoutState checkout) {
    if (checkout.coupon != null) {
      final c = checkout.coupon!;
      return Material(
        color: AppColors.success.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.success),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: const Icon(Icons.local_offer, color: AppColors.success),
          title: Text('Cupón ${c.code} aplicado'),
          subtitle: Text('Descuento: ${Formatters.currency(c.discount)}'),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(checkoutControllerProvider.notifier).removeCoupon(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código de cupón',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: checkout.applyingCoupon ? null : _applyCoupon,
                child: checkout.applyingCoupon
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('APLICAR'),
              ),
            ),
          ],
        ),
        if (checkout.couponError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              checkout.couponError!,
              style: const TextStyle(color: AppColors.coral, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _summary(
    BuildContext context,
    double subtotal,
    double discount,
    double shippingCost,
    double total,
  ) {
    final shippingText = _selectedShipping == null
        ? 'A calcular'
        : (shippingCost == 0 ? 'Gratis' : Formatters.currency(shippingCost));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _row(context, 'Subtotal', Formatters.currency(subtotal)),
            if (discount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _row(
                context,
                'Descuento',
                '- ${Formatters.currency(discount)}',
                color: AppColors.success,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _row(
              context,
              'Envío',
              shippingText,
              color: _selectedShipping == null ? AppColors.muted : null,
            ),
            const Divider(height: AppSpacing.xl),
            _row(context, 'Total', Formatters.currency(total), isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isTotal = false,
  }) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge?.copyWith(color: color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        letterSpacing: 1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
