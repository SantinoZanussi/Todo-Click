import 'package:equatable/equatable.dart';

/// Evento del seguimiento de un envío.
class TrackingEvent extends Equatable {
  const TrackingEvent({
    required this.status,
    required this.description,
    required this.date,
    this.location,
  });

  final String status;
  final String description;
  final DateTime date;
  final String? location;

  factory TrackingEvent.fromJson(Map<String, dynamic> j) => TrackingEvent(
    status: j['status'] as String? ?? '',
    description: j['description'] as String? ?? '',
    date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
    location: j['location'] as String?,
  );

  @override
  List<Object?> get props => [status, description, date, location];
}
