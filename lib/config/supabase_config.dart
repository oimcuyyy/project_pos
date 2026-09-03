import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://cxpmapnjeybvgquwatth.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_WOeGTrwkAMJAnMKnF9fD0g_XYmVzutP';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }
}
