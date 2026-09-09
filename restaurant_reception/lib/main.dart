import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/debug_flags.dart';
import 'table_view_screen.dart';
import 'screens/reception_dashboard.dart';
import 'screens/reception_table_mgmt.dart';
import 'screens/reception_pos_screen.dart';
import 'screens/reception_reports_screen.dart';
import 'screens/reception_menu_screen.dart';
import 'screens/reception_settings_screen.dart';

const _brand = Color(0xFFB51E2B);
const _baseUrl = 'http://48.217.50.135/api';

void main() => runApp(const ReceptionApp());

class ReceptionApp extends StatelessWidget {
  const ReceptionApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Restaurant Reception',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: _brand),
        home: const ReceptionGate(),
      );
}

class ReceptionGate extends StatefulWidget {
  const ReceptionGate({super.key});
  @override
  State<ReceptionGate> createState() => _ReceptionGateState();
}

class _ReceptionGateState extends State<ReceptionGate> {
  bool _loading = true;
  String? _token;
  String _name = 'Reception';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _token = prefs.getString('reception_token');
      _name = prefs.getString('reception_name') ?? 'Reception';
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reception_token');
    await prefs.remove('reception_name');
    if (mounted) setState(() => _token = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _token == null
        ? ReceptionLogin(onLogin: (token, name) => setState(() { _token = token; _name = name; }))
        : ReceptionHome(token: _token!, receptionistName: _name, onLogout: _logout);
  }
}

class ReceptionHome extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;

  const ReceptionHome({
    super.key,
    required this.token,
    required this.receptionistName,
    required this.onLogout,
  });

  @override
  State<ReceptionHome> createState() => _ReceptionHomeState();
}

class _ReceptionHomeState extends State<ReceptionHome> {
  int _index = 0;

  void _openTableMgmt() => setState(() => _index = 1);
  void _openDashboard() => setState(() => _index = 0);

  Future<void> _openPos([dynamic table]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceptionPosScreen(
          token: widget.token,
          receptionistName: widget.receptionistName,
          onLogout: widget.onLogout,
          initialTable: table,
          onNavigateToDashboard: _leavePosToDashboard,
          onNavigateToTableMgmt: _leavePosToTableMgmt,
          onNavigateToReports: _openReports,
          onNavigateToMenu: _openMenu,
          onNavigateToSettings: _openSettings,
        ),
      ),
    );
  }

  void _leavePosToDashboard() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    _openDashboard();
  }

  void _leavePosToTableMgmt() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    _openTableMgmt();
  }

  Future<void> _openReports() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceptionReportsScreen(
          token: widget.token,
          receptionistName: widget.receptionistName,
          onLogout: widget.onLogout,
          onNavigate: _navigateFromSecondary,
        ),
      ),
    );
  }

  Future<void> _openMenu() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ReceptionMenuScreen(
      token: widget.token,
      receptionistName: widget.receptionistName,
      onLogout: widget.onLogout,
      onNavigate: _navigateFromSecondary,
    )));
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ReceptionSettingsScreen(
      token: widget.token,
      receptionistName: widget.receptionistName,
      onLogout: widget.onLogout,
      onNavigate: _navigateFromSecondary,
    )));
  }

  void _navigateFromSecondary(String label) {
    if (label == 'Dashboard') {
      Navigator.pop(context);
      _openDashboard();
    } else if (label == 'Table Management') {
      Navigator.pop(context);
      _openTableMgmt();
    } else if (label == 'POS / Orders') {
      Navigator.pop(context);
      _openPos();
    } else if (label == 'Reports') {
      _openReports();
    } else if (label == 'Settings') {
      _openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ReceptionDashboard(
        token: widget.token,
        receptionistName: widget.receptionistName,
        onLogout: widget.onLogout,
        onNavigateToTableMgmt: _openTableMgmt,
        onNavigateToPos: _openPos,
        onNavigateToReports: _openReports,
        onNavigateToMenu: _openMenu,
        onNavigateToSettings: _openSettings,
      ),
      ReceptionTableMgmt(
        token: widget.token,
        receptionistName: widget.receptionistName,
        onLogout: widget.onLogout,
        onNavigateToDashboard: _openDashboard,
        onNavigateToPos: _openPos,
        onNavigateToReports: _openReports,
        onNavigateToMenu: _openMenu,
        onNavigateToSettings: _openSettings,
      ),
    ];

    return screens[_index];
  }
}

