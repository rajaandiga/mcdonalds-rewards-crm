// ============================================================
// KONFIGURASI SUPABASE
// Isi dua nilai ini dari: Supabase > Project Settings > API
//  - Project URL
//  - anon / publishable key (aman ada di aplikasi, karena data
//    dilindungi aturan keamanan di database)
// JANGAN pernah memakai "service_role" key di aplikasi.
// ============================================================
class SupabaseConfig {
  static const String url = 'https://kbbnijdnmjqyucfhstzu.supabase.co';
  static const String anonKey = 'sb_publishable_p3YgoVOkBeh-HVTe1hIMcA_UdyHxsDN';

  static bool get isConfigured => !url.startsWith('ISI_') && !anonKey.startsWith('ISI_');
}
