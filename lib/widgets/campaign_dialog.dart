import 'package:flutter/material.dart';

import '../core/core.dart';

/// Menampilkan detail kampanye dan tombol klaim voucher.
/// Saat dibuka, kampanye otomatis dihitung sebagai "dilihat".
void showCampaignDialog(BuildContext context, Campaign camp, Customer me) {
  store.markViewed(camp, me);
  showDialog(
    context: context,
    builder: (ctx) => Observe((_) {
      final claimed = camp.claimedBy.contains(me.id);
      return AlertDialog(
        title: Text(camp.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pill(camp.type, typeColor(camp.type)),
            const SizedBox(height: 12),
            Text(camp.desc),
            if (camp.benefit.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(camp.benefit,
                  style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: (claimed || store.working)
                ? null
                : () async {
              final err = await store.claimCampaign(camp, me);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) snack(context, err ?? 'Voucher masuk ke "Voucher Saya"');
            },
            child: Text(claimed ? 'Sudah Diklaim' : 'Klaim Voucher'),
          ),
        ],
      );
    }),
  );
}
