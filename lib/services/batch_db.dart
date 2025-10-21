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
