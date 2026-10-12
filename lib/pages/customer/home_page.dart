import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../widgets/campaign_dialog.dart';
import '../../widgets/personal_promo_card.dart';
import 'complaint_page.dart';

// ============================================================
// BERANDA PELANGGAN
// ============================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onGoTo});
  final void Function(int) onGoTo;

  @override
  Widget build(BuildContext context) {
    return ObserveMe((context, me) {
      final myTxns = store.txns.where((t) => t.customerId == me.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final promos = store.campaignsFor(me);
      final curTier = tierFor(me.lifetime);

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeHeader(me: me),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickAction(Icons.shopping_bag_outlined, 'Pesan', () => onGoTo(1)),
                  _QuickAction(Icons.card_membership, 'Kartu', () => onGoTo(3)),
                  _QuickAction(Icons.confirmation_number_outlined, 'Voucher', () => onGoTo(2)),
                  _QuickAction(
                    Icons.support_agent,
                    'Keluhan',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PersonalPromoCard(me: me),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PromoBanner(onTap: () => onGoTo(1)),
            ),
            const SizedBox(height: 24),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SectionTitle('Promo untuk Kamu')),
            if (promos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Belum ada promo untukmu saat ini.', style: TextStyle(color: Colors.black54)),
              )
            else
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: promos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _PromoCard(
                    promos[i],
                    claimed: promos[i].claimedBy.contains(me.id),
                    onTap: () => showCampaignDialog(context, promos[i], me),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Transaksi Terakhir'),
                  if (myTxns.isEmpty)
                    const Text('Belum ada transaksi. Poin masuk otomatis setelah kamu memesan lewat aplikasi, atau saat kasir mencatat pembelianmu di gerai.',
                        style: TextStyle(color: Colors.black54))
                  else
                    ...myTxns.take(3).map(
                          (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Box(
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long, color: AppColors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rp(t.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                                    Text('${fmtDate(t.date)} • ${t.channel}',
                                        style: const TextStyle(color: Colors.black45, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text('+${t.points} poin',
                                  style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const SectionTitle('Jenjang Membership'),
                  ...tiers.map((t) => _TierTile(t, current: t.name == curTier.name)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _HomeHeader extends StatelessWidget {
  final Customer me;
  const _HomeHeader({required this.me});

  @override
  Widget build(BuildContext context) {
    final tier = tierFor(me.lifetime);
    final next = nextTier(me.lifetime);
    final progress = next == null
        ? 1.0
        : (me.lifetime - tier.minPoints) / (next.minPoints - tier.minPoints);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.red, Color(0xFFB51D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Halo,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(me.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: store.refresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tier.icon, color: tier.color),
                    const SizedBox(width: 8),
                    Text('Member ${tier.name}',
                        style: TextStyle(color: tier.color, fontWeight: FontWeight.w800, fontSize: 16)),
                    const Spacer(),
                    Text(me.memberId, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${me.points}',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.dark)),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('poin', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.black12,
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  next == null
                      ? 'Kamu sudah di jenjang tertinggi'
                      : '${next.minPoints - me.lifetime} poin lagi menuju ${next.name}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
              ),
              child: Icon(icon, color: AppColors.red),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Campaign campaign;
  final bool claimed;
  final VoidCallback onTap;
  const _PromoCard(this.campaign, {required this.claimed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: typeColor(campaign.type), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pill(campaign.type, AppColors.yellow, fg: AppColors.dark),
                const Spacer(),
                if (claimed) const Icon(Icons.check_circle, color: Colors.white, size: 18),
              ],
            ),
            const Spacer(),
            Text(campaign.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(campaign.desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final Tier tier;
  final bool current;
  const _TierTile(this.tier, {required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: current ? AppColors.yellow : Colors.transparent, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: tier.color.withValues(alpha: 0.15),
            child: Icon(tier.icon, color: tier.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tier.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 8),
                    if (current) const Pill('Jenjang kamu', AppColors.yellow, fg: AppColors.dark),
                    const Spacer(),
                    Text('${tier.minPoints}+ poin', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ...tier.benefits.map(
                      (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• $b', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
