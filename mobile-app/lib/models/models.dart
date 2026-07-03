class UserAuth {
  final String userId;
  final String username;
  final String guildId;
  final List<String> capabilities;
  final List<String> roleNames;

  UserAuth({
    required this.userId,
    required this.username,
    required this.guildId,
    required this.capabilities,
    required this.roleNames,
  });

  factory UserAuth.fromJson(Map<String, dynamic> json) => UserAuth(
        userId: json['userId'] ?? '',
        username: json['username'] ?? '',
        guildId: json['guildId'] ?? '',
        capabilities: List<String>.from(json['capabilities'] ?? []),
        roleNames: List<String>.from(json['roleNames'] ?? []),
      );

  bool can(String capability) => capabilities.contains(capability);
}

/// Daftar konstanta kapabilitas — HARUS sama persis dengan backend/config/permissions.js
class Capability {
  static const moderateWarn = 'moderate:warn';
  static const moderateMute = 'moderate:mute';
  static const moderateKick = 'moderate:kick';
  static const moderateBan = 'moderate:ban';
  static const moderateClearWarnings = 'moderate:clear_warnings';
  static const eventsCreate = 'events:create';
  static const eventsDelete = 'events:delete';
  static const dashboardView = 'dashboard:view';
}

class ModAction {
  final String id;
  final String actionType;
  final String targetId;
  final String? targetTag;
  final String moderatorTag;
  final String? reason;
  final DateTime createdAt;
  final String source;

  ModAction({
    required this.id,
    required this.actionType,
    required this.targetId,
    this.targetTag,
    required this.moderatorTag,
    this.reason,
    required this.createdAt,
    required this.source,
  });

  factory ModAction.fromJson(Map<String, dynamic> json) => ModAction(
        id: json['id'],
        actionType: json['action_type'],
        targetId: json['target_id'],
        targetTag: json['target_tag'],
        moderatorTag: json['moderator_tag'] ?? 'Unknown',
        reason: json['reason'],
        createdAt: DateTime.parse(json['created_at']),
        source: json['source'] ?? 'bot',
      );

  /// Emoji & warna dipakai di UI supaya gampang dipindai secara visual
  String get emoji {
    switch (actionType) {
      case 'warn':
        return '⚠️';
      case 'kick':
        return '👢';
      case 'ban':
        return '🔨';
      case 'mute':
        return '🔇';
      case 'unmute':
        return '🔊';
      case 'auto-mute-spam':
        return '🚨';
      default:
        return 'ℹ️';
    }
  }
}

class CommunityEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isRecurring;
  final String createdBy;

  CommunityEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    required this.isRecurring,
    required this.createdBy,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) => CommunityEvent(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startTime: DateTime.parse(json['start_time']),
        endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
        isRecurring: json['is_recurring'] == true,
        createdBy: json['created_by'],
      );
}

class DashboardStats {
  final int memberCount;
  final int onlineCount;
  final int textChannelCount;
  final int voiceChannelCount;
  final int roleCount;
  final int boostCount;
  final int botPing;
  final List<ModAction> recentModActions;
  final int upcomingEventsCount;
  final CommunityEvent? nextEvent;

  DashboardStats({
    required this.memberCount,
    required this.onlineCount,
    required this.textChannelCount,
    required this.voiceChannelCount,
    required this.roleCount,
    required this.boostCount,
    required this.botPing,
    required this.recentModActions,
    required this.upcomingEventsCount,
    this.nextEvent,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        memberCount: json['memberCount'] ?? 0,
        onlineCount: json['onlineCount'] ?? 0,
        textChannelCount: json['textChannelCount'] ?? 0,
        voiceChannelCount: json['voiceChannelCount'] ?? 0,
        roleCount: json['roleCount'] ?? 0,
        boostCount: json['boostCount'] ?? 0,
        botPing: json['botPing'] ?? 0,
        recentModActions: (json['recentModActions'] as List<dynamic>? ?? [])
            .map((e) => ModAction.fromJson(e))
            .toList(),
        upcomingEventsCount: json['upcomingEventsCount'] ?? 0,
        nextEvent: json['nextEvent'] != null ? CommunityEvent.fromJson(json['nextEvent']) : null,
      );
}
