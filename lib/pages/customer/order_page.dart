import 'package:flutter/material.dart';

import '../../core/core.dart';

// ============================================================
// PESAN: MENU, KERANJANG, CHECKOUT
// Harga, potongan voucher, dan poin dihitung ulang di database
// (fungsi place_order). Angka di layar ini hanya perkiraan.
// Pembayaran hanya simulasi.
// ============================================================

class _Cart extends ChangeNotifier {
  final Map<String, int> items = {};

  int qtyOf(String id) => items[id] ?? 0;

  void add(String id) {
    if (qtyOf(id) >= 20) return;
    items[id] = qtyOf(id) + 1;
    notifyListeners();
  }

  void remove(String id) {
    final q = qtyOf(id);
    if (q <= 1) {
      items.remove(id);
    } else {
      items[id] = q - 1;
    }
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }

  int get count => items.values.fold(0, (a, b) => a + b);

  int get subtotal {
    var s = 0;
    for (final e in items.entries) {
      final m = store.menuById(e.key);
      if (m != null) s += m.price * e.value;
    }
    return s;
  }
}

final _Cart _cart = _Cart();

// ------------------------------------------------------------
// Halaman menu
// ------------------------------------------------------------
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  String _cat = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Observe((context) {
      final cats = ['Semua', ...{for (final m in store.menu) m.category}];
      final list = store.menu.where((m) => _cat == 'Semua' || m.category == _cat).toList();

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          title: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  return ChoiceChip(
                    label: Text(c),
                    selected: _cat == c,
                    selectedColor: AppColors.yellow,
                    onSelected: (_) => setState(() => _cat = c),
                  );
                },
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Menu belum tersedia'))
                  : ListenableBuilder(
                      listenable: _cart,
                      builder: (_, __) => ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _MenuTile(list[i]),
                      ),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _cart,
          builder: (context, _) {
            if (_cart.count == 0) return const SizedBox.shrink();
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _CheckoutPage()),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined),
                      const SizedBox(width: 10),
                      Text('${_cart.count} item', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(rp(_cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _MenuTile extends StatelessWidget {
  final FoodItem m;
  const _MenuTile(this.m);

  @override
  Widget build(BuildContext context) {
    final q = _cart.qtyOf(m.id);
    return Box(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.yellow.withValues(alpha: 0.25),
            child: Icon(m.icon, color: AppColors.red, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(m.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 6),
                Text(rp(m.price),
                    style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          q == 0
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () => _cart.add(m.id),
                  child: const Text('Tambah'),
                )
              : _Stepper(qty: q, onAdd: () => _cart.add(m.id), onRemove: () => _cart.remove(m.id)),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _Stepper({required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 28,
          child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        IconButton.filled(
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Checkout
// ------------------------------------------------------------
class _CheckoutPage extends StatefulWidget {
  const _CheckoutPage();

  @override
  State<_CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutPage> {
  Voucher? _voucher;
  String _pay = 'QRIS';
  bool _busy = false;

  static const _payments = ['QRIS', 'E-Wallet', 'Kartu Debit'];

  Future<void> _checkout(Voucher? applied) async {
    if (_busy || _cart.count == 0) return;
    setState(() => _busy = true);
    final res = await store.placeOrder(
      Map<String, int>.from(_cart.items),
      voucher: applied,
      payment: _pay,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.error != null || res.result == null) {
      snack(context, res.error ?? 'Pesanan gagal diproses');
      return;
    }
    final r = res.result!;
    _cart.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.green, size: 48),
        title: const Text('Pesanan berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _line('Subtotal', rp(r.subtotal)),
            if (r.discount > 0) _line('Potongan voucher', '-${rp(r.discount)}', color: AppColors.green),
            const Divider(),
            _line('Total bayar', rp(r.total), bold: true),
            const SizedBox(height: 10),
            Text('+${r.points} poin masuk ke akunmu',
                style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Pembayaran ini hanya simulasi.',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _line(String a, String b, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      return ListenableBuilder(
        listenable: _cart,
        builder: (context, _) {
          final subtotal = _cart.subtotal;
          final usable = store.vouchers
              .where((v) => v.customerId == me.id && !v.used && !v.expired && v.discountValue > 0)
              .toList()
            ..sort((a, b) => b.discountFor(subtotal).compareTo(a.discountFor(subtotal)));

          // Voucher hanya berlaku bila belanja memenuhi syarat minimal
          final applied = (_voucher != null && subtotal >= _voucher!.minSpend) ? _voucher : null;
          final disc = applied?.discountFor(subtotal) ?? 0;
          final total = subtotal - disc;
          final estPts = (total / 1000 * (1 + tierFor(me.lifetime).bonus)).round();

          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.bg,
              surfaceTintColor: Colors.transparent,
              title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            body: _cart.count == 0
                ? const Center(child: Text('Keranjang kosong'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SectionTitle('Pesananmu'),
                      Box(
                        child: Column(
                          children: [
                            for (final e in _cart.items.entries)
                              if (store.menuById(e.key) != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(store.menuById(e.key)!.name,
                                                style: const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(rp(store.menuById(e.key)!.price * e.value),
                                                style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      _Stepper(
                                        qty: e.value,
                                        onAdd: () => _cart.add(e.key),
                                        onRemove: () => _cart.remove(e.key),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SectionTitle('Voucher'),
                      if (usable.isEmpty)
                        const Box(
                          child: Text('Kamu belum punya voucher yang bisa dipakai. Tukar poin di tab Promo.',
                              style: TextStyle(color: Colors.black54)),
                        )
                      else
                        for (final v in usable)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _VoucherChoice(
                              v: v,
                              subtotal: subtotal,
                              selected: _voucher?.id == v.id,
                              onTap: () => setState(() => _voucher = _voucher?.id == v.id ? null : v),
                            ),
                          ),
                      const SizedBox(height: 8),
                      const SectionTitle('Pembayaran (simulasi)'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final p in _payments)
                            ChoiceChip(
                              label: Text(p),
                              selected: _pay == p,
                              selectedColor: AppColors.yellow,
                              onSelected: (_) => setState(() => _pay = p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Box(
                        child: Column(
                          children: [
                            _line('Subtotal', rp(subtotal)),
                            if (disc > 0) _line('Potongan voucher', '-${rp(disc)}', color: AppColors.green),
                            const Divider(),
                            _line('Total bayar', rp(total), bold: true),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text('Perkiraan +$estPts poin',
                                  style: const TextStyle(color: AppColors.red, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: _cart.count == 0
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _busy ? null : () => _checkout(applied),
                        child: Text(_busy ? 'Memproses...' : 'Bayar ${rp(total)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ),
          );
        },
      );
    });
  }
}

class _VoucherChoice extends StatelessWidget {
  final Voucher v;
  final int subtotal;
  final bool selected;
  final VoidCallback onTap;
  const _VoucherChoice({required this.v, required this.subtotal, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ok = subtotal >= v.minSpend;
    final save = v.discountFor(subtotal);
    return Opacity(
      opacity: ok ? 1 : 0.5,
      child: InkWell(
        onTap: ok ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.red : AppColors.yellow, width: selected ? 2 : 1.2),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.check_circle : Icons.confirmation_number_outlined,
                  color: selected ? AppColors.red : Colors.black45),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(v.benefit, style: const TextStyle(color: AppColors.green, fontSize: 12)),
                    if (!ok)
                      Text('Belanja minimal ${rp(v.minSpend)}',
                          style: const TextStyle(color: AppColors.red, fontSize: 11)),
                  ],
                ),
              ),
              if (ok && save > 0)
                Text('-${rp(save)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.green)),
            ],
          ),
        ),
      ),
    );
  }
}
