class CampusFixException implements Exception {
  const CampusFixException(this.message);
  final String message;
  @override
  String toString() => message;
}
