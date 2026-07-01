import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../promotions/domain/entities/coupon.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Formulario de alta/edición de cupón.
class AdminCouponFormPage extends ConsumerStatefulWidget {
  const AdminCouponFormPage({this.coupon, super.key});

  final Coupon? coupon;

  @override
  ConsumerState<AdminCouponFormPage> createState() => _State();
}

class _State extends ConsumerState<AdminCouponFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _minPurchase = TextEditingController(text: '0');
  final _maxDiscount = TextEditingController();
  final _usageLimit = TextEditingController();
  final _description = TextEditingController();
  DiscountType _type = DiscountType.percentage;
  bool _isActive = true;
  late DateTime _validFrom;
  late DateTime _validUntil;

  bool get _isEdit => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _validFrom = c?.validFrom ?? DateTime.now();
    _validUntil = c?.validUntil ?? DateTime.now().add(const Duration(days: 30));
    if (c != null) {
      _code.text = c.code;
      _value.text = c.value.toStringAsFixed(0);
      _minPurchase.text = c.minPurchaseAmount.toStringAsFixed(0);
      _maxDiscount.text = c.maxDiscountAmount?.toStringAsFixed(0) ?? '';
      _usageLimit.text = c.usageLimit?.toString() ?? '';
      _description.text = c.description ?? '';
      _type = c.type;
      _isActive = c.isActive;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _code,
      _value,
      _minPurchase,
      _maxDiscount,
      _usageLimit,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _validFrom : _validUntil;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => isFrom ? _validFrom = picked : _validUntil = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'code': _code.text.trim().toUpperCase(),
      'type': _type.key,
      'value': double.tryParse(_value.text.replaceAll(',', '.')) ?? 0,
      'minPurchaseAmount':
          double.tryParse(_minPurchase.text.replaceAll(',', '.')) ?? 0,
      'maxDiscountAmount': _maxDiscount.text.isEmpty
          ? null
          : double.tryParse(_maxDiscount.text.replaceAll(',', '.')),
      'usageLimit': _usageLimit.text.isEmpty
          ? null
          : int.tryParse(_usageLimit.text),
      'isActive': _isActive,
      'validFrom': _validFrom.toIso8601String(),
      'validUntil': _validUntil.toIso8601String(),
      'description': _description.text.trim(),
    };

    final api = ref.read(adminApiProvider);
    final ok = await runAdminAction(
      context,
      () => _isEdit
          ? api.updateCoupon(widget.coupon!.id, data)
          : api.createCoupon(data),
      success: _isEdit ? 'Cupón actualizado' : 'Cupón creado',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar cupón' : 'Nuevo cupón')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              enabled: !_isEdit, // el código es el id; no se cambia al editar
              decoration: const InputDecoration(labelText: 'Código'),
              validator: (v) => Validators.required(v, field: 'El código'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<DiscountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: DiscountType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            if (_type != DiscountType.freeShipping) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _type == DiscountType.percentage
                      ? 'Valor (%)'
                      : 'Valor (\$)',
                ),
                validator: (v) =>
                    Validators.positiveNumber(v, field: 'El valor'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _minPurchase,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Compra mínima',
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxDiscount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tope desc. (opc)',
                      prefixText: r'$ ',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _usageLimit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Límite usos (opc)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Desde'),
                    subtitle: Text(Formatters.date(_validFrom)),
                    onTap: () => _pickDate(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hasta'),
                    subtitle: Text(Formatters.date(_validUntil)),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descripción (opc)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _isEdit ? 'Guardar' : 'Crear cupón',
              icon: Icons.save,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
