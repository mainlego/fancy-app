import 'package:equatable/equatable.dart';
import '../../../../core/utils/profile_utils.dart';

/// Message type enum
enum MessageType {
  text,
  image,
  video,
  voice,
  gif,
  sticker,
}

/// Message model
class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final MessageType type;
  final String? mediaUrl;
  final int? mediaDurationMs;
  final bool isRead;
  final DateTime createdAt;
  // Private media fields for timed/one-time viewing
  final bool isPrivateMedia; // Is this from private album
  final int? viewDurationSec; // How long can be viewed (null = unlimited)
  final bool oneTimeView; // One-time view only
  final bool hasBeenViewed; // For one-time tracking

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    this.mediaDurationMs,
    this.isRead = false,
    required this.createdAt,
    this.isPrivateMedia = false,
    this.viewDurationSec,
    this.oneTimeView = false,
    this.hasBeenViewed = false,
  });

  bool get isMediaMessage =>
      type == MessageType.image ||
      type == MessageType.video ||
      type == MessageType.voice ||
      type == MessageType.gif ||
      type == MessageType.sticker;

  /// Get image URL (alias for mediaUrl for image messages)
  String? get imageUrl => type == MessageType.image ? mediaUrl : null;

  /// Check if message is from current user (set externally or through currentUserId)
  static String? currentUserId;
  bool get isMe => senderId == currentUserId;

  /// Check if media has view restrictions
  bool get hasViewRestrictions => isPrivateMedia && (viewDurationSec != null || oneTimeView);

  /// Check if media can still be viewed (not a one-time that was already viewed)
  bool get canBeViewed => !oneTimeView || !hasBeenViewed;

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    String? mediaUrl,
    int? mediaDurationMs,
    bool? isRead,
    DateTime? createdAt,
    bool? isPrivateMedia,
    int? viewDurationSec,
    bool? oneTimeView,
    bool? hasBeenViewed,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaDurationMs: mediaDurationMs ?? this.mediaDurationMs,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      isPrivateMedia: isPrivateMedia ?? this.isPrivateMedia,
      viewDurationSec: viewDurationSec ?? this.viewDurationSec,
      oneTimeView: oneTimeView ?? this.oneTimeView,
      hasBeenViewed: hasBeenViewed ?? this.hasBeenViewed,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String?,
      type: MessageType.values.byName(json['type'] as String? ?? 'text'),
      mediaUrl: json['mediaUrl'] as String?,
      mediaDurationMs: json['mediaDurationMs'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPrivateMedia: json['isPrivateMedia'] as bool? ?? false,
      viewDurationSec: json['viewDurationSec'] as int?,
      oneTimeView: json['oneTimeView'] as bool? ?? false,
      hasBeenViewed: json['hasBeenViewed'] as bool? ?? false,
    );
  }

  /// From Supabase JSON (snake_case format)
  factory MessageModel.fromSupabase(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['content'] as String?,
      type: MessageType.values.byName(json['message_type'] as String? ?? 'text'),
      mediaUrl: json['image_url'] as String?,
      mediaDurationMs: json['media_duration_ms'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isPrivateMedia: json['is_private_media'] as bool? ?? false,
      viewDurationSec: json['view_duration_sec'] as int?,
      oneTimeView: json['one_time_view'] as bool? ?? false,
      hasBeenViewed: json['has_been_viewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'mediaDurationMs': mediaDurationMs,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'isPrivateMedia': isPrivateMedia,
      'viewDurationSec': viewDurationSec,
      'oneTimeView': oneTimeView,
      'hasBeenViewed': hasBeenViewed,
    };
  }

  /// To Supabase JSON (snake_case format)
  Map<String, dynamic> toSupabase() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'content': text,
      'message_type': type.name,
      'image_url': mediaUrl,
      'media_duration_ms': mediaDurationMs,
      'is_read': isRead,
      'is_private_media': isPrivateMedia,
      'view_duration_sec': viewDurationSec,
      'one_time_view': oneTimeView,
      'has_been_viewed': hasBeenViewed,
    };
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        text,
        type,
        mediaUrl,
        mediaDurationMs,
        isRead,
        createdAt,
        isPrivateMedia,
        viewDurationSec,
        oneTimeView,
        hasBeenViewed,
      ];
}

/// Chat model
class ChatModel extends Equatable {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatarUrl;
  final bool participantOnline;
  final bool participantVerified;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Whether the other participant has deleted the chat
  final bool deletedByOther;

