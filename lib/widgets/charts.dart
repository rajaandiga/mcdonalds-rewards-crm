import 'dart:math';

import 'package:flutter/material.dart';

import '../core/core.dart';

// ============================================================
// GRAFIK DONAT KOMPOSISI SEGMEN
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
    final rect = (Offset.zero & size).deflate(11);
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..color = Colors.black12,
      );
      return;
    }
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
      child: SizedBox(
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
                    Text(bulan[months[i].month - 1], style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
