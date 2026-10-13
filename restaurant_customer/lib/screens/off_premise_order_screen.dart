import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/menu_model.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/menu_item_card.dart';
import 'cart_screen.dart';
import 'payment_screen.dart';

class OffPremiseOrderScreen extends StatefulWidget {
  final int restaurantId;

  const OffPremiseOrderScreen({super.key, this.restaurantId = 1});

  @override
  State<OffPremiseOrderScreen> createState() => _OffPremiseOrderScreenState();
}

class _OffPremiseOrderScreenState extends State<OffPremiseOrderScreen> {
  final _searchCtrl = TextEditingController();
  final _phoneAuthCtrl = TextEditingController();
  final _otpAuthCtrl = TextEditingController();
  final _api = ApiService();

  int? _selectedCategoryId;
  String? _savedPhone;
  bool _isAuthenticated = false;
  bool _authLoading = true;
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String _authError = '';
  String? _testOtp;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final phone = prefs.getString('phone');

    if (token != null &&
        token.isNotEmpty &&
        phone != null &&
        phone.isNotEmpty) {
      if (mounted) {
        setState(() {
          _savedPhone = phone;
          _isAuthenticated = true;
          _authLoading = false;
        });
        context.read<MenuProvider>().loadMenu(widget.restaurantId.toString());
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _authLoading = false;
        });
      }
    }
  }

  Future<void> _handleSendAuthOtp() async {
    final phone = _phoneAuthCtrl.text.trim();
    if (phone.length != 10) {
      setState(
        () => _authError = 'Please enter a valid 10-digit mobile number',
      );
      return;
    }
    setState(() {
      _isSendingOtp = true;
      _authError = '';
    });

    try {
      final res = await _api.sendOtp(phone);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _otpSent = true;
          _testOtp = res['data']?['otp']?.toString();
        });
      } else {
        setState(() => _authError = res['message'] ?? 'Unable to send OTP');
      }
    } catch (e) {
      setState(() => _authError = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _handleVerifyAuthOtp() async {
    final phone = _phoneAuthCtrl.text.trim();
    final otp = _otpAuthCtrl.text.trim();

    if (otp.length != 6) {
      setState(() => _authError = 'Please enter the 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _authError = '';
    });

    try {
      final res = await _api.verifyOtp(phone, otp);
      if (!mounted) return;

      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone', phone);
        if (res['data']?['token'] != null) {
          await prefs.setString('token', res['data']['token']);
        }

        setState(() {
          _savedPhone = phone;
          _isAuthenticated = true;
        });
        context.read<MenuProvider>().loadMenu(widget.restaurantId.toString());
      } else {
        setState(
          () => _authError = res['message'] ?? 'Incorrect OTP. Try again.',
        );
      }
    } catch (e) {
      setState(() => _authError = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _phoneAuthCtrl.dispose();
    _otpAuthCtrl.dispose();
    super.dispose();
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          isOffPremise: true,
          restaurantId: widget.restaurantId.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F9FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF45B15)),
        ),
      );
    }

    if (!_isAuthenticated) {
      return _buildAuthView();
    }

    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final filteredCategories = menu.filteredCategories;

    final selectedCategories = filteredCategories
        .where((category) => category.id == _selectedCategoryId)
        .toList();
    final displayCategories = selectedCategories.isEmpty
        ? filteredCategories
        : selectedCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1E2022),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Food Plaza',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E2022),
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.delivery_dining_rounded,
                  size: 14,
                  color: Color(0xFFF45B15),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Takeaway & Delivery Menu',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF75787E),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Order History button for phone (Issue 11)
          IconButton(
            icon: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF1E2022),
            ),
            tooltip: 'My Online Orders',
            onPressed: _showOffPremiseHistoryModal,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),

      body: menu.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF45B15)),
            )
          : menu.error.isNotEmpty
          ? _errorView(menu)
          : SizedBox(
              width: double.infinity,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // 1. Promotional Deal Banner
                  _buildFeaturedBanner(),

                  // 2. Search & Veg Toggle Bar (Issue 1)
                  _buildSearchBar(menu),

                  // 3. Category Horizontal List
                  _buildCategoryRail(filteredCategories),

                  // 4. Recommended For You (Diverse items - Issue 3)
                  if (_searchCtrl.text.isEmpty && _selectedCategoryId == null)
                    _buildRecommendedSection(menu.categories),

                  // 5. Full Menu Categories with 4/3/2 Column Grid (Issue 4)
                  if (filteredCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No items found matching your search.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...displayCategories.map(
                      (category) => _buildCategorySection(category),
                    ),
                ],
              ),
            ),

      // Bottom floating cart button (stays on menu, doesn't auto-redirect - Issue 10)
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0x40F45B15),
                    ),
                    onPressed: _openCart,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cart.totalItems} ITEM${cart.totalItems > 1 ? 'S' : ''} ADDED',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'View Cart',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFeaturedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A211D), Color(0xFF1B1614)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              bottom: -20,
              width: 220,
              child: Opacity(
                opacity: 0.9,
                child: Image.network(
                  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E1714),
                    Color(0xD91E1714),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Order Takeaway or Delivery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Freshly Prepared • Fast Pickup & Delivery',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF45B15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Doorstep Delivery Available →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
  }

  Widget _buildSearchBar(MenuProvider menu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFECECEC)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: menu.search,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for dishes...',
                  hintStyle: const TextStyle(color: Color(0xFF9EA1A8)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF75787E),
                  ),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            menu.search('');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => menu.setVegOnly(!menu.vegOnly),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: menu.vegOnly ? const Color(0xFFEAF8F2) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: menu.vegOnly
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFECECEC),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF16A34A),
                        width: 1.3,
                      ),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Veg',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.72,
                    child: Switch(
                      value: menu.vegOnly,
                      activeTrackColor: const Color(0xFF16A34A),
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFE5E7EB),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: menu.setVegOnly,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRail(List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: SizedBox(
        height: 88,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _categoryTile(null, 'All', Icons.grid_view_rounded),
            ...categories.map(
              (cat) =>
                  _categoryTile(cat.id, cat.name, _getCategoryIcon(cat.name)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(int? id, String name, IconData icon) {
    final selected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF45B15) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFF45B15)
                      : const Color(0xFFECECEC),
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0x30F45B15)
                        : const Color(0x06000000),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : const Color(0xFFF45B15),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: const Color(0xFF1E2022),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('start')) return Icons.restaurant_rounded;
    if (n.contains('south') || n.contains('dosa'))
      return Icons.set_meal_rounded;
    if (n.contains('break')) return Icons.bakery_dining_rounded;
    if (n.contains('soup')) return Icons.soup_kitchen_rounded;
    if (n.contains('salad')) return Icons.eco_rounded;
    if (n.contains('burg') || n.contains('sand'))
      return Icons.lunch_dining_rounded;
    if (n.contains('nood') || n.contains('pasta'))
      return Icons.ramen_dining_rounded;
    if (n.contains('pizza')) return Icons.local_pizza_rounded;
    if (n.contains('dessert') || n.contains('sweet'))
      return Icons.icecream_rounded;
    if (n.contains('bever') || n.contains('drink'))
      return Icons.local_cafe_rounded;
    return Icons.fastfood_rounded;
  }

  Widget _buildRecommendedSection(List<Category> allCategories) {
    final allAvailable = allCategories
        .expand((c) => c.items)
        .where((i) => i.isAvailable)
        .toList();
    if (allAvailable.isEmpty) return const SizedBox.shrink();

    final List<MenuItem> diverseItems = [];
    int round = 0;
    while (diverseItems.length < 8 && round < 4) {
      bool anyAdded = false;
      for (var cat in allCategories) {
        final availableInCat = cat.items.where((i) => i.isAvailable).toList();
        if (round < availableInCat.length && diverseItems.length < 8) {
          diverseItems.add(availableInCat[round]);
          anyAdded = true;
        }
      }
      if (!anyAdded) break;
      round++;
    }
    final recommendedItems = diverseItems.isNotEmpty
        ? diverseItems
        : allAvailable.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Recommended for You',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2022),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: recommendedItems.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 175,
                child: MenuItemCard(
                  item: recommendedItems[index],
                  isGrid: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Full Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2022),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(Category category) {
    if (category.items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_searchCtrl.text.isEmpty && _selectedCategoryId == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              category.name,
              style: const TextStyle(
                color: Color(0xFF1E2022),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int crossAxisCount = width >= 1200
                ? 4
                : width >= 800
                ? 3
                : width >= 500
                ? 2
                : 1;

            if (crossAxisCount == 1) {
              return Column(
                children: category.items
                    .map((item) => MenuItemCard(item: item, isGrid: false))
                    .toList(),
              );
            }

            final double itemWidth =
                (width - 32 - (crossAxisCount - 1) * 12) / crossAxisCount;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: category.items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: MenuItemCard(item: item, isGrid: true),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _errorView(MenuProvider menu) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 50,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(menu.error, style: const TextStyle(color: Color(0xFFDC2626))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => menu.loadMenu(widget.restaurantId.toString()),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ---- AUTH VIEW: PHONE & OTP ENTRY FIRST (Matching Dine-in Look) ----
  Widget _buildAuthView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1E2022),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Online Ordering',
          style: TextStyle(
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.delivery_dining_rounded,
                  size: 16,
                  color: Color(0xFFF45B15),
                ),
                SizedBox(width: 6),
                Text(
                  'Takeaway & Delivery',
                  style: TextStyle(
                    color: Color(0xFFF45B15),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFECECEC)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF7A3D), Color(0xFFF45B15)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x35F45B15),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _otpSent
                            ? Icons.mark_email_read_rounded
                            : Icons.phone_iphone_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _otpSent ? 'Enter 6-Digit OTP' : 'Start Your Order',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E2022),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _otpSent
                        ? 'We sent a verification code to +91 ${_phoneAuthCtrl.text}'
                        : 'Enter your mobile number to access takeaway and delivery.',
                    style: const TextStyle(
                      color: Color(0xFF75787E),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (!_otpSent) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 2),
                      child: Text(
                        'Mobile Number *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _phoneAuthCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF1E2022),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '9876543210',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9EA1A8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixText: '+91  ',
                        prefixStyle: const TextStyle(
                          color: Color(0xFF1E2022),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_iphone_rounded,
                          color: Color(0xFFF45B15),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFECECEC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF45B15),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_authError.isNotEmpty) ...[
                      _authErrorBanner(_authError),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSendingOtp ? null : _handleSendAuthOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF45B15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSendingOtp
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue with OTP',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ] else ...[
                    // OTP Box
                    TextField(
                      controller: _otpAuthCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E2022),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '• • • • • •',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9EA1A8),
                          fontSize: 24,
                          letterSpacing: 8,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFECECEC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFF45B15),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    if (_testOtp != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _otpAuthCtrl.text = _testOtp!,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            'Test OTP: $_testOtp (Tap to Autofill)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_authError.isNotEmpty) ...[
                      _authErrorBanner(_authError),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isVerifyingOtp
                            ? null
                            : _handleVerifyAuthOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF45B15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isVerifyingOtp
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                'Verify & Open Menu',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => setState(() {
                        _otpSent = false;
                        _authError = '';
                      }),
                      child: const Text(
                        'Change Mobile Number',
                        style: TextStyle(
                          color: Color(0xFF75787E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- OFF-PREMISE ORDER HISTORY MODAL (Requirements 11 & 12) ----
  void _showOffPremiseHistoryModal() {
    final phoneCtrl = TextEditingController(text: _savedPhone ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OffPremiseHistorySheet(
        phoneCtrl: phoneCtrl,
        onOrderUpdated: () => setState(() {}),
      ),
    );
  }
}

class _OffPremiseHistorySheet extends StatefulWidget {
  final TextEditingController phoneCtrl;
  final VoidCallback onOrderUpdated;

  const _OffPremiseHistorySheet({
    required this.phoneCtrl,
    required this.onOrderUpdated,
  });

  @override
  State<_OffPremiseHistorySheet> createState() =>
      _OffPremiseHistorySheetState();
}

class _OffPremiseHistorySheetState extends State<_OffPremiseHistorySheet> {
  bool _loading = false;
  List<dynamic> _orders = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.phoneCtrl.text.length == 10) {
      _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    final phone = widget.phoneCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'Enter valid 10-digit phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone', phone);

    // Get current/recent off-premise session id if saved
    final session = await SessionService.getSession();
    final sessionId = session?['session_id']?.toString() ?? '';

    if (sessionId.isNotEmpty) {
      final res = await ApiService().getMyOrders(sessionId);
      if (mounted) {
        setState(() {
          _loading = false;
          _orders = res['success'] == true ? (res['data'] ?? []) : [];
        });
      }
    } else {
      setState(() {
        _loading = false;
        _orders = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: 640,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Online Order History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2022),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track and view past takeaway & delivery orders',
            style: TextStyle(fontSize: 12, color: Color(0xFF75787E)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    counterText: '',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _loading ? null : _fetchOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B15),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: const Text('Find Orders'),
              ),
            ],
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const Divider(height: 24),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF45B15)),
                  )
                : _orders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders found for this session.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final o = _orders[idx];
                      final status = o['status'] ?? 'placed';
                      final isPaid = o['payment_status'] == 'completed';
                      final amount = o['final_amount'] ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFECECEC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${o['id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF2EB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$status'.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF45B15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total: ₹$amount  •  ${o['order_type'] ?? "Takeaway"}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF75787E),
                              ),
                            ),
                            if (!isPaid) ...[
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentScreen(
                                        sessionId: o['session_id'].toString(),
                                        tableNumber: 'Online',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.payment_rounded,
                                  size: 16,
                                ),
                                label: const Text('Pay Online Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Live tracking screen for off premise
class OffPremiseTrackingScreen extends StatefulWidget {
  final String sessionId;
  final String orderType;
  final String? pickupToken;

  const OffPremiseTrackingScreen({
    super.key,
    required this.sessionId,
    required this.orderType,
    this.pickupToken,
  });

  @override
  State<OffPremiseTrackingScreen> createState() =>
      _OffPremiseTrackingScreenState();
}

class _OffPremiseTrackingScreenState extends State<OffPremiseTrackingScreen> {
  final _api = ApiService();
  Timer? _timer;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _api.getMyOrders(widget.sessionId);
    if (mounted && result['success'] == true) {
      setState(() => _orders = result['data'] ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _orders.isEmpty ? null : _orders.first;
    final deliveryStatus = latest?['delivery_status'] ?? 'new';
    final title = widget.orderType == 'delivery'
        ? 'Delivery Tracking'
        : 'Pickup Tracking';
    final status = widget.orderType == 'delivery'
        ? deliveryStatus
        : (latest?['status'] ?? 'placed');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1E2022),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: RefreshIndicator(
          color: const Color(0xFFF45B15),
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF2EB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.orderType == 'delivery'
                        ? Icons.delivery_dining_rounded
                        : Icons.shopping_bag_rounded,
                    size: 54,
                    color: const Color(0xFFF45B15),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Order status: ${status.toString().toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2022),
                ),
              ),
              if (widget.pickupToken != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECECEC)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Pickup Token',
                        style: TextStyle(
                          color: Color(0xFF75787E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.pickupToken!,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Ordered Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2022),
                ),
              ),
              const SizedBox(height: 10),
              ..._orders.map((order) {
                final items = order['items'] as List? ?? [];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECECEC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '₹${order['final_amount']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFFF45B15),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      ...items.map(
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Text(
                                '${i['quantity']}x ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${i['name']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                '₹${i['total_price'] ?? i['price']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.maybePop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B15),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
