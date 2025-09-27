enum CallType {
  voice,
  video,
}

enum CallStatus {
  initiating,
  ringing,
  connected,
  ended,
  declined,
  missed,
  busy,
  failed,
}

enum CallDirection {
  incoming,
  outgoing,
}

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerProfileImage;
  final String receiverId;
  final String receiverName;
  final String? receiverProfileImage;
  final CallType callType;
  final CallStatus status;
  final CallDirection direction;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String? callToken;
  final String? roomId;
  final Map<String, dynamic>? metadata;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerProfileImage,
    required this.receiverId,
    required this.receiverName,
    this.receiverProfileImage,
    required this.callType,
    required this.status,
    required this.direction,
    required this.startTime,
    this.endTime,
    this.duration,
    this.callToken,
    this.roomId,
    this.metadata,
  });

  factory CallModel.fromMap(Map<String, dynamic> data) {
    return CallModel(
      id: data['id'] ?? data['_id'] ?? '',
      callerId: data['callerId'] ?? data['caller_id'] ?? '',
      callerName: data['callerName'] ?? data['caller_name'] ?? '',
      callerProfileImage: data['callerProfileImage'] ?? data['caller_profile_image'],
      receiverId: data['receiverId'] ?? data['receiver_id'] ?? '',
      receiverName: data['receiverName'] ?? data['receiver_name'] ?? '',
      receiverProfileImage: data['receiverProfileImage'] ?? data['receiver_profile_image'],
      callType: CallType.values.firstWhere(
        (e) => e.toString() == 'CallType.${data['callType'] ?? data['call_type'] ?? 'voice'}',
        orElse: () => CallType.voice,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.toString() == 'CallStatus.${data['status'] ?? 'initiating'}',
        orElse: () => CallStatus.initiating,
      ),
      direction: CallDirection.values.firstWhere(
        (e) => e.toString() == 'CallDirection.${data['direction'] ?? 'outgoing'}',
        orElse: () => CallDirection.outgoing,
      ),
      startTime: DateTime.tryParse(data['startTime'] ?? data['start_time'] ?? '') ?? DateTime.now(),
      endTime: data['endTime'] != null || data['end_time'] != null 
          ? DateTime.tryParse(data['endTime'] ?? data['end_time'] ?? '')
          : null,
      duration: data['duration'] != null 
          ? Duration(seconds: data['duration'] is int ? data['duration'] : int.tryParse(data['duration'].toString()) ?? 0)
          : null,
      callToken: data['callToken'] ?? data['call_token'],
      roomId: data['roomId'] ?? data['room_id'],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerProfileImage': callerProfileImage,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverProfileImage': receiverProfileImage,
      'callType': callType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'direction': direction.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inSeconds,
      'callToken': callToken,
      'roomId': roomId,
      'metadata': metadata,
    };
  }

  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerProfileImage,
    String? receiverId,
    String? receiverName,
    String? receiverProfileImage,
    CallType? callType,
    CallStatus? status,
    CallDirection? direction,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? callToken,
    String? roomId,
    Map<String, dynamic>? metadata,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerProfileImage: callerProfileImage ?? this.callerProfileImage,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverProfileImage: receiverProfileImage ?? this.receiverProfileImage,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      callToken: callToken ?? this.callToken,
      roomId: roomId ?? this.roomId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  bool get isActive => status == CallStatus.connected || status == CallStatus.ringing;
  bool get isEnded => status == CallStatus.ended || status == CallStatus.declined || status == CallStatus.missed;
  bool get isIncoming => direction == CallDirection.incoming;
  bool get isOutgoing => direction == CallDirection.outgoing;
  bool get isVideoCall => callType == CallType.video;
  bool get isVoiceCall => callType == CallType.voice;

  String get callTypeDisplayName {
    switch (callType) {
      case CallType.voice:
        return 'Voice Call';
      case CallType.video:
        return 'Video Call';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CallStatus.initiating:
        return 'Initiating...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Ended';
      case CallStatus.declined:
        return 'Declined';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.failed:
        return 'Failed';
    }
  }

  String get durationDisplay {
    if (duration == null) return '00:00';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
