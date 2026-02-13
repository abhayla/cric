import 'delivery.dart';

/// Summary of a completed over.
class Over {
  const Over({
    required this.overNumber,
    required this.bowlerId,
    required this.bowlerName,
    this.runsConceded = 0,
    this.wicketsTaken = 0,
    this.isMaiden = false,
    this.deliveries = const [],
  });

  final int overNumber;
  final String bowlerId;
  final String bowlerName;
  final int runsConceded;
  final int wicketsTaken;
  final bool isMaiden;
  final List<Delivery> deliveries;

  /// Number of legal deliveries in this over.
  int get legalBalls =>
      deliveries.where((d) => d.isLegal).length;

  /// Total deliveries (including extras).
  int get totalDeliveries => deliveries.length;

  /// Cricket notation for the full over (e.g. ". 1 4 W . 2").
  String get notation =>
      deliveries.map((d) => d.notation).join(' ');
}
