import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../widgets/campaign_dialog.dart';

// ============================================================
// PROMO, REWARD, VOUCHER, RIWAYAT POIN
// ============================================================
class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          title: const Text('Promo & Reward', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            ObserveMe((context, me) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.stars, size: 16, color: AppColors.red),
                  const SizedBox(width: 4),
                  Text('${me.points} poin', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            )),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.red,
            indicatorColor: AppColors.red,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Untuk Kamu'),
              Tab(text: 'Tukar Poin'),
              Tab(text: 'Voucher Saya'),
              Tab(text: 'Riwayat Poin'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ForYouTab(), _RewardTab(), _VoucherTab(), _HistoryTab()],
        ),
      ),
    );
  }
}

class _ForYouTab extends StatelessWidget {
  const _ForYouTab();

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final list = store.campaignsFor(me);
      if (list.isEmpty) return const Center(child: Text('Belum ada promo untukmu'));
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final k = list[i];
          final claimed = k.claimedBy.contains(me.id);
          return InkWell(
            onTap: () => showCampaignDialog(context, k, me),
            borderRadius: BorderRadius.circular(16),
            child: Box(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeColor(k.type).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.local_offer, color: typeColor(k.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(k.type, typeColor(k.type)),
                        const SizedBox(height: 4),
                        Text(k.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(k.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(claimed ? Icons.check_circle : Icons.chevron_right,
                      color: claimed ? AppColors.green : Colors.black38),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _RewardTab extends StatelessWidget {
  const _RewardTab();

  Future<void> _confirm(BuildContext context, Customer me, Reward r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tukar poin?'),
        content: Text('${r.title}\nBiaya ${r.cost} poin. Sisa poin kamu menjadi ${me.points - r.cost}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await store.redeem(r);
    if (!context.mounted) return;
    snack(context, err ?? 'Berhasil! Voucher masuk ke "Voucher Saya"');
  }

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final myTier = tierIndexOf(me.lifetime);
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: store.rewards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final r = store.rewards[i];
          final locked = myTier < r.minTier;
          final enough = me.points >= r.cost;
          return Box(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.red.withValues(alpha: 0.10),
                  child: Icon(r.icon, color: AppColors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(r.desc, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('${r.cost} poin',
                              style: const TextStyle(
                                  color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 13)),
                          if (r.minTier > 0) ...[
                            const SizedBox(width: 8),
                            Pill('Khusus ${tiers[r.minTier].name}', AppColors.yellow, fg: AppColors.dark),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: (!locked && enough) ? () => _confirm(context, me, r) : null,
                  child: Text(locked ? 'Terkunci' : (enough ? 'Tukar' : 'Kurang')),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _VoucherTab extends StatelessWidget {
  const _VoucherTab();

  void _use(BuildContext context, Voucher v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(v.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tunjukkan kode ini ke kasir.\nUntuk pesan lewat aplikasi, pilih voucher di halaman checkout (tab Pesan).',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: Text(v.code,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              final err = await store.useVoucher(v);
              if (ctx.mounted) Navigator.pop(ctx);
              if (err != null && context.mounted) snack(context, err);
            },
            child: const Text('Tandai Terpakai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final list = store.vouchers.where((v) => v.customerId == me.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (list.isEmpty) return const Center(child: Text('Belum ada voucher'));
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final v = list[i];
          return Opacity(
            opacity: (v.used || v.expired) ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.yellow, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number, color: AppColors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        if (v.benefit.isNotEmpty)
                          Text(v.benefit,
                              style: const TextStyle(
                                  color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 12)),
                        Text(v.note, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Kode: ${v.code}${v.expiredAt == null ? '' : ' • s/d ${fmtDate(v.expiredAt!)}'}',
                            style: const TextStyle(color: Colors.black45, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  (v.used || v.expired)
                      ? Text(v.used ? 'Terpakai' : 'Kedaluwarsa',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54))
                      : FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                    onPressed: () => _use(context, v),
                    child: const Text('Gunakan'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final list = store.logs.where((l) => l.customerId == me.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (list.isEmpty) return const Center(child: Text('Belum ada riwayat poin'));
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final h = list[i];
          final plus = h.delta >= 0;
          return Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(fmtDate(h.date), style: const TextStyle(color: Colors.black45, fontSize: 11)),
                    ],
                  ),
                ),
                Text('${plus ? '+' : ''}${h.delta}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: plus ? AppColors.green : AppColors.red)),
              ],
            ),
          );
        },
      );
    });
  }
}
