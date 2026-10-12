import 'dart:math';

import 'package:flutter/material.dart';

import 'main.dart';

// ============================================================
// GRAFIK DONUT SEGMENTASI (untuk Dashboard Admin)
// ============================================================
class SegmentDonut extends StatelessWidget {
  const SegmentDonut({super.key});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      for (final s in segmentNames) s: store.customers.where((c) => store.rfmOf(c).segment == s).length,
    };
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return Box(
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size(130, 130), painter: _DonutPainter(counts)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const Text('pelanggan', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: segmentNames.map((s) {
                final n = counts[s] ?? 0;
                final pct = total == 0 ? 0 : (n * 100 / total).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: segColors[s], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
                      Text('$n ($pct%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> counts;
  _DonutPainter(this.counts);

  @override
  void paint(Canvas canvas, Size size) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    final rect = (Offset.zero & size).deflate(11);
    double start = -pi / 2;
    counts.forEach((name, v) {
      if (v == 0) return;
      final sweep = 2 * pi * v / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..color = segColors[name] ?? Colors.grey;
      canvas.drawArc(rect, start, max(sweep - 0.04, 0.01), false, paint);
      start += sweep;
    });
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

// ============================================================
// GRAFIK PENJUALAN 6 BULAN TERAKHIR
// ============================================================
class MonthlyRevenueChart extends StatelessWidget {
  const MonthlyRevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final values = months.map((m) {
      return store.txns
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .fold<int>(0, (s, t) => s + t.amount);
    }).toList();
    final maxV = values.fold<int>(1, (a, b) => max(a, b));

    return Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final h = 90.0 * values[i] / maxV;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(values[i] == 0 ? '-' : '${(values[i] / 1000000).toStringAsFixed(1)}jt',
                            style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Container(
                          height: max(h, 3),
                          decoration: BoxDecoration(
                            color: i == 5 ? AppColors.red : AppColors.yellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_bulan[months[i].month - 1], style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROMO PERSONAL (untuk Beranda pelanggan)
// ============================================================
class PersonalPromoCard extends StatelessWidget {
  final Customer me;
  const PersonalPromoCard({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    final r = store.rfmOf(me);
    final next = nextTier(me.lifetime);
    String title;
    String text;
    IconData icon;

    switch (r.segment) {
      case 'Champions':
        title = 'Spesial untuk Pelanggan Terbaik';
        text = 'Kamu salah satu pelanggan paling setia. Akses awal menu baru dan reward eksklusif sudah menunggu.';
        icon = Icons.emoji_events;
        break;
      case 'Loyal':
        title = 'Tinggal Selangkah Lagi';
        text = 'Belanja dengan poin ganda di akhir pekan supaya jenjangmu cepat naik.';
        icon = Icons.trending_up;
        break;
      case 'Potensial':
        title = 'Yuk Mampir Lagi';
        text = 'Pakai voucher kunjungan ulang di jam makan siang untuk tambahan poin.';
        icon = Icons.schedule;
        break;
      case 'Berisiko':
        title = 'Kami Kangen Kamu';
        text = 'Sudah lama tidak mampir. Klaim voucher di tab Promo, berlaku untuk kunjungan berikutnya.';
        icon = Icons.favorite;
        break;
      case 'Tidak Aktif':
        title = 'Penawaran Kembali Datang';
        text = 'Ada penawaran terbatas untuk kamu. Cek tab Promo sebelum berakhir.';
        icon = Icons.notifications_active;
        break;
      default:
        title = 'Selamat Datang';
        text = 'Lakukan pesanan pertamamu dan nikmati diskon pelanggan baru.';
        icon = Icons.waving_hand;
    }

    final nudge = (next != null && next.minPoints - me.lifetime <= 300)
        ? '\nHanya ${next.minPoints - me.lifetime} poin lagi menuju ${next.name}.'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.yellow, Color(0xFFFFD966)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROMO PERSONAL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$text$nudge', style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN: LAPORAN
// ============================================================
class AdminReportPage extends StatelessWidget {
  const AdminReportPage({super.key});

  Widget _kpi(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    ),
  );

  Widget _cell(String t, {bool head = false, TextAlign align = TextAlign.center}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(t,
        textAlign: align,
        style: TextStyle(fontSize: 12, fontWeight: head ? FontWeight.w800 : FontWeight.w500)),
  );

  @override
  Widget build(BuildContext context) {
    return Observe((context) {
      final total = store.customers.length;
      final revenue = store.txns.fold<int>(0, (s, t) => s + t.amount);
      final aov = store.txns.isEmpty ? 0 : (revenue / store.txns.length).round();
      final repeat = store.customers.where((c) => store.rfmOf(c).frequency >= 2).length;
      final repeatRate = total == 0 ? 0 : (repeat * 100 / total).round();

      int targetSum = 0;
      int claimSum = 0;
      for (final k in store.campaigns) {
        targetSum += store.targetCount(k);
        claimSum += k.claimedBy.length;
      }
      final claimRate = targetSum == 0 ? 0 : (claimSum * 100 / targetSum).round();

      final done = store.complaints.where((q) => q.status == 'Selesai').length;
      final doneRate = store.complaints.isEmpty ? 0 : (done * 100 / store.complaints.length).round();

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: adminBar(context, 'Laporan CRM'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              _kpi('Rata-rata nilai pesanan', rp(aov)),
              const SizedBox(width: 10),
              _kpi('Pelanggan repeat order', '$repeatRate%'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _kpi('Klaim kampanye', '$claimRate%'),
              const SizedBox(width: 10),
              _kpi('Keluhan selesai', '$doneRate%'),
            ]),
            const SizedBox(height: 20),
            const SectionTitle('Penjualan 6 Bulan Terakhir'),
            const MonthlyRevenueChart(),
            const SizedBox(height: 20),
            const SectionTitle('Komposisi Segmen'),
            const SegmentDonut(),
            const SizedBox(height: 20),
            const SectionTitle('Ringkasan per Segmen'),
            Box(
              padding: const EdgeInsets.all(8),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(children: [
                    _cell('Segmen', head: true, align: TextAlign.left),
                    _cell('Jumlah', head: true),
                    _cell('Rata-rata transaksi', head: true),
                    _cell('Total belanja', head: true),
                  ]),
                  ...segmentNames.map((s) {
                    final list = store.customers.where((c) => store.rfmOf(c).segment == s).toList();
                    final freq = list.fold<int>(0, (a, c) => a + store.rfmOf(c).frequency);
                    final mon = list.fold<int>(0, (a, c) => a + store.rfmOf(c).monetary);
                    final avg = list.isEmpty ? '-' : (freq / list.length).toStringAsFixed(1);
                    return TableRow(children: [
                      _cell(s, align: TextAlign.left),
                      _cell('${list.length}'),
                      _cell(avg),
                      _cell(rp(mon)),
                    ]);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Keluhan per Kategori'),
            Box(
              child: Column(
                children: complaintCategories.map((cat) {
                  final all = store.complaints.where((q) => q.category == cat).length;
                  final open = store.complaints.where((q) => q.category == cat && q.status != 'Selesai').length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(cat, style: const TextStyle(fontSize: 13))),
                        Text('$all total • $open terbuka',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Engagement Kampanye'),
            ...store.campaigns.map((k) {
              final target = store.targetCount(k);
              final rate = target == 0 ? 0.0 : k.claimedBy.length / target;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Box(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: rate.clamp(0.0, 1.0),
                          minHeight: 8,
                          color: typeColor(k.type),
                          backgroundColor: Colors.black12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${k.claimedBy.length} klaim dari $target target • dilihat ${k.viewedBy.length}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}