import 'package:equatable/equatable.dart';

/// Media type enum
enum MediaType {
  photo,
  video,
}

/// Album privacy enum
enum AlbumPrivacy {
  public,
  private,
}

/// Media item model
class MediaModel extends Equatable {
  final String id;
  final String albumId;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final int? durationMs;
  final int? width;
  final int? height;
  final DateTime createdAt;

  const MediaModel({
    required this.id,
    required this.albumId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.durationMs,
    this.width,
    this.height,
    required this.createdAt,
  });

  bool get isVideo => type == MediaType.video;
  bool get isPhoto => type == MediaType.photo;

  String get displayUrl => thumbnailUrl ?? url;

  MediaModel copyWith({
    String? id,
    String? albumId,
    MediaType? type,
    String? url,
    String? thumbnailUrl,
    int? durationMs,
    int? width,
    int? height,
    DateTime? createdAt,
  }) {
    return MediaModel(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as String,
      albumId: json['albumId'] as String,
      type: MediaType.values.byName(json['type'] as String),
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationMs: json['durationMs'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'type': type.name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'durationMs': durationMs,
      'width': width,
      'height': height,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        albumId,
        type,
        url,
        thumbnailUrl,
        durationMs,
        width,
        height,
        createdAt,
      ];
}

/// Album model
class AlbumModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AlbumPrivacy privacy;
  final List<MediaModel> media;
  final String? coverUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlbumModel({
    required this.id,
    required this.userId,
    required this.name,
    this.privacy = AlbumPrivacy.public,
    this.media = const [],
    this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPrivate => privacy == AlbumPrivacy.private;
  bool get isEmpty => media.isEmpty;
  int get mediaCount => media.length;
  int get photoCount => media.where((m) => m.isPhoto).length;
  int get videoCount => media.where((m) => m.isVideo).length;

  String? get displayCover => coverUrl ?? (media.isNotEmpty ? media.first.displayUrl : null);

  AlbumModel copyWith({
    String? id,
    String? userId,
    String? name,
    AlbumPrivacy? privacy,
    List<MediaModel>? media,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      privacy: privacy ?? this.privacy,
      media: media ?? this.media,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      privacy: AlbumPrivacy.values.byName(json['privacy'] as String? ?? 'public'),
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => MediaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      coverUrl: json['coverUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'privacy': privacy.name,
      'media': media.map((m) => m.toJson()).toList(),
      'coverUrl': coverUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        privacy,
        media,
        coverUrl,
        createdAt,
        updatedAt,
      ];
}
