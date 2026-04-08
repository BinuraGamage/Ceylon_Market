import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CustomRequestMessageModel extends Equatable {
  final String messageId;
  final String requestId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime sentAt;

  const CustomRequestMessageModel({
    required this.messageId,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
  });

  factory CustomRequestMessageModel.fromMap(
    Map<String, dynamic> map,
    String id,
    String requestId,
  ) {
    return CustomRequestMessageModel(
      messageId: id,
      requestId: requestId,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Unknown',
      message: map['message'] as String? ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'message': message,
    'sentAt': Timestamp.fromDate(sentAt),
  };

  CustomRequestMessageModel copyWith({
    String? messageId,
    String? requestId,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? sentAt,
  }) {
    return CustomRequestMessageModel(
      messageId: messageId ?? this.messageId,
      requestId: requestId ?? this.requestId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  List<Object?> get props => [messageId, requestId, senderId, message, sentAt];
}
