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

    return Card(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 18 : 12, vertical: 5),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.isAvailable ? () => _showCustomizeDialog(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // ---- IMAGE / PLACEHOLDER ----
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey[100],
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              const SizedBox(width: 12),

              // ---- DETAILS ----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg/Non-Veg + Name
                    Row(
                      children: [
                        _vegBadge(item.isVeg),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Description
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Price + Time + Stock
                    Row(
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFF45B15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                        Text(
                          ' ${item.prepTimeMinutes} min',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                        if (item.modifiers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Customizable',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Out of Stock',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
      child: Icon(Icons.restaurant, size: 28, color: Colors.grey[300]),
    );
  }

  Widget _vegBadge(bool isVeg) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? Colors.green : Colors.red,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isVeg ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showCustomizeDialog(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('ADD', style: TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF45B15),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _quantityControl(BuildContext context, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF45B15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove, () {
            final cart = context.read<CartProvider>();
            final idx = cart.items.indexWhere((i) => i.menuItemId == item.id);
            if (idx >= 0) cart.decreaseQty(idx);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _qtyBtn(Icons.add, () {
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
        child: Icon(icon, color: Colors.white, size: 18),
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
