import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/responsive.dart';
import '../config/theme.dart';
import '../models/menu_model.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  final int tableId;
  final String restaurantId;
  final String sessionId;
  final String tableNumber;

  const CartScreen({
    super.key,
    required this.tableId,
    required this.restaurantId,
    required this.sessionId,
    required this.tableNumber,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacing = false;
  final TextEditingController _couponCtrl = TextEditingController();

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: CustomerTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: CustomerTheme.textDark,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: CustomerTheme.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClearCart(cart),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: CustomerTheme.redDanger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CustomerTheme.borderSubtle, height: 1),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : CustomerPage(
              maxWidth: 640,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- TABLE HEADER PILL ----
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CustomerTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: CustomerTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.table_restaurant_rounded,
                              color: CustomerTheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Table ${widget.tableNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: CustomerTheme.textDark,
                                  ),
                                ),
                                const Text(
                                  'Dine-in Order',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CustomerTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CustomerTheme.greenLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Active Session',
                              style: TextStyle(
                                color: CustomerTheme.greenSuccess,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- CART ITEMS LIST (Card 02 UI) ----
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _buildCartItemTile(context, cart, item, index);
                      },
                    ),

                    const SizedBox(height: 18),

                    // ---- APPLY COUPON SECTION (Reference Card 02) ----
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CustomerTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.percent_rounded,
                                size: 18,
                                color: CustomerTheme.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Apply Coupon',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: CustomerTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: CustomerTheme.borderSubtle,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _couponCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter coupon code',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: CustomerTheme.textLight,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No active coupons for this order',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CustomerTheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                  ),
                                  child: const Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ---- SUGGESTIONS ("You may also like") ----
                    _buildSuggestions(context, cart),

                    const SizedBox(height: 18),

                    // ---- BILL SUMMARY CARD (Reference Card 02) ----
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: CustomerTheme.borderSubtle),
                        boxShadow: CustomerTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: CustomerTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildBillLine(
                            'Items Total',
                            '₹${cart.subtotal.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 8),
                          _buildBillLine(
                            'GST (5%)',
                            '₹${cart.gst.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _buildBillLine(
                            'Service Charge (5%)',
                            '₹${cart.serviceCharge.toStringAsFixed(2)}',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: CustomerTheme.borderSubtle,
                              thickness: 1,
                            ),
                          ),
                          _buildBillLine(
                            'Grand Total',
                            '₹${cart.totalAmount.toStringAsFixed(2)}',
                            isGrandTotal: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---- PLACE / PROCEED BUTTON (Direct clean button matching Card 02) ----
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _isPlacing
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFFFF7A3D),
                                  CustomerTheme.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        boxShadow: _isPlacing
                            ? null
                            : CustomerTheme.primaryButtonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _isPlacing ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          disabledForegroundColor: const Color(0xFF9CA3AF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isPlacing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Proceed to Order (₹${cart.totalAmount.toStringAsFixed(0)})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Order once placed will be sent directly to the kitchen',
                        style: TextStyle(
                          fontSize: 11,
                          color: CustomerTheme.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCartItemTile(
    BuildContext context,
    CartProvider cart,
    dynamic item,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerTheme.borderSubtle),
        boxShadow: CustomerTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderImage(item.isVeg),
                        )
                      : _buildPlaceholderImage(item.isVeg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildVegIcon(item.isVeg),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: CustomerTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CustomerTheme.textMuted,
                      ),
                    ),
                    if (item.modifiers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.modifiers.map((m) => m.name).join(', '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: CustomerTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: CustomerTheme.redDanger,
                  size: 20,
                ),
                tooltip: 'Remove',
                onPressed: () => cart.removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: CustomerTheme.borderSubtle),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CustomerTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => cart.decreaseQty(index),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: CustomerTheme.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CustomerTheme.textDark,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => cart.increaseQty(index),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: CustomerTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${item.itemTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CustomerTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.specialInstructions,
            onChanged: (value) => cart.updateInstructions(index, value),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Add cooking note (e.g. less spicy, no onion)',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: CustomerTheme.textLight,
              ),
              prefixIcon: const Icon(
                Icons.mode_comment_outlined,
                size: 14,
                color: CustomerTheme.textMuted,
              ),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CustomerTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isVeg) {
    return Container(
      color: isVeg ? const Color(0xFFEDF7ED) : const Color(0xFFFFECEB),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: isVeg ? CustomerTheme.greenSuccess : CustomerTheme.primary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildVegIcon(bool isVeg) {
    final color = isVeg ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
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

  Widget _buildBillLine(
    String label,
    String value, {
    bool isGrandTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 16 : 13,
            fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w500,
            color: isGrandTotal
                ? CustomerTheme.textDark
                : CustomerTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 14,
            fontWeight: isGrandTotal ? FontWeight.w900 : FontWeight.w700,
            color: isGrandTotal
                ? CustomerTheme.primary
                : CustomerTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context, CartProvider cart) {
    final suggestions = context
        .watch<MenuProvider>()
        .categories
        .expand((category) => category.items)
        .where(
          (item) =>
              item.isAvailable &&
              !cart.items.any((cartItem) => cartItem.menuItemId == item.id),
        )
        .take(5)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'You may also like',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CustomerTheme.textDark,
              ),
            ),
            Text(
              '${suggestions.length} items',
              style: const TextStyle(
                fontSize: 12,
                color: CustomerTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return Container(
                width: 220,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CustomerTheme.borderSubtle),
                  boxShadow: CustomerTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child:
                            item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderImage(item.isVeg),
                              )
                            : _buildPlaceholderImage(item.isVeg),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: CustomerTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CustomerTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        color: CustomerTheme.primary,
                        size: 26,
                      ),
                      onPressed: () => cart.addItem(menuItem: item),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmClearCart(CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear Cart?'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomerTheme.redDanger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: CustomerTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CustomerTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Explore delicious food items from the menu and add them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: CustomerTheme.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: const Text('Explore Menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomerTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final cart = context.read<CartProvider>();
    final order = context.read<OrderProvider>();
    order.setSessionId(widget.sessionId);
    final success = await order.placeOrder(
      tableId: widget.tableId,
      restaurantId: int.parse(widget.restaurantId),
      items: cart.toApiFormat(),
    );

    if (!mounted) return;
    if (success) {
      cart.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            sessionId: widget.sessionId,
            tableNumber: widget.tableNumber,
            restaurantId: widget.restaurantId,
            tableId: widget.tableId,
          ),
        ),
      );
      return;
    }

    setState(() => _isPlacing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          order.error.isNotEmpty ? order.error : 'Order not placed. Try again.',
        ),
        backgroundColor: CustomerTheme.redDanger,
      ),
    );
  }
}