class ReceptionLogin extends StatefulWidget {
  final void Function(String token, String name) onLogin;
  const ReceptionLogin({super.key, required this.onLogin});
  @override
  State<ReceptionLogin> createState() => _ReceptionLoginState();
}

class _ReceptionLoginState extends State<ReceptionLogin> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _sent = false;
  bool _working = false;
  String _error = '';
  String? _testOtp;

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(Uri.parse('$_baseUrl$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    return response.body.isEmpty ? {'success': false} : jsonDecode(response.body);
  }

  Future<void> _sendOtp() async {
    if (_phone.text.trim().length != 10) { setState(() => _error = 'Enter a 10 digit phone number'); return; }
    setState(() { _working = true; _error = ''; });
    final result = await _post('/auth/send-otp', {'phone': _phone.text.trim()});
    if (!mounted) return;
    setState(() {
      _working = false;
      _sent = result['success'] == true;
      _testOtp = result['data']?['otp']?.toString();
      _error = result['success'] == true ? '' : (result['message'] ?? 'Unable to send OTP');
    });
  }

  Future<void> _login() async {
    setState(() { _working = true; _error = ''; });
    final result = await _post('/auth/verify-otp', {'phone': _phone.text.trim(), 'otp': _otp.text.trim()});
    if (!mounted) return;
    if (result['success'] != true || result['data']?['user']?['role'] != 'reception') {
      setState(() { _working = false; _error = result['success'] == true ? 'This account is not a Reception user' : (result['message'] ?? 'Login failed'); });
      return;
    }
    final token = result['data']['token'] as String;
    final name = result['data']['user']['name']?.toString() ?? 'Reception';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reception_token', token);
    await prefs.setString('reception_name', name);
    if (mounted) widget.onLogin(token, name);
  }

  @override
  void dispose() { _phone.dispose(); _otp.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F5F6),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Card(
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(radius: 30, backgroundColor: Color(0xFFFFE8EA), child: Icon(Icons.support_agent, color: _brand, size: 35)),
        const SizedBox(height: 16), const Text('Reception Console', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), const Text('Counter billing, bookings and delivery desk', textAlign: TextAlign.center), const SizedBox(height: 24),
        TextField(controller: _phone, enabled: !_sent, maxLength: 10, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Reception phone', prefixText: '+91 ', border: OutlineInputBorder(), counterText: '')),
        if (_sent) ...[const SizedBox(height: 12), TextField(controller: _otp, maxLength: 6, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder(), counterText: ''))],
        if (kShowTestOtp && _testOtp != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)),
              child: Text('Test OTP: $_testOtp', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ),
        if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 18), SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _working ? null : (_sent ? _login : _sendOtp), style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white), child: Text(_working ? 'Please wait...' : (_sent ? 'Login' : 'Send OTP')))),
      ])),
    ))),
  );
}

class ReceptionPos extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;
  final dynamic initialTable;
  const ReceptionPos({super.key, required this.token, required this.receptionistName, required this.onLogout, this.initialTable});
  @override
  State<ReceptionPos> createState() => _ReceptionPosState();
}

