import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../promotions/domain/entities/promotion.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Formulario de alta/edición de promoción (campaña/banner).
class AdminPromotionFormPage extends ConsumerStatefulWidget {
  const AdminPromotionFormPage({this.promotion, super.key});

  final Promotion? promotion;

  @override
  ConsumerState<AdminPromotionFormPage> createState() => _State();
}

class _State extends ConsumerState<AdminPromotionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _value = TextEditingController();
  final _order = TextEditingController(text: '0');
  final _banner = TextEditingController();
  DiscountType _type = DiscountType.percentage;
  bool _isActive = true;
  late DateTime _validFrom;
  late DateTime _validUntil;

  bool get _isEdit => widget.promotion != null;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _validFrom = p?.validFrom ?? DateTime.now();
    _validUntil = p?.validUntil ?? DateTime.now().add(const Duration(days: 7));
    if (p != null) {
      _title.text = p.title;
      _subtitle.text = p.subtitle ?? '';
      _value.text = p.value.toStringAsFixed(0);
      _order.text = '${p.order}';
      _banner.text = p.bannerUrl ?? '';
      _type = p.type;
      _isActive = p.isActive;
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _subtitle, _value, _order, _banner]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validUntil,
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
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim(),
      'type': _type.key,
      'value': double.tryParse(_value.text.replaceAll(',', '.')) ?? 0,
      'order': int.tryParse(_order.text) ?? 0,
      'bannerUrl': _banner.text.trim().isEmpty ? null : _banner.text.trim(),
      'isActive': _isActive,
      'validFrom': _validFrom.toIso8601String(),
      'validUntil': _validUntil.toIso8601String(),
    };
    final api = ref.read(adminApiProvider);
    final ok = await runAdminAction(
      context,
      () => _isEdit
          ? api.updatePromotion(widget.promotion!.id, data)
          : api.createPromotion(data),
      success: _isEdit ? 'Promoción actualizada' : 'Promoción creada',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar promoción' : 'Nueva promoción'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => Validators.required(v, field: 'El título'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _subtitle,
              decoration: const InputDecoration(labelText: 'Subtítulo (opc)'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<DiscountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo de descuento'),
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
                decoration: const InputDecoration(labelText: 'Valor'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _banner,
              decoration: const InputDecoration(
                labelText: 'URL del banner (opc)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Orden'),
            ),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activa'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _isEdit ? 'Guardar' : 'Crear promoción',
              icon: Icons.save,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
