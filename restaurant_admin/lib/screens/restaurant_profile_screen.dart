import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _api = ApiService();

  bool _loading = true;
  bool _saving = false;
  int _currentRestaurantId = 1;
  List<dynamic> _allRestaurants = [];

  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRestaurantProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantProfile([int? targetId]) async {
    setState(() => _loading = true);
    final res = await _api.getRestaurantProfile(restaurantId: targetId);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] ?? {};
      _allRestaurants = res['all_restaurants'] ?? [];
      _currentRestaurantId = data['id'] ?? (targetId ?? 1);

      _nameCtrl.text = data['name'] ?? '';
      _taglineCtrl.text = data['tagline'] ?? '';
      _addressCtrl.text = data['address'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _gstCtrl.text = data['gst_number'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveRestaurantProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter restaurant name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final res = await _api.updateRestaurantProfile({
      'restaurant_id': _currentRestaurantId,
      'name': _nameCtrl.text.trim(),
      'tagline': _taglineCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'gst_number': _gstCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Restaurant details saved! Customer bills will now reflect these details.',
          ),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _loadRestaurantProfile(_currentRestaurantId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ?? 'Failed to update restaurant profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      drawer: isDesktop
          ? null
          : const Drawer(
              backgroundColor: Color(0xFF1E1E1E),
              child: SafeArea(
                child: AppSidebar(activeLabel: 'Restaurant Details'),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              const CollapsibleSidebar(activeLabel: 'Restaurant Details'),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: !isDesktop
                        ? () => Scaffold.of(context).openDrawer()
                        : null,
                    title: 'Restaurant Details & Bill Branding',
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF45B15),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Multi-Restaurant Header & Branch Selector
                                _buildMultiRestaurantHeader(),

                                const SizedBox(height: 20),

                                // Responsive Content: Form & Live Bill Preview
                                if (width >= 1000)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Left: Form (60%)
                                      Expanded(
                                        flex: 6,
                                        child: _buildFormCard(),
                                      ),
                                      const SizedBox(width: 24),
                                      // Right: Live Bill Preview (40%)
                                      Expanded(
                                        flex: 4,
                                        child: _buildLiveBillPreviewCard(),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildFormCard(),
                                      const SizedBox(height: 24),
                                      _buildLiveBillPreviewCard(),
                                    ],
                                  ),
                              ],
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

  // ---- MULTI-RESTAURANT BRANCH SELECTOR ----
  Widget _buildMultiRestaurantHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_mall_directory_rounded,
                  color: Color(0xFFF45B15),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Restaurant Management',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Each restaurant branch maintains its own branding, address, phone and customer bill format.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF75787E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_allRestaurants.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFECECEC), height: 1),
            ),
            Row(
              children: [
                const Text(
                  'Active Branch:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2022),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _allRestaurants.map((r) {
                        final id = r['id'] as int;
                        final isSelected = id == _currentRestaurantId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${r['name']} (#$id)'),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFFF2EB),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFF45B15)
                                  : const Color(0xFF1E2022),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFF45B15)
                                  : const Color(0xFFE5E7EB),
                            ),
                            onSelected: (selected) {
                              if (selected && id != _currentRestaurantId) {
                                _loadRestaurantProfile(id);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---- FORM CARD ----
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFF45B15),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Branch #$_currentRestaurantId Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2022),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Fill out the details below. These will dynamically appear on your customer bills and online ordering menus.',
            style: TextStyle(fontSize: 12, color: Color(0xFF75787E)),
          ),
          const SizedBox(height: 20),

          // 1. Restaurant Name
          _buildFieldLabel('Restaurant Name *', Icons.badge_outlined),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            decoration: _inputDecoration('e.g. Food Plaza / Sarjapur PetPooja'),
          ),
          const SizedBox(height: 16),

          // 2. Tagline / Tag
          _buildFieldLabel(
            'Tagline / Slogan (Tag)',
            Icons.local_offer_outlined,
          ),
          TextField(
            controller: _taglineCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(
              'e.g. Good Food, Good Mood / Authentic Taste',
            ),
          ),
          const SizedBox(height: 16),

          // 3. Address
          _buildFieldLabel(
            'Full Restaurant Address',
            Icons.location_on_outlined,
          ),
          TextField(
            controller: _addressCtrl,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _inputDecoration(
              'e.g. 123 Food Street, Sector 62, Noida, UP - 201309',
            ),
          ),
          const SizedBox(height: 16),

          // 4. Phone Number
          _buildFieldLabel('Contact Phone Number', Icons.phone_outlined),
          TextField(
            controller: _phoneCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _inputDecoration('e.g. +91 98765 43210'),
          ),
          const SizedBox(height: 16),

          // 5. GST Number
          _buildFieldLabel('GST Number (GSTIN)', Icons.receipt_long_outlined),
          TextField(
            controller: _gstCtrl,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            decoration: _inputDecoration('e.g. 07AAAAA0000A1Z5 (Optional)'),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveRestaurantProfile,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                _saving ? 'Saving Changes...' : 'Save Restaurant Details',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF45B15),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- LIVE BILL PREVIEW CARD ----
  Widget _buildLiveBillPreviewCard() {
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : 'Restaurant Name';
    final tagline = _taglineCtrl.text.trim().isNotEmpty
        ? _taglineCtrl.text.trim()
        : 'Good Food, Good Mood';
    final address = _addressCtrl.text.trim().isNotEmpty
        ? _addressCtrl.text.trim()
        : '123 Food Street, City - 000000';
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? _phoneCtrl.text.trim()
        : '+91 98765 43210';
    final gst = _gstCtrl.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE PREVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Customer Bill Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF75787E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simulated Customer Bill Slip
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                // Logo & Header
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF45B15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E2022),
                  ),
                ),
                Text(
                  tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF75787E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF75787E),
                  ),
                ),
                Text(
                  'Phone: $phone',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF75787E),
                  ),
                ),
                if (gst.isNotEmpty)
                  Text(
                    'GSTIN: $gst',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF75787E),
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 10),

                // Simulated Invoice Body
                const Text(
                  'TAX INVOICE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFF1E2022),
                  ),
                ),
                const SizedBox(height: 8),
                _previewMetaRow('Order No', '#ORD-8921'),
                _previewMetaRow('Table No', 'Table 4 (Dine In)'),
                _previewMetaRow('Date & Time', 'Today, 02:45 PM'),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),

                _previewItemRow('Paneer Butter Masala', '1x', '₹260'),
                _previewItemRow('Butter Roti', '3x', '₹90'),
                _previewItemRow('Jeera Rice', '1x', '₹150'),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),

                _previewMetaRow('Subtotal', '₹500'),
                _previewMetaRow('GST (5%)', '₹25'),
                _previewMetaRow('Grand Total', '₹525', isBold: true),

                const SizedBox(height: 16),
                const Text(
                  'Thank You! Visit Again 😊',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF75787E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewMetaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF75787E),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF1E2022),
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewItemRow(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2022),
              ),
            ),
          ),
          Text(
            qty,
            style: const TextStyle(fontSize: 11, color: Color(0xFF75787E)),
          ),
          const SizedBox(width: 14),
          Text(
            price,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2022),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF45B15)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2022),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF9EA1A8),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFECECEC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF45B15), width: 1.5),
      ),
    );
  }
}
