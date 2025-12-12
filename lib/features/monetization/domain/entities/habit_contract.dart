import 'package:equatable/equatable.dart';

class HabitContract extends Equatable {
  final String id;
  final String userId;
  final String habitId;
  final String partnerEmail;
  final double penaltyAmount;
  final bool isActive;
  final String? signatureUrl;
  final DateTime? signedAt;

  const HabitContract({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.partnerEmail,
    required this.penaltyAmount,
    this.isActive = true,
    this.signatureUrl,
    this.signedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'habitId': habitId,
      'partnerEmail': partnerEmail,
      'penaltyAmount': penaltyAmount,
      'isActive': isActive,
      'signatureUrl': signatureUrl,
      'signedAt': signedAt?.toIso8601String(),
    };
  }

  factory HabitContract.fromMap(Map<String, dynamic> map) {
    return HabitContract(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      habitId: map['habitId'] ?? '',
      partnerEmail: map['partnerEmail'] ?? '',
      penaltyAmount: (map['penaltyAmount'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? false,
      signatureUrl: map['signatureUrl'] as String?,
      signedAt:
          map['signedAt'] != null
              ? DateTime.tryParse(map['signedAt'] as String)
              : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    habitId,
    partnerEmail,
    penaltyAmount,
    isActive,
    signatureUrl,
    signedAt,
  ];
}
