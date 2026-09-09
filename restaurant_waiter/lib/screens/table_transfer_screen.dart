import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/waiter_provider.dart';
import '../widgets/waiter_shell.dart';

class TableTransferScreen extends StatefulWidget {
  const TableTransferScreen({super.key});

  @override
  State<TableTransferScreen> createState() => _TableTransferScreenState();
}

class _TableTransferScreenState extends State<TableTransferScreen> {
  int? _sourceTableId;
  int? _destTableId;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final waiter = context.read<WaiterProvider>();
      waiter.loadTables();
      waiter.loadActiveOrders();
      waiter.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    context.read<WaiterProvider>().stopAutoRefresh();
    super.dispose();
  }

  double _tableAmount(TableModel table, List<WaiterOrder> orders) {
    if (table.activeSessionId == null) return 0;
    return orders
        .where((o) => o.sessionId == table.activeSessionId)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
  }

  int _tableItemCount(TableModel table, List<WaiterOrder> orders) {
    if (table.activeSessionId == null) return 0;
    return orders
        .where((o) => o.sessionId == table.activeSessionId)
        .fold<int>(0, (sum, o) => sum + o.items.length);
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1100;

    final occupied = waiter.tables.where((t) => t.isOccupied).toList();
    final available = waiter.tables.where((t) => t.isAvailable).toList();
    final reserved = waiter.tables.where((t) => t.isReserved).toList();

    final sourceTable = waiter.tables.where((t) => t.id == _sourceTableId).firstOrNull;
    final destTable = waiter.tables.where((t) => t.id == _destTableId).firstOrNull;

    return WaiterShell(
      route: WaiterRoute.transfer,
      title: 'Hello, Rahul! 👋',
      subtitle: 'Move guests, not just orders! Make dining flexible.',
      searchHint: 'Search table or order...',
      onRefresh: () {
        waiter.loadTables();
        waiter.loadActiveOrders();
      },
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaiterPageHeader(
              icon: Icons.compare_arrows_rounded,
              iconColor: kRed,
              title: 'Table Transfer',
              subtitle: 'Transfer guests and their active order to another table',
              pills: [
                WaiterStatPill(icon: Icons.person_rounded, value: '${occupied.length}', label: 'Tables Occupied', color: kRed),
                WaiterStatPill(icon: Icons.groups_rounded, value: '${available.length}', label: 'Tables Available', color: Colors.green),
                WaiterStatPill(icon: Icons.event_seat_rounded, value: '${reserved.length}', label: 'Tables Reserved', color: Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 14),
            _legendRow(),
            const SizedBox(height: 12),
            Expanded(
              child: compact
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _floorGrid(waiter, crossAxisCount: width < 700 ? 2 : 3),
                          const SizedBox(height: 12),
                          _transferPanel(waiter, occupied, available, sourceTable, destTable),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _floorGrid(waiter, crossAxisCount: 4)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 340,
                          child: _transferPanel(waiter, occupied, available, sourceTable, destTable),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _legend('Available', Colors.green),
        _legend('Occupied', kRed),
        _legend('Reserved', Colors.deepPurple),
        _legend('Cleaning', Colors.orange),
        _legend('Out of Service', Colors.grey),
      ],
    );
  }

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10.5, color: Colors.blueGrey.shade600)),
    ],
  );

  Widget _floorGrid(WaiterProvider waiter, {required int crossAxisCount}) {
    if (waiter.tables.isEmpty) {
      return const Center(child: Text('Koi table nahi mili', style: TextStyle(color: Colors.grey)));
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.05,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: waiter.tables.length,
      itemBuilder: (context, index) => _tableCard(waiter, waiter.tables[index]),
    );
  }

  Widget _tableCard(WaiterProvider waiter, TableModel table) {
    final color = table.isAvailable
        ? Colors.green
        : table.isOccupied
            ? kRed
            : table.isCleaning
                ? Colors.orange
                : table.isReserved
                    ? Colors.deepPurple
                    : Colors.grey;
    final isSource = _sourceTableId == table.id;
    final isDest = _destTableId == table.id;
    final amount = _tableAmount(table, waiter.activeOrders);

    return GestureDetector(
      onTap: () => _handleTap(table, waiter),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSource || isDest ? kInk : Colors.white,
            width: isSource || isDest ? 3 : 1,
          ),
          boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Table ${table.tableNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            Text(
              table.isOccupied
                  ? 'up to ${table.capacity} guests'
                  : table.isCleaning
                      ? 'Cleaning'
                      : table.isReserved
                          ? 'Reserved'
                          : 'Available',
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
            if (table.isOccupied && amount > 0)
              Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            if (isSource)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Source', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            if (isDest)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Destination', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(TableModel table, WaiterProvider waiter) {
    if (table.isOccupied) {
      setState(() {
        _sourceTableId = table.id;
        if (_destTableId == table.id) _destTableId = null;
      });
    } else if (table.isAvailable && _sourceTableId != null) {
      setState(() => _destTableId = table.id);
    } else if (table.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle ek occupied table select karo')),
      );
    }
  }

  Widget _transferPanel(
    WaiterProvider waiter,
    List<TableModel> occupied,
    List<TableModel> available,
    TableModel? sourceTable,
    TableModel? destTable,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transfer Table', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            Text('Move current order to another table', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500)),
            const SizedBox(height: 14),
            _stepLabel(1, 'Select Current Table'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _sourceTableId,
              isExpanded: true,
              hint: const Text('Select current table', style: TextStyle(fontSize: 12)),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: occupied
                  .map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          'T${t.tableNumber} \u2022 \u20b9${_tableAmount(t, waiter.activeOrders).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() {
                _sourceTableId = value;
                if (_destTableId == value) _destTableId = null;
              }),
            ),
            if (sourceTable != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kPage, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Table Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    _detailRow('Table', 'T${sourceTable.tableNumber}'),
                    _detailRow('Capacity', 'up to ${sourceTable.capacity} guests'),
                    _detailRow('Items', '${_tableItemCount(sourceTable, waiter.activeOrders)}'),
                    _detailRow('Total Amount', '\u20b9${_tableAmount(sourceTable, waiter.activeOrders).toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _stepLabel(2, 'Select New Table'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _destTableId,
              isExpanded: true,
              hint: const Text('Select destination table', style: TextStyle(fontSize: 12)),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: available
                  .map((t) => DropdownMenuItem(value: t.id, child: Text('T${t.tableNumber}', style: const TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: sourceTable == null ? null : (value) => setState(() => _destTableId = value),
            ),
            const SizedBox(height: 8),
            Text('Available Tables (${available.length})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available
                  .map(
                    (t) => ChoiceChip(
                      label: Text('T${t.tableNumber}', style: const TextStyle(fontSize: 11)),
                      selected: _destTableId == t.id,
                      selectedColor: Colors.green.shade100,
                      onSelected: sourceTable == null ? null : (_) => setState(() => _destTableId = t.id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _stepLabel(3, 'Transfer Options'),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: true,
              onChanged: null,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Transfer entire order', style: TextStyle(fontSize: 12)),
            ),
            const CheckboxListTile(
              value: false,
              onChanged: null,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('Move only selected items (coming soon)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const CheckboxListTile(
              value: false,
              onChanged: null,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('Keep current table open / split order (coming soon)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: .06), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transferring a table will move the active order and bill to the new table. Make sure the destination table is available.',
                      style: TextStyle(fontSize: 10.5, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _sourceTableId = null;
                      _destTableId = null;
                    }),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (sourceTable == null || destTable == null || _isTransferring)
                        ? null
                        : () => _transfer(waiter, sourceTable, destTable),
                    icon: const Icon(Icons.compare_arrows, size: 16),
                    label: Text(_isTransferring ? 'Transferring...' : 'Transfer Table'),
                    style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLabel(int step, String label) => Row(
    children: [
      CircleAvatar(radius: 10, backgroundColor: kRed, child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 11))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ],
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Future<void> _transfer(WaiterProvider waiter, TableModel source, TableModel dest) async {
    if (source.activeSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source table ka active session nahi mila'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isTransferring = true);
    final result = await waiter.transferTable(source.activeSessionId!, dest.id);
    if (!mounted) return;
    setState(() => _isTransferring = false);
    final success = result['success'] == true;
    if (success) {
      setState(() {
        _sourceTableId = null;
        _destTableId = null;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Table transferred successfully.' : (result['message']?.toString() ?? 'Transfer failed.')),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
