import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';
import 'category_icons.dart';
import 'category_form_screen.dart';
import 'product_form_screen.dart';

final NumberFormat _money = NumberFormat('#,##0');

/// إدارة الكتالوج: المنتجات والتصنيفات (CRUD + إظهار/إخفاء + رفع صور).
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  int _section = 0; // 0 = منتجات، 1 = تصنيفات

  Future<void> _refresh() async {
    ref.invalidate(catalogProductsProvider);
    ref.invalidate(catalogCategoriesProvider);
    final List<Future<void>> futures = <Future<void>>[
      ref.read(catalogProductsProvider.future).then((_) {}),
      ref.read(catalogCategoriesProvider.future).then((_) {}),
    ];
    try {
      await Future.wait<void>(futures);
    } on Object {
      // تُعرض حالة الخطأ من المزوّد.
    }
  }

  Future<void> _openProductForm([CatalogProduct? product]) async {
    final List<CatalogCategory> categories =
        ref.read(catalogCategoriesProvider).valueOrNull ?? const <CatalogCategory>[];
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductFormScreen(product: product, categories: categories),
      ),
    );
    if (saved == true) {
      ref.invalidate(catalogProductsProvider);
    }
  }

  Future<void> _openCategoryForm([CatalogCategory? category]) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CategoryFormScreen(category: category),
      ),
    );
    if (saved == true) {
      ref.invalidate(catalogCategoriesProvider);
    }
  }

  Future<void> _toggleProductActive(CatalogProduct product, bool active) async {
    await ref.read(catalogRepositoryProvider).setProductActive(product.id, active);
    ref.invalidate(catalogProductsProvider);
  }

  Future<void> _toggleCategoryActive(CatalogCategory category, bool active) async {
    await ref.read(catalogRepositoryProvider).updateCategory(category.id, <String, dynamic>{'is_active': active});
    ref.invalidate(catalogCategoriesProvider);
  }

  Future<void> _deleteCategory(CatalogCategory category) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(t('حذف التصنيف')),
        content: Text(t('سيُحذف التصنيف «%s» نهائياً. المنتجات المرتبطة ستبقى بدون تصنيف. متابعة؟').replaceFirst('%s', category.displayName)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('إلغاء'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('حذف')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(catalogRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(catalogCategoriesProvider);
    }
  }

  Future<void> _deleteProduct(CatalogProduct product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(t('حذف المنتج')),
        content: Text(t('سيُحذف «%s» نهائياً. متابعة؟').replaceFirst('%s', product.displayName)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('إلغاء'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('حذف')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(catalogRepositoryProvider).deleteProduct(product.id);
      ref.invalidate(catalogProductsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CatalogProduct>> products = ref.watch(catalogProductsProvider);
    final AsyncValue<List<CatalogCategory>> categories = ref.watch(catalogCategoriesProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: <ButtonSegment<int>>[
                      ButtonSegment<int>(value: 0, label: Text(t('المنتجات'))),
                      ButtonSegment<int>(value: 1, label: Text(t('التصنيفات'))),
                    ],
                    selected: <int>{_section},
                    onSelectionChanged: (Set<int> selection) => setState(() => _section = selection.first),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: _section == 0 ? t('إضافة منتج') : t('إضافة تصنيف'),
                icon: const Icon(Icons.add_rounded),
                onPressed: _section == 0 ? () => _openProductForm() : () => _openCategoryForm(),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _section == 0
                ? _productsList(products)
                : _categoriesList(categories),
          ),
        ),
      ],
    );
  }

  Widget _productsList(AsyncValue<List<CatalogProduct>> products) {
    return products.when(
      data: (List<CatalogProduct> items) {
        if (items.isEmpty) {
          return _empty(t('لا توجد منتجات بعد'), t('اضغط + لإضافة أول منتج'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final CatalogProduct product = items[index];
            return _ProductTile(
              product: product,
              onToggleActive: (bool active) => _toggleProductActive(product, active),
              onEdit: () => _openProductForm(product),
              onDelete: () => _deleteProduct(product),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل المنتجات'), '$error'),
    );
  }

  Widget _categoriesList(AsyncValue<List<CatalogCategory>> categories) {
    return categories.when(
      data: (List<CatalogCategory> items) {
        if (items.isEmpty) {
          return _empty(t('لا توجد تصنيفات بعد'), t('اضغط + لإضافة أول تصنيف'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final CatalogCategory category = items[index];
            return _CategoryTile(
              category: category,
              onToggleActive: (bool active) => _toggleCategoryActive(category, active),
              onEdit: () => _openCategoryForm(category),
              onDelete: () => _deleteCategory(category),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل التصنيفات'), '$error'),
    );
  }

  Widget _empty(String title, String hint) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        const SizedBox(height: 120),
        Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(hint, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}

class CatalogThumb extends StatelessWidget {
  const CatalogThumb({super.key, this.url, this.size = 56});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = url != null && url!.trim().isNotEmpty;
    final Widget placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: hasUrl
          ? Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          : placeholder,
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final CatalogProduct product;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double discount = product.discountPercent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CatalogThumb(url: product.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(product.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [if ((product.nameFr ?? '').isNotEmpty) product.nameFr!, if ((product.unit ?? '').isNotEmpty) product.unit!].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Text('${_money.format(product.price)} $currency', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                      if (discount > 0) ...<Widget>[
                        const SizedBox(width: 8),
                        Text('${_money.format(product.oldPrice)} $currency', style: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('${discount.round()}%', style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: <Widget>[
                Switch(value: product.isActive, onChanged: onToggleActive),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(visualDensity: VisualDensity.compact, tooltip: t('تعديل'), icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
                    IconButton(visualDensity: VisualDensity.compact, tooltip: t('حذف'), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger), onPressed: onDelete),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final CatalogCategory category;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(categoryIconFor(category.iconName), color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(category.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [if ((category.nameFr ?? '').isNotEmpty) category.nameFr!, t('ترتيب: %s').replaceFirst('%s', '${category.displayOrder}')].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Switch(value: category.isActive, onChanged: onToggleActive),
            IconButton(tooltip: t('تعديل'), icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(tooltip: t('حذف'), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
