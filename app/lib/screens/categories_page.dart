import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';
import 'package:totals/models/category.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/utils/category_icons.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openEditor(context),
            tooltip: 'Add category',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories;
          final essentialCategories =
              categories.where((c) => c.essential).toList(growable: false);
          final nonEssentialCategories =
              categories.where((c) => !c.essential).toList(growable: false);

          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No categories yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              if (essentialCategories.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Essential',
                  count: essentialCategories.length,
                ),
                const SizedBox(height: 8),
                for (final c in essentialCategories) ...[
                  _CategoryTile(
                    category: c,
                    onEdit: () => _openEditor(context, existing: c),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
              ],
              if (nonEssentialCategories.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Non-essential',
                  count: nonEssentialCategories.length,
                ),
                const SizedBox(height: 8),
                for (final c in nonEssentialCategories) ...[
                  _CategoryTile(
                    category: c,
                    onEdit: () => _openEditor(context, existing: c),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Category? existing}) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    final result = await showModalBottomSheet<_CategoryEditorResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _CategoryEditorSheet(existing: existing);
      },
    );

    if (result == null) return;
    if (result.name.trim().isEmpty) return;

    try {
      if (existing == null) {
        await provider.createCategory(
          name: result.name,
          essential: result.essential,
          iconKey: result.iconKey,
          description: result.description,
        );
      } else {
        await provider.updateCategory(
          existing.copyWith(
            name: result.name,
            essential: result.essential,
            iconKey: result.iconKey,
            description: result.description,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save category: $e')),
        );
      }
    }
  }
}

class _CategoryEditorResult {
  final String name;
  final bool essential;
  final String? iconKey;
  final String? description;

  const _CategoryEditorResult({
    required this.name,
    required this.essential,
    required this.iconKey,
    required this.description,
  });
}

class _CategoryEditorSheet extends StatefulWidget {
  final Category? existing;

  const _CategoryEditorSheet({required this.existing});

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _essential;
  String? _iconKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _essential = widget.existing?.essential ?? false;
    _iconKey = widget.existing?.iconKey ?? 'more_horiz';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit category' : 'Add category',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _CategoryEditorResult(
                          name: _nameController.text,
                          essential: _essential,
                          iconKey: _iconKey,
                          description: _descriptionController.text,
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _essential,
                onChanged: (v) => setState(() => _essential = v),
                title: const Text('Essential'),
                subtitle: const Text('Used for spending insights'),
              ),
              const SizedBox(height: 12),
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  const itemSize = 44.0;
                  const gap = 10.0;
                  final maxWidth = constraints.maxWidth;
                  final rawCount =
                      ((maxWidth + gap) / (itemSize + gap)).floor();
                  final crossAxisCount = rawCount.clamp(3, 7);
                  final gridWidth =
                      (crossAxisCount * itemSize) + ((crossAxisCount - 1) * gap);

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: gridWidth),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryIconOptions.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          mainAxisExtent: itemSize,
                        ),
                        itemBuilder: (context, index) {
                          final option = categoryIconOptions[index];
                          return _IconChoice(
                            option: option,
                            selected: _iconKey == option.key,
                            onTap: () => setState(() => _iconKey = option.key),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final CategoryIconOption option;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : Theme.of(context).dividerColor,
                width: selected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(option.icon, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.essential ? Colors.blue : Colors.orange;
    final description = (category.description ?? '').trim();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            iconForCategoryKey(category.iconKey),
            color: color,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description.isEmpty ? 'No description' : description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