  const ChatModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatarUrl,
    this.participantOnline = false,
    this.participantVerified = false,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedByOther = false,
  });

  bool get hasUnread => unreadCount > 0;

  ChatModel copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantAvatarUrl,
    bool? participantOnline,
    bool? participantVerified,
    MessageModel? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deletedByOther,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatarUrl: participantAvatarUrl ?? this.participantAvatarUrl,
      participantOnline: participantOnline ?? this.participantOnline,
      participantVerified: participantVerified ?? this.participantVerified,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedByOther: deletedByOther ?? this.deletedByOther,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String,
      participantAvatarUrl: json['participantAvatarUrl'] as String?,
      participantOnline: json['participantOnline'] as bool? ?? false,
      participantVerified: json['participantVerified'] as bool? ?? false,
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedByOther: json['deletedByOther'] as bool? ?? false,
    );
  }

  /// From Supabase JSON (snake_case format)
  /// Handles both join formats: profiles!participant1_id or participant1/participant2
  factory ChatModel.fromSupabase(Map<String, dynamic> json, String currentUserId) {
    // Determine which participant is the other user
    final participant1Id = json['participant1_id'] as String?;
    final isParticipant1 = participant1Id == currentUserId;

    // Try different profile key formats (join vs separate load)
    Map<String, dynamic>? participantProfile;

    // Format 1: profiles!participantX_id (from join)
    final joinKey = isParticipant1 ? 'profiles!participant2_id' : 'profiles!participant1_id';
    participantProfile = json[joinKey] as Map<String, dynamic>?;

    // Format 2: participantX (from separate load in getChats)
    if (participantProfile == null) {
      final separateKey = isParticipant1 ? 'participant2' : 'participant1';
      participantProfile = json[separateKey] as Map<String, dynamic>?;
    }

    // Get avatar using utility function
    final avatarUrl = getDisplayAvatar(participantProfile);

    // Get last message from messages array if available
    MessageModel? lastMessage;
    final messages = json['messages'] as List<dynamic>?;
    if (messages != null && messages.isNotEmpty) {
      final lastMsgData = messages.first as Map<String, dynamic>;
      final messageType = MessageType.values.byName(
        lastMsgData['message_type'] as String? ?? 'text',
      );
      lastMessage = MessageModel(
        id: lastMsgData['id'] as String? ?? 'last',
        chatId: json['id'] as String,
        senderId: lastMsgData['sender_id'] as String? ?? '',
        text: lastMsgData['content'] as String?,
        type: messageType,
        mediaUrl: lastMsgData['image_url'] as String?,
        createdAt: lastMsgData['created_at'] != null
            ? DateTime.parse(lastMsgData['created_at'] as String)
            : DateTime.now(),
      );
    }

    // Check if the other participant deleted the chat
    final deletedByOther = isParticipant1
        ? (json['deleted_by_participant2'] as bool? ?? false)
        : (json['deleted_by_participant1'] as bool? ?? false);

    return ChatModel(
      id: json['id'] as String,
      participantId: participantProfile?['id'] as String? ??
          (isParticipant1 ? json['participant2_id'] as String : json['participant1_id'] as String),
      participantName: participantProfile?['name'] as String? ??
          participantProfile?['display_name'] as String? ?? 'Unknown',
      participantAvatarUrl: avatarUrl,
      participantOnline: participantProfile?['is_online'] as bool? ?? false,
      participantVerified: participantProfile?['is_verified'] as bool? ?? false,
      lastMessage: lastMessage,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      deletedByOther: deletedByOther,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatarUrl': participantAvatarUrl,
      'participantOnline': participantOnline,
      'participantVerified': participantVerified,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedByOther': deletedByOther,
    };
  }

  @override
  List<Object?> get props => [
        id,
        participantId,
        participantName,
        participantAvatarUrl,
        participantOnline,
        participantVerified,
        lastMessage,
        unreadCount,
        createdAt,
        updatedAt,
        deletedByOther,
      ];
}

/// Like model (for Likes tab)
class LikeModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int userAge;
  final bool isSuperLike;
  final bool isMatched;
  final DateTime createdAt;

  const LikeModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.userAge,
    this.isSuperLike = false,
    this.isMatched = false,
    required this.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      userAge: json['userAge'] as int,
      isSuperLike: json['isSuperLike'] as bool? ?? false,
      isMatched: json['isMatched'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// From Supabase JSON (snake_case format)
  /// Expects profile data from join: profiles!from_user_id
  factory LikeModel.fromSupabase(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;

    // Calculate age using utility function
    final age = calculateAgeFromString(profileData?['birth_date'] as String?);

    // Get avatar using utility function
    final avatarUrl = getDisplayAvatar(profileData);

    return LikeModel(
      id: json['from_user_id'] as String? ?? '',
      userId: json['from_user_id'] as String? ?? profileData?['id'] as String? ?? '',
      userName: profileData?['name'] as String? ??
          profileData?['display_name'] as String? ?? 'Unknown',
      userAvatarUrl: avatarUrl,
      userAge: age,
      isSuperLike: json['is_super_like'] as bool? ?? false,
      isMatched: false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'userAge': userAge,
      'isSuperLike': isSuperLike,
      'isMatched': isMatched,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userAvatarUrl,
        userAge,
        isSuperLike,
        isMatched,
        createdAt,
      ];
}

/// Favorite model (for Favs tab)
class FavoriteModel extends Equatable {
  final String id;
  final String oderId;
  final String userName;
  final String? userAvatarUrl;
  final int userAge;
  final bool isOnline;
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.oderId,
    required this.userName,
    this.userAvatarUrl,
    required this.userAge,
    this.isOnline = false,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      oderId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      userAge: json['userAge'] as int,
      isOnline: json['isOnline'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// From Supabase JSON (snake_case format)
  /// Expects profile data from join
  factory FavoriteModel.fromSupabase(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;

    // Calculate age using utility function
    final age = calculateAgeFromString(profileData?['birth_date'] as String?);

    // Get avatar using utility function
    final avatarUrl = getDisplayAvatar(profileData);

    return FavoriteModel(
      id: json['id'] as String? ?? '',
      oderId: json['favorite_user_id'] as String? ?? profileData?['id'] as String? ?? '',
      userName: profileData?['name'] as String? ??
          profileData?['display_name'] as String? ?? 'Unknown',
      userAvatarUrl: avatarUrl,
      userAge: age,
      isOnline: profileData?['is_online'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': oderId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'userAge': userAge,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        oderId,
        userName,
        userAvatarUrl,
        userAge,
        isOnline,
        createdAt,
      ];
}
