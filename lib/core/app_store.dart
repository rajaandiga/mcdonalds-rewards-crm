import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';
import 'models.dart';

/// Satu-satunya instance store yang dipakai seluruh aplikasi.
final AppStore store = AppStore();

// ============================================================
// STORE: DATA DARI SUPABASE
// Semua data disimpan di database Supabase. Aturan bisnis yang
// sensitif (poin, reward, voucher, keluhan, klaim kampanye, RFM)
// dijalankan di database lewat fungsi SQL, sehingga pelanggan
// tidak bisa mengubah poinnya sendiri. Aplikasi hanya memanggil
// fungsi itu lalu memuat ulang data.
// ============================================================
class AppStore extends ChangeNotifier {
  SupabaseClient get _db => Supabase.instance.client;

  bool loaded = false;
  bool working = false; // true saat ada proses ke server
  String? currentId; // id pengguna yang sedang masuk
  bool isAdmin = false;

  List<Customer> customers = [];
  List<Txn> txns = [];
  List<Voucher> vouchers = [];
  List<PointLog> logs = [];
  List<Complaint> complaints = [];
  List<Campaign> campaigns = [];
  List<Reward> rewards = [];
  List<FoodItem> menu = [];
  Map<String, Rfm> rfm = {};

  FoodItem? menuById(String id) {
    for (final m in menu) {
      if (m.id == id) return m;
    }
    return null;
  }

  Customer? customerById(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Customer? get me {
    final id = currentId;
    if (id == null || isAdmin) return null;
    return customerById(id);
  }

  // ---------- pemuatan data ----------
  Future<List<Map<String, dynamic>>> _rows(Future<dynamic> q) async {
    final r = await q;
    return (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _clear() {
    currentId = null;
    isAdmin = false;
    customers = [];
    txns = [];
    vouchers = [];
    logs = [];
    complaints = [];
    campaigns = [];
    rewards = [];
    menu = [];
    rfm = {};
  }

  /// Memuat semua data yang boleh dilihat pengguna ini (dibatasi aturan
  /// keamanan di database: pelanggan hanya melihat datanya sendiri).
  Future<void> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      _clear();
      notifyListeners();
      return;
    }
    final prof = await _db.from('profiles').select('role').eq('id', user.id).maybeSingle();
    if (prof == null) {
      await _db.auth.signOut();
      _clear();
      notifyListeners();
      throw 'Profil akun tidak ditemukan. Hubungi admin.';
    }
    final admin = prof['role'] == 'admin';
    if (!admin) await _db.rpc('refresh_my_benefits');

    final res = await Future.wait([
      _rows(_db.from('profiles').select().eq('role', 'customer')),
      _rows(_db.from('txns').select().order('date')),
      _rows(_db.from('vouchers').select()),
      _rows(_db.from('point_logs').select()),
      _rows(_db.from('complaints').select('*, complaint_logs(*)')),
      _rows(_db.from('campaigns').select('*, campaign_views(customer_id), campaign_claims(customer_id)')),
      _rows(_db.from('rewards').select().order('cost', ascending: true)),
      _rows(_db.rpc('compute_rfm')),
      _rows(_db.from('menu_items').select().eq('active', true).order('sort', ascending: true)),
    ]);

    currentId = user.id;
    isAdmin = admin;
    customers = res[0].map(Customer.fromRow).toList();
    txns = res[1].map(Txn.fromRow).toList();
    vouchers = res[2].map(Voucher.fromRow).toList();
    logs = res[3].map(PointLog.fromRow).toList();
    complaints = res[4].map(Complaint.fromRow).toList();
    campaigns = res[5].map(Campaign.fromRow).toList();
    rewards = res[6].map(Reward.fromRow).toList();
    rfm = {for (final r in res[7]) r['customer_id'].toString(): Rfm.fromRow(r)};
    menu = res[8].map(FoodItem.fromRow).toList();
    notifyListeners();
  }

  /// Dipanggil saat aplikasi dibuka: memulihkan sesi login bila masih ada.
  Future<void> load() async {
    try {
      if (_db.auth.currentSession != null) await _load();
    } catch (_) {
      // Gagal memuat (mis. tidak ada internet): biarkan pengguna menekan
      // tombol muat ulang setelah masuk.
    }
    loaded = true;
    notifyListeners();
  }

  /// Muat ulang data. Mengembalikan pesan error bila gagal.
  Future<String?> refresh() async {
    try {
      await _load();
      return null;
    } catch (e) {
      return _err(e);
    }
  }

  // ---------- util ----------
  String _err(Object e) {
    if (e is String) return e;
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Email atau kata sandi salah';
      if (m.contains('already registered') || m.contains('already been registered')) {
        return 'Email sudah terdaftar';
      }
      if (m.contains('not confirmed')) return 'Email belum dikonfirmasi. Cek kotak masuk emailmu.';
      if (m.contains('password')) return 'Kata sandi minimal 6 karakter';
      return e.message;
    }
    if (e is PostgrestException) {
      if (e.code == '23505') return 'No. HP atau email sudah dipakai akun lain';
      return e.message;
    }
    return kDebugMode
        ? 'Kesalahan: $e'
        : 'Tidak dapat terhubung ke server. Periksa koneksi internetmu.';
  }

