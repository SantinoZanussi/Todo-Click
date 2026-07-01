import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../data/repositories/shipping_repository_impl.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/repositories/shipping_repository.dart';

final shippingRepositoryProvider = Provider<ShippingRepository>(
  (ref) => ShippingRepositoryImpl(ref.watch(dioProvider)),
);

/// Seguimiento de un envío por código de tracking (para el detalle del pedido).
final shippingTrackProvider =
    FutureProvider.family<List<TrackingEvent>, String>((ref, code) async {
      final result = await ref.watch(shippingRepositoryProvider).track(code);
      return result.fold((f) => throw f, (events) => events);
    });
