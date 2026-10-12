import 'package:flutter/material.dart';

import '../core/core.dart';

/// Dialog untuk mencatat transaksi pembelian di gerai.
/// Kalau [fixed] diisi, pelanggan sudah terpilih dan dropdown disembunyikan.
Future<void> showTxnDialog(BuildContext context, {Customer? fixed, String channel = 'gerai'}) async {
  if (fixed == null && store.customers.isEmpty) {
    snack(context, 'Belum ada pelanggan terdaftar');
    return;
  }
  await showDialog(context: context, builder: (_) => _TxnDialog(fixed: fixed, channel: channel));
}

class _TxnDialog extends StatefulWidget {
  final Customer? fixed;
  final String channel;
  const _TxnDialog({this.fixed, required this.channel});

  @override
  State<_TxnDialog> createState() => _TxnDialogState();
}

class _TxnDialogState extends State<_TxnDialog> {
  final _amount = TextEditingController(text: '100000');
  Customer? _sel;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sel = widget.fixed ?? (store.customers.isNotEmpty ? store.customers.first : null);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final amt = int.tryParse(_amount.text.replaceAll('.', '').trim()) ?? 0;
    if (amt < 1000 || _sel == null) {
      snack(context, 'Isi nominal minimal Rp1.000');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final c = _sel!;
    final now = DateTime.now();
    final today = _date.year == now.year && _date.month == now.month && _date.day == now.day;
    final when = today ? now : DateTime(_date.year, _date.month, _date.day, 12);
    setState(() => _busy = true);
    final res = await store.addTxn(c, amt, widget.channel, date: when);
    if (!mounted) return;
    if (res.error != null) {
      setState(() => _busy = false);
      snack(context, res.error!);
      return;
    }
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('+${res.points} poin untuk ${c.name}')));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mode Kasir'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.fixed == null) ...[
              DropdownButtonFormField<Customer>(
                initialValue: _sel,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Pelanggan', border: OutlineInputBorder()),
                items: store.customers
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.name} (${c.memberId})', overflow: TextOverflow.ellipsis),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _sel = v),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.fixed!.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total belanja (Rp)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [50000, 100000, 200000]
                  .map((v) => ActionChip(label: Text(rp(v)), onPressed: () => setState(() => _amount.text = '$v')))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 18),
                label: Text('Tanggal: ${fmtDate(_date)}'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Simulasi kasir di gerai: total belanja dicatat setelah pelanggan menunjukkan Kartu Member. 1 poin tiap Rp1.000, ditambah bonus sesuai jenjang. Pilih tanggal lampau untuk simulasi RFM.',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}
