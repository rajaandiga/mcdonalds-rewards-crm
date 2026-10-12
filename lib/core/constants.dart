import 'package:flutter/material.dart';

// ============================================================
// WARNA, FORMAT, KONSTANTA
// ============================================================
class AppColors {
  static const red = Color(0xFFDA291C);
  static const yellow = Color(0xFFFFC72C);
  static const dark = Color(0xFF27251F);
  static const bg = Color(0xFFF7F5F0);
  static const green = Color(0xFF1E7A4C);
  static const orange = Color(0xFFE67E22);
}

const List<String> bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String fmtDate(DateTime d) => '${d.day} ${bulan[d.month - 1]} ${d.year}';

String rp(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

// ---------- jenjang membership ----------
class Tier {
  final String name;
  final int minPoints;
  final Color color;
  final IconData icon;
  final double bonus;
  final List<String> benefits;
  const Tier(this.name, this.minPoints, this.color, this.icon, this.bonus, this.benefits);
}

const List<Tier> tiers = [
  Tier('Reguler', 0, Color(0xFF8D8D8D), Icons.person_outline, 0.0, [
    'Kumpulkan 1 poin tiap Rp1.000',
    'Akses promo pelanggan baru',
  ]),
  Tier('Silver', 500, Color(0xFF9AA5B1), Icons.workspace_premium_outlined, 0.10, [
    'Bonus poin 10%',
    'Voucher ulang tahun',
    'Akses promo member',
  ]),
  Tier('Gold', 1500, Color(0xFFE0A100), Icons.workspace_premium, 0.25, [
    'Bonus poin 25%',
    'Voucher bulanan',
    'Promo personal eksklusif',
  ]),
  Tier('Platinum', 3000, Color(0xFF5B4B8A), Icons.diamond_outlined, 0.50, [
    'Bonus poin 50%',
    'Voucher prioritas',
    'Penanganan keluhan prioritas',
  ]),
];

int tierIndexOf(int lifetime) => tiers.lastIndexWhere((t) => lifetime >= t.minPoints);
Tier tierFor(int lifetime) => tiers[tierIndexOf(lifetime)];

Tier? nextTier(int lifetime) {
  for (final t in tiers) {
    if (t.minPoints > lifetime) return t;
  }
  return null;
}

// ---------- segmentasi ----------
const List<String> segmentNames = ['Champions', 'Loyal', 'Potensial', 'Baru', 'Berisiko', 'Tidak Aktif'];

const Map<String, Color> segColors = {
  'Champions': Color(0xFF5B4B8A),
  'Loyal': AppColors.green,
  'Potensial': Color(0xFF2E86C1),
  'Baru': AppColors.orange,
  'Berisiko': AppColors.red,
  'Tidak Aktif': Color(0xFF7F8C8D),
};

const Map<String, String> segStrategy = {
  'Champions': 'Pertahankan: reward eksklusif, akses awal menu baru, penanganan prioritas.',
  'Loyal': 'Tingkatkan: promo poin ganda, dorong naik jenjang, tawarkan paket.',
  'Potensial': 'Dorong frekuensi: voucher kunjungan ulang, promo jam tertentu.',
  'Baru': 'Onboarding: diskon pesanan pertama, ajak memakai aplikasi.',
  'Berisiko': 'Win-back: voucher "kami kangen kamu", survei alasan berhenti.',
  'Tidak Aktif': 'Reaktivasi: penawaran besar terbatas waktu, kampanye pengingat.',
};

// ---------- target kampanye ----------
// Nilai yang disimpan: 'Semua', nama segmen RFM (mis. 'Loyal'), atau 'Jenjang Silver'
final List<String> campaignTargets = [
  'Semua',
  ...segmentNames,
  ...tiers.map((t) => 'Jenjang ${t.name}'),
];

String targetLabel(String t) {
  if (t == 'Semua') return 'Semua pelanggan';
  if (t.startsWith('Jenjang ')) return t;
  return 'Segmen $t';
}

// ---------- kampanye & keluhan ----------
const List<String> campaignTypes = [
  'Promo Pelanggan Baru',
  'Promo Pelanggan Loyal',
  'Win-back',
  'Kampanye Umum',
];

const List<String> complaintCategories = [
  'Produk',
  'Layanan Gerai',
  'Pesanan / Delivery',
  'Aplikasi & Poin',
  'Lainnya',
];

const List<String> complaintStatuses = ['Baru', 'Diproses', 'Selesai'];

Color typeColor(String t) {
  switch (t) {
    case 'Promo Pelanggan Baru':
      return AppColors.red;
    case 'Promo Pelanggan Loyal':
      return AppColors.green;
    case 'Win-back':
      return const Color(0xFF5B4B8A);
    default:
      return const Color(0xFF2E86C1);
  }
}

Color statusColor(String s) =>
    s == 'Selesai' ? AppColors.green : (s == 'Diproses' ? AppColors.orange : AppColors.red);
