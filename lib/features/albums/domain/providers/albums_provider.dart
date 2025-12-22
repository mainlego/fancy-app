import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/access_request_model.dart';
import '../models/album_model.dart';

/// Provider for current user's albums
final myAlbumsProvider = FutureProvider<List<AlbumModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final albumsData = await service.getMyAlbums();
  return albumsData.map((data) => AlbumModel.fromSupabase(data)).toList();
});

/// Provider for default albums (Public and Private)
final defaultAlbumsProvider = FutureProvider<Map<String, AlbumModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final albumsData = await service.getOrCreateDefaultAlbums();
  return {
    'public': AlbumModel.fromSupabase(albumsData['public']!),
    'private': AlbumModel.fromSupabase(albumsData['private']!),
  };
});

/// Provider for specific user's albums (for profile view)
final userAlbumsProvider = FutureProvider.family<List<AlbumModel>, String>((ref, userId) async {
  final service = ref.watch(supabaseServiceProvider);
  // Get all albums, not just public - access is controlled by hasAlbumAccess
  final albumsData = await service.getUserAlbums(userId);
  return albumsData.map((data) => AlbumModel.fromSupabase(data)).toList();
});

/// Provider for access requests (as owner)
final accessRequestsProvider = FutureProvider<List<AccessRequestModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final requestsData = await service.getAccessRequestsAsOwner();
  return requestsData.map((data) => AccessRequestModel.fromSupabase(data)).toList();
});