  /// Menjalankan satu proses ke server dengan penanda "working" dan
  /// menerjemahkan error menjadi pesan yang mudah dibaca.
  Future<String?> _run(Future<void> Function() job) async {
    if (working) return 'Masih memproses, tunggu sebentar';
    working = true;
    notifyListeners();
    try {
      await job();
      return null;
    } catch (e, st) {
      debugPrint('CRM ERROR: $e\n$st');
      return _err(e);
    } finally {
      working = false;
      notifyListeners();
    }
  }

  Future<void> _bg(Future<dynamic> f) async {
    try {
      await f;
    } catch (_) {}
  }

  String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------- RFM & segmentasi (dihitung di database) ----------
  Rfm rfmOf(Customer c) =>
      rfm[c.id] ??
          const Rfm(recency: -1, frequency: 0, monetary: 0, r: 0, f: 0, m: 0, segment: 'Baru', value: 'Rendah');

  // ---------- autentikasi ----------
  Future<String?> login(String email, String pw) => _run(() async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || pw.isEmpty) throw 'Email dan kata sandi wajib diisi';
    await _db.auth.signInWithPassword(email: e, password: pw);
    await _load();
  });

  Future<String?> register(String name, String phone, String email, String pw) => _run(() async {
    final n = name.trim();
    final p = phone.trim();
    final e = email.trim().toLowerCase();
    if (n.isEmpty || p.isEmpty || e.isEmpty || pw.isEmpty) throw 'Semua kolom wajib diisi';
    if (!e.contains('@')) throw 'Format email tidak valid';
    if (pw.length < 6) throw 'Kata sandi minimal 6 karakter';
    final free = await _db.rpc('phone_available', params: {'p_phone': p});
    if (free != true) throw 'No. HP sudah terdaftar';
    final res = await _db.auth.signUp(email: e, password: pw, data: {'name': n, 'phone': p});
    if (res.session == null) {
      throw 'Pendaftaran berhasil, tetapi email perlu dikonfirmasi dulu. Cek kotak masuk emailmu.';
    }
    await _load();
  });

  Future<void> logout() async {
    try {
      await _db.auth.signOut();
    } catch (_) {}
    _clear();
    notifyListeners();
  }

  // ---------- transaksi & poin ----------
  /// Admin mencatat transaksi. [date] boleh tanggal lampau (untuk simulasi RFM).
  Future<({int? points, String? error})> addTxn(Customer c, int amount, String channel,
      {DateTime? date}) async {
    int? pts;
    final err = await _run(() async {
      final r = await _db.rpc('add_txn', params: {
        'p_customer': c.id,
        'p_amount': amount,
        'p_channel': channel,
        'p_date': (date ?? DateTime.now()).toUtc().toIso8601String(),
      });
      pts = (r as num).toInt();
      await _load();
    });
    return (points: pts, error: err);
  }

  /// Pelanggan memesan lewat aplikasi. Harga, potongan voucher, dan poin
  /// dihitung di database (fungsi place_order). Pembayaran hanya simulasi.
  Future<({OrderResult? result, String? error})> placeOrder(
      Map<String, int> cart, {
        Voucher? voucher,
        String payment = 'QRIS',
      }) async {
    OrderResult? res;
    final err = await _run(() async {
      final r = await _db.rpc('place_order', params: {
        'p_items': cart.entries.map((e) => {'id': e.key, 'qty': e.value}).toList(),
        'p_voucher': voucher?.id,
        'p_payment': payment,
      });
      res = OrderResult.fromJson(Map<String, dynamic>.from(r as Map));
      await _load();
    });
    return (result: res, error: err);
  }

  Future<String?> redeem(Reward r) => _run(() async {
    await _db.rpc('redeem_reward', params: {'p_reward': r.id});
    await _load();
  });

  Future<String?> useVoucher(Voucher v) => _run(() async {
    await _db.rpc('use_voucher', params: {'p_voucher': v.id});
    await _load();
  });

  // ---------- keluhan ----------
  Future<String?> addComplaint(String category, String description) => _run(() async {
    await _db.rpc('add_complaint', params: {'p_category': category, 'p_description': description});
    await _load();
  });

  Future<String?> updateComplaint(Complaint q, String status, String note) => _run(() async {
    await _db.rpc('update_complaint', params: {'p_id': q.id, 'p_status': status, 'p_note': note});
    await _load();
  });

  Future<String?> rateComplaint(Complaint q, int rating) => _run(() async {
    await _db.rpc('rate_complaint', params: {'p_id': q.id, 'p_rating': rating});
    await _load();
  });

  // ---------- kampanye ----------
  /// Target kampanye: 'Semua', nama segmen RFM, atau 'Jenjang Silver'.
  bool targetMatches(String target, Customer c) {
    if (target == 'Semua') return true;
    if (target.startsWith('Jenjang ')) return tierFor(c.lifetime).name == target.substring(8);
    return rfmOf(c).segment == target;
  }

  List<Campaign> campaignsFor(Customer c) {
    final list = campaigns.where((k) => targetMatches(k.target, c)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int targetCount(Campaign k) => customers.where((c) => targetMatches(k.target, c)).length;

  Future<String?> addCampaign(
      String title,
      String desc,
      String type,
      String target, {
        String discountType = 'amount',
        int discountValue = 0,
        int minSpend = 0,
        int maxDiscount = 0,
      }) =>
      _run(() async {
        await _db.from('campaigns').insert({
          'title': title,
          'description': desc,
          'type': type,
          'target': target,
          'discount_type': discountType,
          'discount_value': discountValue,
          'min_spend': minSpend,
          'max_discount': maxDiscount,
        });
        await _load();
      });

  Future<String?> deleteCampaign(Campaign k) => _run(() async {
    await _db.from('campaigns').delete().eq('id', k.id);
    await _load();
  });

  /// Dicatat "dilihat" saat pelanggan membuka detail kampanye.
  void markViewed(Campaign k, Customer c) {
    if (k.viewedBy.contains(c.id)) return;
    k.viewedBy.add(c.id);
    unawaited(_bg(_db.rpc('mark_viewed', params: {'p_campaign': k.id})));
  }

  Future<String?> claimCampaign(Campaign k, Customer c) => _run(() async {
    await _db.rpc('claim_campaign', params: {'p_campaign': k.id});
    await _load();
  });

  // ---------- profil ----------
  Future<String?> updateProfile(
      Customer c, {
        required String name,
        required String phone,
        DateTime? birthDate,
        required String gender,
        required String city,
      }) =>
      _run(() async {
        final n = name.trim();
        final p = phone.trim();
        if (n.isEmpty || p.isEmpty) throw 'Nama dan No. HP wajib diisi';
        await _db.from('profiles').update({
          'name': n,
          'phone': p,
          'birth_date': birthDate == null ? null : _dateOnly(birthDate),
          'gender': gender,
          'city': city.trim(),
        }).eq('id', c.id);
        await _db.rpc('refresh_my_benefits');
        await _load();
      });
}