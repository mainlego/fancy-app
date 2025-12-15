import 'package:equatable/equatable.dart';

/// Access request status enum
enum AccessRequestStatus {
  pending,
  approved,
  denied,
}

/// Access request model for private album access
class AccessRequestModel extends Equatable {
  final String id;
  final String requesterId; // Who is requesting
  final String ownerId; // Owner of private album
  final String albumId; // Which album
  final AccessRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  // Optional profile data for display
  final String? requesterName;
  final String? requesterAvatarUrl;
  final String? albumName;

  const AccessRequestModel({
    required this.id,
    required this.requesterId,
    required this.ownerId,
    required this.albumId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.requesterName,
    this.requesterAvatarUrl,
    this.albumName,
  });

  bool get isPending => status == AccessRequestStatus.pending;
  bool get isApproved => status == AccessRequestStatus.approved;
  bool get isDenied => status == AccessRequestStatus.denied;

  AccessRequestModel copyWith({
    String? id,
    String? requesterId,
    String? ownerId,
    String? albumId,
    AccessRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? requesterName,
    String? requesterAvatarUrl,
    String? albumName,
  }) {
    return AccessRequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      ownerId: ownerId ?? this.ownerId,
      albumId: albumId ?? this.albumId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      requesterName: requesterName ?? this.requesterName,
      requesterAvatarUrl: requesterAvatarUrl ?? this.requesterAvatarUrl,
      albumName: albumName ?? this.albumName,
    );
  }

  factory AccessRequestModel.fromJson(Map<String, dynamic> json) {
    return AccessRequestModel(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String? ?? json['requester_id'] as String,
      ownerId: json['ownerId'] as String? ?? json['owner_id'] as String,
      albumId: json['albumId'] as String? ?? json['album_id'] as String,
      status: AccessRequestStatus.values.byName(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : json['responded_at'] != null
              ? DateTime.parse(json['responded_at'] as String)
              : null,
      requesterName: json['requesterName'] as String? ?? json['requester_name'] as String?,
      requesterAvatarUrl: json['requesterAvatarUrl'] as String? ?? json['requester_avatar_url'] as String?,
      albumName: json['albumName'] as String? ?? json['album_name'] as String?,
    );
  }

  /// From Supabase JSON (snake_case format)
  factory AccessRequestModel.fromSupabase(Map<String, dynamic> json) {
    // Parse requester profile data if available
    final requesterProfile = json['profiles'] as Map<String, dynamic>?;
    final albumData = json['albums'] as Map<String, dynamic>?;

    String? avatarUrl = requesterProfile?['avatar_url'] as String?;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final photos = requesterProfile?['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) {
        avatarUrl = photos.first as String?;
      }
    }

    return AccessRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      ownerId: json['owner_id'] as String,
      albumId: json['album_id'] as String,
      status: AccessRequestStatus.values.byName(json['status'] as String? ?? 'pending'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      requesterName: requesterProfile?['name'] as String?,
      requesterAvatarUrl: avatarUrl,
      albumName: albumData?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'ownerId': ownerId,
      'albumId': albumId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'requesterName': requesterName,
      'requesterAvatarUrl': requesterAvatarUrl,
      'albumName': albumName,
    };
  }

  /// To Supabase JSON (snake_case format)
  Map<String, dynamic> toSupabase() {
    return {
      'requester_id': requesterId,
      'owner_id': ownerId,
      'album_id': albumId,
      'status': status.name,
    };
  }

  @override
  List<Object?> get props => [
        id,
        requesterId,
        ownerId,
        albumId,
        status,
        createdAt,
        respondedAt,
        requesterName,
        requesterAvatarUrl,
        albumName,
      ];
}
