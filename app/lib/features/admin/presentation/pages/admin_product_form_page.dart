import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/presentation/controllers/catalog_providers.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Formulario de alta/edición de producto, con carga de imágenes a Cloudinary.
class AdminProductFormPage extends ConsumerStatefulWidget {
  const AdminProductFormPage({this.product, super.key});

  final Product? product;

  @override
  ConsumerState<AdminProductFormPage> createState() =>
      _AdminProductFormPageState();
}

class _AdminProductFormPageState extends ConsumerState<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _sku = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _weight = TextEditingController(text: '0');
  final _width = TextEditingController(text: '0');
  final _height = TextEditingController(text: '0');
  final _length = TextEditingController(text: '0');

  String? _categoryId;
  String? _subcategoryId;
  String? _brandId;
  bool _isFeatured = false;
  bool _isOnSale = false;
  bool _isActive = true;
  List<String> _images = [];
  bool _uploading = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _description.text = p.description;
      _sku.text = p.sku;
      _price.text = p.price.toStringAsFixed(0);
      _stock.text = '${p.stock}';
      _discount.text = p.discountPercentage.toStringAsFixed(0);
      _weight.text = p.dimensions.weightGrams.toStringAsFixed(0);
      _width.text = p.dimensions.widthCm.toStringAsFixed(0);
      _height.text = p.dimensions.heightCm.toStringAsFixed(0);
      _length.text = p.dimensions.lengthCm.toStringAsFixed(0);
      _categoryId = p.categoryId;
      _subcategoryId = p.subcategoryId;
      _brandId = p.brandId;
      _isFeatured = p.isFeatured;
      _isOnSale = p.isOnSale;
      _isActive = p.isActive;
      _images = [...p.images];
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _sku,
      _price,
      _stock,
      _discount,
      _weight,
      _width,
      _height,
      _length,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref
          .read(adminApiProvider)
          .uploadImage(bytes, filename: file.name);
      setState(() => _images = [..._images, url]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _brandId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Elegí categoría y marca.')));
      return;
    }

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'sku': _sku.text.trim(),
      'categoryId': _categoryId,
      'subcategoryId': _subcategoryId ?? '',
      'brandId': _brandId,
      'price': _num(_price),
      'stock': int.tryParse(_stock.text) ?? 0,
      'discountPercentage': _num(_discount),
      'isOnSale': _isOnSale,
      'isFeatured': _isFeatured,
      'isActive': _isActive,
      'images': _images,
      'dimensions': {
        'weightGrams': _num(_weight),
        'widthCm': _num(_width),
        'heightCm': _num(_height),
        'lengthCm': _num(_length),
      },
    };

    final api = ref.read(adminApiProvider);
    final ok = await runAdminAction(
      context,
      () => _isEdit
          ? api.updateProduct(widget.product!.id, data)
          : api.createProduct(data),
      success: _isEdit ? 'Producto actualizado' : 'Producto creado',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final brands = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _imagesSection(),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => Validators.required(v, field: 'El nombre'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _sku,
              decoration: const InputDecoration(labelText: 'SKU'),
              validator: (v) => Validators.required(v, field: 'El SKU'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: r'$ ',
                    ),
                    validator: (v) =>
                        Validators.positiveNumber(v, field: 'El precio'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    validator: (v) =>
                        Validators.positiveNumber(v, field: 'El stock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            categories.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Error cargando categorías'),
              data: (list) {
                final selected = list
                    .where((c) => c.id == _categoryId)
                    .toList();
                final List<Subcategory> subs = selected.isEmpty
                    ? const <Subcategory>[]
                    : selected.first.subcategories;
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: list
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _categoryId = v;
                        _subcategoryId = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (subs.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _subcategoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subcategoría',
                        ),
                        items: subs
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _subcategoryId = v),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            brands.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Error cargando marcas'),
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _brandId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Marca'),
                items: list
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _brandId = v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('En oferta'),
              value: _isOnSale,
              onChanged: (v) => setState(() => _isOnSale = v),
            ),
            if (_isOnSale)
              TextFormField(
                controller: _discount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Descuento (%)',
                  suffixText: '%',
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Destacado'),
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const Divider(height: AppSpacing.xl),
            Text(
              'Dimensiones (envío)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _dimField(_weight, 'Peso (g)')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _dimField(_width, 'Ancho (cm)')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _dimField(_height, 'Alto (cm)')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _dimField(_length, 'Largo (cm)')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isEdit ? 'Guardar cambios' : 'Crear producto',
              icon: Icons.save,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dimField(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
  );

  Widget _imagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imágenes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < _images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.network(
                          _images[i],
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _images = [..._images]..removeAt(i),
                          ),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.coral,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: _uploading
                      ? const Center(child: CircularProgressIndicator())
                      : const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.slate,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