class _ReceptionPosState extends State<ReceptionPos> {
  final _search = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final List<Map<String, dynamic>> _cart = [];
  List<dynamic> _categories = [];
  List<dynamic> _tables = [];
  String _mode = 'dine-in';
  int _category = 0;
  int? _tableId;
  bool _loading = true;
  bool _saving = false;
  List<dynamic> _existingItems = [];
  double _existingTotal = 0;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); _phone.dispose(); _name.dispose(); _address.dispose(); super.dispose(); }

  Future<Map<String, dynamic>> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))..headers.addAll({'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'})..body = body == null ? '' : jsonEncode(body);
    final response = await http.Client().send(request);
    final text = await response.stream.bytesToString();
    return text.isEmpty ? {'success': false} : jsonDecode(text);
  }

  Future<void> _load() async {
    final menu = await _request('GET', '/menu?restaurant_id=1');
    final tables = await _request('GET', '/tables/all');
    if (!mounted) return;
    setState(() {
      _categories = menu['success'] == true ? menu['data']['menu'] ?? [] : [];
      _tables = tables['success'] == true ? tables['data'] ?? [] : [];
      if (widget.initialTable != null) {
        _mode = 'dine-in';
        _tableId = widget.initialTable['id'] as int?;
      }
      _loading = false;
    });
    final sessionId = widget.initialTable?['active_session_id'];
    if (sessionId != null) await _loadExistingBill(sessionId);
  }

  Future<void> _loadExistingBill(dynamic sessionId) async {
    final result = await _request('GET', '/orders/bill/$sessionId');
    if (!mounted || result['success'] != true) return;
    final data = result['data'] as Map<String, dynamic>;
    setState(() {
      _existingItems = data['items'] as List? ?? [];
      _existingTotal = _money(data['summary']?['final_amount']);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(automaticallyImplyLeading: false, backgroundColor: Colors.white, foregroundColor: const Color(0xFF313131), titleSpacing: 10, title: Row(children: [IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Table view', onPressed: () => Navigator.pop(context)), const Text('petpos', style: TextStyle(color: _brand, fontWeight: FontWeight.w900, fontSize: 24)), const SizedBox(width: 12), FilledButton.icon(onPressed: _newOrder, icon: const Icon(Icons.add), label: const Text('New Order'), style: FilledButton.styleFrom(backgroundColor: _brand))]), actions: [Text('Hello, ${widget.receptionistName}'), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: widget.onLogout)]),
      body: LayoutBuilder(builder: (context, constraints) => Column(children: [_orderBar(), Expanded(child: Row(children: [_categoriesRail(), Expanded(child: _menuGrid()), SizedBox(width: constraints.maxWidth < 1250 ? 370 : 440, child: _ticket())]))])),
    );
  }

  Widget _orderBar() => Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Row(children: [Expanded(child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(isDense: true, hintText: 'Search item', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()))), const SizedBox(width: 12), SizedBox(width: 410, child: SegmentedButton<String>(segments: const [ButtonSegment(value: 'dine-in', label: Text('Dine In')), ButtonSegment(value: 'delivery', label: Text('Delivery')), ButtonSegment(value: 'takeaway', label: Text('Pick Up'))], selected: {_mode}, onSelectionChanged: (value) => setState(() => _mode = value.first)))]));

  Widget _categoriesRail() => Container(width: 110, color: const Color(0xFF555555), child: ListView.builder(itemCount: _categories.length + 1, itemBuilder: (_, index) { final selected = _category == index; final name = index == 0 ? 'Favorite Items' : _categories[index - 1]['name'] ?? 'Category'; return InkWell(onTap: () => setState(() => _category = index), child: Container(padding: const EdgeInsets.all(11), constraints: const BoxConstraints(minHeight: 47), color: selected ? _brand : null, child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)))); }));

  Widget _menuGrid() {
    final items = _items();
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, childAspectRatio: 1.25, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _add(item),
          child: Ink(
            decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: item['is_veg'] == false ? Colors.red : Colors.green, width: 3)), boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 2)]),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const Spacer(), Text('₹${_money(item['price']).toStringAsFixed(0)}', style: const TextStyle(color: _brand, fontWeight: FontWeight.bold))]),
            ),
          ),
        );
      },
    );
  }

  Widget _ticket() {
    final subtotal = _cart.fold<double>(0, (total, item) => total + _money(item['price']) * (item['qty'] as int));
    final total = subtotal * 1.10;
    return Container(color: Colors.white, child: Column(children: [
      _customerPanel(),
      if (_existingItems.isNotEmpty)
        Container(
          width: double.infinity,
          color: const Color(0xFFFFF3CD),
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.receipt_long, size: 16, color: Color(0xFF8A6400)),
                const SizedBox(width: 6),
                const Expanded(child: Text('Running table bill', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D4D00)))),
                Text('₹${_existingTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D4D00))),
              ]),
              const SizedBox(height: 4),
              Text(
                _existingItems.map((item) => '${item['quantity']}x ${item['item_name']}').join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6D4D00)),
              ),
            ],
          ),
        ),
      Container(color: const Color(0xFFEEEEEE), padding: const EdgeInsets.all(8), child: const Row(children: [Expanded(child: Text('NEW KOT ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 75, child: Text('QTY.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 65, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))])),
      Expanded(child: _cart.isEmpty ? const Center(child: Text('Add new items for the next KOT')) : ListView.separated(itemCount: _cart.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (_, index) => _line(index))),
      Container(color: const Color(0xFF393939), padding: const EdgeInsets.all(10), child: Row(children: [const Icon(Icons.check_box_outline_blank, color: Colors.white), const SizedBox(width: 7), const Text('Complimentary', style: TextStyle(color: Colors.white, fontSize: 12)), const Spacer(), const Text('Total', style: TextStyle(color: Colors.white)), const SizedBox(width: 8), Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFFD21F), fontWeight: FontWeight.bold, fontSize: 20))])),
      Container(padding: const EdgeInsets.all(10), child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [SizedBox(width: 180, child: ElevatedButton(onPressed: _cart.isEmpty || _saving ? null : () => _place(false), style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white), child: Text(_saving ? 'Saving...' : 'Save & Print'))), OutlinedButton(onPressed: _cart.isEmpty || _saving ? null : () => _place(true), child: const Text('KOT')), OutlinedButton(onPressed: _newOrder, child: const Text('Hold'))]))
    ]));
  }

  Widget _customerPanel() => Padding(padding: const EdgeInsets.all(10), child: Column(children: [
    if (_mode == 'dine-in') DropdownButtonFormField<int>(isDense: true, decoration: const InputDecoration(labelText: 'Table No.', border: OutlineInputBorder()), initialValue: _tableId, items: _tables.map((table) => DropdownMenuItem(value: table['id'] as int, child: Text('${table['table_number']} (${table['status']})'))).toList(), onChanged: (value) => setState(() => _tableId = value)),
    if (_mode != 'dine-in') TextField(controller: _phone, decoration: const InputDecoration(isDense: true, labelText: 'Mobile', border: OutlineInputBorder())),
    const SizedBox(height: 7), TextField(controller: _name, decoration: const InputDecoration(isDense: true, labelText: 'Name', border: OutlineInputBorder())),
    if (_mode == 'delivery') ...[const SizedBox(height: 7), TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(isDense: true, labelText: 'Delivery Address', border: OutlineInputBorder()))],
  ]));

  Widget _line(int index) { final item = _cart[index]; final amount = _money(item['price']) * (item['qty'] as int); return Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Row(children: [IconButton(icon: const Icon(Icons.cancel, color: _brand, size: 18), tooltip: 'Remove', onPressed: () => setState(() => _cart.removeAt(index))), Expanded(child: Text(item['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))), SizedBox(width: 72, child: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(constraints: const BoxConstraints.tightFor(width: 20, height: 30), icon: const Icon(Icons.remove, size: 15), padding: EdgeInsets.zero, onPressed: () => _qty(index, -1)), Text('${item['qty']}', style: const TextStyle(fontSize: 12)), IconButton(constraints: const BoxConstraints.tightFor(width: 20, height: 30), icon: const Icon(Icons.add, size: 15), padding: EdgeInsets.zero, onPressed: () => _qty(index, 1))])), SizedBox(width: 58, child: Text('₹${amount.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)))])); }

  List<dynamic> _items() { final categories = _category == 0 ? _categories : [_categories[_category - 1]]; final all = <dynamic>[]; for (final category in categories) { all.addAll(category['items'] as List? ?? []); } final query = _search.text.toLowerCase(); return all.where((item) => (item['is_available'] ?? true) && (query.isEmpty || (item['name'] ?? '').toString().toLowerCase().contains(query))).toList(); }
  void _add(dynamic item) { final index = _cart.indexWhere((entry) => entry['id'] == item['id']); setState(() { if (index < 0) { _cart.add({'id': item['id'], 'name': item['name'], 'price': _money(item['price']), 'qty': 1}); } else { _cart[index]['qty'] = (_cart[index]['qty'] as int) + 1; } }); }
  void _qty(int index, int change) => setState(() { final quantity = (_cart[index]['qty'] as int) + change; if (quantity < 1) { _cart.removeAt(index); } else { _cart[index]['qty'] = quantity; } });
  void _newOrder() => setState(() { _cart.clear(); _tableId = null; _phone.clear(); _name.clear(); _address.clear(); });

  Future<void> _place(bool kotOnly) async {
    if (_mode == 'dine-in' && _tableId == null) { _message('Select a table for dine-in'); return; }
    if (_mode == 'delivery' && _address.text.trim().isEmpty) { _message('Enter delivery address'); return; }
    setState(() => _saving = true);
    final result = await _request('POST', '/pos/orders', body: {'order_type': _mode, if (_tableId != null) 'table_id': _tableId, 'customer_phone': _phone.text.trim(), 'customer_name': _name.text.trim(), 'delivery_address': _address.text.trim(), 'items': _cart.map((item) => {'menu_item_id': item['id'], 'quantity': item['qty']}).toList()});
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) { final order = result['data']; _newOrder(); _message('${kotOnly ? 'KOT' : 'Order'} created: #${order['order_id']}${order['table_number'] != null ? ' • ${order['table_number']}' : ''}'); } else { _message(result['message'] ?? 'Unable to create order'); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: _brand));
  double _money(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}
