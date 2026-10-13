import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_model.dart';
import '../models/cart_model.dart';
import '../providers/cart_provider.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.getItemQty(item.id);
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 16 : 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.isAvailable ? () => _showCustomizeDialog(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---- IMAGE / PLACEHOLDER (Reference rounded image with shadow) ----
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFFF9FAFB),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),
                  ),
                  Positioned(top: 6, left: 6, child: _vegBadge(item.isVeg)),
                ],
              ),
              const SizedBox(width: 14),

              // ---- DETAILS ----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E2022),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: Color(0xFF75787E),
                          fontSize: 12,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),

                    // Price + prep time + customizable tag
                    Row(
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFFF45B15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.prepTimeMinutes > 0) ...[
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: Color(0xFF9EA1A8),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.prepTimeMinutes}m',
                            style: const TextStyle(
                              color: Color(0xFF9EA1A8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (item.modifiers.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Custom',
                              style: TextStyle(
                                color: Color(0xFFF45B15),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---- ADD BUTTON / QUANTITY ----
              const SizedBox(width: 8),
              if (!item.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Sold Out',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (qty == 0)
                _addButton(context)
              else
                _quantityControl(context, qty),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF2EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.restaurant_rounded,
          size: 24,
          color: Color(0xFFF45B15),
        ),
      ),
    );
  }

  Widget _vegBadge(bool isVeg) {
    final color = isVeg ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF45B15),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30F45B15),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _showCustomizeDialog(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
        tooltip: 'Add to Cart',
      ),
    );
  }

  Widget _quantityControl(BuildContext context, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD4C2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove_rounded, () {
            final cart = context.read<CartProvider>();
            final idx = cart.items.indexWhere((i) => i.menuItemId == item.id);
            if (idx >= 0) cart.decreaseQty(idx);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Color(0xFFF45B15),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          _qtyBtn(Icons.add_rounded, () {
            final cart = context.read<CartProvider>();
            final idx = cart.items.indexWhere((i) => i.menuItemId == item.id);
            if (idx >= 0) cart.increaseQty(idx);
          }),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: const Color(0xFFF45B15), size: 16),
      ),
    );
  }

  // ---- CUSTOMIZE DIALOG ----
  void _showCustomizeDialog(BuildContext context) {
    final selectedMods = <SelectedModifier>[];
    final instructionsCtrl = TextEditingController();

    // Default modifiers pre-select karo
    for (final mod in item.modifiers) {
      if (mod.isDefault) {
        selectedMods.add(
          SelectedModifier(id: mod.id, name: mod.name, price: mod.price),
        );
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double modTotal = selectedMods.fold(0, (sum, m) => sum + m.price);
          double finalPrice = item.price + modTotal;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B5E20),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        _vegBadge(item.isVeg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),

                          // Modifiers
                          if (item.modifiers.isNotEmpty) ...[
                            const Text(
                              '🧀 Customize Your Order',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...item.modifiers.map((mod) {
                              final isSelected = selectedMods.any(
                                (s) => s.id == mod.id,
                              );
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: const Color(0xFF1B5E20),
                                title: Text(mod.name),
                                subtitle: mod.price > 0
                                    ? Text(
                                        '+₹${mod.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : const Text('Free'),
                                value: isSelected,
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selectedMods.add(
                                        SelectedModifier(
                                          id: mod.id,
                                          name: mod.name,
                                          price: mod.price,
                                        ),
                                      );
                                    } else {
                                      selectedMods.removeWhere(
                                        (s) => s.id == mod.id,
                                      );
                                    }
                                  });
                                },
                              );
                            }),
                            const Divider(),
                          ],

                          // Special Instructions
                          const Text(
                            '📝 Special Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: instructionsCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g., Less spicy, No onion, Extra gravy...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer — Price + Add Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₹${finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<CartProvider>().addItem(
                              menuItem: item,
                              modifiers: selectedMods,
                              instructions: instructionsCtrl.text,
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${item.name} added to cart!'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF1B5E20),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart, size: 18),
                          label: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
