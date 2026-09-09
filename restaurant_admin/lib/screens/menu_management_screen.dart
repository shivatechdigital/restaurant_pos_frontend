import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../utils/picked_image.dart';
import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  // --- UI States ---
  String _activeCategory = 'All Items';
  String _searchQuery = '';
  String _statusFilter = 'All Status'; // All Status, Available, Unavailable
  String _sortBy = 'Sort by Name'; // Sort by Name, Price: Low to High, Price: High to Low
  int _currentPage = 1;
  static const int _pageSize = 10;
  final Set<int> _selectedIds = {};
  
  // --- Form States ---
  bool _isEditing = false;
  int? _editingItemId;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  int? _selectedCategoryId;
  String _gst = '5%';
  bool _isAvailable = true;
  String _itemType = 'Veg'; // Veg, Non-Veg, Jain
  bool _isSaving = false;
  PickedImage? _pickedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadMenu();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  // Fallback icon lookup so real backend category names still get a nice icon
  static const Map<String, IconData> _categoryIcons = {
    'Starters': Icons.kebab_dining,
    'Main Course': Icons.room_service,
    'Biryani': Icons.rice_bowl,
    'Chinese': Icons.ramen_dining,
    'Pizza': Icons.local_pizza,
    'Burgers': Icons.lunch_dining,
    'Beverages': Icons.local_drink,
    'Desserts': Icons.cake,
  };

  IconData _iconFor(String name) => _categoryIcons[name] ?? Icons.restaurant_menu;

  // Flatten items out of admin.menuCategories, attaching category name for display/filtering
  List<Map<String, dynamic>> _flattenItems(List<dynamic> categories) {
    final items = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final catItems = cat['items'] as List<dynamic>? ?? [];
      for (final item in catItems) {
        items.add({...item as Map<String, dynamic>, 'category_name': cat['name']});
      }
    }
    return items;
  }

  // ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1200; // Need wider screen for 3 columns
    final isMobile = w < 750;

    final items = _flattenItems(admin.menuCategories);

    // Filter Items
    final filteredItems = items.where((i) {
      final matchesCat = _activeCategory == 'All Items' || (i['category_name'] == _activeCategory);
      final matchesSearch = (i['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'All Status' ||
          (_statusFilter == 'Available' && i['is_available'] == true) ||
          (_statusFilter == 'Unavailable' && i['is_available'] != true);
      return matchesCat && matchesSearch && matchesStatus;
    }).toList();

    if (_sortBy == 'Sort by Name') {
      filteredItems.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    } else if (_sortBy == 'Price: Low to High') {
      filteredItems.sort((a, b) => _asDouble(a['price']).compareTo(_asDouble(b['price'])));
    } else if (_sortBy == 'Price: High to Low') {
      filteredItems.sort((a, b) => _asDouble(b['price']).compareTo(_asDouble(a['price'])));
    }

    final totalPages = filteredItems.isEmpty ? 1 : (filteredItems.length / _pageSize).ceil();
    final page = _currentPage.clamp(1, totalPages);
    final pagedItems = filteredItems.skip((page - 1) * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: isDesktop ? null : Drawer(backgroundColor: const Color(0xFF1E1E1E), child: AppSidebar(activeLabel: 'Menu Management')),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT: Sidebar (Desktop)
            if (isDesktop)
              Container(width: 220, color: const Color(0xFF1E1E1E), child: AppSidebar(activeLabel: 'Menu Management')),
            
            // MIDDLE: Menu List
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Menu Management',
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Main List Area
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _headerRow(),
                                const SizedBox(height: 20),
                                _categoryIconsRow(),
                                const SizedBox(height: 20),
                                _filterRow(isMobile),
                                const SizedBox(height: 16),
                                _buildTable(pagedItems, isMobile),
                                const SizedBox(height: 20),
                                _paginationRow(filteredItems.length, page, totalPages),
                              ],
                            ),
                          ),
                        ),
                        
                        // RIGHT: Add/Edit Form Panel (Desktop only)
                        if (isDesktop)
                          Container(
                            width: 380,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFDFD), // Slight off-white like image
                              border: Border(left: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: _buildRightFormPanel(),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // FAB for Mobile/Tablet to open form
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => _openFormModal(context),
              backgroundColor: const Color(0xFFE67E22),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ================= UI COMPONENTS (LEFT/MIDDLE) =================

  Widget _topBar(bool isMobile) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          if (isMobile) IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(hintText: 'Search menu items, categories...', hintStyle: TextStyle(fontSize: 13, color: Colors.grey), border: InputBorder.none, isDense: true),
                      onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            _dropdownBtn(Icons.store, 'Main Branch', const ['Main Branch'], (_) {}),
          ],
          const SizedBox(width: 16),
          Stack(
            children: [
              const Icon(Icons.notifications_none, size: 26),
              Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9)))),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(radius: 16, backgroundColor: Color(0xFF6D4C41), child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Main Branch', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ]
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Menu Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Manage your restaurant menu, categories and item details', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => _showManageCategoriesDialog(),
          icon: const Icon(Icons.settings, size: 16, color: Colors.black87),
          label: const Text('Manage Categories', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade300), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
      ],
    );
  }

  Widget _categoryIconsRow() {
    final categories = context.watch<AdminProvider>().menuCategories;
    final tabs = [
      {'name': 'All Items', 'icon': Icons.grid_view_rounded},
      ...categories.map((c) => {'name': c['name'], 'icon': _iconFor(c['name'])}),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((cat) {
          final isActive = _activeCategory == cat['name'];
          return GestureDetector(
            onTap: () => setState(() { _activeCategory = cat['name'] as String; _currentPage = 1; }),
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE67E22) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? const Color(0xFFE67E22) : Colors.grey.shade200),
                boxShadow: isActive ? [BoxShadow(color: const Color(0xFFE67E22).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, color: isActive ? Colors.white : Colors.orange.shade700, size: 28),
                  const SizedBox(height: 8),
                  Text(cat['name'] as String, style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showManageCategoriesDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Manage Categories'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...context.read<AdminProvider>().menuCategories.map((c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c['name'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final r = await context.read<AdminProvider>().deleteCategory(c['id']);
                          if (!ctx.mounted) return;
                          if (!r) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete: category has items'), backgroundColor: Colors.red));
                          }
                          setDialogState(() {});
                        },
                      ),
                    )),
                const SizedBox(height: 8),
                TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'New category name', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                await context.read<AdminProvider>().createCategory(ctrl.text.trim());
                ctrl.clear();
                setDialogState(() {});
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(bool isMobile) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        Container(
          width: 250,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search menu items...', hintStyle: TextStyle(fontSize: 13, color: Colors.grey), border: InputBorder.none, isDense: true),
                  onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                ),
              ),
            ],
          ),
        ),
        _dropdownBtn(
          null,
          _activeCategory,
          ['All Items', ...context.watch<AdminProvider>().menuCategories.map((c) => c['name'] as String)],
          (v) => setState(() { _activeCategory = v; _currentPage = 1; }),
        ),
        _dropdownBtn(
          null,
          _statusFilter,
          const ['All Status', 'Available', 'Unavailable'],
          (v) => setState(() { _statusFilter = v; _currentPage = 1; }),
        ),
        _dropdownBtn(
          Icons.sort,
          _sortBy,
          const ['Sort by Name', 'Price: Low to High', 'Price: High to Low'],
          (v) => setState(() => _sortBy = v),
        ),
      ],
    );
  }

  Widget _dropdownBtn(IconData? icon, String label, List<String> options, ValueChanged<String> onSelected) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (ctx) => options.map((o) => PopupMenuItem<String>(value: o, child: Text(o))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: Colors.grey.shade600), const SizedBox(width: 6)],
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List items, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: isMobile ? 800 : 900,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  children: [
                    Checkbox(value: false, onChanged: (v) {}),
                    _th('Item Name', 3),
                    _th('Category', 1.5),
                    _th('Price (₹)', 1),
                    _th('Availability', 1.5),
                    _th('Actions', 1.5, center: true),
                  ],
                ),
              ),
              // Rows
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Text('No items found', style: TextStyle(color: Colors.grey))),
              ...items.map((item) => _buildTableRow(item)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _th(String text, double flex, {bool center = false}) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(text, textAlign: center ? TextAlign.center : TextAlign.left, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
    );
  }

  Widget _buildTableRow(dynamic item) {
    bool isSelected = _selectedIds.contains(item['id']);
    bool isAvail = item['is_available'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.shade50 : Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: const Color(0xFFE67E22),
            onChanged: (v) => setState(() => v == true ? _selectedIds.add(item['id']) : _selectedIds.remove(item['id'])),
          ),
          
          // Image + Name
          Expanded(
            flex: 30,
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.fastfood, color: Colors.grey), // Placeholder for image
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(item['description'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category Badge
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _categoryBadge(item['category_name'] as String?),
            ),
          ),

          // Price
          Expanded(
            flex: 10,
            child: Text('₹${_asDouble(item['price']).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),

          // Availability Toggle
          Expanded(
            flex: 15,
            child: Row(
              children: [
                Switch(
                  value: isAvail,
                  activeColor: Colors.green,
                  onChanged: (v) => context.read<AdminProvider>().toggleItemAvailability(item['id'], v),
                ),
                Text(isAvail ? 'Available' : 'Unavailable', style: TextStyle(color: isAvail ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Actions
          Expanded(
            flex: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionBtn(Icons.edit, Colors.grey.shade600, () => _populateForm(item)),
                _actionBtn(Icons.delete_outline, Colors.red.shade400, () => _confirmDeleteItem(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  void _confirmDeleteItem(dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item['name']}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<AdminProvider>().deleteMenuItem(item['id']);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Item deleted' : 'Failed to delete item'), backgroundColor: ok ? Colors.green : Colors.red));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _categoryBadge(String? category) {
    final label = category ?? 'Uncategorized';
    Color bg, text;
    if (label == 'Main Course') { bg = Colors.orange.shade50; text = Colors.orange.shade800; }
    else if (label == 'Chinese' || label == 'Beverages') { bg = Colors.green.shade50; text = Colors.green.shade800; }
    else if (label == 'Pizza' || label == 'Desserts') { bg = Colors.pink.shade50; text = Colors.pink.shade800; }
    else if (label == 'Biryani' || label == 'Starters') { bg = Colors.blue.shade50; text = Colors.blue.shade800; }
    else { bg = Colors.grey.shade100; text = Colors.grey.shade800; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _paginationRow(int total, int page, int totalPages) {
    final startItem = total == 0 ? 0 : (page - 1) * _pageSize + 1;
    final endItem = (page * _pageSize) > total ? total : page * _pageSize;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Showing $startItem to $endItem of $total items', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Row(
          children: [
            _pageBox('<', false, page > 1 ? () => setState(() => _currentPage = page - 1) : null),
            for (final p in List.generate(totalPages, (i) => i + 1))
              if (totalPages <= 5 || p == 1 || p == totalPages || (p - page).abs() <= 1)
                _pageBox('$p', p == page, () => setState(() => _currentPage = p))
              else if (p == 2 || p == totalPages - 1)
                _pageBox('...', false, null),
            _pageBox('>', false, page < totalPages ? () => setState(() => _currentPage = page + 1) : null),
          ],
        )
      ],
    );
  }

  Widget _pageBox(String text, bool active, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE67E22) : Colors.white,
          border: Border.all(color: active ? const Color(0xFFE67E22) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(color: active ? Colors.white : (onTap == null ? Colors.grey.shade300 : Colors.black87), fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ================= RIGHT PANEL / FORM =================

  void _populateForm(dynamic item) {
    setState(() {
      _isEditing = true;
      _editingItemId = item['id'];
      _nameCtrl.text = item['name'] ?? '';
      _descCtrl.text = item['description'] ?? '';
      _priceCtrl.text = _asDouble(item['price']).toString();
      _selectedCategoryId = item['category_id'];
      _isAvailable = item['is_available'] ?? true;
      _itemType = item['is_veg'] == false ? 'Non-Veg' : 'Veg';
      _pickedImage = null;
      _uploadedImageUrl = item['image_url'];
    });
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingItemId = null;
      _nameCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _costCtrl.clear();
      _tagsCtrl.clear();
      _selectedCategoryId = null;
      _isAvailable = true;
      _itemType = 'Veg';
      _pickedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await pickImageFile();
    if (picked == null || !mounted) return;
    setState(() {
      _pickedImage = picked;
      _isUploadingImage = true;
    });
    final url = await context.read<AdminProvider>().uploadMenuImage(picked.bytes, picked.filename);
    if (!mounted) return;
    setState(() {
      _isUploadingImage = false;
      if (url != null) _uploadedImageUrl = url;
    });
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload failed'), backgroundColor: Colors.red));
    }
  }

  ImageProvider? _currentImagePreview() {
    if (_pickedImage != null) return MemoryImage(_pickedImage!.bytes);
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      final url = _uploadedImageUrl!.startsWith('http') ? _uploadedImageUrl! : '${ApiConfig.serverOrigin}$_uploadedImageUrl';
      return NetworkImage(url);
    }
    return null;
  }

  Future<void> _saveItem({bool isModal = false}) async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty || price == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item name, price and category are required'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSaving = true);
    final body = {
      'category_id': _selectedCategoryId,
      'name': name,
      'description': _descCtrl.text.trim(),
      'price': price,
      'is_veg': _itemType != 'Non-Veg',
      'is_available': _isAvailable,
      if (_uploadedImageUrl != null) 'image_url': _uploadedImageUrl,
    };
    final admin = context.read<AdminProvider>();
    final ok = _isEditing ? await admin.updateMenuItem(_editingItemId!, body) : await admin.createMenuItem(body);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Item saved successfully!' : 'Failed to save item'), backgroundColor: ok ? Colors.green : Colors.red));
    if (ok) {
      _resetForm();
      if (isModal) Navigator.of(context).pop();
    }
  }

  Widget _buildRightFormPanel({bool isModal = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isEditing ? 'Edit Menu Item' : 'Add New Menu Item', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(_isEditing ? 'Update existing item details' : 'Create a new menu item', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  _formTab('Add Item', !_isEditing),
                  _formTab('Edit Item', _isEditing),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          
          // Image Upload Row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: _currentImagePreview() != null ? DecorationImage(image: _currentImagePreview()!, fit: BoxFit.cover) : null,
                    ),
                    child: Stack(
                      children: [
                        if (_currentImagePreview() == null) const Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey)),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: _isUploadingImage
                                ? const Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.camera_alt, size: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_uploadedImageUrl != null ? Icons.check_circle : Icons.upload_file, color: _uploadedImageUrl != null ? Colors.green : Colors.grey.shade500),
                        const SizedBox(height: 4),
                        Text(_uploadedImageUrl != null ? 'Image Uploaded' : 'Upload Image', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('JPG, PNG (Max 2MB)', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // Inputs
          Row(
            children: [
              Expanded(child: _inputField('Item Name *', 'e.g. Chicken Biryani', _nameCtrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300))),
                      hint: const Text('Select Category', style: TextStyle(fontSize: 13)),
                      items: context.watch<AdminProvider>().menuCategories.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))).toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _inputField('Description', 'Enter item description...', _descCtrl, maxLines: 3),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _inputField('Price (₹) *', 'e.g. 320', _priceCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _inputField('Cost Price (₹)', 'e.g. 150', _costCtrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GST (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _gst,
                      decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300))),
                      items: ['0%', '5%', '12%', '18%'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _gst = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Toggles
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(value: _isAvailable, activeColor: Colors.green, onChanged: (v) => setState(() => _isAvailable = v)),
                        ),
                        Flexible(
                          child: Text('Available', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _radioType('Veg', Colors.green),
                        _radioType('Non-Veg', Colors.red),
                        _radioType('Jain', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add-ons / Variations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.add, size: 14), label: const Text('Add Variation', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          _inputField('Tags (Optional)', 'e.g. Spicy, Chef Special, Bestseller', _tagsCtrl),
          const SizedBox(height: 4),
          Text('Add tags to help in search and filtering', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300)),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveItem(isModal: isModal),
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, color: Colors.white, size: 18),
                  label: const Text('Save Menu Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22), padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _formTab(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE67E22) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _inputField(String label, String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  Widget _radioType(String type, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: type,
          groupValue: _itemType,
          activeColor: color,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (v) => setState(() => _itemType = v!),
        ),
        Text(type, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Mobile/Tablet Form Modal
  void _openFormModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: _buildRightFormPanel(isModal: true),
        ),
      ),
    );
  }
}