/// Provider for pending access requests count
final pendingAccessRequestsCountProvider = Provider<int>((ref) {
  final requestsAsync = ref.watch(accessRequestsProvider);
  return requestsAsync.when(
    data: (requests) => requests.where((r) => r.isPending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider to check if user has access to a specific album
final albumAccessProvider = FutureProvider.family<bool, String>((ref, albumId) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.hasAlbumAccess(albumId);
});

/// Provider for access request status for a specific album
final albumAccessRequestStatusProvider = FutureProvider.family<AccessRequestStatus?, String>((ref, albumId) async {
  final service = ref.watch(supabaseServiceProvider);
  final request = await service.getAccessRequestStatus(albumId);
  if (request == null) return null;
  return AccessRequestStatus.values.byName(request['status'] as String? ?? 'pending');
});

/// Albums notifier for managing album operations
class AlbumsNotifier extends StateNotifier<AsyncValue<List<AlbumModel>>> {
  final SupabaseService _service;
  final Ref _ref;

  AlbumsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadAlbums();
  }

  Future<void> loadAlbums() async {
    state = const AsyncValue.loading();
    try {
      final albumsData = await _service.getMyAlbums();
      final albums = albumsData.map((data) => AlbumModel.fromSupabase(data)).toList();
      state = AsyncValue.data(albums);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final albumsData = await _service.getMyAlbums();
      final albums = albumsData.map((data) => AlbumModel.fromSupabase(data)).toList();
      state = AsyncValue.data(albums);
      // Also refresh the default albums provider
      _ref.invalidate(defaultAlbumsProvider);
      _ref.invalidate(myAlbumsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AlbumModel> createAlbum({
    required String name,
    required AlbumPrivacy privacy,
  }) async {
    final albumData = await _service.createAlbum(
      name: name,
      privacy: privacy.name,
    );
    albumData['album_photos'] = [];
    final album = AlbumModel.fromSupabase(albumData);

    state.whenData((albums) {
      state = AsyncValue.data([album, ...albums]);
    });

    return album;
  }

  Future<void> deleteAlbum(String albumId) async {
    await _service.deleteAlbum(albumId);

    state.whenData((albums) {
      state = AsyncValue.data(albums.where((a) => a.id != albumId).toList());
    });
  }

  Future<MediaModel> uploadPhoto({
    required String albumId,
    required String fileName,
    required Uint8List bytes,
    bool isPrivate = false,
  }) async {
    final photoData = await _service.uploadAlbumPhoto(
      albumId: albumId,
      fileName: fileName,
      bytes: bytes,
      isPrivate: isPrivate,
    );
    final media = MediaModel.fromSupabase(photoData);

    state.whenData((albums) {
      final updated = albums.map((album) {
        if (album.id == albumId) {
          return album.copyWith(
            media: [...album.media, media],
            updatedAt: DateTime.now(),
          );
        }
        return album;
      }).toList();
      state = AsyncValue.data(updated);
    });

    // Refresh to get updated data
    _ref.invalidate(defaultAlbumsProvider);
    _ref.invalidate(myAlbumsProvider);

    return media;
  }

  Future<void> deletePhoto(String albumId, String photoId, String photoUrl) async {
    await _service.deleteAlbumPhoto(photoId, photoUrl);

    state.whenData((albums) {
      final updated = albums.map((album) {
        if (album.id == albumId) {
          return album.copyWith(
            media: album.media.where((m) => m.id != photoId).toList(),
            updatedAt: DateTime.now(),
          );
        }
        return album;
      }).toList();
      state = AsyncValue.data(updated);
    });

    // Refresh to get updated data
    _ref.invalidate(defaultAlbumsProvider);
    _ref.invalidate(myAlbumsProvider);
  }
}

/// Provider for albums notifier
final albumsNotifierProvider = StateNotifierProvider<AlbumsNotifier, AsyncValue<List<AlbumModel>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return AlbumsNotifier(service, ref);
});

/// Access requests notifier for managing access request operations with realtime
class AccessRequestsNotifier extends StateNotifier<AsyncValue<List<AccessRequestModel>>> {
  final SupabaseService _service;
  final Ref _ref;
  RealtimeChannel? _subscription;

  AccessRequestsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadRequests();
    _subscribeToRequests();
  }

  void _subscribeToRequests() {
    final currentUserId = _service.currentUser?.id;
    if (currentUserId == null) return;

    final channel = Supabase.instance.client.channel('access_requests_$currentUserId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'album_access_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'owner_id',
        value: currentUserId,
      ),
      callback: (payload) {
        print('📂 AccessRequests: New request received');
        Future.microtask(() => refresh());
      },
    );

    channel.subscribe();
    _subscription = channel;
  }

  Future<void> loadRequests() async {
    state = const AsyncValue.loading();
    try {
      final requestsData = await _service.getAccessRequestsAsOwner();
      final requests = requestsData.map((data) => AccessRequestModel.fromSupabase(data)).toList();
      state = AsyncValue.data(requests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final requestsData = await _service.getAccessRequestsAsOwner();
      final requests = requestsData.map((data) => AccessRequestModel.fromSupabase(data)).toList();
      state = AsyncValue.data(requests);
      _ref.invalidate(accessRequestsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> requestAccess(String albumId, String ownerId) async {
    await _service.requestAlbumAccess(albumId, ownerId);
    // Invalidate status provider for this album
    _ref.invalidate(albumAccessRequestStatusProvider(albumId));
  }

  Future<void> respondToRequest(String requestId, bool approve) async {
    await _service.respondToAccessRequest(requestId, approve);

    state.whenData((requests) {
      final updated = requests.map((request) {
        if (request.id == requestId) {
          return request.copyWith(
            status: approve ? AccessRequestStatus.approved : AccessRequestStatus.denied,
            respondedAt: DateTime.now(),
          );
        }
        return request;
      }).toList();
      // Remove approved/denied from pending list
      state = AsyncValue.data(updated.where((r) => r.isPending).toList());
    });

    _ref.invalidate(accessRequestsProvider);
  }

  Future<void> revokeAccess(String requestId) async {
    await _service.revokeAlbumAccess(requestId);
    await refresh();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

/// Provider for access requests notifier
final accessRequestsNotifierProvider = StateNotifierProvider<AccessRequestsNotifier, AsyncValue<List<AccessRequestModel>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return AccessRequestsNotifier(service, ref);
});
