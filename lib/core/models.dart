import 'package:flutter/material.dart';

import 'constants.dart';

// ============================================================
// MODEL DATA (dibaca dari tabel Supabase)
// ============================================================
DateTime _dt(dynamic v) => DateTime.parse(v as String).toLocal();
DateTime? _dtn(dynamic v) => v == null ? null : _dt(v);
int _int(dynamic v) => (v as num).toInt();

/// Teks manfaat voucher/kampanye, mis. "Diskon 20% (maks. Rp30.000, min. belanja Rp50.000)".
String benefitText(String type, int value, int minSpend, int maxDiscount) {
  if (value <= 0) return '';
  final base = type == 'percent' ? 'Diskon $value%' : 'Potongan ${rp(value)}';
  final extra = <String>[];
  if (type == 'percent' && maxDiscount > 0) extra.add('maks. ${rp(maxDiscount)}');
  if (minSpend > 0) extra.add('min. belanja ${rp(minSpend)}');
  return extra.isEmpty ? base : '$base (${extra.join(', ')})';
}

class Customer {
  final String id;
  String name;
  String phone;
  String email;
  String memberId;
  int points;
  int lifetime;
  DateTime joinDate;
  DateTime? birthDate;
  String gender; // '' = tidak disebut
  String city;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.memberId,
    this.points = 0,
    this.lifetime = 0,
    required this.joinDate,
    this.birthDate,
    this.gender = '',
    this.city = '',
  });

  factory Customer.fromRow(Map<String, dynamic> j) => Customer(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: (j['phone'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    memberId: j['member_id'] as String,
    points: _int(j['points']),
    lifetime: _int(j['lifetime']),
    joinDate: _dt(j['join_date']),
    birthDate: _dtn(j['birth_date']),
    gender: (j['gender'] as String?) ?? '',
    city: (j['city'] as String?) ?? '',
  );
}

class Txn {
  final String id;
  final String customerId;
  final DateTime date;
  final int amount;
  final int points;
  final String channel;
  Txn({
    required this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    required this.points,
    required this.channel,
  });

  factory Txn.fromRow(Map<String, dynamic> j) => Txn(
    id: j['id'] as String,
    customerId: j['customer_id'] as String,
    date: _dt(j['date']),
    amount: _int(j['amount']),
    points: _int(j['points']),
    channel: j['channel'] as String,
  );
}

class Voucher {
  final String id;
  final String customerId;
  final String title;
  final String note;
  final String code;
  final DateTime date;
  final bool used;
  final DateTime? expiredAt;
  final String discountType; // 'amount' atau 'percent'
  final int discountValue;
  final int minSpend;
  final int maxDiscount;
  Voucher({
    required this.id,
    required this.customerId,
    required this.title,
    required this.note,
    required this.code,
    required this.date,
    this.used = false,
    this.expiredAt,
    this.discountType = 'amount',
    this.discountValue = 0,
    this.minSpend = 0,
    this.maxDiscount = 0,
  });

  bool get expired => expiredAt != null && DateTime.now().isAfter(expiredAt!);

  String get benefit => benefitText(discountType, discountValue, minSpend, maxDiscount);

  /// Potongan untuk total belanja [subtotal]. Sama dengan hitungan di database.
  int discountFor(int subtotal) {
    if (discountValue <= 0 || subtotal < minSpend) return 0;
    var d = discountType == 'percent' ? (subtotal * discountValue / 100).floor() : discountValue;
    if (discountType == 'percent' && maxDiscount > 0 && d > maxDiscount) d = maxDiscount;
    if (d > subtotal - 1000) d = subtotal - 1000;
    return d < 0 ? 0 : d;
  }

  factory Voucher.fromRow(Map<String, dynamic> j) => Voucher(
    id: j['id'] as String,
    customerId: j['customer_id'] as String,
    title: j['title'] as String,
    note: (j['note'] as String?) ?? '',
    code: j['code'] as String,
    date: _dt(j['date']),
    used: j['used'] as bool,
    expiredAt: _dtn(j['expired_at']),
    discountType: (j['discount_type'] as String?) ?? 'amount',
    discountValue: j['discount_value'] == null ? 0 : _int(j['discount_value']),
    minSpend: j['min_spend'] == null ? 0 : _int(j['min_spend']),
    maxDiscount: j['max_discount'] == null ? 0 : _int(j['max_discount']),
  );
}

class PointLog {
  final String customerId;
  final String title;
  final int delta;
  final DateTime date;
  PointLog(this.customerId, this.title, this.delta, this.date);

  factory PointLog.fromRow(Map<String, dynamic> j) =>
      PointLog(j['customer_id'] as String, j['title'] as String, _int(j['delta']), _dt(j['date']));
}

class ComplaintLog {
  final DateTime date;
  final String text;
  ComplaintLog(this.date, this.text);

  factory ComplaintLog.fromRow(Map<String, dynamic> j) => ComplaintLog(_dt(j['date']), j['message'] as String);
}

class Complaint {
  final String id;
  final String customerId;
  final String category;
  final String description;
  final DateTime createdAt;
  final String status;
  final bool priority; // keluhan dari member Platinum
  final int? rating; // kepuasan 1-5 setelah selesai
  final List<ComplaintLog> logs;
  Complaint({
    required this.id,
    required this.customerId,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.priority,
    required this.rating,
    required this.logs,
  });

  factory Complaint.fromRow(Map<String, dynamic> j) {
    final logs = ((j['complaint_logs'] as List?) ?? [])
        .map((e) => ComplaintLog.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return Complaint(
      id: j['id'] as String,
      customerId: j['customer_id'] as String,
      category: j['category'] as String,
      description: j['description'] as String,
      createdAt: _dt(j['created_at']),
      status: j['status'] as String,
      priority: (j['priority'] as bool?) ?? false,
      rating: j['rating'] == null ? null : _int(j['rating']),
      logs: logs,
    );
  }
}

class Campaign {
  final String id;
  final String title;
  final String desc;
  final String type;
  final String target;
  final DateTime createdAt;
  final List<String> viewedBy;
  final List<String> claimedBy;
  final String discountType;
  final int discountValue;
  final int minSpend;
  final int maxDiscount;
  Campaign({
    required this.id,
    required this.title,
    required this.desc,
    required this.type,
    required this.target,
    required this.createdAt,
    required this.viewedBy,
    required this.claimedBy,
    this.discountType = 'amount',
    this.discountValue = 0,
    this.minSpend = 0,
    this.maxDiscount = 0,
  });

  String get benefit => benefitText(discountType, discountValue, minSpend, maxDiscount);

  factory Campaign.fromRow(Map<String, dynamic> j) {
    List<String> ids(String key) => ((j[key] as List?) ?? [])
        .map((e) => (e as Map)['customer_id'].toString())
        .toList();
    return Campaign(
      id: j['id'] as String,
      title: j['title'] as String,
      desc: j['description'] as String,
      type: j['type'] as String,
      target: j['target'] as String,
      createdAt: _dt(j['created_at']),
      viewedBy: ids('campaign_views'),
      claimedBy: ids('campaign_claims'),
      discountType: (j['discount_type'] as String?) ?? 'amount',
      discountValue: j['discount_value'] == null ? 0 : _int(j['discount_value']),
      minSpend: j['min_spend'] == null ? 0 : _int(j['min_spend']),
      maxDiscount: j['max_discount'] == null ? 0 : _int(j['max_discount']),
    );
  }
}

class Rfm {
  final int recency; // hari sejak transaksi terakhir (-1 = belum pernah)
  final int frequency;
  final int monetary;
  final int r;
  final int f;
  final int m;
  final String segment;
  final String value;
  const Rfm({
    required this.recency,
    required this.frequency,
    required this.monetary,
    required this.r,
    required this.f,
    required this.m,
    required this.segment,
    required this.value,
  });

  factory Rfm.fromRow(Map<String, dynamic> j) => Rfm(
    recency: _int(j['recency']),
    frequency: _int(j['frequency']),
    monetary: _int(j['monetary']),
    r: _int(j['r']),
    f: _int(j['f']),
    m: _int(j['m']),
    segment: j['segment'] as String,
    value: j['value'] as String,
  );
}

class Reward {
  final String id;
  final String title;
  final String desc;
  final int cost;
  final int minTier;
  const Reward(this.id, this.title, this.desc, this.cost, this.minTier);

  factory Reward.fromRow(Map<String, dynamic> j) => Reward(
    j['id'] as String,
    j['title'] as String,
    (j['description'] as String?) ?? '',
    _int(j['cost']),
    _int(j['min_tier']),
  );

  IconData get icon => _rewardIcons[id] ?? Icons.card_giftcard;
}

const Map<String, IconData> _rewardIcons = {
  'KTG': Icons.fastfood,
  'MNM': Icons.local_drink,
  'MCF': Icons.icecream,
  'DSK': Icons.sell,
  'BMC': Icons.lunch_dining,
  'KLG': Icons.groups,
};

// ---------- menu & pesanan ----------
class FoodItem {
  final String id;
  final String name;
  final String desc;
  final String category;
  final int price;
  const FoodItem(this.id, this.name, this.desc, this.category, this.price);

  factory FoodItem.fromRow(Map<String, dynamic> j) => FoodItem(
    j['id'] as String,
    j['name'] as String,
    (j['description'] as String?) ?? '',
    j['category'] as String,
    _int(j['price']),
  );

  IconData get icon => menuCategoryIcon(category);
}

IconData menuCategoryIcon(String c) {
  switch (c) {
    case 'Burger':
      return Icons.lunch_dining;
    case 'Ayam':
      return Icons.restaurant;
    case 'Paket':
      return Icons.takeout_dining;
    case 'Camilan':
      return Icons.bakery_dining;
    case 'Minuman':
      return Icons.local_drink;
    case 'Dessert':
      return Icons.icecream;
    default:
      return Icons.fastfood;
  }
}

class OrderResult {
  final int subtotal;
  final int discount;
  final int total;
  final int points;
  const OrderResult(this.subtotal, this.discount, this.total, this.points);

  factory OrderResult.fromJson(Map<String, dynamic> j) =>
      OrderResult(_int(j['subtotal']), _int(j['discount']), _int(j['total']), _int(j['points']));
}
