import 'package:supabase_flutter/supabase_flutter.dart';

class Batch {
  final String id;
  final int startYear;
  final int endYear;

  Batch({required this.id, required this.startYear, required this.endYear});

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'].toString(),
      startYear: map['start_year'] is int
          ? map['start_year']
          : int.parse(map['start_year'].toString()),
      endYear: map['end_year'] is int
          ? map['end_year']
          : int.parse(map['end_year'].toString()),
    );
  }
}

class BatchDatabase {
  static const _table = 'batches';

  static Future<List<Batch>> getBatches() async {
    try {
      final supabase = Supabase.instance.client;
      print('Fetching batches from Supabase...');
      print('Auth user: ${supabase.auth.currentUser?.id}');
      final response = await supabase.from(_table).select();
      print('Batches response: $response');
      print('Batches response length: ${(response as List).length}');
      return (response as List).map((data) => Batch.fromMap(data)).toList();
    } catch (e, stackTrace) {
      print('Error fetching batches: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<void> createBatch(int startYear, int endYear) async {
    final supabase = Supabase.instance.client;
    await supabase.from(_table).insert({
      'start_year': startYear,
      'end_year': endYear,
    });
  }

  static Future<void> setActiveBatch(String batchId) async {
    final supabase = Supabase.instance.client;
    await supabase.from(_table).update({'is_active': true}).eq('id', batchId);
    await supabase.from(_table).update({'is_active': false}).neq('id', batchId);
  }
}
