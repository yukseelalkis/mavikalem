import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/core/supabase/supabase_client_provider.dart';
import 'package:mavikalem_app/features/picking/data/datasources/supabase_picking_remote_datasource.dart';
import 'package:mavikalem_app/features/picking/data/repositories/supabase_picking_repository_impl.dart';
import 'package:mavikalem_app/features/picking/domain/repositories/picking_repository.dart';
import 'package:mavikalem_app/features/picking/domain/usecases/add_picked_item.dart';
import 'package:mavikalem_app/features/picking/domain/usecases/watch_order_picking_progress.dart';
import 'package:mavikalem_app/features/picking/domain/usecases/watch_picked_items.dart';

final pickingRemoteDataSourceProvider =
    Provider<SupabasePickingRemoteDataSource>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return SupabasePickingRemoteDataSource(client);
    });

final pickingRepositoryProvider = Provider<PickingRepository>((ref) {
  final remote = ref.watch(pickingRemoteDataSourceProvider);
  return SupabasePickingRepositoryImpl(remote);
});

final addPickedItemUseCaseProvider = Provider<AddPickedItem>((ref) {
  final repository = ref.watch(pickingRepositoryProvider);
  return AddPickedItem(repository);
});

final watchPickedItemsUseCaseProvider = Provider<WatchPickedItems>((ref) {
  final repository = ref.watch(pickingRepositoryProvider);
  return WatchPickedItems(repository);
});

final watchOrderPickingProgressUseCaseProvider =
    Provider<WatchOrderPickingProgress>((ref) {
      final repository = ref.watch(pickingRepositoryProvider);
      return WatchOrderPickingProgress(repository);
    });
