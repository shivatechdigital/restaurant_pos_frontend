import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StockRequestScreen extends StatefulWidget {
  const StockRequestScreen({super.key});

  @override
  State<StockRequestScreen> createState() => _StockRequestScreenState();
}

class _StockRequestScreenState extends State<StockRequestScreen> {
  final _api = ApiService();
  final _itemCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _urgency = 'normal';
  bool _isSubmitting = false;

  final _quickItems = const [
    'Paneer',
    'Chicken',
    'Tomato',
    'Onion',
    'Milk',
    'Curd',
    'Rice',
    'Naan Dough',
    'Oil',
    'Masala',
  ];

  @override
  void dispose() {
    _itemCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: const Text('Stock Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kya khatam ho gaya?',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickItems.map((item) {
                return ActionChip(
                  label: Text(item),
                  onPressed: () => _itemCtrl.text = item,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _itemCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Item / Ingredient',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g. 2 kg, 5 packet, 10 litre',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'urgent', label: Text('Urgent')),
              ],
              selected: {_urgency},
              onSelectionChanged: (value) => setState(() => _urgency = value.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional details...',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Sending...' : 'Send to Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _urgency == 'urgent' ? Colors.orange : const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_itemCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item name required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _api.createInventoryRequest(
      itemName: _itemCtrl.text.trim(),
      quantity: _qtyCtrl.text.trim(),
      urgency: _urgency,
      notes: _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _itemCtrl.clear();
      _qtyCtrl.clear();
      _notesCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request admin ko bhej di'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Request failed'), backgroundColor: Colors.red),
      );
    }
  }
}
