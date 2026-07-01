import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Notificación in-app (documento de la colección `notificaciones`).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  /// Id del pedido asociado (si la notificación es de un pedido).
  String? get orderId => data['orderId'] as String?;

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    final created = d['createdAt'];
    return AppNotification(
      id: doc.id,
      type: d['type'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      read: d['read'] as bool? ?? false,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      data: (d['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, read, createdAt];
}
